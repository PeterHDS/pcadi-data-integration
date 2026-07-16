@echo off
setlocal
cd /d "%~dp0"
echo Rebuilding the frozen OCS/GPAD annual reference from the 21 manifest files...
echo Source files must be placed under data\downloads\reference as specified in reference-release\input_manifest.csv.
python reference-release\automation\run_reference_build.py --manifest reference-release\input_manifest.csv --database work\reference-build\primary_practice_access_pipeline.sqlite --master-sql sql\core_pipeline\run_complete_core_pipeline.sql --output-dir work\reference-build\outputs --validation-dir work\reference-build\validation --expected-fingerprint reference-release\validation\expected_modelling_output_fingerprint.csv --overwrite
set EXIT_CODE=%ERRORLEVEL%
echo.
if %EXIT_CODE% EQU 0 (
  echo REFERENCE BUILD VALIDATED - see work\reference-build.
) else (
  echo REFERENCE BUILD STOPPED - verify every manifest file and checksum.
)
echo No clustering was run.
pause
exit /b %EXIT_CODE%
