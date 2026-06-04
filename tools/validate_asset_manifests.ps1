param(
  [string]$AssetsRoot = ".\\assets"
)

$requiredKeys = @(
  "asset_id",
  "display_name",
  "kind",
  "domain",
  "status",
  "version",
  "canonical_file",
  "workflow_file",
  "generator",
  "model_family",
  "created_at",
  "tags"
)

$manifestFiles = Get-ChildItem -Path $AssetsRoot -Recurse -Filter "asset.json" -File
$errors = @()

foreach ($manifestFile in $manifestFiles) {
  try {
    $manifest = Get-Content $manifestFile.FullName -Raw | ConvertFrom-Json
  }
  catch {
    $errors += "Invalid JSON: $($manifestFile.FullName)"
    continue
  }

  foreach ($key in $requiredKeys) {
    if (-not ($manifest.PSObject.Properties.Name -contains $key)) {
      $errors += "Missing '$key' in $($manifestFile.FullName)"
    }
  }

  if ($manifest.asset_id -notmatch '^[a-z0-9]+(_[a-z0-9]+)*_v[0-9]{3}$') {
    $errors += "Invalid asset_id format in $($manifestFile.FullName): $($manifest.asset_id)"
  }

  $bundleName = Split-Path -Leaf (Split-Path -Parent $manifestFile.FullName)
  if ($manifest.asset_id -and $bundleName -ne $manifest.asset_id) {
    $errors += "Bundle folder name does not match asset_id in $($manifestFile.FullName)"
  }

  if ($manifest.canonical_file) {
    $canonicalPath = Join-Path (Split-Path -Parent $manifestFile.FullName) $manifest.canonical_file
    if (-not (Test-Path $canonicalPath)) {
      $errors += "Missing canonical file in bundle $($manifestFile.FullName): $($manifest.canonical_file)"
    }
  }

  if ($manifest.workflow_file) {
    $workflowPath = Join-Path (Split-Path -Parent $manifestFile.FullName) $manifest.workflow_file
    if (-not (Test-Path $workflowPath)) {
      $errors += "Missing workflow file in bundle $($manifestFile.FullName): $($manifest.workflow_file)"
    }
  }
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Output $_ }
  exit 1
}

Write-Output "Validated $($manifestFiles.Count) asset manifest(s) successfully."
