@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
echo ================================================
echo  VETO-LEGAL - Deploy to Render + Vercel
echo  Render:  https://veto-app-new.onrender.com
echo  Vercel:  https://web-nine-gamma-76.vercel.app
echo ================================================
echo.

:: Repo root = folder containing this script (works for any clone path)
cd /d "%~dp0"
echo Working in: %CD%
echo.

:: Step 1 - Remove git lock
echo [1/4] Removing git lock...
if exist ".git\index.lock" (
  del /f ".git\index.lock"
  echo   Lock removed.
) else (
  echo   No lock found.
)
echo.

:: Step 2 - Build Flutter Web
echo [2/4] Building Flutter Web...
echo   This may take 2-5 minutes...
cd frontend
for /f "delims=" %%i in ('git -C .. rev-parse --short HEAD 2^>nul') do set "VETO_SHA=%%i"
if not defined VETO_SHA set "VETO_SHA=local"
call flutter build web --release --no-wasm-dry-run --no-tree-shake-icons --pwa-strategy=none --dart-define=VETO_API_BASE=https://veto-app-new.onrender.com --dart-define=VETO_BUILD_ID=!VETO_SHA!
if %errorlevel% neq 0 (
  echo.
  echo   ERROR: Flutter build failed! See error above.
  cd ..
  pause
  exit /b 1
)
cd ..
echo   Flutter build complete!
echo.

:: Step 3 - Git add
echo [3/4] Staging all files...
git add -A
echo   Done.
echo.

:: Step 4 - Commit + Push
echo [4/4] Committing and pushing to GitHub...
git -c user.email="sysybu@gmail.com" -c user.name="VETO" commit -m "chore: deploy web (icons + build flags)"
echo   Pushing... (may ask for GitHub password)
git push origin main
if %errorlevel% neq 0 (
  echo.
  echo   Push failed. Try running: git push origin main
  pause
  exit /b 1
)

echo.
echo ================================================
echo  SUCCESS! Code pushed to GitHub.
echo.
echo  Render auto-deploy:  ~2 min
echo    https://dashboard.render.com
echo.
echo  Vercel auto-deploy:  ~1 min
echo    https://vercel.com/sysybu-2933s-projects/veto-legal
echo.
echo  Live site:
echo    https://web-nine-gamma-76.vercel.app
echo ================================================
echo.
pause
