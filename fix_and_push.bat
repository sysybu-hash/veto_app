@echo off
chcp 65001 >nul
echo ================================
echo  VETO - Fix Lock and Push
echo ================================
echo.

cd /d "C:\Users\User\Desktop\VETO_App"

echo Removing ALL git locks...
del /f ".git\index.lock" 2>nul
del /f ".git\MERGE_HEAD" 2>nul
del /f ".git\CHERRY_PICK_HEAD" 2>nul
PowerShell -Command "Get-ChildItem '.git' -Filter '*.lock' | Remove-Item -Force -ErrorAction SilentlyContinue"
echo Done.
echo.

echo Checking build/web...
if exist "frontend\build\web\main.dart.js" (
  echo   main.dart.js found - OK
) else (
  echo   ERROR: main.dart.js missing!
  pause
  exit /b 1
)
echo.

echo Staging build/web...
git add frontend/build/web/
echo.

echo Staging source files...
git add frontend/lib/
git add frontend/pubspec.yaml 2>nul
git add .github/
echo.

echo Committing...
git -c user.email="sysybu@gmail.com" -c user.name="VETO" commit -m "fix: restore complete build/web + professional gold redesign"
echo.

echo Pushing to GitHub...
git push origin main
echo.

if %errorlevel% equ 0 (
  echo ================================
  echo  SUCCESS! Vercel will redeploy
  echo  in ~1-2 minutes.
  echo.
  echo  Check: https://web-nine-gamma-76.vercel.app
  echo ================================
) else (
  echo ================================
  echo  Push failed. Try running:
  echo  git push origin main
  echo ================================
)
echo.
pause
