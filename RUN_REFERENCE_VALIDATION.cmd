@echo off
setlocal
cd /d "%~dp0"
echo Validating the frozen reference outputs against their SHA-256 manifest...
echo Missing release-only outputs will be restored from the pinned, checksum-verified asset.
python automation\pipeline_cli.py validate-reference --restore-missing --output work\reference_validation.csv
set EXIT_CODE=%ERRORLEVEL%
echo.
if %EXIT_CODE% EQU 0 (
  echo REFERENCE OUTPUTS VALIDATED - see work\reference_validation.csv
) else (
  echo REFERENCE VALIDATION FAILED.
)
echo No database rebuild and no clustering were performed.
pause
exit /b %EXIT_CODE%
