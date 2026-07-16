@echo off
setlocal
cd /d "%~dp0"
set "CONFIG_FILE=%~1"
if not "%CONFIG_FILE%"=="" goto run_pipeline

echo Create a configuration for your observation period.
set /p "START_MONTH=First month (YYYY-MM): "
set /p "MONTH_COUNT=Number of consecutive months: "
set "CONFIG_FILE=work\current_period.json"
python automation\pipeline_cli.py make-config --start "%START_MONTH%" --months "%MONTH_COUNT%" --output "%CONFIG_FILE%"
if errorlevel 1 (
  echo CONFIGURATION FAILED - check the month and number entered.
  pause
  exit /b 1
)

:run_pipeline
echo Running the practice-month integration using %CONFIG_FILE%...
echo Required contract files must be present in data\prepared.
python automation\pipeline_cli.py run --config "%CONFIG_FILE%" --input-dir data\prepared --output-dir work\custom-output --database work\custom.sqlite --overwrite
set EXIT_CODE=%ERRORLEVEL%
echo.
if %EXIT_CODE% EQU 0 (
  echo VALIDATED - see work\custom-output\run_report.json
) else (
  echo RUN STOPPED - correct the reported input or validation failure.
)
echo No clustering was run.
pause
exit /b %EXIT_CODE%
