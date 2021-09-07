@echo off
python3 download_assets.py
odin test image    -vet -strict-style
odin test compress -vet -strict-style