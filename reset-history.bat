@echo off
:: 设置代码页为简体中文
chcp 936 >nul
setlocal enabledelayedexpansion


echo === Create new branch without history ===
echo [DEBUG] Current directory: %CD%

echo Warning: This operation will create a new branch
echo Make sure you have backed up important information
set /p "CONFIRM=Continue (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo [DEBUG] Operation cancelled by user
    exit /b 0
)

echo [DEBUG] Checking if in submodule directory
git rev-parse --show-superproject-working-tree >nul 2>&1
if not %errorlevel% EQU 0 (
    echo [ERROR] Must run this script in public submodule
    pause
    exit /b 1
)
echo [DEBUG] Confirmed in submodule directory

:: Clean up existing temp branches in submodule
call :clean_temp_branches
if not %errorlevel% EQU 0 goto error

echo === Create submodule temporary branch ===

:: Create temp_main branch in submodule
call :create_orphan_branch main
if not %errorlevel% EQU 0 goto error

cd ..

echo === Create main repository temporary branches ===

:: Clean up existing temp branches in main repository
call :clean_temp_branches
if not %errorlevel% EQU 0 goto error

:: Save current branch
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set "CURRENT_BRANCH=%%i"
echo [DEBUG] Current branch: %CURRENT_BRANCH%

:: Process each branch in main repository
echo [DEBUG] Processing branches:
git branch | findstr /v /c:"*" >branches.txt
for /f "tokens=* delims= " %%i in (branches.txt) do (
    set "BRANCH=%%i"
    echo [DEBUG] Processing branch: !BRANCH!
    :: Delete existing temp branch if it exists
    git branch | findstr "temp_!BRANCH!" >nul
    if %errorlevel% EQU 0 (
        echo [DEBUG] Deleting existing temp_!BRANCH! branch
        git worktree remove temp_!BRANCH! >nul 2>&1
        git branch -D temp_!BRANCH! 2>nul
    )
    :: Create new temp branch
    call :create_orphan_branch !BRANCH!
    if not %errorlevel% EQU 0 goto error
)
del branches.txt

echo [DEBUG] Switching back to original branch
git checkout %CURRENT_BRANCH%
if not %errorlevel% EQU 0 (
    echo [ERROR] Cannot switch back to original branch
    goto error
)

cd public
echo === Complete ===
echo Note: Please check all temporary branches
echo - Submodule temp_main
echo - Main repository temp_ versions of all branches
echo.
echo After confirmation, run clean-old-branches.bat to delete old branches
pause
exit /b 0

:: ====================================================
:: Subroutines
:: ====================================================

:clean_temp_branches
echo [DEBUG] Cleaning temporary branches
:: First, switch to a non-temp branch if we're on a temp branch
git branch | findstr /c:"*" >current_branch.txt
for /f "tokens=* delims= " %%i in (current_branch.txt) do (
    set "BRANCH=%%i"
    set "BRANCH=!BRANCH:* =!"
    echo !BRANCH! | findstr "temp" >nul
    if not %errorlevel% EQU 1 (
        echo [DEBUG] Currently on temp branch, switching to main
        git checkout main
    )
)
del current_branch.txt

:: Now clean up temp branches
for /f "tokens=* delims= " %%i in ('git branch') do (
    set "BRANCH=%%i"
    if "!BRANCH:~0,1!"=="*" (
        set "BRANCH=!BRANCH:~2!"
    )
    if not "!BRANCH!"=="" (
        echo !BRANCH! | findstr "temp" >nul
        if not %errorlevel% EQU 1 (
            echo [DEBUG] Deleting local branch: !BRANCH!
            git worktree remove !BRANCH! >nul 2>&1
            git branch -D !BRANCH! 2>nul
        )
    )
)

for /f "tokens=*" %%i in ('git branch -r') do (
    set "BRANCH=%%i"
    set "BRANCH=!BRANCH:remotes/origin/=!"
    if not "!BRANCH!"=="" (
        echo !BRANCH! | findstr "HEAD" >nul
        if %errorlevel% EQU 1 (
            echo !BRANCH! | findstr "temp" >nul
            if not %errorlevel% EQU 1 (
                echo [DEBUG] Deleting remote branch: !BRANCH!
                git push origin :!BRANCH!
            )
        )
    )
)
exit /b 0

:create_orphan_branch
echo [DEBUG] Creating orphan branch
set "BRANCH=%~1"
echo [DEBUG] Processing branch: %BRANCH%

echo [DEBUG] Switching to branch: %BRANCH%
git checkout %BRANCH%
if not %errorlevel% EQU 0 (
    echo [ERROR] Cannot switch to branch: %BRANCH%
    exit /b 1
)

echo [DEBUG] Creating temporary branch: temp_%BRANCH%
git checkout --orphan temp_%BRANCH%
if not %errorlevel% EQU 0 (
    echo [ERROR] Cannot create temporary branch: temp_%BRANCH%
    exit /b 1
)

echo [DEBUG] Adding all files
git add -A
if not %errorlevel% EQU 0 (
    echo [ERROR] Cannot add files
    exit /b 1
)

echo [DEBUG] Committing changes
git commit -m "Initialize branch: %BRANCH%"
if not %errorlevel% EQU 0 (
    echo [ERROR] Cannot commit changes
    exit /b 1
)

echo.
echo [DEBUG] temp_%BRANCH% new branch status
git status
echo.
set /p "CONFIRM=Confirm to continue (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo [DEBUG] Operation cancelled by user
    git checkout %BRANCH%
    git branch -D temp_%BRANCH%
    exit /b 1
)

echo [DEBUG] Pushing to remote repository
git push -f origin temp_%BRANCH%
if not %errorlevel% EQU 0 (
    echo [ERROR] Cannot push to remote repository
    exit /b 1
)
exit /b 0

:error
echo.
echo [ERROR] Error occurred, restoring original state
cd public 2>nul
pause
exit /b 1 