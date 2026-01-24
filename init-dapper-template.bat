@echo off
setlocal enabledelayedexpansion

:: ======================================
:: TNI DataService Project Creation Script
:: ======================================

echo.
echo ========================================
echo TNI DataService Project Creator
echo ========================================
echo.

:: Prompt for project name
set PROJECT_NAME=
set /p PROJECT_NAME="Enter project name: "

:: Validate project name
if "%PROJECT_NAME%"=="" (
    echo Error: Project name cannot be empty
    exit /b 1
)
set TEMPLATE_REPO=https://github.com/NITINAIP/tni.dataservice.git
set TARGET_DIR=%PROJECT_NAME%

echo Creating new project: %PROJECT_NAME%
echo.

:: Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo Error: Git is not installed or not in PATH
    exit /b 1
)

:: Check if directory already exists
if exist "%TARGET_DIR%" (
    echo Error: Directory '%TARGET_DIR%' already exists
    exit /b 1
)

echo Step 1: Cloning template repository...
git clone %TEMPLATE_REPO% %TARGET_DIR%
if errorlevel 1 (
    echo Error: Failed to clone template repository
    exit /b 1
)

cd %TARGET_DIR%

echo.
echo Step 2: Removing git history...
rmdir /s /q .git
if errorlevel 1 (
    echo Warning: Failed to remove .git directory
)

echo.
echo Step 3: Renaming project files...

:: Rename solution file
if exist "tni.dataservices.sln" (
    ren "tni.dataservices.sln" "%PROJECT_NAME%.sln"
    echo - Renamed solution file
)

:: Rename API project folder and files
if exist "src\API" (
    echo - Renaming API project...
    
    :: Rename csproj file if exists
    for %%f in (src\API\*.csproj) do (
        set OLD_PROJ=%%~nxf
        ren "%%f" "%PROJECT_NAME%.API.csproj"
    )
    
    :: Rename folder
    ren "src\API" "%PROJECT_NAME%.API"
)

:: Rename UnitTests project folder and files
if exist "tests\UnitTests" (
    echo - Renaming UnitTests project...
    
    :: Rename csproj file if exists
    for %%f in (tests\UnitTests\*.csproj) do (
        set OLD_TEST_PROJ=%%~nxf
        ren "%%f" "%PROJECT_NAME%.UnitTests.csproj"
    )
    
    :: Rename folder
    ren "tests\UnitTests" "%PROJECT_NAME%.UnitTests"
)

echo.
echo Step 4: Recreating solution file...

:: Delete old solution file
if exist "%PROJECT_NAME%.sln" (
    del "%PROJECT_NAME%.sln"
)

:: Create new solution
dotnet new sln -n %PROJECT_NAME%
if errorlevel 1 (
    echo Error: Failed to create solution file
    exit /b 1
)
echo - Created new solution file

:: Add API project to solution
if exist "src\%PROJECT_NAME%.API\%PROJECT_NAME%.API.csproj" (
    dotnet sln %PROJECT_NAME%.sln add "src\%PROJECT_NAME%.API\%PROJECT_NAME%.API.csproj"
    echo - Added API project to solution
)

:: Add UnitTests project to solution
if exist "tests\%PROJECT_NAME%.UnitTests\%PROJECT_NAME%.UnitTests.csproj" (
    dotnet sln %PROJECT_NAME%.sln add "tests\%PROJECT_NAME%.UnitTests\%PROJECT_NAME%.UnitTests.csproj"
    echo - Added UnitTests project to solution
)

echo.
echo Step 5: Updating namespace references in files...

:: Update namespaces in .cs files
for /r %%f in (*.cs) do (
    powershell -Command "(Get-Content '%%f') -replace 'tni\.dataservice', '%PROJECT_NAME%' -replace 'tni\.dataservices', '%PROJECT_NAME%' | Set-Content '%%f'"
)

:: Update namespaces in .csproj files
for /r %%f in (*.csproj) do (
    powershell -Command "(Get-Content '%%f') -replace 'tni\.dataservice', '%PROJECT_NAME%' -replace 'tni\.dataservices', '%PROJECT_NAME%' | Set-Content '%%f'"
)

echo - Updated namespaces in all files

echo.
echo Step 6: Initializing new git repository...
git init
git add .
git commit -m "Initial commit from tni.dataservice template"

echo.
echo ========================================
echo Project created successfully!
echo ========================================
echo.
echo Project location: %cd%
echo Solution file: %PROJECT_NAME%.sln
echo.
echo Next steps:
echo 1. Open %PROJECT_NAME%.sln in Visual Studio or Rider
echo 2. Review and update the README.md file
echo 3. Configure your project settings
echo 4. Start coding!
echo.
echo To build the project:
echo   dotnet build
echo.
echo To run the API:
echo   dotnet run --project src\%PROJECT_NAME%.API
echo.
echo To run tests:
echo   dotnet test
echo.

cd ..

endlocal