param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("concept", "sprite", "texture", "lora")]
  [string]$Kind,

  [Parameter(Mandatory = $true)]
  [string]$Subject,

  [Parameter(Mandatory = $true)]
  [string]$Variant,

  [string]$Domain = "environment",

  [ValidateSet("generated", "approved", "staging", "reviewed", "published")]
  [string]$Stage = "generated",

  [ValidateSet("sdxl", "flux", "custom", "none")]
  [string]$ModelFamily = "sdxl"
)

$root = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $root "assets\\metadata\\templates\\asset_manifest.template.json"

function Get-BaseFolder {
  param([string]$AssetKind, [string]$AssetStage)

  if ($AssetStage -eq "published") {
    return Join-Path $root "assets\\published"
  }

  if ($AssetStage -in @("staging", "reviewed")) {
    return Join-Path $root "assets\\imports\\$AssetStage"
  }

  switch ($AssetKind) {
    "concept" { return Join-Path $root "assets\\concepts\\$AssetStage" }
    "sprite" { return Join-Path $root "assets\\sprites\\$AssetStage" }
    "texture" { return Join-Path $root "assets\\textures\\$AssetStage" }
    "lora" { return Join-Path $root "assets\\lora\\datasets" }
  }

  throw "Unsupported asset kind: $AssetKind"
}

function New-Slug {
  param([string]$Value)

  $normalized = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "_"
  return $normalized.Trim("_")
}

function Convert-ToDisplayName {
  param([string]$Value)

  $parts = (New-Slug $Value).Split("_", [System.StringSplitOptions]::RemoveEmptyEntries)
  return (($parts | ForEach-Object {
    if ($_.Length -gt 0) {
      $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1)
    }
  }) -join " ")
}

function Get-NextVersion {
  param(
    [string]$BundleRoot,
    [string]$BundlePrefix
  )

  if (-not (Test-Path $BundleRoot)) {
    return 1
  }

  $existing = Get-ChildItem -Path $BundleRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "^$([regex]::Escape($BundlePrefix))_v([0-9]{3})$" } |
    ForEach-Object { [int]$Matches[1] }

  if (-not $existing) {
    return 1
  }

  return (($existing | Measure-Object -Maximum).Maximum + 1)
}

$kindSlug = New-Slug $Kind
$subjectSlug = New-Slug $Subject
$variantSlug = New-Slug $Variant
$bundleRoot = Get-BaseFolder -AssetKind $Kind -AssetStage $Stage
$bundlePrefix = "{0}_{1}_{2}" -f $kindSlug, $subjectSlug, $variantSlug
$version = Get-NextVersion -BundleRoot $bundleRoot -BundlePrefix $bundlePrefix
$assetId = "{0}_v{1}" -f $bundlePrefix, $version.ToString("000")
$bundlePath = Join-Path $bundleRoot $assetId

if (Test-Path $bundlePath) {
  throw "Bundle already exists: $bundlePath"
}

New-Item -ItemType Directory -Path $bundlePath -Force | Out-Null

if ($Stage -ne "published") {
  # Pipeline staging folders hold raw/empty placeholders; .gdignore keeps the
  # Godot importer from trying (and failing) to import them.
  $gdignorePath = Join-Path $bundleRoot ".gdignore"
  if (-not (Test-Path $gdignorePath)) {
    New-Item -ItemType File -Path $gdignorePath | Out-Null
  }
}
New-Item -ItemType File -Path (Join-Path $bundlePath "preview.png") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $bundlePath "output.png") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $bundlePath "workflow.json") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $bundlePath "notes.md") -Force | Out-Null

$manifest = Get-Content $templatePath -Raw | ConvertFrom-Json
$manifest.asset_id = $assetId
$manifest.display_name = @(
  Convert-ToDisplayName $Subject
  Convert-ToDisplayName $Variant
) -join " "
$manifest.kind = $Kind
$manifest.domain = (New-Slug $Domain)
$manifest.status = $Stage
$manifest.version = $version
$manifest.model_family = $ModelFamily
$manifest.created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$manifest.tags = @($kindSlug, (New-Slug $Domain))
$manifest.import_target = (New-Slug $Domain)
$manifest.upstream_concept = ""
$manifest.prompt_summary = ""
$manifest.negative_prompt_summary = ""
$manifest.seed = 0

$manifest | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $bundlePath "asset.json")

Write-Output "Created asset bundle: $bundlePath"
