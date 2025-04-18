@echo off
setlocal enabledelayedexpansion
chcp 936 >nul

git switch main

echo === 检查所有分支 ===
echo 当前所有分支：
git branch -a
echo.

echo === 识别需要删除的临时分支 ===
echo 本地临时分支：
for /f "tokens=*" %%i in ('git branch') do (
    set "BRANCH=%%i"
    set "BRANCH=!BRANCH:* =!"
    if "!BRANCH!" neq "" (
        echo 检查分支: [!BRANCH!]
        echo !BRANCH! | findstr "temp" >nul
        if not errorlevel 1 (
            echo - !BRANCH!
            set "LOCAL_BRANCHES=!LOCAL_BRANCHES! !BRANCH!"
        )
    )
)

echo.
echo 远程临时分支：
for /f "tokens=*" %%i in ('git branch -r') do (
    set "BRANCH=%%i"
    set "BRANCH=!BRANCH:remotes/origin/=!"
    if "!BRANCH!" neq "" (
        rem 跳过 HEAD 和特殊分支
        echo !BRANCH! | findstr "HEAD" >nul
        if errorlevel 1 (
            echo 检查分支: [!BRANCH!]
            echo !BRANCH! | findstr "temp" >nul
            if not errorlevel 1 (
                rem 提取分支名的最后一段
                for /f "tokens=2 delims=/" %%b in ("!BRANCH!") do (
                    echo - %%b
                    set "REMOTE_BRANCHES=!REMOTE_BRANCHES! %%b"
                )
            )
        )
    )
)

echo.
if not defined LOCAL_BRANCHES if not defined REMOTE_BRANCHES (
    echo 没有找到需要删除的临时分支
    pause
    exit /b 0
)

echo 将要删除以下分支：
if defined LOCAL_BRANCHES (
    echo 本地分支：!LOCAL_BRANCHES!
)
if defined REMOTE_BRANCHES (
    echo 远程分支：!REMOTE_BRANCHES!
)
echo.
set /p CONFIRM=是否确认删除这些分支？(Y/N)：
if /i not "%CONFIRM%"=="Y" (
    echo 操作已取消
    pause
    exit /b 0
)

echo.
echo === 开始删除分支 ===

rem 删除本地分支
if defined LOCAL_BRANCHES (
    echo 正在删除本地分支...
    for %%b in (!LOCAL_BRANCHES!) do (
        echo 执行命令: git branch -D %%b
        git branch -D %%b
    )
)

rem 删除远程分支
if defined REMOTE_BRANCHES (
    echo 正在删除远程分支...
    for %%b in (!REMOTE_BRANCHES!) do (
        echo 执行命令: git push origin :%%b
        git push origin :%%b
        if %errorlevel% neq 0 (
            echo 警告：远程分支 %%b 可能不存在
        )
    )
)

echo.
echo === 完成 ===
echo 最终分支状态：
git branch -a
pause
exit /b 0 