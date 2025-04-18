@echo off
setlocal enabledelayedexpansion
chcp 936 >nul

rem ====================================================
rem 更新子模块的正确流程
rem
rem 1. 子模块更新（在子模块目录中）
rem    - 确保在子模块目录中执行
rem    - 检查是否有未提交的更改
rem    - 如果有更改
rem      * git add .
rem      * git commit -m "提交信息"
rem      * git push origin HEAD:main
rem    - 切换回主仓库目录（cd ..）
rem    - 保存提交信息用于主仓库提交
rem
rem 2. 更新主仓库中的子模块引用
rem    - 检查当前分支（必须是 frontend 或 backend）
rem    - 暂存主仓库的本地修改
rem    - 拉取当前分支的最新代码
rem    - 更新子模块引用 git submodule update --remote
rem    - 提交更新
rem      * git add .gitmodules public
rem      * git commit -m "更新公共子模块版本 子模块提交信息"
rem      * git push origin <当前分支>
rem
rem 3. 在另一个分支重复步骤2
rem    - 切换到另一个分支（frontend/backend）
rem    - 拉取该分支的最新代码
rem    - 更新子模块引用
rem    - 提交并推送更新（使用相同的提交信息）
rem    - 切换回原始分支
rem    - 恢复暂存的修改
rem ====================================================

echo === 更新公共子模块 ===
echo [DEBUG] 当前目录 %CD%

rem 检查是否在子模块中
echo [DEBUG] 检查是否在子模块目录中
git rev-parse --show-superproject-working-tree >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 必须在公共子模块中运行此脚本
    pause
    exit /b 1
)
echo [DEBUG] 确认在子模块目录中

rem 检查并清理未跟踪的文件
echo [DEBUG] 检查未跟踪的文件
git clean -n
set /p CLEAN_CONFIRM=是否清理以上未跟踪的文件 (Y/N) 
if /i "%CLEAN_CONFIRM%"=="Y" (
    echo [DEBUG] 清理未跟踪的文件
    git clean -f
)

rem 检查是否有未提交的更改
echo [DEBUG] 检查文件状态
git status --porcelain
if %errorlevel% neq 0 (
    echo [ERROR] 无法检查文件状态
    pause
    exit /b 1
)

git status --porcelain | findstr /r "^[^?]" >nul
if %errorlevel% neq 0 (
    echo [DEBUG] 没有需要提交的更改，切换到主仓库目录
    cd ..
    goto update_main
)

echo [DEBUG] 发现未提交的更改
git status
echo.
set /p COMMIT_CONFIRM=是否提交这些更改 (Y/N) 
if /i not "%COMMIT_CONFIRM%"=="Y" (
    echo [DEBUG] 用户取消操作
    exit /b 0
)

set /p MSG=请输入提交信息 
if "!MSG!"=="" (
    echo [ERROR] 提交信息不能为空
    pause
    exit /b 1
)

rem 更新并推送子模块更改
echo [DEBUG] 添加并提交更改
git add .
git commit -m "%MSG%"
set COMMIT_MSG=%MSG%

echo [DEBUG] 推送更改到远程仓库
git push origin HEAD:main
if %errorlevel% neq 0 (
    echo [DEBUG] 推送失败，尝试拉取最新更改
    git pull origin main
    echo [DEBUG] 重新推送更改
    git push origin HEAD:main
    if %errorlevel% neq 0 (
        echo [ERROR] 推送失败
        pause
        exit /b 1
    )
)

cd ..

:update_main
rem 保存当前状态
echo [DEBUG] 获取当前分支信息
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%i
echo [DEBUG] 当前分支 %CURRENT_BRANCH%

rem 检查当前分支是否合法
if "%CURRENT_BRANCH%" neq "frontend" (
    if "%CURRENT_BRANCH%" neq "backend" (
        echo [ERROR] 当前分支必须是 frontend 或 backend
        pause
        exit /b 1
    )
)

rem 检查是否有未提交的更改
echo [DEBUG] 检查主仓库未提交的更改
git status --porcelain | findstr /r "^" >nul
if %errorlevel% equ 0 (
    echo [DEBUG] 发现主仓库有未提交的更改
    git status
    echo.
    set /p STASH_CONFIRM=是否暂存这些更改 (Y/N) 
    if /i not "!STASH_CONFIRM!"=="Y" (
        echo [DEBUG] 用户取消操作
        exit /b 0
    )
)

rem 暂存主仓库的本地修改
echo [DEBUG] 暂存主仓库的本地修改
git stash push -m "临时保存用于子模块更新"

