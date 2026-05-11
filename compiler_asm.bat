@echo off
setlocal

set "ROOT=%~dp0"
set "ASM_DIR=%ROOT%compiler_asm"
set "BUILD_DIR=%ASM_DIR%\build"

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

set "NASM=nasm"
set "CXX=g++"

if exist "C:\Strawberry\c\bin\nasm.exe" set "NASM=C:\Strawberry\c\bin\nasm.exe"
if exist "C:\Strawberry\c\bin\g++.exe" set "CXX=C:\Strawberry\c\bin\g++.exe"

if exist "%NASM%" goto nasm_found
where %NASM% >nul 2>nul
if errorlevel 1 (
    echo nasm not found. Install NASM or add it to PATH.
    exit /b 1
)
:nasm_found

if exist "%CXX%" goto cxx_found
where %CXX% >nul 2>nul
if errorlevel 1 (
    echo g++ not found. Install g++ or add it to PATH.
    exit /b 1
)
:cxx_found

echo [1/4] Converting Compiler.s to NASM syntax...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ASM_DIR%\gas_to_nasm.ps1" "%ASM_DIR%\Compiler.s" "%BUILD_DIR%\Compiler.asm"
if errorlevel 1 exit /b 1

echo [2/4] Assembling Compiler.obj with NASM...
"%NASM%" -f win64 "%BUILD_DIR%\Compiler.asm" -o "%BUILD_DIR%\Compiler.obj"
if errorlevel 1 exit /b 1

if exist "%BUILD_DIR%\Compiler_main.obj" del /q "%BUILD_DIR%\Compiler_main.obj"

echo [3/3] Linking compiler_asm.exe from Compiler.obj...
"%CXX%" "%BUILD_DIR%\Compiler.obj" -o "%ROOT%compiler_asm.exe"
if errorlevel 1 exit /b 1

echo Built "%ROOT%compiler_asm.exe"
echo Object files are in "%BUILD_DIR%"
exit /b 0
