@echo off
setlocal enabledelayedexpansion

:: =============================================
:: 配置部分
:: =============================================
set MAIN_REPO_BRANCHES=main dev test staging  :: 主仓库需要处理的分支
set TEMP_BRANCH_PREFIX=temp_backup_           :: 临时分支前缀
set TIMESTAMP=%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

:: =============================================
:: 主函数
:: =============================================
call :main
exit /b %ERRORLEVEL%

:: =============================================
:: 子函数定义
:: =============================================

:main
    echo === 开始执行仓库状态备份脚本 ===
    echo 当前时间: %TIMESTAMP%
    
    :: 检查是否在子模块目录中
    call :is_git_submodule
    if %ERRORLEVEL% neq 0 (
        echo 错误: 必须在子模块目录中执行此脚本
        exit /b 1
    )
    
    :: 处理子模块
    call :process_submodule
    
    :: 处理主仓库
    call :process_main_repo
    
    echo === 备份完成 ===
    echo 请检查所有临时分支是否创建成功
    echo 确认无误后，将执行第二阶段的重命名操作
exit /b 0

:is_git_submodule
    :: 检查当前目录是否是子模块
    git rev-parse --show-superproject-working-tree >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo 当前目录是子模块
        exit /b 0
    ) else (
        exit /b 1
    )

:process_submodule
    echo === 开始处理子模块 ===
    
    :: 删除现有临时分支
    call :delete_temp_branches
    
    :: 创建新的临时分支备份当前状态
    call :create_temp_branch main
    
    echo === 子模块处理完成 ===
exit /b 0

:process_main_repo
    echo === 开始处理主仓库 ===
    
    :: 切换到主仓库目录
    pushd ..
    
    :: 删除现有临时分支
    call :delete_temp_branches
    
    :: 为每个配置的分支创建临时备份
    for %%b in (%MAIN_REPO_BRANCHES%) do (
        call :process_main_branch %%b
    )
    
    :: 返回子模块目录
    popd
    
    echo === 主仓库处理完成 ===
exit /b 0

:process_main_branch
    setlocal
    set branch=%~1
    
    echo -- 处理主仓库分支: %branch% --
    
    :: 切换到目标分支
    git checkout %branch% >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo 错误: 无法切换到分支 %branch%
        exit /b 1
    )
    
    :: 拉取最新更改
    git pull >nul 2>&1
    
    :: 创建临时分支
    call :create_temp_branch %branch%
    
    endlocal
exit /b 0

:delete_temp_branches
    echo -- 删除所有临时分支 --
    
    :: 删除本地临时分支
    for /f "delims=" %%b in ('git branch --list "%TEMP_BRANCH_PREFIX%*"') do (
        set branch=%%b
        set branch=!branch: =!
        if not "!branch!"=="*" (
            echo 删除本地分支: !branch!
            git branch -D !branch! >nul 2>&1
        )
    )
    
    :: 删除远程临时分支
    for /f "delims=" %%b in ('git branch -r --list "origin/%TEMP_BRANCH_PREFIX%*"') do (
        set branch=%%b
        set branch=!branch:origin/=!
        set branch=!branch: =!
        if not "!branch!"=="*" (
            echo 删除远程分支: !branch!
            git push origin --delete !branch! >nul 2>&1
        )
    )
exit /b 0

:create_temp_branch
    setlocal
    set base_branch=%~1
    set temp_branch=%TEMP_BRANCH_PREFIX%%base_branch%_%TIMESTAMP%
    
    echo -- 基于 %base_branch% 创建临时分支 %temp_branch% --
    
    :: 确保在基础分支上
    git checkout %base_branch% >nul 2>&1
    git pull >nul 2>&1
    
    :: 创建并切换到临时分支
    git checkout -b %temp_branch% >nul 2>&1
    
    :: 添加所有更改
    git add --all >nul 2>&1
    
    :: 提交更改
    git commit -m "临时备份: %base_branch% 分支状态于 %TIMESTAMP%" >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo 警告: 没有更改需要提交或提交失败
    )
    
    :: 推送到远程
    git push -u origin %temp_branch% >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo 成功创建并推送临时分支: %temp_branch%
    ) else (
        echo 错误: 推送临时分支 %temp_branch% 失败
    )
    
    :: 切换回基础分支
    git checkout %base_branch% >nul 2>&1
    
    endlocal
exit /b 0