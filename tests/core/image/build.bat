@echo off
odin test . -define:ODIN_TEST_TRACK_MEMORY=true -define:ODIN_TEST_PROGRESS_WIDTH=12 -vet -strict-style
