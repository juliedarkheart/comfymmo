param(
    [string]$GodotExe = "D:\Tools\Godot_v4.6.3-stable_win64.exe",
    [switch]$Editor,
    [switch]$Headless,
    [switch]$SmokeTest,
    [int]$TimeoutSeconds = 0,
    [string[]]$GodotArgs = @()
)

$ErrorActionPreference = "Stop"

function Resolve-GodotExecutable {
    param(
        [string]$RequestedPath,
        [bool]$UseConsoleBuild
    )

    if (-not (Test-Path -LiteralPath $RequestedPath)) {
        throw "Godot executable or install folder not found at '$RequestedPath'. Pass -GodotExe with the installed path."
    }

    $item = Get-Item -LiteralPath $RequestedPath
    if (-not $item.PSIsContainer) {
        return $item.FullName
    }

    $exePattern = if ($UseConsoleBuild) { "*_console.exe" } else { "Godot*.exe" }
    $resolvedExe = Get-ChildItem -LiteralPath $RequestedPath -Filter $exePattern |
        Sort-Object Name |
        Select-Object -First 1

    if (-not $resolvedExe) {
        throw "No Godot executable found inside '$RequestedPath'."
    }

    return $resolvedExe.FullName
}

function Remove-TempFileIfPresent {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    }
}

function Write-RedirectedOutput {
    param(
        [string]$StdOutPath,
        [string]$StdErrPath
    )

    if (Test-Path -LiteralPath $StdOutPath) {
        Get-Content -LiteralPath $StdOutPath | ForEach-Object {
            Write-Output $_
        }
    }

    if (Test-Path -LiteralPath $StdErrPath) {
        Get-Content -LiteralPath $StdErrPath | ForEach-Object {
            Write-Error $_
        }
    }
}

function Stop-ProcessTree {
    param([int]$ProcessId)

    $taskkill = Get-Command taskkill.exe -ErrorAction SilentlyContinue
    if ($taskkill) {
        & $taskkill.Source /PID $ProcessId /T /F | Out-Null
        return
    }

    Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}

function ConvertTo-ProcessArgumentString {
    param([string[]]$ArgumentList)

    $escapedArguments = foreach ($argument in $ArgumentList) {
        if ($null -eq $argument) {
            '""'
            continue
        }

        '"' + ($argument -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
    }

    return [string]::Join(' ', $escapedArguments)
}

function Invoke-ManagedGodot {
    param(
        [string]$ExecutablePath,
        [string[]]$ArgumentList,
        [string]$WorkingDirectory,
        [int]$TimeoutSecondsValue
    )

    $stdoutPath = Join-Path ([System.IO.Path]::GetTempPath()) ("godot_stdout_{0}.log" -f ([guid]::NewGuid().ToString("N")))
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ("godot_stderr_{0}.log" -f ([guid]::NewGuid().ToString("N")))

    $stdoutEvent = $null
    $stderrEvent = $null
    $process = $null

    try {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $ExecutablePath
        $startInfo.Arguments = ConvertTo-ProcessArgumentString -ArgumentList $ArgumentList
        $startInfo.WorkingDirectory = $WorkingDirectory
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo

        # PowerShell 5.1 cannot pass a ScriptBlock to TaskFactory.StartNew as a
        # delegate, so capture output asynchronously via process events instead.
        # The StringBuilders are passed through -MessageData and appended to from
        # the (serialized) PowerShell event loop, avoiding the read/WaitForExit
        # buffer deadlock that synchronous ReadToEnd() would risk.
        $stdoutBuilder = New-Object System.Text.StringBuilder
        $stderrBuilder = New-Object System.Text.StringBuilder

        $appendAction = {
            if ($null -ne $EventArgs.Data) {
                [void]$Event.MessageData.AppendLine($EventArgs.Data)
            }
        }

        $stdoutEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived `
            -MessageData $stdoutBuilder -Action $appendAction
        $stderrEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived `
            -MessageData $stderrBuilder -Action $appendAction

        [void]$process.Start()
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()

        if ($TimeoutSecondsValue -gt 0) {
            $exited = $process.WaitForExit($TimeoutSecondsValue * 1000)
            if (-not $exited) {
                Stop-ProcessTree -ProcessId $process.Id
                $process.WaitForExit()
                # Block-less overload flushes any pending async output.
                $process.WaitForExit()
                [System.IO.File]::WriteAllText($stdoutPath, $stdoutBuilder.ToString())
                [System.IO.File]::WriteAllText($stderrPath, $stderrBuilder.ToString())
                Write-RedirectedOutput -StdOutPath $stdoutPath -StdErrPath $stderrPath
                throw "Godot helper timed out after $TimeoutSecondsValue seconds and cleaned up process tree rooted at PID $($process.Id)."
            }
        } else {
            $process.WaitForExit()
        }

        # Call the parameterless overload after exit so the remaining async
        # output is flushed into the builders before we read them.
        $process.WaitForExit()

        [System.IO.File]::WriteAllText($stdoutPath, $stdoutBuilder.ToString())
        [System.IO.File]::WriteAllText($stderrPath, $stderrBuilder.ToString())
        Write-RedirectedOutput -StdOutPath $stdoutPath -StdErrPath $stderrPath
        return $process.ExitCode
    }
    finally {
        if ($stdoutEvent) { Unregister-Event -SourceIdentifier $stdoutEvent.Name -ErrorAction SilentlyContinue }
        if ($stderrEvent) { Unregister-Event -SourceIdentifier $stderrEvent.Name -ErrorAction SilentlyContinue }
        if ($process) { $process.Dispose() }
        Remove-TempFileIfPresent -Path $stdoutPath
        Remove-TempFileIfPresent -Path $stderrPath
    }
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$useConsoleBuild = $Headless -or $SmokeTest
$resolvedGodotExe = Resolve-GodotExecutable -RequestedPath $GodotExe -UseConsoleBuild:$useConsoleBuild

$args = @("--path", $projectRoot)

if ($Editor) {
    $args += "--editor"
}

if ($Headless -or $SmokeTest) {
    $args += "--headless"
}

if ($SmokeTest) {
    $args += @("--script", "res://tools/validate_project.gd")
}

$args += $GodotArgs

$isManualEditorLaunch = $Editor -and -not $Headless -and -not $SmokeTest -and $TimeoutSeconds -le 0
if ($isManualEditorLaunch) {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $resolvedGodotExe
    $startInfo.Arguments = ConvertTo-ProcessArgumentString -ArgumentList $args
    $startInfo.WorkingDirectory = $projectRoot
    $startInfo.UseShellExecute = $true

    $process = [System.Diagnostics.Process]::Start($startInfo)
    Write-Output ("Launched Godot editor (PID {0})." -f $process.Id)
    return
}

$exitCode = Invoke-ManagedGodot `
    -ExecutablePath $resolvedGodotExe `
    -ArgumentList $args `
    -WorkingDirectory $projectRoot `
    -TimeoutSecondsValue $TimeoutSeconds

exit $exitCode
