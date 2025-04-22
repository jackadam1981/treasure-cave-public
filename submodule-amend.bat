@echo off
setlocal enabledelayedexpansion
chcp 936 >nul

:: 配置参数
set "SUBMODULE_DIR=public_submodule"
set "MAIN_REPO_DIR=.."
set "SUBMODULE_URL=https://github.com/jackadam1981/treasure-cave-public.git"
set "AUTO_FIX=1"  :: 是否自动修复配置问题

:: 主函数
:main
    echo 正在修正子模块提交...
    call :amend_submodule
    echo 正在同步主仓库提交...
    call :amend_main_repo
    pause
    exit /b 0

:: 修正子模块提交
:amend_submodule
    pushd %SUBMODULE_DIR%
    
    :: 获取原提交信息
    for /f "delims=" %%m in ('git log -1 --pretty=%%s') do set "OLD_MSG=%%m"
    
    :: 交互输入新信息
    choice /c YN /m "是否修改提交信息（原信息：!OLD_MSG!）[Y/N]"
    if %errorlevel% equ 1 (
        set /p "NEW_MSG=请输入新提交信息: "
    ) else (
        set "NEW_MSG=!OLD_MSG!"
    )
    
    git add -A
    git commit --amend -m "!NEW_MSG!"
    git push --force origin main
    
    popd
    exit /b 0

:: 修正主仓库提交（正确使用全局变量）
:amend_main_repo
    pushd %MAIN_REPO_DIR%
    
    :: 保存当前分支
    for /f "delims=" %%i in ('git rev-parse --abbrev-ref HEAD') do set "ORIGIN_BRANCH=%%i"
    
    :: 直接使用全局变量 NEW_MSG
    for /f "delims=" %%m in ('git -C %SUBMODULE_DIR% log -1 --pretty=%%s') do set "NEW_MSG=%%m"
    
    :: 遍历分支
    for /f "delims=" %%b in ('git for-each-ref --format^=%%^(refname:short^) refs/heads/') do (
        set "branch=%%b"
        echo 正在处理分支: !branch!
        
        git checkout "!branch!" && (
            git add "%SUBMODULE_DIR%"
            git commit --amend -m "更新子模块: !NEW_MSG!"
            git push --force origin "!branch!"
        )
    )
    
    :: 恢复原始分支
    git checkout "!ORIGIN_BRANCH!"
    popd
    exit /b 0

:: 执行主程序
call :main
