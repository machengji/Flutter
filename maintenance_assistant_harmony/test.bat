@echo off
echo ========================================
echo 微行动助手 - 鸿蒙版 测试脚本
echo ========================================
echo.

REM 检查 hvigorw 是否存在
if not exist "hvigorw.bat" (
    echo [错误] 未找到 hvigorw.bat
    echo 请在 DevEco Studio 中运行测试
    pause
    exit /b 1
)

echo [1/2] 编译测试模块...
call hvigorw.bat assembleHap -p module=entry@ohosTest

echo.
echo [2/2] 运行测试...
REM 安装测试 HAP
set TEST_HAP_PATH=entry\build\default\outputs\default\entry_test-default-signed.hap
if exist "%TEST_HAP_PATH%" (
    hdc install "%TEST_HAP_PATH%"
    hdc shell aa start -a TestAbility -b com.example.maintenanceassistant
) else (
    echo [提示] 请在 DevEco Studio 中运行测试
)

echo.
echo ========================================
echo [完成] 测试执行完毕
echo ========================================
pause
