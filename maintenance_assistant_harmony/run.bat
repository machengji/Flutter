@echo off
echo ========================================
echo 微行动助手 - 鸿蒙版 运行脚本
echo ========================================
echo.

REM 检查设备连接
echo [1/3] 检查设备连接...
hdc list targets
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未检测到设备，请确保：
    echo   1. 设备已通过 USB 连接
    echo   2. 设备已开启开发者模式
    echo   3. HDC 工具已正确安装
    pause
    exit /b 1
)

echo.
echo [2/3] 安装应用...
set HAP_PATH=entry\build\default\outputs\default\entry-default-signed.hap
if not exist "%HAP_PATH%" (
    echo [错误] 未找到 HAP 文件，请先运行 build.bat 编译项目
    pause
    exit /b 1
)

hdc install "%HAP_PATH%"

echo.
echo [3/3] 启动应用...
hdc shell aa start -a EntryAbility -b com.example.maintenanceassistant

echo.
echo ========================================
echo [完成] 应用已启动
echo ========================================
pause
