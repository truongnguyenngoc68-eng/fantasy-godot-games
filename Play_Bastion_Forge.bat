@echo off
chcp 65001 >nul
title Bastion Forge 2.0 - Milestone 1 (Godot 4.7.2)
cd /d "%~dp0"
if exist "%~dp0BastionForge_Godot472.exe" (
    start "" "%~dp0BastionForge_Godot472.exe" --path "%~dp0"
) else (
    start "" "C:\Users\truon\.gemini\antigravity\brain\d22ae0c0-1053-4893-8621-d1b356f26b08\scratch\godot472\Godot_v4.7.2-stable_win64.exe" --path "%~dp0"
)
