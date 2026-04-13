@echo off
chcp 65001 >nul
echo ================================
echo  VETO - Force Push Build
echo ================================
echo.

cd /d "C:\Users\User\Desktop\VETO_App"

echo Removing git lock...
del /f ".git\index.lock" 2>nul
echo Done.
echo.

echo Force-adding build/web...
git add -f frontend/build/web/
echo.

echo Force-adding source files...
git add -f frontend/lib/
git add -f frontend/pubspec.yaml 2>nul
git add -f .github/workflows/ 2>nul
echo.

echo Staging .gitignore fix...
git add .gitignore
echo.

echo Committing...
git -c user.email="sysybu@gmail.com" -c user.name="VETO" commit -m "fix: force-add complete build/web and source files"
echo.

echo Pushing to GitHub...
git push origin main
echo.

if %errorlevel% equ 0 (
  echo ================================
  echo  SUCCESS!
  echo  GitHub Actions will now:
  echo  1. Build frontend with Flutter
  echo  2. Deploy to Vercel
  echo  3. Render auto-deploys
  echo.
  echo  Check in ~2-3 minutes:
  echo  https://web-nine-gamma-76.vercel.app
  echo ================================
) else (
  echo ERROR: Push failed
)
echo.
pause
