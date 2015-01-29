:: This script runs all tests in this directory and checks their results. Supports two optional parameters.


setlocal EnableDelayedExpansion
@echo off
echo "STARTING TESTS"
:: Initialize the returned value to 0 (all succesfully)
set errorstatus=0
set globalerrorstatus=0
set configuration=x64Win64VS2013
set platform=x64
set failedtests=
set correcttests=
set configurations=Release DLL,Release,Debug DLL,Debug

for %%a in ("%configurations:,=" "%") do (
	echo "CONFIGURATION %%a"
)


:: Get number of arguments
set argC=0
for %%x in (%*) do set /A argC+=1
echo "UNTIL HERE OK %argC%"
:: Get the optional parameter
if "%argC%" == "1" (
	echo "EXECUTING %1"
	cd %1
	call :execTest
	cd ..
	if %errorstatus% == 0 	(
		echo TEST %1 SUCESSFUL
	) else 	(
		echo TEST %1 FAILED
		set globalerrorstatus=1
		set failedtests=%1
	)
) else (
	echo "EXECUTING ALL TESTS IN THIS DIRECTORY"
	for /D %%D in ("*") do 	(
		cd %%D
		call :execTest
		cd ..
		if %errorstatus% == 0 (
			echo TEST %1 SUCESSFUL
			set correcttests="%correcttests% %1"
		) else (
			echo TEST %1 FAILED
			set globalerrorstatus=1
			set failedtests="%failedtests% %1"
		)
	)
)
echo "TESTS FINISHED"
if %globalerrorstatus% == 0 (
    echo "TEST SUCCESSFULL"
) else (
    echo "TESTS FAILED: %failedtests%"
	echo "TESTS OK: %correcttests%"
)

exit /b %globalerrorstatus%

:: This function execute a test in a directory. Use "call" to call this method.
:: @param Target used.
:: @param Plaform for Visual Studio.
:: @param Name of the test
:execTest
::Get the IDL files:
echo "EXECUTING TEST"
set "IDLFILES= "
for %%i in (*.idl) do (
	::echo %%i
	set "IDLFILES=!IDLFILES! %%~NXi"
)
echo "FOUND IDL FILES: %IDLFILES%"
::Generate Info
copy ..\..\..\lib\fastrtpsgen.jar .
java -jar fastrtpsgen.jar -example %configuration% -replace %IDLFILES%
set errorstatus=%ERRORLEVEL%
if not %errorstatus%==0 goto :EOF
if exist *.sln ( 
	echo "Solution exists, compiling"
	for %%s in ("%configurations:,=" "%") do (
		echo "****************Compiling Configuration %%s **********************"
		:: Clean the visual solution
		msbuild "solution-%configuration%.sln" /t:Clean /p:Configuration=%%s /p:Platform="%platform%"
		:: Build the visual solution
		msbuild "solution-%configuration%.sln" /t:Build /p:Configuration=%%s /p:Platform="%platform%"
		set errorstatus=%ERRORLEVEL%
		if not %errorstatus%==0 goto :EOF
	)
	rd /s /q x64
	rd /s /q bin
	rd /s /q lib
	del *.sln
	del *.vcxproj
	del *.filters
)
del *.h
del *.cxx
del *.jar

goto :EOF