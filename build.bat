@echo off
setlocal enabledelayedexpansion

REM checking param
if "%~1"=="" (
    echo Usage: build.bat ^<platform^>
    echo Allowed: windows ^| android ^| ios
    exit /b 1
)

set PLATFORM=%~1

REM paramter/platform validatoin
if /I not "%PLATFORM%"=="windows" if /I not "%PLATFORM%"=="android" if /I not "%PLATFORM%"=="ios" (
    echo Invalid platform: %PLATFORM%
    echo Allowed platforms: windows, android, ios
    exit /b 1
)

set BASE_PROFILE=%PLATFORM%_base
set NORMAL_PROFILE=%PLATFORM%
set NOCLOUDS_PROFILE=%PLATFORM%_noclouds

set SHADERC_PATH=shaderc.exe
set ZIP_FILE=shaderc.zip
set DOWNLOAD_URL=https://github.com/veka0/bgfx-mcbe/releases/download/binaries/shaderc-win-x64.zip

REM checking lazurite
where lazurite >nul 2>nul
if errorlevel 1 (
    echo ERROR: lazurite not found.
    echo Please install first:
    echo pip install lazurite
    exit /b 1
)


REM checking shaderc
if exist "%SHADERC_PATH%" (
    echo shaderc found.
) else (
    echo shaderc not found. Downloading...

    powershell -Command ^
        "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'"

    echo Extracting...
    powershell -Command ^
        "Expand-Archive -Force '%ZIP_FILE%' '.'"

    for /r %%f in (shadercRelease.exe) do (
        move "%%f" "%SHADERC_PATH%" >nul
        goto :found_shaderc
    )

    echo shaderc binary not found after extraction!
    exit /b 1

:found_shaderc
    del "%ZIP_FILE%"
    echo shaderc downloaded.
)


REM do build

echo Running build: %BASE_PROFILE%
lazurite build ./src -p %BASE_PROFILE% -o ./pack/renderer/materials --skip-validation
if errorlevel 1 exit /b 1

echo Running build: %NORMAL_PROFILE%
lazurite build ./src -p %NORMAL_PROFILE% -o ./pack/subpacks/vc/renderer/materials --skip-validation
if errorlevel 1 exit /b 1

echo Running build: %NOCLOUDS_PROFILE%
lazurite build ./src -p %NOCLOUDS_PROFILE% -o ./pack/subpacks/novc/renderer/materials --skip-validation
if errorlevel 1 exit /b 1

echo Build completed successfully!
