# PowerShell script to verify build steps

Write-Host "=== Project root files ===" -ForegroundColor Green
ls -la

Write-Host "" 
Write-Host "=== Resources/ ===" -ForegroundColor Green
ls -la Resources/

Write-Host ""
Write-Host "=== Resources/web/ ===" -ForegroundColor Green
ls -la Resources/web/

Write-Host ""
Write-Host "=== iOS-SmartWebView-Info.plist ===" -ForegroundColor Green
if (Test-Path "iOS-SmartWebView-Info.plist") {
    cat "iOS-SmartWebView-Info.plist"
} else {
    Write-Host "ERROR: iOS-SmartWebView-Info.plist not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== iOS-SmartWebView.entitlements ===" -ForegroundColor Green
if (Test-Path "iOS-SmartWebView.entitlements") {
    cat "iOS-SmartWebView.entitlements"
} else {
    Write-Host "ERROR: iOS-SmartWebView.entitlements not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== swv.properties ===" -ForegroundColor Green
if (Test-Path "Resources/swv.properties") {
    cat "Resources/swv.properties"
} else {
    Write-Host "ERROR: Resources/swv.properties not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== pbxproj check ===" -ForegroundColor Green
Select-String -Path "iOS-SmartWebView.xcodeproj/project.pbxproj" -Pattern "INFOPLIST" -CaseSensitive:$false