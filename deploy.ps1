#!/usr/bin/env pwsh
# Build Flutter web and deploy to Firebase Hosting
# Usage: .\deploy.ps1 [-Preview]

param (
    [switch]$Preview   # pass -Preview to do a channel preview instead of live deploy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n==> Building Flutter web (release)..." -ForegroundColor Cyan
flutter build web --release --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter build failed. Aborting deploy."
    exit 1
}

if ($Preview) {
    Write-Host "`n==> Deploying to Firebase preview channel..." -ForegroundColor Cyan
    firebase hosting:channel:deploy preview --expires 7d
} else {
    Write-Host "`n==> Deploying to Firebase Hosting (live)..." -ForegroundColor Cyan
    firebase deploy --only hosting
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Firebase deploy failed."
    exit 1
}

Write-Host "`n==> Done!" -ForegroundColor Green
