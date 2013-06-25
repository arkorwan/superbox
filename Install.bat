@echo off
cls
echo Create Superbox folder...
md c:\Superbox
echo Copy files to Superbox 
xcopy *.* c:\Superbox /s
echo Installation successful.