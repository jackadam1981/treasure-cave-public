@echo off
setlocal enabledelayedexpansion
chcp 936 >nul


::v1.1 20250421 2008

:: ���ò���
set "SUBMODULE_DIR=public_submodule"
set "MAIN_REPO_DIR=.."
set "SUBMODULE_URL=https://github.com/jackadam1981/treasure-cave-public.git"
set "AUTO_FIX=1"  :: �Ƿ��Զ��޸���������

:: ������
:main
    :: ���������ύ��Ϣ
    set /p "COMMIT_MESSAGE=�������ύ��Ϣ: "
    echo ���ڴ�����ģ�����...
    call :process_submodule
    echo ���ڸ������ֿ����з�֧...
    call :process_main_repo
    pause
    exit /b 0

:: ������ģ�飨�޸�detached HEAD���⣩
:process_submodule
    :: ȷ������Ч��֧�ϲ���
    git checkout -B main 2>nul || git checkout -b main
    git pull origin main --allow-unrelated-histories 2>nul
    
    :: �ύ���
    git add -A
    git commit -m "%COMMIT_MESSAGE%" || (
        echo �ޱ�����ύ
        exit /b 0
    )
    
    :: ���͵�Զ�̷�֧
    git push origin main:main --force
    exit /b 0

:: �������ֿ⣨�򻯰棩
:process_main_repo
    pushd %MAIN_REPO_DIR%
    
    echo ���ֿ��֧�б�
    echo --------------------------
    
    :: ͳһʹ�� delims= �����֧��
    :: ��ȡ��ǰ��֧
    for /f "delims=" %%i in ('git rev-parse --abbrev-ref HEAD') do (
        set "CURRENT_BRANCH=%%i"
        set "CURRENT_BRANCH=!CURRENT_BRANCH:HEAD=!"
    )
    echo ��ǰ��֧: !CURRENT_BRANCH!

    :: �������з�֧
    for /f "delims=" %%b in ('git for-each-ref --format^=%%^(refname:short^) refs/heads/') do (
        set "branch=%%b"
        echo ��֧����: !branch!

        git checkout "!branch!"
        git reset HEAD -- .
        git submodule deinit -f public
        git submodule add --force "%SUBMODULE_URL%" "%SUBMODULE_DIR%"
        git add .gitmodules %SUBMODULE_DIR% || (
            echo ��ģ��������
        )
        git submodule update --init --recursive
        git commit -m "������ģ�� [!COMMIT_MESSAGE!]"
        git push origin "!branch!"

    )
    git checkout %CURRENT_BRANCH% 
    
    echo --------------------------
    popd
    exit /b 0

:: ִ��������
call :main
