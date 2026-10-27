@echo off
chcp 65001 >nul
title Doan Tau So 09 - Chuong 1: Thanh Pho Khong Tat Den (Phuong an 3)
cd /d "d:\fantasy"
if exist "d:\fantasy\BastionForge_Godot472.exe" (
    start "" "d:\fantasy\BastionForge_Godot472.exe" --path "d:\fantasy" res://scenes/train_09_defense.tscn
)
