@echo off
chcp 65001 >nul
echo ================================
echo  VETO - Push to GitHub
echo ================================
echo.

cd /d "C:\Users\User\Desktop\VETO_App"

echo Removing git lock...
PowerShell -Command "Remove-Item -Force '.git\index.lock' -ErrorAction SilentlyContinue"
echo Done.
echo.

echo Restoring build/web from last good version...
git checkout -- frontend/build/web/ 2>nul
echo Done.
echo.

echo Staging all changes...
git add -A
echo.

echo Committing...
git -c user.email="sysybu@gmail.com" -c user.name="VETO" commit -m "feat: professional legal redesign + GitHub Actions auto-build"
echo.

echo Pushing to GitHub...
echo (if prompted, enter your GitHub username and token/password)
git push origin main

echo.
echo ================================
if %errorlevel% equ 0 (
  echo  SUCCESS!
  echo  GitHub Actions will now automatically:
  echo  1. Build Flutter Web
  echo  2. Deploy to Vercel
  echo.
  echo  Watch progress at:
  echo  https://github.com/sysybu-hash/veto_app/actions
) else (
  echo  Push failed - check credentials
)
echo ================================
echo.
pause
