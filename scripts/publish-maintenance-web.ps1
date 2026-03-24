$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectDir = Join-Path $repoRoot "maintenance_assistant"
$buildDir = Join-Path $projectDir "build\web"
$docsDir = Join-Path $repoRoot "docs"

Write-Host "Building Flutter web app..."
Push-Location $projectDir
try {
    flutter build web --release --base-href /Flutter/
}
finally {
    Pop-Location
}

if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir | Out-Null
}

Write-Host "Syncing build/web to docs..."
robocopy $buildDir $docsDir /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) {
    throw "robocopy failed with exit code $LASTEXITCODE"
}

Write-Host "Done. Commit and push the docs/ directory to publish."
