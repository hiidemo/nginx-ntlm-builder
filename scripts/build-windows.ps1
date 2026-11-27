
$ErrorActionPreference = "Stop"

$Root = (Get-Location).Path
$Version = $env:NGINX_VERSION
$Package = "nginx-$Version-ntlm-windows-x64"

$Source = Join-Path $Root "nginx-$Version"
$Dist = Join-Path $Root "dist"
$Target = Join-Path $Dist $Package

Write-Host "========================================"
Write-Host "Building NGINX for Windows x64"
Write-Host "NGINX: $Version"
Write-Host "NTLM: $env:NTLM_COMMIT"
Write-Host "========================================"

# 1. Compile NGINX

Set-Location $Source

nmake.exe /f objs/Makefile

if ($LASTEXITCODE -ne 0) {
    throw "NGINX compilation failed"
}

if (-not (Test-Path "objs/nginx.exe")) {
    throw "nginx.exe not found"
}

# 2. Prepare deployment directory

New-Item -ItemType Directory -Force $Target | Out-Null

New-Item -ItemType Directory -Force `
    "$Target/logs",
    "$Target/temp",
    "$Target/licenses" | Out-Null

Copy-Item "$Source/objs/nginx.exe" $Target

Copy-Item "$Source/conf" $Target -Recurse

Copy-Item "$Source/html" $Target -Recurse

Copy-Item "$Source/LICENSE" `
    "$Target/licenses/nginx.txt"

Copy-Item "$Root/configs/ntlm-test.conf" `
    "$Target/conf/ntlm-test.conf"

Get-ChildItem "$Root/ntlm-module" -File |
    Where-Object {
        $_.Name -like "LICENSE*" -or
        $_.Name -like "COPYING*"
    } |
    ForEach-Object {
        Copy-Item $_.FullName `
            "$Target/licenses/NTLM-$($_.Name)"
    }

# Preserve empty folders in the archive

New-Item -ItemType File -Force `
    "$Target/logs/placeholder.txt",
    "$Target/temp/placeholder.txt" | Out-Null

# 3. Verify binary and module

Set-Location $Target

.\nginx.exe -V

if ($LASTEXITCODE -ne 0) {
    throw "NGINX version check failed"
}

.\nginx.exe -t -c conf/ntlm-test.conf

if ($LASTEXITCODE -ne 0) {
    throw "NTLM configuration test failed"
}

# 4. Create start.bat

@'
@echo off
cd /d "%~dp0"
nginx.exe -t
if errorlevel 1 exit /b 1
start "" nginx.exe
'@ | Set-Content "start.bat" -Encoding ascii

# 5. Create stop.bat

@'
@echo off
cd /d "%~dp0"
nginx.exe -s quit
'@ | Set-Content "stop.bat" -Encoding ascii

# 6. Create reload.bat

@'
@echo off
cd /d "%~dp0"
nginx.exe -t
if errorlevel 1 exit /b 1
nginx.exe -s reload
'@ | Set-Content "reload.bat" -Encoding ascii

# 7. Create test.bat

@'
@echo off
cd /d "%~dp0"
nginx.exe -t
pause
'@ | Set-Content "test.bat" -Encoding ascii

# 8. Save build information

@(
    "NGINX_VERSION=$Version"
    "NGINX_SHA256=$env:NGINX_SHA256"
    "NTLM_COMMIT=$env:NTLM_COMMIT"
    "PLATFORM=Windows"
    "ARCHITECTURE=x64"
    "BUILD_DATE=$([DateTime]::UtcNow.ToString('o'))"
) | Set-Content "build-info.txt"

.\nginx.exe -V 2>&1 |
    Out-File "build-info.txt" -Append

Select-String `
    -Path "$Root/ntlm-module/utils/build_common.sh" `
    -Pattern '^(PCRE2|OPENSSL|ZLIB)_VERSION=' |
    ForEach-Object { $_.Line } |
    Out-File "build-info.txt" -Append

# 9. Create ZIP archive

Set-Location $Dist

Compress-Archive `
    -Path $Target `
    -DestinationPath "$Package.zip" `
    -Force

# 10. Generate SHA256

$Hash = Get-FileHash `
    "$Package.zip" `
    -Algorithm SHA256

"$($Hash.Hash.ToLower())  $Package.zip" |
    Set-Content "$Package.zip.sha256" -Encoding ascii

Write-Host "========================================"
Write-Host "WINDOWS BUILD SUCCESSFUL"
Write-Host "========================================"

Get-Item "$Package.zip"

Get-Content "$Package.zip.sha256"
