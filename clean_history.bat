@echo off
setlocal enabledelayedexpansion

:: ��ʾ��ǰĿ¼
echo ��ǰĿ¼: %CD%
echo �ű�·��: %~dp0
echo.

:: ���git�����Ƿ����
echo ���git����...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ����: δ�ҵ�git����
    echo ��ȷ��git�Ѱ�װ����ӵ�PATH��������
    pause
    exit /b 1
)
echo git�������
echo.

:: ����Ƿ���git�ֿ�Ŀ¼
echo ���git�ֿ�״̬...
git rev-parse --is-inside-work-tree >nul 2>&1
if %errorlevel% neq 0 (
    echo ����: ��ǰĿ¼����git�ֿ�
    pause
    exit /b 1
)
echo ��ǰĿ¼��git�ֿ�
echo.

:: ��ȡԶ�̷�֧
echo [����] ��ȡԶ�̷�֧��Ϣ...
git fetch --all
echo.

:: ��ʾ���з�֧��Ϣ
echo [����] ���з�֧��Ϣ:
git branch -a
echo.

:: ���浱ǰ��֧
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%i
echo [����] ��ǰ��֧: %CURRENT_BRANCH%
echo.

:: ��������Զ�̷�֧
echo [����] ��ʼ�������з�֧...
for /f "tokens=* delims= " %%b in ('git branch -r ^| findstr /v "HEAD" ^| findstr "origin/"') do (
    set "branch=%%b"
    set "branch=!branch:origin/=!"
    
    echo [�����֧] !branch!
    
    :: �л���Ŀ���֧
    echo [�л���֧] �����л��� !branch! ��֧...
    git checkout !branch!
    if %errorlevel% neq 0 (
        echo ����: �޷��л��� !branch! ��֧
        pause
        exit /b 1
    )

    :: ��ʾ�ύ��ʷ
    echo [����] ��ǰ�ύ��ʷ:
    git log --oneline
    echo.

    :: �����µĸ��ύ
    echo [�����¸��ύ] ���ڴ����µĸ��ύ...
    git checkout --orphan temp_branch
    if %errorlevel% neq 0 (
        echo ����: �޷�������ʱ��֧
        pause
        exit /b 1
    )

    git add -A
    git commit -m "Initial commit"

    :: ɾ��ԭ��֧
    echo [ɾ��ԭ��֧] ����ɾ��ԭ��֧ !branch!...
    git branch -D !branch!

    :: ��������ʱ��֧
    echo [��������֧] ������������ʱ��֧Ϊ !branch!...
    git branch -m !branch!

    :: ����������־
    echo [��������] ��������������־...
    git reflog expire --expire=now --all

    :: ����δ���õĶ���
    echo [�������] ��������δ���ö���...
    git gc --prune=now --aggressive

    :: ��ʾ�������ύ��ʷ
    echo [����] �������ύ��ʷ:
    git log --oneline
    echo.

    :: ǿ�����͵�Զ�̲��������η�֧
    echo [����Զ��] ����ǿ�����͵�Զ�̲��������η�֧...
    git push -f origin !branch!
    git branch --set-upstream-to=origin/!branch! !branch!

    echo.
    echo ============================================
    echo ��֧ !branch! �� Git ��ʷ�������
    echo ============================================
    echo.
)

:: �л���ԭʼ��֧
echo [�л���֧] �����л���ԭʼ��֧ %CURRENT_BRANCH%...
git checkout %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo ����: �޷��л���ԭʼ��֧
    pause
    exit /b 1
)

:: ���õ�ǰ��֧�����η�֧
echo [�������η�֧] �������õ�ǰ��֧�����η�֧...
git branch --set-upstream-to=origin/%CURRENT_BRANCH% %CURRENT_BRANCH%

echo.
echo ============================================
echo ���з�֧�� Git ��ʷ�������
echo ============================================
echo.
echo ��������˳�...
pause >nul

endlocal 