@echo off
cd /d "C:\Users\User\Desktop\VETO_App"

echo Fetching GOLD commit from server...
git fetch file:///tmp/veto_final 7eb19d2:refs/remotes/origin/gold-design

echo Merging GOLD design...
git merge --no-edit refs/remotes/origin/gold-design

echo Pushing...
git push origin main -f

echo DONE
pause
