@echo off
setlocal enabledelayedexpansion

:: 显示当前目录
echo 当前目录: %CD%
echo 脚本路径: %~dp0
echo.

:: 检查git命令是否可用
echo 检查git命令...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到git命令
    echo 请确保git已安装并添加到PATH环境变量
    pause
    exit /b 1
)
echo git命令可用
echo.

:: 检查是否在git仓库目录
echo 检查git仓库状态...
git rev-parse --is-inside-work-tree >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 当前目录不是git仓库
    pause
    exit /b 1
)
echo 当前目录是git仓库
echo.

:: 获取远程分支
echo [更新] 获取远程分支信息...
git fetch --all
echo.

:: 显示所有分支信息
echo [调试] 所有分支信息:
git branch -a
echo.

:: 保存当前分支
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%i
echo [调试] 当前分支: %CURRENT_BRANCH%
echo.

:: 遍历所有远程分支
echo [处理] 开始处理所有分支...
for /f "tokens=* delims= " %%b in ('git branch -r ^| findstr /v "HEAD" ^| findstr "origin/"') do (
    set "branch=%%b"
    set "branch=!branch:origin/=!"
    
    echo [处理分支] !branch!
    
    :: 切换到目标分支
    echo [切换分支] 正在切换到 !branch! 分支...
    git checkout !branch!
    if %errorlevel% neq 0 (
        echo 错误: 无法切换到 !branch! 分支
        pause
        exit /b 1
    )

    :: 显示提交历史
    echo [调试] 当前提交历史:
    git log --oneline
    echo.

    :: 创建新的根提交
    echo [创建新根提交] 正在创建新的根提交...
    git checkout --orphan temp_branch
    if %errorlevel% neq 0 (
        echo 错误: 无法创建临时分支
        pause
        exit /b 1
    )

    git add -A
    git commit -m "Initial commit"

    :: 删除原分支
    echo [删除原分支] 正在删除原分支 !branch!...
    git branch -D !branch!

    :: 重命名临时分支
    echo [重命名分支] 正在重命名临时分支为 !branch!...
    git branch -m !branch!

    :: 清理引用日志
    echo [清理引用] 正在清理引用日志...
    git reflog expire --expire=now --all

    :: 清理未引用的对象
    echo [清理对象] 正在清理未引用对象...
    git gc --prune=now --aggressive

    :: 显示清理后的提交历史
    echo [调试] 清理后的提交历史:
    git log --oneline
    echo.

    :: 强制推送到远程并设置上游分支
    echo [推送远程] 正在强制推送到远程并设置上游分支...
    git push -f origin !branch!
    git branch --set-upstream-to=origin/!branch! !branch!

    echo.
    echo ============================================
    echo 分支 !branch! 的 Git 历史清理完成
    echo ============================================
    echo.
)

:: 切换回原始分支
echo [切换分支] 正在切换回原始分支 %CURRENT_BRANCH%...
git checkout %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo 错误: 无法切换回原始分支
    pause
    exit /b 1
)

:: 设置当前分支的上游分支
echo [设置上游分支] 正在设置当前分支的上游分支...
git branch --set-upstream-to=origin/%CURRENT_BRANCH% %CURRENT_BRANCH%

echo.
echo ============================================
echo 所有分支的 Git 历史清理完成
echo ============================================
echo.
echo 按任意键退出...
pause >nul

endlocal 