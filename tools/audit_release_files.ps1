param([switch]$SourceOnly)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$forbidden = @("shrububu- child", "shrububu- older", "desktop.ini")
$candidates = git -C $root ls-files --cached --others --exclude-standard
$violations = @()

foreach ($relativePath in $candidates) {
    $normalized = $relativePath.Replace("\", "/")
    foreach ($name in $forbidden) {
        if ($normalized.ToLowerInvariant().Contains($name.ToLowerInvariant())) {
            $violations += "Forbidden private path: $relativePath"
        }
    }
    if ($normalized.StartsWith(".godot/") -or $normalized.Contains("/node_modules/") -or $normalized.StartsWith("tools/godot/")) {
        $violations += "Generated/development file is not ignored: $relativePath"
    }
    $absolute = Join-Path $root $relativePath
    if (Test-Path $absolute -PathType Leaf) {
        $length = (Get-Item $absolute).Length
        if ($length -gt 95MB) {
            $violations += "Repository file exceeds 95 MB: $relativePath ($length bytes)"
        }
    }
}

$exportConfig = Get-Content (Join-Path $root "export_presets.cfg") -Raw
foreach ($requiredExclusion in @("tests/*", "docs/*", "tools/*", "electron/*", "site/*", "marketing/*", "release/*")) {
    if (-not $exportConfig.Contains($requiredExclusion)) {
        $violations += "Web export exclusion is missing: $requiredExclusion"
    }
}

$builderConfig = Get-Content (Join-Path $root "electron/electron-builder.yml") -Raw
foreach ($requiredScope in @("main.cjs", "preload.cjs", "renderer/**/*", "godot-export/web/**/*", "assets/**/*")) {
    if (-not $builderConfig.Contains($requiredScope)) {
        $violations += "Electron package allowlist is missing: $requiredScope"
    }
}

if (-not $SourceOnly) {
    $webRoot = Join-Path $root "electron/godot-export/web"
    foreach ($required in @("index.html", "index.js", "index.wasm", "index.pck")) {
        if (-not (Test-Path (Join-Path $webRoot $required))) {
            $violations += "Web export is missing $required"
        }
    }
    $windowsArtifacts = Get-ChildItem (Join-Path $root "electron/dist") -Filter "*.exe" -ErrorAction SilentlyContinue
    if ($windowsArtifacts.Count -lt 2) {
        $violations += "Windows installer and portable artifacts were not both produced"
    }
}

$reportDir = Join-Path $root "builds/qa"
New-Item -ItemType Directory -Force $reportDir | Out-Null
[ordered]@{
    generated_at = (Get-Date).ToString("o")
    source_only = [bool]$SourceOnly
    checked_files = $candidates.Count
    violations = $violations
    passed = $violations.Count -eq 0
} | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $reportDir "release-file-audit.json")

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    exit 1
}
Write-Host "Release file audit passed."
