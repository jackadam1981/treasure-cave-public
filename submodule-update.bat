@echo off
setlocal enabledelayedexpansion
chcp 936 >nul


::v1.1 20250421 2008

:: 配置参数
set "SUBMODULE_DIR=public_submodule"
set "MAIN_REPO_DIR=.."
set "SUBMODULE_URL=https://github.com/jackadam1981/treasure-cave-public.git"
set "AUTO_FIX=1"  :: 是否自动修复配置问题

:: 主函数
:main
    :: 交互接收提交信息
    set /p "COMMIT_MESSAGE=请输入提交信息: "
    echo 正在处理子模块更新...
    call :process_submodule
    echo 正在更新主仓库所有分支...
    call :process_main_repo
    pause
    exit /b 0

:: 处理子模块（修复detached HEAD问题）
:process_submodule
    :: 确保在有效分支上操作
    git checkout -B main 2>nul || git checkout -b main
    git pull origin main --allow-unrelated-histories 2>nul
    
    :: 提交变更
    git add -A
    git commit -m "%COMMIT_MESSAGE%" || (
        echo 无变更可提交
        exit /b 0
    )
    
    :: 推送到远程分支
    git push origin main:main --force
    exit /b 0

:: 处理主仓库（简化版）
:process_main_repo
    pushd %MAIN_REPO_DIR%
    
    echo 主仓库分支列表：
    echo --------------------------
    
    :: 统一使用 delims= 处理分支名
    :: 获取当前分支
    for /f "delims=" %%i in ('git rev-parse --abbrev-ref HEAD') do (
        set "CURRENT_BRANCH=%%i"
        set "CURRENT_BRANCH=!CURRENT_BRANCH:HEAD=!"
    )
    echo 当前分支: !CURRENT_BRANCH!

    :: 遍历所有分支
    for /f "delims=" %%b in ('git for-each-ref --format^=%%^(refname:short^) refs/heads/') do (
        set "branch=%%b"
        echo 分支名称: !branch!

        git checkout "!branch!"
        git reset HEAD -- .
        git submodule deinit -f public
        git submodule add --force "%SUBMODULE_URL%" "%SUBMODULE_DIR%"
        git add .gitmodules %SUBMODULE_DIR% || (
            echo 子模块已配置
        )
        git submodule update --init --recursive
        git commit -m "更新子模块 [!COMMIT_MESSAGE!]"
        git push origin "!branch!"

    )
    git checkout %CURRENT_BRANCH% 
    
    echo --------------------------
    popd
    exit /b 0

:: 执行主程序
call :main
