@echo off
setlocal EnableDelayedExpansion 

set PROGFILES=%ProgramFiles%
if not "%ProgramFiles(x86)%" == "" set PROGFILES=%ProgramFiles(x86)%

REM Check if Visual Studio 2013 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 12.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2013"
	goto setup_env
)

REM Check if Visual Studio 2012 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 11.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2012"
	goto setup_env
)

REM Check if Visual Studio 2010 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 10.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2010"
	goto setup_env
)

REM Check if Visual Studio 2008 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 9.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2008"
	goto setup_env
)

REM Check if Visual Studio 2005 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 8"
if exist %MSVCDIR% (
	set COMPILER_VER="2005"
	goto setup_env
) 

REM Check if Visual C++ 6 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio\VC98"
if exist %MSVCDIR% (
	set COMPILER_VER="6"
	goto setup_env
) 

echo No compiler : Microsoft Visual Studio (6, 2005, 2008, 2010, 2012 or 2013) is not installed.
goto end

:setup_env

echo Setting up environment
if %COMPILER_VER% == "6" (
	call %MSVCDIR%\Bin\VCVARS32.BAT
	goto begin
)

call %MSVCDIR%\VC\vcvarsall.bat x86

:begin

REM Setup path to helper bin
set ROOT_DIR="%CD%"
set RM="%CD%\bin\unxutils\rm.exe"
set CP="%CD%\bin\unxutils\cp.exe"
set MKDIR="%CD%\bin\unxutils\mkdir.exe"
set SEVEN_ZIP="%CD%\bin\7-zip\7za.exe"
set SED="%CD%\bin\unxutils\sed.exe"
set WGET="%CD%\bin\unxutils\wget.exe"
set XIDEL="%CD%\bin\xidel\xidel.exe"
set VSPC="%CD%\bin\vspc\vspc.exe"

REM Housekeeping
%RM% -rf tmp_*
%RM% -rf third-party
%RM% -rf fltk.tar*
%RM% -rf build_*.txt

REM Get download url.
echo Get download url...
%XIDEL% http://www.fltk.org/software.php --follow "(//tbody/tr/th/a/@href)[1]" -e "//form/input[@name='FILE']/@value" > tmp_url
set /p url=<tmp_url

REM Download latest curl and rename to fltk.tar.gz
echo Downloading latest fltk...
%WGET% "http://www.fltk.org/pub/%url%" -O fltk.tar.gz

REM Extract downloaded zip file to tmp_libfltk
%SEVEN_ZIP% x fltk.tar.gz -y | FIND /V "Igor Pavlov"

:set_compiler

cd %ROOT_DIR%
%RM% -rf tmp_libfltk
%SEVEN_ZIP% x fltk.tar -y -otmp_libfltk | FIND /V "ing  " | FIND /V "Igor Pavlov"

REM set compiler
if %COMPILER_VER% == "6" goto vc6
if %COMPILER_VER% == "2005" goto vc2005
if %COMPILER_VER% == "2008" goto vc2008
if %COMPILER_VER% == "2010" goto vc2010
if %COMPILER_VER% == "2012" goto vc2012
if %COMPILER_VER% == "2013" goto vc2013

:vc2005
cd %ROOT_DIR%\tmp_libfltk\fltk*\ide\VisualC2008
%SED% -i "s|ProgramDataBaseFileName=\".*\"|ProgramDataBaseFileName=\"$(TargetDir)$(TargetName).pdb\"|g" fltk.lib.vcproj
%SED% -i "s|ProgramDataBaseFileName=\".*\"|ProgramDataBaseFileName=\"$(TargetDir)$(TargetName).pdb\"|g" fltkdll.vcproj
%VSPC% VS2008 VS2005 fltk.sln
goto build_using_devenv

:vc2008
cd %ROOT_DIR%\tmp_libfltk\fltk*\ide\VisualC2008
%SED% -i "s|ProgramDataBaseFileName=\".*\"|ProgramDataBaseFileName=\"$(TargetDir)$(TargetName).pdb\"|g" fltk.lib.vcproj
%SED% -i "s|ProgramDataBaseFileName=\".*\"|ProgramDataBaseFileName=\"$(TargetDir)$(TargetName).pdb\"|g" fltkdll.vcproj
goto build_using_msbuild

:vc2010
cd %ROOT_DIR%\tmp_libfltk\fltk*\ide\VisualC2010
%SED% -i "s|<ProgramDataBaseFileName>.*</ProgramDataBaseFileName>|<ProgramDataBaseFileName>$(TargetDir)$(TargetName).pdb</ProgramDataBaseFileName>|g" fltk.lib.vcxproj
%SED% -i "s|<ProgramDataBaseFileName>.*</ProgramDataBaseFileName>|<ProgramDataBaseFileName>$(TargetDir)$(TargetName).pdb</ProgramDataBaseFileName>|g" fltkdll.vcxproj
goto build_using_msbuild