rem 处理当前分支
echo.
echo === 处理当前分支 %CURRENT_BRANCH% ===

rem 拉取当前分支的最新代码
echo [DEBUG] 拉取最新代码
:: 检查是否有未合并的文件
git status --porcelain | findstr /r "^U" >nul
if %errorlevel% equ 0 (
    echo [DEBUG] 发现未合并的文件
    git status
    echo.
    set /p MERGE_CONFIRM=是否放弃未合并的更改 (Y/N) 
    if /i not "!MERGE_CONFIRM!"=="Y" (
        echo [DEBUG] 用户取消操作
        exit /b 0
    )
    :: 放弃未合并的更改
    echo [DEBUG] 放弃未合并的更改
    git reset --hard
    git clean -fd
)

git pull origin %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo [ERROR] 无法拉取分支 %CURRENT_BRANCH% 的最新代码
    goto error
)

rem 更新子模块引用
echo [DEBUG] 更新子模块引用
git submodule update --remote
if %errorlevel% neq 0 (
    echo [ERROR] 无法更新子模块引用
    goto error
)

rem 检查是否有子模块更改需要提交
echo [DEBUG] 检查子模块更改
git status --porcelain | findstr /r "^.M public$" >nul
if %errorlevel% neq 0 (
    echo [DEBUG] 没有子模块更改需要提交
    goto process_other_branch
)

rem 提交子模块更新
echo [DEBUG] 提交子模块更新
git add .gitmodules public
git commit -m "更新公共子模块版本 !COMMIT_MSG!"
if %errorlevel% neq 0 (
    echo [ERROR] 无法提交子模块更新
    goto error
)

rem 推送更改
echo [DEBUG] 推送更改
git push origin %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo [ERROR] 无法推送到分支 %CURRENT_BRANCH%
    goto error
)

process_other_branch
rem 处理另一个分支
if "%CURRENT_BRANCH%"=="frontend" (
    set TARGET_BRANCH=backend
) else (
    set TARGET_BRANCH=frontend
)

echo === 处理分支 %TARGET_BRANCH% ===

rem 切换到目标分支
echo [DEBUG] 切换到分支 %TARGET_BRANCH%
git checkout %TARGET_BRANCH%
if %errorlevel% neq 0 (
    echo [ERROR] 无法切换到分支 %TARGET_BRANCH%
    goto error
)


rem 拉取目标分支的最新代码
echo [DEBUG] 拉取最新代码
git pull origin %TARGET_BRANCH%
if %errorlevel% neq 0 (
    echo [ERROR] 无法拉取分支 %TARGET_BRANCH% 的最新代码
    goto error
)

rem 更新子模块引用
echo [DEBUG] 更新子模块引用
git submodule update --remote
if %errorlevel% neq 0 (
    echo [ERROR] 无法更新子模块引用
    goto error
)

rem 检查是否有子模块更改需要提交
echo [DEBUG] 检查子模块更改
git status --porcelain | findstr /r "^.M public$" >nul
if %errorlevel% neq 0 (
    echo [DEBUG] 没有子模块更改需要提交
    goto finish
)

rem 提交子模块更新
echo [DEBUG] 提交子模块更新
git add .gitmodules public
git commit -m "更新公共子模块版本 !COMMIT_MSG!"
if %errorlevel% neq 0 (
    echo [ERROR] 无法提交子模块更新
    goto error
)

rem 推送更改
echo [DEBUG] 推送更改
git push origin %TARGET_BRANCH%
if %errorlevel% neq 0 (
    echo [ERROR] 无法推送到分支 %TARGET_BRANCH%
    goto error
)

finish
rem 切换回当前分支
echo [DEBUG] 切换回原始分支
git checkout %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo [ERROR] 无法切换回分支 %CURRENT_BRANCH%
    goto error
)

rem 检查是否有暂存的更改
echo [DEBUG] 检查暂存的更改
git stash list | findstr "临时保存用于子模块更新" >nul
if %errorlevel% equ 0 (
    echo [DEBUG] 恢复暂存的更改
    git stash pop
)

echo === 更新完成 ===
pause
exit /b 0

error
echo.
echo [ERROR] 发生错误，正在恢复原始状态
git checkout %CURRENT_BRANCH%
echo [DEBUG] 检查暂存的更改
git stash list | findstr "临时保存用于子模块更新" >nul
if %errorlevel% equ 0 (
    echo [DEBUG] 恢复暂存的更改
    git stash pop
)
pause
exit /b 1 

