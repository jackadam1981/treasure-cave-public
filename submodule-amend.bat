@echo off
setlocal enabledelayedexpansion
chcp 936 >nul

:: ���ò���
set "SUBMODULE_DIR=public_submodule"
set "MAIN_REPO_DIR=.."
set "SUBMODULE_URL=https://github.com/jackadam1981/treasure-cave-public.git"
set "AUTO_FIX=1"  :: �Ƿ��Զ��޸���������

:: ������
:main
    echo ����������ģ���ύ...
    call :amend_submodule
    echo ����ͬ�����ֿ��ύ...
    call :amend_main_repo
    pause
    exit /b 0

:: ������ģ���ύ
:amend_submodule
    pushd %SUBMODULE_DIR%
    
    :: ��ȡԭ�ύ��Ϣ
    for /f "delims=" %%m in ('git log -1 --pretty=%%s') do set "OLD_MSG=%%m"
    
    :: ������������Ϣ
    choice /c YN /m "�Ƿ��޸��ύ��Ϣ��ԭ��Ϣ��!OLD_MSG!��[Y/N]"
    if %errorlevel% equ 1 (
        set /p "NEW_MSG=���������ύ��Ϣ: "
    ) else (
        set "NEW_MSG=!OLD_MSG!"
    )
    
    git add -A
    git commit --amend -m "!NEW_MSG!"
    git push --force origin main
    
    popd
    exit /b 0

:: �������ֿ��ύ����ȷʹ��ȫ�ֱ�����
:amend_main_repo
    pushd %MAIN_REPO_DIR%
    
    :: ���浱ǰ��֧
    for /f "delims=" %%i in ('git rev-parse --abbrev-ref HEAD') do set "ORIGIN_BRANCH=%%i"
    
    :: ֱ��ʹ��ȫ�ֱ��� NEW_MSG
    for /f "delims=" %%m in ('git -C %SUBMODULE_DIR% log -1 --pretty=%%s') do set "NEW_MSG=%%m"
    
    :: ������֧
    for /f "delims=" %%b in ('git for-each-ref --format^=%%^(refname:short^) refs/heads/') do (
        set "branch=%%b"
        echo ���ڴ����֧: !branch!
        
        git checkout "!branch!" && (
            git add "%SUBMODULE_DIR%"
            git commit --amend -m "������ģ��: !NEW_MSG!"
            git push --force origin "!branch!"
        )
    )
    
    :: �ָ�ԭʼ��֧
    git checkout "!ORIGIN_BRANCH!"
    popd
    exit /b 0

:: ִ��������
call :main