:vc2012
:vc2013
cd %ROOT_DIR%\tmp_libfltk\fltk*\ide\VisualC2010
%SED% -i "s|<ProgramDataBaseFileName>.*</ProgramDataBaseFileName>|<ProgramDataBaseFileName>$(TargetDir)$(TargetName).pdb</ProgramDataBaseFileName>|g" fltk.lib.vcxproj
%SED% -i "s|<ProgramDataBaseFileName>.*</ProgramDataBaseFileName>|<ProgramDataBaseFileName>$(TargetDir)$(TargetName).pdb</ProgramDataBaseFileName>|g" fltkdll.vcxproj
devenv /upgrade fltk.sln
goto build_using_msbuild

:build_using_devenv

REM Build Release!
if NOT "%RELEASE_IS_OK%" == "1" (
	devenv fltk.sln /Rebuild "Release|Win32" /Project "demo"
	set RELEASE_IS_OK=1
	goto copy_release_files
)

REM Build Debug!
if NOT "%DEBUG_IS_OK%" == "1" (
	devenv fltk.sln /Rebuild "Debug|Win32" /Project "demo"
	set DEBUG_IS_OK=1
	goto copy_debug_files
)
goto cleanup

:build_using_msbuild

REM Build Release!
if NOT "%RELEASE_IS_OK%" == "1" (
	msbuild fltk.sln /t:demo /p:Configuration=Release
	set RELEASE_IS_OK=1
	goto copy_release_files
)

REM Build Debug!
if NOT "%DEBUG_IS_OK%" == "1" (
	msbuild fltk.sln /t:demo /p:Configuration=Debug
	set DEBUG_IS_OK=1
	goto copy_debug_files
)
goto cleanup

:copy_release_files

REM Copy compiled .*lib files in lib folder to third-party folder
cd %ROOT_DIR%\tmp_libfltk\fltk*
%MKDIR% -p %ROOT_DIR%\third-party\libfltk\lib\lib-release
%CP% lib\*.lib %ROOT_DIR%\third-party\libfltk\lib\lib-release
%RM% %ROOT_DIR%\third-party\libfltk\lib\lib-release\README.lib

REM Copy compiled dll files in test folder to third-party folder
%MKDIR% -p %ROOT_DIR%\third-party\libfltk\lib\dll-release
%CP% lib\*.lib %ROOT_DIR%\third-party\libfltk\lib\dll-release
%CP% test\fltkdll.lib %ROOT_DIR%\third-party\libfltk\lib\dll-release
%CP% test\fltkdll.dll %ROOT_DIR%\third-party\libfltk\lib\dll-release
%RM% %ROOT_DIR%\third-party\libfltk\lib\dll-release\README.lib
%RM% %ROOT_DIR%\third-party\libfltk\lib\dll-release\fltk.lib

if "%BIN_IS_OK%" == "1" goto set_compiler
REM Copy compiled fluid.exe files in lib folder to third-party folder
%MKDIR% -p %ROOT_DIR%\third-party\libfltk\bin
%CP% fluid\fluid.exe %ROOT_DIR%\third-party\libfltk\bin

REM Copy FL folder to third-party folder
%MKDIR% -p %ROOT_DIR%\third-party\libfltk\include
%CP% -rf FL %ROOT_DIR%\third-party\libfltk\include
set BIN_IS_OK=1
goto set_compiler

:copy_debug_files

REM Copy compiled .*lib files in lib folder to third-party folder
cd %ROOT_DIR%\tmp_libfltk\fltk*
%MKDIR% -p %ROOT_DIR%\third-party\libfltk\lib\lib-debug
%CP% lib\*.lib %ROOT_DIR%\third-party\libfltk\lib\lib-debug
%CP% lib\*.pdb %ROOT_DIR%\third-party\libfltk\lib\lib-debug
%RM% %ROOT_DIR%\third-party\libfltk\lib\lib-debug\README.lib

REM Copy compiled dll files in test folder to third-party folder
%MKDIR% -p %ROOT_DIR%\third-party\libfltk\lib\dll-debug
%CP% lib\*.lib %ROOT_DIR%\third-party\libfltk\lib\dll-debug
%CP% lib\*.pdb %ROOT_DIR%\third-party\libfltk\lib\dll-debug
%CP% test\fltkdlld.lib %ROOT_DIR%\third-party\libfltk\lib\dll-debug
%CP% test\fltkdlld.dll %ROOT_DIR%\third-party\libfltk\lib\dll-debug
%RM% %ROOT_DIR%\third-party\libfltk\lib\dll-debug\README.lib
%RM% %ROOT_DIR%\third-party\libfltk\lib\dll-debug\fltkd.lib

:cleanup

REM Cleanup temporary file/folders
cd %ROOT_DIR%
%RM% -rf tmp_*
%RM% fltk.tar.gz

:end
exit /b
