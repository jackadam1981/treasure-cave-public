@echo off
setlocal enabledelayedexpansion
chcp 936 >nul

rem ====================================================
rem 修正子模块提交的流程：
rem
rem 1. 子模块修正（在子模块目录中）：
rem    - 确保在子模块目录中执行
rem    - 检查是否有未提交的更改
rem    - 询问是否修改提交信息
rem    - 如果有更改：
rem      * git add .
rem      * git commit --amend [--no-edit]
rem      * git push -f origin HEAD:main
rem    - 切换回主仓库目录（cd ..）
rem
rem 2. 更新主仓库中的子模块引用：
rem    - 检查当前分支（必须是 frontend 或 backend）
rem    - 暂存主仓库的本地修改
rem    - 拉取当前分支的最新代码
rem    - 更新子模块引用：git submodule update --remote
rem    - 询问是否修改主仓库的提交信息
rem    - 修改最后一次提交：
rem      * git add .gitmodules public
rem      * git commit --amend [--no-edit]
rem      * git push -f origin <当前分支>
rem
rem 3. 在另一个分支重复步骤2：
rem    - 切换到另一个分支（frontend/backend）
rem    - 拉取该分支的最新代码
rem    - 更新子模块引用
rem    - 使用与当前分支相同的提交信息选择
rem    - 修改最后一次提交并强制推送
rem    - 切换回原始分支
rem    - 恢复暂存的修改
rem
rem 注意事项：
rem - 此脚本会修改 Git 历史，需要强制推送
rem - 只能修改最近的一次提交
rem - 需要确保其他人没有基于这个提交做新的工作
rem - 主仓库的本地修改会被暂存和恢复
rem - 子模块目录虽然在 .gitignore 中，但其引用变更仍需要提交
rem ====================================================

echo === 修正子模块提交 ===

rem 检查是否在子模块中
git rev-parse --show-superproject-working-tree >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：必须在公共子模块中运行此脚本
    pause
    exit /b 1
)

rem 检查是否有未提交的更改
git status --porcelain
if %errorlevel% neq 0 (
    echo 错误：无法检查文件状态
    pause
    exit /b 1
)

git status --porcelain | findstr /r "^[^?]" >nul
if %errorlevel% neq 0 (
    echo 没有需要提交的更改
    cd ..
    goto :update_main
)

rem 询问是否修改子模块的提交信息
set /p AMEND_MSG=是否需要修改子模块的提交信息？(Y/N)：

rem 获取当前提交信息
for /f "tokens=*" %%i in ('git log -1 --pretty^=format:"%%s"') do set OLD_MSG=%%i
echo 当前提交信息：!OLD_MSG!
echo.

rem 更新并推送子模块更改
git add .
if /i "%AMEND_MSG%"=="Y" (
    echo 请输入新的提交信息：
    set /p NEW_MSG=
    if "!NEW_MSG!"=="" (
        git commit --amend --no-edit
        set COMMIT_MSG=!OLD_MSG!
    ) else (
        git commit --amend -m "!NEW_MSG!"
        set COMMIT_MSG=!NEW_MSG!
    )
) else (
    git commit --amend --no-edit
    set COMMIT_MSG=!OLD_MSG!
)
if %errorlevel% neq 0 (
    echo 错误：提交失败
    pause
    exit /b 1
)

git push -f origin HEAD:main
if %errorlevel% neq 0 (
    echo 错误：推送失败
    pause
    exit /b 1
)

cd ..

:update_main
rem 保存当前状态
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%i
echo 当前分支是：%CURRENT_BRANCH%

rem 检查当前分支是否合法
if "%CURRENT_BRANCH%" neq "frontend" (
    if "%CURRENT_BRANCH%" neq "backend" (
        echo 错误：当前分支必须是 frontend 或 backend
        pause
        exit /b 1
    )
)


rem 暂存主仓库的本地修改
echo 正在暂存主仓库的本地修改...
git stash push -m "临时保存用于子模块更新"

rem 处理当前分支
echo.
echo === 正在处理当前分支：%CURRENT_BRANCH% ===

rem 拉取当前分支的最新代码
echo 正在拉取最新代码...
git pull origin %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo 错误：无法拉取分支 %CURRENT_BRANCH% 的最新代码
    goto :error
)

rem 更新子模块引用
echo 正在更新子模块引用...
git submodule update --remote
if %errorlevel% neq 0 (
    echo 错误：无法更新子模块引用
    goto :error
)

rem 修改最后一次提交
echo 正在修改子模块更新提交...
git add .gitmodules public
git commit --amend -m "更新公共子模块版本：!COMMIT_MSG!"
if %errorlevel% neq 0 (
    echo 错误：无法修改提交
    goto :error
)

rem 推送更改
echo 正在推送更改...
git push -f origin %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo 错误：无法推送到分支 %CURRENT_BRANCH%
    goto :error
)

rem 处理另一个分支
if "%CURRENT_BRANCH%"=="frontend" (
    set TARGET_BRANCH=backend
) else (
    set TARGET_BRANCH=frontend
)

echo === 正在处理分支：%TARGET_BRANCH% ===

rem 切换到目标分支
echo 正在切换到分支 %TARGET_BRANCH%...
git checkout %TARGET_BRANCH%
if %errorlevel% neq 0 (
    echo 错误：无法切换到分支 %TARGET_BRANCH%
    goto :error
)

rem 拉取目标分支的最新代码
echo 正在拉取最新代码...
git pull origin %TARGET_BRANCH%
if %errorlevel% neq 0 (
    echo 错误：无法拉取分支 %TARGET_BRANCH% 的最新代码
    goto :error
)

rem 更新子模块引用
echo 正在更新子模块引用...
git submodule update --remote
if %errorlevel% neq 0 (
    echo 错误：无法更新子模块引用
    goto :error
)

rem 修改最后一次提交（使用与当前分支相同的选择）
echo 正在修改子模块更新提交...
git add .gitmodules public
git commit --amend -m "更新公共子模块版本：!COMMIT_MSG!"
if %errorlevel% neq 0 (
    echo 错误：无法修改提交
    goto :error
)

rem 推送更改
echo 正在推送更改...
git push -f origin %TARGET_BRANCH%
if %errorlevel% neq 0 (
    echo 错误：无法推送到分支 %TARGET_BRANCH%
    goto :error
)

rem 切换回当前分支
echo 正在切换回当前分支...
git checkout %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo 错误：无法切换回分支 %CURRENT_BRANCH%
    goto :error
)

rem 恢复主仓库的本地修改
echo 正在恢复主仓库的本地修改...
git stash pop

cd public
echo === 完成 ===
exit /b 0

:error
echo.
echo 发生错误，正在恢复原始状态...
git checkout %CURRENT_BRANCH%
git stash pop
pause
exit /b 1 