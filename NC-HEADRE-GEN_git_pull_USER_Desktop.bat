@echo off
setlocal
chcp 65001 >nul

set "PROJECT_DIR=C:\Users\USER\Desktop\NC-HEADRE-GEN"
set "PARENT_DIR=C:\Users\USER\Desktop"
set "REPO_URL=https://github.com/yanyoou-web/NC-HEADRE-GEN.git"
set "BRANCH=main"

title NC-HEADRE-GEN Git Pull

echo ========================================
echo   NC-HEADRE-GEN Git Pull
echo ========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git が見つかりません。
    echo Git for Windows をインストールしてから再実行してください。
    goto :failed
)

if not exist "%PROJECT_DIR%" (
    echo プロジェクトフォルダがないため、初回クローンを実行します。
    if not exist "%PARENT_DIR%" mkdir "%PARENT_DIR%"

    git clone --branch "%BRANCH%" "%REPO_URL%" "%PROJECT_DIR%"
    if errorlevel 1 goto :failed
    goto :success
)

if not exist "%PROJECT_DIR%\.git" (
    echo [ERROR] 次のフォルダは Git リポジトリではありません。
    echo %PROJECT_DIR%
    goto :failed
)

echo リポジトリ情報を確認しています...
git -C "%PROJECT_DIR%" remote get-url origin >nul 2>&1
if errorlevel 1 (
    git -C "%PROJECT_DIR%" remote add origin "%REPO_URL%"
) else (
    git -C "%PROJECT_DIR%" remote set-url origin "%REPO_URL%"
)
if errorlevel 1 goto :failed

echo 最新情報を取得しています...
git -C "%PROJECT_DIR%" fetch origin
if errorlevel 1 goto :failed

git -C "%PROJECT_DIR%" show-ref --verify --quiet "refs/heads/%BRANCH%"
if errorlevel 1 (
    git -C "%PROJECT_DIR%" checkout -b "%BRANCH%" "origin/%BRANCH%"
) else (
    git -C "%PROJECT_DIR%" checkout "%BRANCH%"
)
if errorlevel 1 goto :failed

git -C "%PROJECT_DIR%" pull --ff-only origin "%BRANCH%"
if errorlevel 1 goto :failed

:success
echo.
echo [OK] NC-HEADRE-GEN を最新状態に更新しました。
echo.
pause
exit /b 0

:failed
echo.
echo [ERROR] 更新に失敗しました。
echo ローカル変更、競合、認証、ネットワーク接続などを確認してください。
echo.
pause
exit /b 1
