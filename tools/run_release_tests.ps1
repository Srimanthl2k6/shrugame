param(
    [string]$GodotBin = "",
    [switch]$IncludeLegacy
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $GodotBin) {
    $GodotBin = Join-Path $root "tools/godot/Godot_v4.7-stable_win64_console.exe"
}
if (-not (Test-Path $GodotBin)) {
    throw "Godot console binary not found: $GodotBin"
}

$releaseTests = @(
    "tests/pass30_difficulty_data_smoke.gd",
    "tests/pass31_difficulty_menu_smoke.gd",
    "tests/pass32_difficulty_battle_tuning_smoke.gd",
    "tests/pass33_ending_birthday_message_smoke.gd",
    "tests/pass35_cutscene_director_smoke.gd",
    "tests/pass37_final_ui_smoke.gd",
    "tests/pass38_shrububu_animation_smoke.gd",
    "tests/pass39_level01_final_art_smoke.gd",
    "tests/pass40_level01_story_staging_smoke.gd",
    "tests/pass41_battle_dodging_and_defeat_smoke.gd",
    "tests/pass42_premium_level_backplates_smoke.gd",
    "tests/pass43_shrububu_photo_identity_smoke.gd",
    "tests/pass44_level02_premium_cast_and_flow_smoke.gd",
    "tests/pass45_level03_berry_barks_premium_smoke.gd",
    "tests/pass46_level04_auticity_premium_smoke.gd",
    "tests/pass47_production_baseline_smoke.gd",
    "tests/pass48_room_architecture_smoke.gd",
    "tests/pass50_art_scale_contract_smoke.gd",
    "tests/pass51_battle_production_framework_smoke.gd",
    "tests/pass52_61_production_districts_smoke.gd",
    "tests/pass62_narrative_editorial_smoke.gd",
    "tests/pass63_art_cutscene_smoke.gd",
    "tests/pass64_audio_gamefeel_smoke.gd",
    "tests/pass65_accessibility_menu_smoke.gd",
    "tests/pass66_release_hardening_smoke.gd",
    "tests/pass67_site_contract_smoke.gd",
    "tests/pass68_ci_packaging_contract_smoke.gd",
    "tests/pass69_progression_and_combat_qa.gd"
)

if ($IncludeLegacy) {
    $releaseTests = Get-ChildItem (Join-Path $root "tests") -Filter "*.gd" |
        Where-Object { $_.Name -notlike "*.uid" } |
        Sort-Object Name |
        ForEach-Object { "tests/$($_.Name)" }
}

$logDir = Join-Path $root "builds/qa/test-logs"
New-Item -ItemType Directory -Force $logDir | Out-Null
$failed = @()
$started = Get-Date

foreach ($relativeTest in $releaseTests) {
    $testPath = Join-Path $root $relativeTest
    if (-not (Test-Path $testPath)) {
        $failed += "$relativeTest (missing)"
        continue
    }
    Write-Host "[QA] $relativeTest"
    $previousErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $GodotBin --headless --path $root --script $testPath 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorPreference
    $safeName = [IO.Path]::GetFileNameWithoutExtension($testPath)
    $output | Set-Content (Join-Path $logDir "$safeName.log")
    $output | Write-Host
    if ($exitCode -ne 0 -or $output -match "SCRIPT ERROR|Parse Error|Failed loading resource") {
        $failed += $relativeTest
    }
}

$summary = [ordered]@{
    started_at = $started.ToString("o")
    completed_at = (Get-Date).ToString("o")
    tests_run = $releaseTests.Count
    failures = $failed
    passed = $failed.Count -eq 0
}
$summary | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $root "builds/qa/release-test-summary.json")

if ($failed.Count -gt 0) {
    throw "Release test failures: $($failed -join ', ')"
}
Write-Host "Release regression suite passed: $($releaseTests.Count) tests."
