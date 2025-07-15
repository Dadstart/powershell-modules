@echo off
REM Windows batch file to run PowerShell code validation
REM Usage: run-validation.bat [ModuleName] [Detailed] [InstallTools]

echo.
echo ========================================
echo PowerShell Code Quality Validation
echo ========================================
echo.

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\.."

REM Change to project root directory
cd /d "%PROJECT_ROOT%"

echo Working Directory: %PROJECT_ROOT%
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is not available or not in PATH
    echo Please ensure PowerShell is installed and accessible
    pause
    exit /b 1
)

REM Build PowerShell command based on parameters
set "PS_COMMAND=.\scripts\powershell\Run-Validation-Windows.ps1"

if not "%1"=="" (
    set "PS_COMMAND=%PS_COMMAND% -ModuleName %1"
)

if /i "%2"=="Detailed" (
    set "PS_COMMAND=%PS_COMMAND% -Detailed"
)

if /i "%3"=="InstallTools" (
    set "PS_COMMAND=%PS_COMMAND% -InstallTools"
)

echo Running: powershell -ExecutionPolicy Bypass -File %PS_COMMAND%
echo.

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File %PS_COMMAND%

REM Check if the command was successful
if errorlevel 1 (
    echo.
    echo ERROR: Validation failed with exit code %errorlevel%
    echo.
    echo Troubleshooting tips:
    echo 1. Ensure PowerShell execution policy allows script execution
    echo 2. Check that all required modules are available
    echo 3. Verify the project structure is correct
    echo.
    pause
    exit /b 1
)

echo.
echo Validation completed successfully!
echo.
pause 