@echo off
chcp 65001 >nul
echo ================================
echo  VETO - SYNC & PUSH TO GITHUB
echo ================================
echo.

cd /d "C:\Users\User\Desktop\VETO_App"

echo [1/7] Removing git locks...
del /f ".git\index.lock" 2>nul
del /f ".git\MERGE_HEAD" 2>nul
del /f ".git\CHERRY_PICK_HEAD" 2>nul
echo Done.
echo.

echo [2/7] Clearing git cache for frontend/build...
git rm --cached -r frontend/build 2>&1 | find /V "fatal" | find /V "error"
echo.

echo [3/7] Checking what will be added...
git status --short | head -20
echo.

echo [4/7] Force-adding frontend/lib...
git add -f frontend/lib/
echo.

echo [5/7] Force-adding frontend/build/web...
git add -f frontend/build/web/
echo.

echo [6/7] Committing all changes...
git -c user.email="sysybu@gmail.com" -c user.name="VETO" commit -m "feat: add complete source files and build artifacts with professional legal design"
echo.

echo [7/7] Pushing to GitHub...
git push -u origin main
echo.

echo ================================
echo  STATUS:
echo ================================
git log --oneline -3
echo.

echo ================================
echo  NEXT STEPS:
echo ================================
echo.
echo  1. Render will auto-build in ~30s
echo     Watch: https://dashboard.render.com
echo.
echo  2. Vercel will auto-build in ~1-2 min
echo     Watch: https://vercel.com/dashboard
echo.
echo  3. Check GitHub Actions:
echo     https://github.com/sysybu-hash/veto_app/actions
echo.
echo ================================
pause
