@echo off
REM Helper script to reload Prometheus configuration after changes

echo === Prometheus Configuration Reload ===
echo.

REM Reload Prometheus
echo 1. Reloading Prometheus...
curl -X POST http://localhost:9090/-/reload 2>nul

if %ERRORLEVEL% EQU 0 (
    echo    √ Prometheus reloaded successfully
) else (
    echo    ✗ Failed to reload Prometheus
    echo    Try restarting: docker-compose restart prometheus
    exit /b 1
)

echo.
echo 2. Waiting for reload to take effect...
timeout /t 2 /nobreak >nul

echo.
echo 3. Current target status:
echo.
curl -s http://localhost:9090/api/v1/targets 2>nul | findstr /C:"job" /C:"health"

echo.
echo === Check targets in detail at: ===
echo http://localhost:9090/targets
pause
