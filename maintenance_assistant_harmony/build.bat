@echo off
echo ========================================
echo 微行动助手 - 鸿蒙版 编译脚本
echo ========================================
echo.

REM 检查 hvigorw 是否存在
if not exist "hvigorw.bat" (
    echo [错误] 未找到 hvigorw.bat，请确保在 DevEco Studio 中打开项目
    echo 或者使用 DevEco Studio 的 Build 菜单进行编译
    pause
    exit /b 1
)

echo [1/3] 清理旧的构建文件...
call hvigorw.bat clean

echo.
echo [2/3] 安装依赖...
call ohpm install

echo.
echo [3/3] 编译项目...
call hvigorw.bat assembleHap

echo.
echo ========================================
if %ERRORLEVEL% EQU 0 (
    echo [成功] 编译完成！
    echo HAP 文件位置: entry\build\default\outputs\default\entry-default-signed.hap
) else (
    echo [失败] 编译失败，请检查错误信息
)
echo ========================================
pause
