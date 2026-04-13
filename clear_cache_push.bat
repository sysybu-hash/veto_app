@echo off
chcp 65001 >nul
echo ================================
echo  VETO - Clear Cache & Push
echo ================================
echo.

cd /d "C:\Users\User\Desktop\VETO_App"

echo [1/6] Removing git lock...
del /f ".git\index.lock" 2>nul

echo [2/6] Clearing git cache for build folder...
git rm --cached -r frontend/build 2>&1 | find /V "fatal"
echo Done.
echo.

echo [3/6] Re-staging build/web...
git add frontend/build/web/
echo.

echo [4/6] Staging source files...
git add frontend/lib/
git add frontend/pubspec.yaml 2>nul
git add .github/ 2>nul
echo.

echo [5/6] Committing...
git -c user.email="sysybu@gmail.com" -c user.name="VETO" commit -m "fix: add build/web and source files - clear git cache"
echo.

echo [6/6] Pushing...
git push origin main
echo.

if %errorlevel% equ 0 (
  echo ================================
  echo  SUCCESS! Vercel + Render deploy
  echo  in 1-2 minutes.
  echo ================================
) else (
  echo ================================
  echo  ERROR - see above
  echo ================================
)
pause
