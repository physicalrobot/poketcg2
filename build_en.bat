@echo off
rem Double-click to build poketcg2_en.gbc (pastel palettes + English patch) in WSL Ubuntu.
wsl -d Ubuntu --cd "%~dp0." -- bash ./build_en.sh
pause
