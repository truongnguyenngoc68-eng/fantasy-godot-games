@echo off
chcp 65001 >nul
title Meowtopia: Thanh Pho Meo Nhan Nha (Idle Cat City)
cd /d "d:\fantasy"
if exist "d:\fantasy\BastionForge_Godot472.exe" (
    start "" "d:\fantasy\BastionForge_Godot472.exe" --path "d:\fantasy" res://scenes/cat_city_idle.tscn
)
