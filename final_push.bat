@echo off
chcp 65001 >nul
echo ================================
echo  VETO - FINAL PUSH
echo ================================
echo.

cd /d "C:\Users\User\Desktop\VETO_App"

echo [1/5] Removing git lock...
del /f ".git\index.lock" 2>nul
timeout /t 1 /nobreak >nul

echo [2/5] Checking git status...
git status
echo.

echo [3/5] Adding ALL changes...
git add -A
echo.

echo [4/5] Committing...
git -c user.email="sysybu@gmail.com" -c user.name="VETO" commit -m "chore: add complete build/web and source files"
echo.

echo [5/5] Pushing to GitHub...
git push -u origin main
echo.

if %errorlevel% equ 0 (
  echo ================================
  echo  SUCCESS!
  echo.
  echo  Render + Vercel will auto-deploy
  echo  within 1-2 minutes.
  echo.
  echo  Monitor:
  echo  - Render: https://dashboard.render.com
  echo  - Vercel: https://vercel.com/dashboard
  echo ================================
) else (
  echo ================================
  echo  ERROR: Check the output above
  echo ================================
)
echo.
pause
