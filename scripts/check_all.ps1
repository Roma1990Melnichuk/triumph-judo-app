# Full quality check -- run before any release.
# Usage: .\scripts\check_all.ps1
# Success criteria:
#   flutter analyze  -- 0 errors (warnings/infos are OK)
#   flutter test     -- all tests green
#   flutter build    -- debug APK builds without errors

$ErrorActionPreference = 'Continue'
$failed = @()

function Step($label, $cmd) {
    Write-Host ""
    Write-Host "=== $label ===" -ForegroundColor Cyan
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: $label" -ForegroundColor Red
        $script:failed += $label
    } else {
        Write-Host "OK: $label" -ForegroundColor Green
    }
}

Step "flutter analyze" "flutter analyze --no-fatal-infos --no-fatal-warnings"
Step "flutter test"    "flutter test --reporter compact"
Step "debug build"     "flutter build apk --debug --quiet"

Write-Host ""
if ($failed.Count -eq 0) {
    Write-Host "All checks passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Failed steps: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
