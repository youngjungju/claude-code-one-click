@echo off
rem =====================================================
rem  Claude Code One-Click Installer (Windows)
rem  Double-click this file to install Claude Code.
rem  (All messages will appear in Korean in the window)
rem =====================================================
title Claude Code Installer
echo.
echo  Starting Claude Code installer...
echo  (If Windows SmartScreen blocked this file: click "More info" then "Run anyway")
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex"
echo.
pause
