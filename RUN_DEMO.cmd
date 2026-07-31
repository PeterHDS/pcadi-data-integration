@echo off
setlocal
cd /d "%~dp0"
echo Running a small deterministic three-month SQL demonstration...
echo The configurable pipeline also supports any other positive month count.
python automation\pipeline_cli.py demo --months 3
set EXIT_CODE=%ERRORLEVEL%
echo.
if %EXIT_CODE% EQU 0 (
  echo VALIDATED DEMO - see work\demo_3_months\outputs\run_report.json
) else (
  echo DEMO FAILED - review the error above.
)
echo No clustering was run.
pause
exit /b %EXIT_CODE%
