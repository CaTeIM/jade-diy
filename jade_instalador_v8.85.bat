@echo off
chcp 65001 > NUL

:: Elevar privilégios automaticamente
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Elevando privilégios para administrador...
    powershell -Command "Start-Process -FilePath '%COMSPEC%' -ArgumentList '/c %~f0' -Verb runAs"
    exit /b
)

cd /d "%~dp0"

setlocal enabledelayedexpansion

:MENU
cd /d "%~dp0"
echo.
echo =============================================
echo       Bem-vindo ao Instalador Jade
echo         Desenvolvido por Sandmann
echo =============================================
echo.
echo Por favor, selecione uma opção:
echo.
echo [1] Instalar dependências e aplicativos necessários
echo [2] Baixar arquivos Jade e selecionar tipo de dispositivo
echo [3] Instalar o software Jade no seu dispositivo
echo.
echo [0] Sair
echo.

set "OPTION="
set /p OPTION=Digite o número da sua escolha e pressione Enter: 

if "%OPTION%"=="" (
    echo Opção inválida. Por favor, tente novamente.
    goto MENU
)

if "%OPTION%"=="1" (
    goto INSTALL_DEPENDENCIES
) else if "%OPTION%"=="2" (
    goto DOWNLOAD_JADE
) else if "%OPTION%"=="3" (
    goto INSTALL_SOFTWARE
) else if "%OPTION%"=="0" (
    goto EXIT_SCRIPT
) else (
    echo Opção inválida. Por favor, tente novamente.
    goto MENU
)

:INSTALL_DEPENDENCIES
REM -------------------------------------------------------------
REM Opção 1: Instalar dependências e aplicativos necessários
REM -------------------------------------------------------------

REM Buscar versão recomendada de ESP-IDF pelo projeto Jade
echo Buscando versão recomendada do ESP-IDF...
set "DEFAULT_VERSION=5.4"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"try { ^
    $content = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Blockstream/Jade/master/main/idf_component.yml' -UseBasicParsing).Content; ^
    if($content -match 'idf:\s*[\"'']?>=?([0-9]+\.[0-9]+)') { ^
        Write-Output $matches[1] ^
    } elseif($content -match 'version:\s*[\"'']?>=?([0-9]+\.[0-9]+)') { ^
        Write-Output $matches[1] ^
    } else { ^
        Write-Output '5.4' ^
    } ^
} catch { Write-Output '5.4' }" > temp_version.txt 2>NUL

set /p DEFAULT_VERSION=<temp_version.txt
del temp_version.txt 2>NUL
if "%DEFAULT_VERSION%"=="" set "DEFAULT_VERSION=5.4"

echo.
echo Versão padrão do ESP-IDF: %DEFAULT_VERSION%
echo.
powershell -Command "$releases = (Invoke-WebRequest -Uri 'https://api.github.com/repos/espressif/idf-installer/releases' -UseBasicParsing | ConvertFrom-Json); $offline = $releases | Where-Object { $_.tag_name -like 'offline-*' } | Select-Object -First 5; $i=1; foreach($r in $offline) { $v = $r.tag_name -replace 'offline-',''; Write-Host \" [$i] $v\"; $i++ }"
echo.
set /p ESP_IDF_VERSION=Digite a versão do ESP-IDF (pressione Enter para usar %DEFAULT_VERSION%): 

REM Usar a versão padrão se o usuário não inserir uma versão
if "%ESP_IDF_VERSION%"=="" (
    set "ESP_IDF_VERSION=%DEFAULT_VERSION%"
)

REM Definir o nome do arquivo e o URL de download
set "ESP_IDF_FILE=esp-idf-tools-setup-offline-%ESP_IDF_VERSION%.exe"
set "ESP_IDF_URL=https://github.com/espressif/idf-installer/releases/download/offline-%ESP_IDF_VERSION%/%ESP_IDF_FILE%"

REM Verificar se a versão do ESP-IDF já está instalada
set "IDF_ALREADY_INSTALLED=NO"
set "INSTALL_IDF=YES"

if exist "C:\Espressif\frameworks\esp-idf-v%ESP_IDF_VERSION%\export.bat" (
    set "IDF_ALREADY_INSTALLED=YES"
)

if "%IDF_ALREADY_INSTALLED%"=="NO" (
    if exist "%USERPROFILE%\.espressif\frameworks\esp-idf-v%ESP_IDF_VERSION%\export.bat" (
        set "IDF_ALREADY_INSTALLED=YES"
    )
)

REM Se já instalado, perguntar se quer reinstalar
if "%IDF_ALREADY_INSTALLED%"=="YES" (
    echo.
    echo ESP-IDF versão %ESP_IDF_VERSION% já está instalado.
    echo.
    choice /C SN /M "Deseja reinstalar"
    if errorlevel 2 set "INSTALL_IDF=NO"
)

if "%INSTALL_IDF%"=="NO" (
    echo Pulando instalação do ESP-IDF.
) else (
    if "%IDF_ALREADY_INSTALLED%"=="YES" (
        echo Prosseguindo com a reinstalação...
    )

    REM Verificar se o ESP-IDF já foi baixado
    if exist "%ESP_IDF_FILE%" (
        echo O arquivo %ESP_IDF_FILE% já existe. Pulando download...
    ) else (
        echo Baixando o ESP-IDF versão %ESP_IDF_VERSION%...
        echo URL: %ESP_IDF_URL%
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-BitsTransfer -Source '%ESP_IDF_URL%' -Destination '%ESP_IDF_FILE%' -Description 'ESP-IDF %ESP_IDF_VERSION%' -DisplayName 'Baixando ESP-IDF'"
        echo Download concluído.
    )

    REM Instalar o ESP-IDF
    echo Instalando o ESP-IDF versão %ESP_IDF_VERSION%...
    "%ESP_IDF_FILE%"
    if !ERRORLEVEL! neq 0 (
        echo Falha na instalação do ESP-IDF.
        pause
        goto MENU
    )
    echo ESP-IDF instalado com sucesso.
)

REM Passo 2: Verificar e instalar o Python automaticamente
echo.
echo Verificando o Python...

REM Definir versão do Python
set "PYTHON_VERSION=3.13.0"

python --version > NUL 2>&1

set "PYTHON_ALREADY_INSTALLED=NO"
set "INSTALL_PYTHON=YES"

if %ERRORLEVEL% equ 0 (
    set "PYTHON_ALREADY_INSTALLED=YES"
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do set "CURRENT_PYTHON_VERSION=%%v"
)

if "%PYTHON_ALREADY_INSTALLED%"=="YES" (
    echo Python !CURRENT_PYTHON_VERSION! já está instalado.
    echo.
    choice /C SN /M "Deseja reinstalar o Python"
    if errorlevel 2 set "INSTALL_PYTHON=NO"
)

if "%INSTALL_PYTHON%"=="NO" goto SKIP_PYTHON_INSTALL

if "%PYTHON_ALREADY_INSTALLED%"=="YES" (
    echo Prosseguindo com a reinstalação...
) else (
    echo Python não foi detectado. Procedendo com a instalação...
)

REM Detectar arquitetura e escolher versão
echo.
echo Selecione a arquitetura do Python:
echo.
echo [1] x64 (AMD64) - Recomendado para maioria dos PCs
echo [2] ARM64 - Para processadores ARM
echo [3] x86 (32-bit) - Compatibilidade máxima
echo.

set "ARCH_CHOICE=1"
set /p ARCH_CHOICE=Digite sua escolha (1-3) [padrao: 1]: 

REM Definir instalador baseado na escolha (SEM IF ANINHADOS)
set "PYTHON_INSTALLER=python-%PYTHON_VERSION%-amd64.exe"
if "!ARCH_CHOICE!"=="2" set "PYTHON_INSTALLER=python-%PYTHON_VERSION%-arm64.exe"
if "!ARCH_CHOICE!"=="3" set "PYTHON_INSTALLER=python-%PYTHON_VERSION%.exe"

set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/!PYTHON_INSTALLER!"

echo.
echo Instalador selecionado: !PYTHON_INSTALLER!
echo.

if exist "!PYTHON_INSTALLER!" (
    echo O instalador do Python já existe. Pulando download...
    goto INSTALL_PYTHON_NOW
)

echo Baixando o instalador do Python...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-BitsTransfer -Source '!PYTHON_URL!' -Destination '!PYTHON_INSTALLER!' -Description 'Python Installer' -DisplayName 'Baixando Python'"
echo Download concluído.

:INSTALL_PYTHON_NOW
echo Instalando o Python...
"!PYTHON_INSTALLER!" /passive InstallAllUsers=1 PrependPath=1 Include_test=0
if !ERRORLEVEL! neq 0 (
    echo Falha na instalação do Python.
    pause
    goto MENU
)
echo Python instalado com sucesso.

:SKIP_PYTHON_INSTALL

REM Passo 3: Verificar e instalar o Git
echo.
echo Verificando o Git...

git --version > NUL 2>&1

set "GIT_ALREADY_INSTALLED=NO"
set "INSTALL_GIT=YES"

if %ERRORLEVEL% equ 0 (
    set "GIT_ALREADY_INSTALLED=YES"
    for /f "tokens=3" %%v in ('git --version 2^>^&1') do set "GIT_VERSION=%%v"
)

if "%GIT_ALREADY_INSTALLED%"=="YES" (
    echo Git !GIT_VERSION! já está instalado.
    echo.
    choice /C SN /M "Deseja reinstalar o Git"
    if errorlevel 2 set "INSTALL_GIT=NO"
)

if "%INSTALL_GIT%"=="NO" (
    echo Pulando instalação do Git.
) else (
    if "%GIT_ALREADY_INSTALLED%"=="YES" (
        echo Prosseguindo com a reinstalação...
    ) else (
        echo Git não foi detectado. Procedendo com a instalação...
    )

    echo Buscando a última versão do Git for Windows...

    REM Obter URL da última versão do Git for Windows (64-bit)
        set "GIT_INSTALLER=Git-2.51.2-64-bit.exe"
        set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.51.2.windows.1/Git-2.51.2-64-bit.exe"

    for /f "delims=" %%U in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest'; $asset = $release.assets | Where-Object { $_.name -like '*64-bit.exe' -and $_.name -notlike '*MinGit*' } | Select-Object -First 1; if($asset) { Write-Output $asset.browser_download_url } else { Write-Output '' } } catch { Write-Output '' }"') do set "GIT_URL_LATEST=%%U"

    if not "!GIT_URL_LATEST!"=="" (
        set "GIT_URL=!GIT_URL_LATEST!"
        for %%F in ("!GIT_URL!") do set "GIT_INSTALLER=%%~nxF"
        echo Última versão encontrada: !GIT_INSTALLER!
    ) else (
        echo Usando versão padrão: !GIT_INSTALLER!
    )

    if exist "!GIT_INSTALLER!" (
        echo O instalador do Git já existe. Pulando download...
    ) else (
        echo Baixando o Git for Windows...
        echo URL: !GIT_URL!
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-BitsTransfer -Source '!GIT_URL!' -Destination '!GIT_INSTALLER!' -Description 'Git for Windows' -DisplayName 'Baixando Git'"
        if !ERRORLEVEL! neq 0 (
            echo Falha ao baixar o Git.
            pause
            goto MENU
        )
        echo Download concluído.
    )

    echo Instalando o Git...
    "!GIT_INSTALLER!" /SILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
    if !ERRORLEVEL! neq 0 (
        echo Falha na instalação do Git.
        pause
        goto MENU
    )
    echo Git instalado com sucesso.
    echo.
    echo IMPORTANTE: Reinicie este script para o Git ser reconhecido no PATH.
    pause
)

REM Passo 4: Baixar drivers do ESP32
set "DRIVER_ZIP=CH341SER_WINDOWS.zip"
set "DRIVER_URL=https://s3-sa-east-1.amazonaws.com/robocore-tutoriais/163/%DRIVER_ZIP%"

if exist "%DRIVER_ZIP%" (
    echo O arquivo %DRIVER_ZIP% já existe. Pulando download...
) else (
    echo Baixando drivers do ESP32...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-BitsTransfer -Source '%DRIVER_URL%' -Destination '%DRIVER_ZIP%' -Description 'Drivers CH341' -DisplayName 'Baixando Drivers'"
    echo Download concluído.
)

REM Passo 4: Extrair e instalar os drivers do ESP32
set "DRIVER_FOLDER=CH341SER_WINDOWS"

if exist "%DRIVER_FOLDER%" (
    echo A pasta %DRIVER_FOLDER% já existe. Pulando extração...
) else (
    echo Extraindo drivers do ESP32...
    powershell -Command "Expand-Archive -Path '%DRIVER_ZIP%' -DestinationPath '%DRIVER_FOLDER%'"
    if %ERRORLEVEL% neq 0 (
        echo Falha ao extrair os drivers do ESP32.
        pause
        goto MENU
    )
    echo Drivers extraídos com sucesso.
)

REM Instalar os drivers
echo Instalando os drivers do ESP32...
cd "%DRIVER_FOLDER%"
if exist "CH341SER.EXE" (
    "CH341SER.EXE"
    if %ERRORLEVEL% neq 0 (
        echo Falha na instalação dos drivers do ESP32.
        pause
        goto MENU
    )
    echo Drivers instalados com sucesso.
) else (
    echo Arquivo CH341SER.EXE não encontrado nos drivers do ESP32.
    pause
    goto MENU
)
cd ..

echo Todos os passos foram concluídos com sucesso.
pause
goto MENU

:SELECT_IDF_VERSION
REM -------------------------------------------------------------
REM Sub-rotina: Selecionar versão do ESP-IDF
REM -------------------------------------------------------------
set "IDF_FRAMEWORKS_DIR=C:\Espressif\frameworks"
if not exist "%IDF_FRAMEWORKS_DIR%" (
    set "IDF_FRAMEWORKS_DIR=%USERPROFILE%\.espressif\frameworks"
)
if not exist "%IDF_FRAMEWORKS_DIR%" (
    set "IDF_FRAMEWORKS_DIR=%ProgramFiles%\Espressif\frameworks"
)
:RETRY_PATH
echo Procurando versões do ESP-IDF instaladas...
set "INDEX=1"
for /F "tokens=*" %%A in ('set IDF_VERSION_ 2^>NUL') do set "%%A="
for /D %%D in ("%IDF_FRAMEWORKS_DIR%\esp-idf-v*") do (
    set "IDF_VERSION_!INDEX!=%%~nxD"
    echo  !INDEX!. %%~nxD
    set /A INDEX+=1
)
if %INDEX% EQU 1 (
    echo.
    echo ERRO: Nenhuma versão do ESP-IDF foi encontrada.
    echo Utilize a opção [1] do menu para instalar dependências antes de continuar!
    pause
    goto MENU
)
set /A MAX_OPTION=INDEX-1
set "USER_SELECTION="

:ASK_VERSION
set /P "USER_SELECTION=Selecione o número da versão do ESP-IDF que deseja usar (1-%MAX_OPTION%): "
if "%USER_SELECTION%"=="" (
    echo Por favor, insira um número entre 1 e %MAX_OPTION%.
    goto ASK_VERSION
)
set /A TEST_INPUT=%USER_SELECTION%+0 2> NUL
if %TEST_INPUT% EQU 0 if not "%USER_SELECTION%"=="0" (
    echo Entrada inválida. Por favor, insira um número.
    goto ASK_VERSION
)
if %TEST_INPUT% GEQ 1 if %TEST_INPUT% LEQ %MAX_OPTION% (
    set "SELECTED_IDF_VERSION=!IDF_VERSION_%USER_SELECTION%!"
) else (
    echo Número fora do intervalo. Por favor, escolha entre 1 e %MAX_OPTION%.
    goto ASK_VERSION
)
echo Versão selecionada: %SELECTED_IDF_VERSION%
set "IDF_PATH=%IDF_FRAMEWORKS_DIR%\%SELECTED_IDF_VERSION%"
goto :EOF

:SELECT_COM_PORT
REM -------------------------------------------------------------
REM Sub-rotina: Detectar e selecionar porta COM
REM -------------------------------------------------------------
echo.
echo Detectando portas COM disponíveis...
set "INDEX=1"
for /F "tokens=*" %%A in ('set COM_PORT_ 2^>NUL') do set "%%A="
for /F "tokens=1* delims=:" %%A in ('powershell -Command "[System.IO.Ports.SerialPort]::getportnames() | Sort-Object"') do (
    set "COM_PORT_!INDEX!=%%A"
    echo  !INDEX!. %%A
    set /A INDEX+=1
)

if %INDEX% EQU 1 (
    echo.
    echo Nenhuma porta COM detectada.
    echo.
    choice /C SC /M "Deseja [S]air ou [C]ontinuar (sem -p COM)"
    if errorlevel 2 (
        set "SELECTED_PORT="
        echo Continuando sem porta serial...
        goto :EOF
    ) else (
        set "SELECTED_PORT=ABORT"
        goto :EOF
    )
)

echo  0. Detecção automática (padrão)
echo.
set /A MAX_PORT=INDEX-1
set "PORT_SELECTION="

:ASK_PORT_SELECTION
set /P "PORT_SELECTION=Selecione a porta (0-%MAX_PORT%): "
if "%PORT_SELECTION%"=="" (
    echo Por favor, insira um número válido entre 0 e %MAX_PORT%.
    goto ASK_PORT_SELECTION
)
set /A TEST_PORT=%PORT_SELECTION%+0 2> NUL
if %TEST_PORT% GEQ 0 if %TEST_PORT% LEQ %MAX_PORT% (
    if "%PORT_SELECTION%"=="0" (
        set "SELECTED_PORT="
        echo Usando detecção automática.
    ) else (
        set "SELECTED_PORT=!COM_PORT_%PORT_SELECTION%!"
        echo Porta selecionada: !SELECTED_PORT!
    )
) else (
    echo Seleção inválida. Por favor, escolha um número entre 0 e %MAX_PORT%.
    goto ASK_PORT_SELECTION
)

goto :EOF

:DOWNLOAD_JADE
REM -------------------------------------------------------------
REM Opção 2: Baixar arquivos Jade e selecionar tipo de dispositivo
REM -------------------------------------------------------------

call :SELECT_IDF_VERSION

REM Verificar se o export.bat existe na versão selecionada
if not exist "%IDF_PATH%\export.bat" (
    echo O arquivo export.bat não foi encontrado na pasta %IDF_PATH%.
    pause
    goto MENU
)

REM Inicializar o ambiente do ESP-IDF
echo Inicializando o ambiente do ESP-IDF na versão %SELECTED_IDF_VERSION%...

REM Definir arquivo temporário para captura da saída de export.bat
set "EXPORT_LOG=%TEMP%\esp_export_log.txt"
call "%IDF_PATH%\export.bat" > "%EXPORT_LOG%" 2>&1
set EXPORT_ERRORLEVEL=%ERRORLEVEL%

REM Verificar se ocorreu erro de ambiente python não encontrado
findstr /C:"ESP-IDF Python virtual environment not found" "%EXPORT_LOG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Ambiente python ESP-IDF não encontrado, executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo após instalar Python.
        pause
        goto MENU
    )
) else (
    if %EXPORT_ERRORLEVEL% NEQ 0 (
        echo Falha ao inicializar o ambiente ESP-IDF.
        pause
        goto MENU
    )
)

del "%EXPORT_LOG%" 2>nul

REM Verificar se a inicialização foi bem-sucedida
if errorlevel 1 (
    echo Falha ao inicializar o ambiente do ESP-IDF.
    pause
    goto MENU
)

REM Definir o caminho base como o diretório atual
set "BASE_DIR=%cd%"

REM Verificar se a pasta Jade já foi clonada
set "JADE_REPO_DIR=%BASE_DIR%\Jade"
set "JADE_REPO_URL=https://github.com/Blockstream/Jade.git"

if exist "%JADE_REPO_DIR%" (
    echo O repositório Jade já foi clonado na pasta %JADE_REPO_DIR%. Pulando clonagem...
    
    REM Verificar e configurar safe.directory mesmo se já existir
    echo Configurando repositório como safe directory...
    git config --global --add safe.directory "%JADE_REPO_DIR%" 2>nul
) else (
    echo Clonando o repositório Jade...
    git clone --recursive %JADE_REPO_URL%
    if %ERRORLEVEL% neq 0 (
        echo Falha ao clonar o repositório Jade. Verifique sua conexão e tente novamente.
        pause
        goto MENU
    )
    
    REM Configurar o diretório como seguro imediatamente após o clone
    echo Configurando repositório como safe directory...
    git config --global --add safe.directory "%JADE_REPO_DIR%"
    if %ERRORLEVEL% neq 0 (
        echo AVISO: Não foi possível configurar safe.directory, mas o clone foi bem-sucedido.
    ) else (
        echo Repositório configurado como seguro.
    )
)

REM Caminho para o diretório de configurações
set "CONFIGS_DIR=%JADE_REPO_DIR%\configs"

:SELECT_CONFIG
REM Listar os arquivos disponíveis
echo.
echo Por favor, escolha uma das opções abaixo para configurar o Jade:
echo.

REM Inicializar contador
set /a COUNT=1

REM Limpar variáveis temporárias de opções anteriores
for /F "tokens=*" %%A in ('set OPTION_ 2^>NUL') do set "%%A="

REM Listar todas as opções disponíveis de arquivos sdkconfig
for %%f in ("%CONFIGS_DIR%\sdkconfig_display_*.defaults") do (
    echo [!COUNT!] %%~nxf
    set "OPTION_!COUNT!=%%~nxf"
    set /a COUNT+=1
)

REM Verificar se encontrou opções de configuração
if %COUNT% EQU 1 (
    echo Nenhum arquivo de configuração encontrado em %CONFIGS_DIR%.
    pause
    goto MENU
)

REM Solicitar a escolha do usuário
echo.
set "CHOICE="
set /p CHOICE=Digite o número da sua escolha e pressione Enter: 

REM Verificar se a escolha é válida
if not defined OPTION_%CHOICE% (
    echo Opção inválida. Tente novamente.
    pause
    goto SELECT_CONFIG
)

setlocal enabledelayedexpansion
set "SELECTED_CONFIG=!OPTION_%CHOICE%!"
endlocal & set "SELECTED_CONFIG=%SELECTED_CONFIG%"
echo.
echo Você escolheu: %SELECTED_CONFIG%
echo.
choice /C SC /M "Deseja [S]eguir ou [C]ancelar e escolher novamente"
if errorlevel 2 goto SELECT_CONFIG

REM Copiar o arquivo de configuração escolhido para a pasta Jade e renomeá-lo
echo.
echo Copiando arquivo de configuração...
copy /y "%CONFIGS_DIR%\%SELECTED_CONFIG%" "%JADE_REPO_DIR%\sdkconfig.defaults"
if %ERRORLEVEL% neq 0 (
    echo Falha ao copiar e renomear o arquivo de configuração.
    pause
    goto MENU
) else (
    echo Arquivo de configuração copiado e renomeado com sucesso.
)

REM Aplicar configuração de 16MB para TTGO T-Display
if /I "%SELECTED_CONFIG%"=="sdkconfig_display_ttgo_tdisplay.defaults" (
    echo.
    echo Aplicando configuração de flash 16MB para TTGO T-Display...
    
    setlocal enabledelayedexpansion
    set "SDKCONFIG_DEFAULTS=%JADE_REPO_DIR%\sdkconfig.defaults"
    
    REM Substituir 4MB por 16MB diretamente
    powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '!SDKCONFIG_DEFAULTS!') -replace 'CONFIG_ESPTOOLPY_FLASHSIZE_4MB=y', 'CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y' | Set-Content '!SDKCONFIG_DEFAULTS!'"
    
    echo Flash size configurado para 16MB.
    endlocal
)

REM Aplicar configuração específica para Waveshare S3 Touch LCD2
if /I "%SELECTED_CONFIG%"=="sdkconfig_display_waveshares3_touch_lcd2.defaults" (
    echo.
    echo Aplicando configuração específica para Waveshare S3 Touch LCD2...
    echo Habilitando CONFIG_JADE_USE_USB_JTAG_SERIAL...

    setlocal enabledelayedexpansion

    set "SDKCONFIG_DEFAULTS=%JADE_REPO_DIR%\sdkconfig.defaults"

    REM Verificar se a configuração já existe no arquivo
    findstr /C:"CONFIG_JADE_USE_USB_JTAG_SERIAL=y" "!SDKCONFIG_DEFAULTS!" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        REM Remover linha comentada se existir
        powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '!SDKCONFIG_DEFAULTS!') | Where-Object { $_ -notmatch '# CONFIG_JADE_USE_USB_JTAG_SERIAL is not set' } | Set-Content '!SDKCONFIG_DEFAULTS!'"
        
        REM Adicionar configuração habilitada ao final do arquivo
        echo CONFIG_JADE_USE_USB_JTAG_SERIAL=y >> "!SDKCONFIG_DEFAULTS!"
        echo Configuração USB JTAG serial habilitada com sucesso.
    ) else (
        echo Configuração USB JTAG serial já estava habilitada.
    )

    endlocal
)

echo O processo de configuração foi concluído.
pause
goto MENU

:INSTALL_SOFTWARE
REM -------------------------------------------------------------
REM Opção 3: Instalar o software Jade no seu dispositivo
REM -------------------------------------------------------------

REM Verificar se a pasta Jade existe
if not exist "%~dp0Jade" (
    echo A pasta Jade não foi encontrada. Certifique-se de que você executou a opção 2 primeiro.
    pause
    goto MENU
)

echo.
echo Por favor, selecione uma opção:
echo.
echo [1] Compilar (limpeza completa)
echo [2] Compilar incremental (mais rápido)
echo [3] Compilar e Instalar
echo [4] Instalar (já compilado)
echo.
echo [0] Retornar ao menu principal
echo.

set "INSTALL_OPTION="
set /p INSTALL_OPTION=Digite o número da sua escolha e pressione Enter: 

if "%INSTALL_OPTION%"=="" (
    echo Opção inválida. Retornando ao menu principal.
    pause
    goto MENU
)

if "%INSTALL_OPTION%"=="1" (
    goto COMPILE
) else if "%INSTALL_OPTION%"=="2" (
    goto COMPILE_INCREMENTAL
) else if "%INSTALL_OPTION%"=="3" (
    goto COMPILE_AND_INSTALL
) else if "%INSTALL_OPTION%"=="4" (
    goto INSTALL_ONLY
) else if "%INSTALL_OPTION%"=="0" (
    goto MENU
) else (
    echo Opção inválida. Retornando ao menu principal.
    pause
    goto MENU
)

:COMPILE
call :SELECT_IDF_VERSION

REM Verificar se o export.bat existe na versão selecionada
if not exist "%IDF_PATH%\export.bat" (
    echo O arquivo export.bat não foi encontrado na pasta %IDF_PATH%.
    pause
    goto MENU
)

REM Inicializar o ambiente do ESP-IDF
echo Inicializando o ambiente do ESP-IDF na versão %SELECTED_IDF_VERSION%...

REM Definir arquivo temporário para captura da saída de export.bat
set "EXPORT_LOG=%TEMP%\esp_export_log.txt"
call "%IDF_PATH%\export.bat" > "%EXPORT_LOG%" 2>&1
set EXPORT_ERRORLEVEL=%ERRORLEVEL%

REM Verificar se ocorreu erro de ambiente python não encontrado
findstr /C:"ESP-IDF Python virtual environment not found" "%EXPORT_LOG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Ambiente python ESP-IDF não encontrado, executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo após instalar Python.
        pause
        goto MENU
    )
) else (
    if %EXPORT_ERRORLEVEL% NEQ 0 (
        echo Falha ao inicializar o ambiente ESP-IDF.
        pause
        goto MENU
    )
)

del "%EXPORT_LOG%" 2>nul

REM Verificar se a inicialização foi bem-sucedida
if errorlevel 1 (
    echo Falha ao inicializar o ambiente do ESP-IDF.
    pause
    goto MENU
)

REM Criar python3 no ambiente Python do ESP-IDF
echo Configurando alias python3...
for /f "delims=" %%I in ('where python') do (
    set "IDF_PYTHON=%%I"
    goto :FOUND_IDF_PYTHON
)
:FOUND_IDF_PYTHON
if defined IDF_PYTHON (
    for %%D in ("!IDF_PYTHON!") do set "IDF_PYTHON_DIR=%%~dpD"
    if not exist "!IDF_PYTHON_DIR!python3.exe" (
        copy /y "!IDF_PYTHON!" "!IDF_PYTHON_DIR!python3.exe" > NUL 2>&1
        if !ERRORLEVEL! equ 0 (
            echo Alias python3 criado com sucesso.
        ) else (
            echo Aviso: Não foi possível criar alias python3.
        )
    ) else (
        echo Alias python3 já existe.
    )
)

REM Navegar para a pasta Jade
cd /d "%cd%\Jade"

REM Limpar o diretório de build para evitar conflitos (FULLCLEAN)
echo Limpando build anterior (fullclean)...
idf.py fullclean

REM Compilar o projeto
echo Compilando o projeto...
idf.py build
if %ERRORLEVEL% neq 0 (
    echo Falha na compilação do projeto.
    pause
    goto MENU
)

REM Extrair os binários após a compilação
echo Extraindo binários...
if not exist "%cd%\bin_jade" mkdir "%cd%\bin_jade"

copy /y "build\bootloader\bootloader.bin" "bin_jade\"
copy /y "build\jade.bin" "bin_jade\"
copy /y "build\ota_data_initial.bin" "bin_jade\"
copy /y "build\partition_table\partition-table.bin" "bin_jade\"

echo Binários extraídos com sucesso.

REM Após a conclusão, retornar ao menu
pause
goto MENU

:COMPILE_INCREMENTAL
call :SELECT_IDF_VERSION

REM Verificar se o export.bat existe na versão selecionada
if not exist "%IDF_PATH%\export.bat" (
    echo O arquivo export.bat não foi encontrado na pasta %IDF_PATH%.
    pause
    goto MENU
)

REM Inicializar o ambiente do ESP-IDF
echo Inicializando o ambiente do ESP-IDF na versão %SELECTED_IDF_VERSION%...

REM Definir arquivo temporário para captura da saída de export.bat
set "EXPORT_LOG=%TEMP%\esp_export_log.txt"
call "%IDF_PATH%\export.bat" > "%EXPORT_LOG%" 2>&1
set EXPORT_ERRORLEVEL=%ERRORLEVEL%

REM Verificar se ocorreu erro de ambiente python não encontrado
findstr /C:"ESP-IDF Python virtual environment not found" "%EXPORT_LOG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Ambiente python ESP-IDF não encontrado, executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo após instalar Python.
        pause
        goto MENU
    )
) else (
    if %EXPORT_ERRORLEVEL% NEQ 0 (
        echo Falha ao inicializar o ambiente ESP-IDF.
        pause
        goto MENU
    )
)

del "%EXPORT_LOG%" 2>nul

REM Verificar se a inicialização foi bem-sucedida
if errorlevel 1 (
    echo Falha ao inicializar o ambiente do ESP-IDF.
    pause
    goto MENU
)

REM Criar python3 no ambiente Python do ESP-IDF
echo Configurando alias python3...
for /f "delims=" %%I in ('where python') do (
    set "IDF_PYTHON=%%I"
    goto :FOUND_IDF_PYTHON_INCREMENTAL
)
:FOUND_IDF_PYTHON_INCREMENTAL
if defined IDF_PYTHON (
    for %%D in ("!IDF_PYTHON!") do set "IDF_PYTHON_DIR=%%~dpD"
    if not exist "!IDF_PYTHON_DIR!python3.exe" (
        copy /y "!IDF_PYTHON!" "!IDF_PYTHON_DIR!python3.exe" > NUL 2>&1
        if !ERRORLEVEL! equ 0 (
            echo Alias python3 criado com sucesso.
        ) else (
            echo Aviso: Não foi possível criar alias python3.
        )
    ) else (
        echo Alias python3 já existe.
    )
)

REM Navegar para a pasta Jade
cd /d "%cd%\Jade"

REM Compilar o projeto (INCREMENTAL - SEM fullclean, usando cache)
echo Compilando o projeto (incremental - usando cache)...
idf.py build
if %ERRORLEVEL% neq 0 (
    echo Falha na compilação do projeto.
    pause
    goto MENU
)

REM Extrair os binários após a compilação
echo Extraindo binários...
if not exist "%cd%\bin_jade" mkdir "%cd%\bin_jade"

copy /y "build\bootloader\bootloader.bin" "bin_jade\"
copy /y "build\jade.bin" "bin_jade\"
copy /y "build\ota_data_initial.bin" "bin_jade\"
copy /y "build\partition_table\partition-table.bin" "bin_jade\"

echo Binários extraídos com sucesso.

REM Após a conclusão, retornar ao menu
pause
goto MENU

:COMPILE_AND_INSTALL
call :SELECT_IDF_VERSION

REM Verificar se o export.bat existe na versão selecionada
if not exist "%IDF_PATH%\export.bat" (
    echo O arquivo export.bat não foi encontrado na pasta %IDF_PATH%.
    pause
    goto MENU
)

REM Inicializar o ambiente do ESP-IDF
echo Inicializando o ambiente do ESP-IDF na versão %SELECTED_IDF_VERSION%...

REM Definir arquivo temporário para captura da saída de export.bat
set "EXPORT_LOG=%TEMP%\esp_export_log.txt"
call "%IDF_PATH%\export.bat" > "%EXPORT_LOG%" 2>&1
set EXPORT_ERRORLEVEL=%ERRORLEVEL%

REM Verificar se ocorreu erro de ambiente python não encontrado
findstr /C:"ESP-IDF Python virtual environment not found" "%EXPORT_LOG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Ambiente python ESP-IDF não encontrado, executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo após instalar Python.
        pause
        goto MENU
    )
) else (
    if %EXPORT_ERRORLEVEL% NEQ 0 (
        echo Falha ao inicializar o ambiente ESP-IDF.
        pause
        goto MENU
    )
)

del "%EXPORT_LOG%" 2>nul

REM Verificar se a inicialização foi bem-sucedida
if errorlevel 1 (
    echo Falha ao inicializar o ambiente do ESP-IDF.
    pause
    goto MENU
)

REM Criar python3 no ambiente Python do ESP-IDF
echo Configurando alias python3...
for /f "delims=" %%I in ('where python') do (
    set "IDF_PYTHON=%%I"
    goto :FOUND_IDF_PYTHON2
)
:FOUND_IDF_PYTHON2
if defined IDF_PYTHON (
    for %%D in ("!IDF_PYTHON!") do set "IDF_PYTHON_DIR=%%~dpD"
    if not exist "!IDF_PYTHON_DIR!python3.exe" (
        copy /y "!IDF_PYTHON!" "!IDF_PYTHON_DIR!python3.exe" > NUL 2>&1
        if !ERRORLEVEL! equ 0 (
            echo Alias python3 criado com sucesso.
        ) else (
            echo Aviso: Não foi possível criar alias python3.
        )
    ) else (
        echo Alias python3 já existe.
    )
)

REM Navegar para a pasta Jade
cd /d "%cd%\Jade"

REM Limpar o diretório de build para evitar conflitos
idf.py fullclean

REM Compilar o projeto
echo Compilando o projeto...
idf.py build
if %ERRORLEVEL% neq 0 (
    echo Falha na compilação do projeto.
    pause
    goto MENU
)

REM Extrair os binários após a compilação
echo Extraindo binários...
if not exist "%cd%\bin_jade" mkdir "%cd%\bin_jade"

copy /y "build\bootloader\bootloader.bin" "bin_jade\"
copy /y "build\jade.bin" "bin_jade\"
copy /y "build\ota_data_initial.bin" "bin_jade\"
copy /y "build\partition_table\partition-table.bin" "bin_jade\"

echo Binários extraídos com sucesso.

REM Selecionar porta COM
call :SELECT_COM_PORT

REM Verificar se o usuário escolheu abortar
if "%SELECTED_PORT%"=="ABORT" (
    echo Operação cancelada pelo usuário.
    pause
    goto MENU
)

REM Flashar o dispositivo
echo Instalando o software no dispositivo...
if "%SELECTED_PORT%"=="" (
    idf.py flash
) else (
    idf.py -p %SELECTED_PORT% flash
)

REM Após a conclusão, retornar ao menu
pause
goto MENU

:INSTALL_ONLY
call :SELECT_IDF_VERSION

REM Verificar se o export.bat existe na versão selecionada
if not exist "%IDF_PATH%\export.bat" (
    echo O arquivo export.bat não foi encontrado na pasta %IDF_PATH%.
    pause
    goto MENU
)

REM Navegar para a pasta Jade
cd /d "%~dp0\Jade"

REM Verificar se os binários existem
if not exist "%cd%\bin_jade\bootloader.bin" (
    echo.
    echo ================================================
    echo ERRO: Os binários não foram encontrados!
    echo ================================================
    echo.
    echo A pasta bin_jade não contém os arquivos compilados.
    echo Certifique-se de que você compilou o projeto primeiro usando:
    echo   [1] Compilar  ou  [2] Compilar e Instalar
    echo.
    pause
    goto MENU
)

:VERIFY_CONFIG
REM Verificar qual configuração foi usada
echo.
echo ================================================
echo Verificando informações da compilação
echo ================================================
echo.

set "SDKCONFIG_FILE=%cd%\sdkconfig.defaults"
set "CONFIG_DETECTED=Não identificada"

if exist "%SDKCONFIG_FILE%" (
    echo Analisando sdkconfig.defaults...
    
    REM Detectar tipo de placa usando PowerShell (OTIMIZADO - 5x mais rápido)
    for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$content = Get-Content '%SDKCONFIG_FILE%' -Raw; switch -Regex ($content) { 'CONFIG_BOARD_TYPE_JADE=y' { 'Blockstream Jade v1 (wheel)'; break } 'CONFIG_BOARD_TYPE_JADE_V1_1=y' { 'Blockstream Jade v1.1 (rocker)'; break } 'CONFIG_BOARD_TYPE_JADE_V2=y' { 'Blockstream Jade v2 (esp32s3)'; break } 'CONFIG_BOARD_TYPE_M5_FIRE=y' { 'M5Stack Fire'; break } 'CONFIG_BOARD_TYPE_M5_BLACK_GRAY=y' { 'M5Stack Black/Gray'; break } 'CONFIG_BOARD_TYPE_M5_CORE2=y' { 'M5Stack Core 2'; break } 'CONFIG_BOARD_TYPE_M5_CORES3=y' { 'M5Stack Core S3'; break } 'CONFIG_BOARD_TYPE_M5_STICKC_PLUS=y' { 'M5StickC Plus'; break } 'CONFIG_BOARD_TYPE_M5_STICKC_PLUS_2=y' { 'M5StickC Plus 2'; break } 'CONFIG_BOARD_TYPE_TTGO_TDISPLAY=y' { 'TTGO T-Display'; break } 'CONFIG_BOARD_TYPE_TTGO_TDISPLAYS3=y' { 'TTGO T-Display S3'; break } 'CONFIG_BOARD_TYPE_TTGO_TDISPLAYS3PROCAMERA=y' { 'TTGO T-Display S3 Pro Camera'; break } 'CONFIG_BOARD_TYPE_TTGO_TWATCHS3=y' { 'TTGO T-Watch S3'; break } 'CONFIG_BOARD_TYPE_WS_TOUCH_LCD2=y' { 'Waveshare S3 Touch LCD 2'; break } default { 'Não identificada' } }" 2^>nul`) do set "CONFIG_DETECTED=%%i"
    
    REM Fallback caso PowerShell falhe
    if "!CONFIG_DETECTED!"=="" set "CONFIG_DETECTED=Não identificada"
    
    echo Configuração detectada: !CONFIG_DETECTED!
) else (
    echo AVISO: Arquivo sdkconfig.defaults não encontrado.
)

REM Verificar data da última compilação
if exist "%cd%\build\jade.bin" (
    for %%F in ("%cd%\build\jade.bin") do (
        echo Última compilação: %%~tF
    )
) else if exist "%cd%\bin_jade\jade.bin" (
    for %%F in ("%cd%\bin_jade\jade.bin") do (
        echo Última extração de binários: %%~tF
    )
)

echo.
echo ================================================
echo.

REM Perguntar se deseja alterar configuração ou seguir
choice /C STC /M "Deseja [S]eguir, [T]rocar configuração ou [C]ancelar"
if errorlevel 3 (
    echo Instalação cancelada pelo usuário.
    pause
    goto MENU
)
if errorlevel 2 (
    REM Usuário quer trocar a configuração
    goto CHANGE_CONFIG_FOR_INSTALL
)
if errorlevel 1 (
    REM Usuário quer seguir com a configuração atual
    goto PROCEED_WITH_INSTALL
)

:CHANGE_CONFIG_FOR_INSTALL
REM Listar configurações disponíveis
echo.
echo Por favor, escolha a nova configuração para o dispositivo:
echo.

set "CONFIGS_DIR=%cd%\configs"
set /a COUNT=1

REM Limpar variáveis temporárias
for /F "tokens=*" %%A in ('set CONFIG_OPTION_ 2^>NUL') do set "%%A="

REM Listar todas as opções disponíveis
for %%f in ("%CONFIGS_DIR%\sdkconfig_display_*.defaults") do (
    echo [!COUNT!] %%~nxf
    set "CONFIG_OPTION_!COUNT!=%%~nxf"
    set /a COUNT+=1
)

if %COUNT% EQU 1 (
    echo Nenhuma configuração encontrada em %CONFIGS_DIR%.
    pause
    goto MENU
)

echo.
set "NEW_CONFIG_CHOICE="
set /p NEW_CONFIG_CHOICE=Digite o número da configuração desejada: 

if not defined CONFIG_OPTION_%NEW_CONFIG_CHOICE% (
    echo Opção inválida.
    pause
    goto CHANGE_CONFIG_FOR_INSTALL
)

setlocal enabledelayedexpansion
set "NEW_SELECTED_CONFIG=!CONFIG_OPTION_%NEW_CONFIG_CHOICE%!"
endlocal & set "NEW_SELECTED_CONFIG=%NEW_SELECTED_CONFIG%"

echo.
echo Você escolheu: %NEW_SELECTED_CONFIG%
echo.
choice /C SC /M "Deseja [S]eguir ou [C]ancelar"
if errorlevel 2 goto CHANGE_CONFIG_FOR_INSTALL

REM Copiar nova configuração
echo.
echo Copiando nova configuração...
copy /y "%CONFIGS_DIR%\%NEW_SELECTED_CONFIG%" "%cd%\sdkconfig.defaults"
if %ERRORLEVEL% neq 0 (
    echo Falha ao copiar configuração.
    pause
    goto MENU
) else (
    echo Configuração copiada com sucesso.
)

REM Aplicar configuração de 16MB para TTGO T-Display
if /I "%NEW_SELECTED_CONFIG%"=="sdkconfig_display_ttgo_tdisplay.defaults" (
    echo.
    echo Aplicando configuração de flash 16MB para TTGO T-Display...
    
    setlocal enabledelayedexpansion
    set "SDKCONFIG_DEFAULTS=%cd%\sdkconfig.defaults"
    
    REM Substituir 4MB por 16MB diretamente
    powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '!SDKCONFIG_DEFAULTS!') -replace 'CONFIG_ESPTOOLPY_FLASHSIZE_4MB=y', 'CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y' | Set-Content '!SDKCONFIG_DEFAULTS!'"
    
    echo Flash size configurado para 16MB.
    endlocal
)

REM Aplicar configuração específica para Waveshare S3 Touch LCD2
if /I "%NEW_SELECTED_CONFIG%"=="sdkconfig_display_waveshares3_touch_lcd2.defaults" (
    echo.
    echo Aplicando configuração específica para Waveshare S3 Touch LCD2...
    echo Habilitando CONFIG_JADE_USE_USB_JTAG_SERIAL...

    setlocal enabledelayedexpansion

    set "SDKCONFIG_DEFAULTS=%cd%\sdkconfig.defaults"

    REM Verificar se a configuração já existe no arquivo
    findstr /C:"CONFIG_JADE_USE_USB_JTAG_SERIAL=y" "!SDKCONFIG_DEFAULTS!" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        REM Remover linha comentada se existir
        powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '!SDKCONFIG_DEFAULTS!') | Where-Object { $_ -notmatch '# CONFIG_JADE_USE_USB_JTAG_SERIAL is not set' } | Set-Content '!SDKCONFIG_DEFAULTS!'"
        
        REM Adicionar configuração habilitada ao final do arquivo
        echo CONFIG_JADE_USE_USB_JTAG_SERIAL=y >> "!SDKCONFIG_DEFAULTS!"
        echo Configuração USB JTAG serial habilitada com sucesso.
    ) else (
        echo Configuração USB JTAG serial já estava habilitada.
    )

    endlocal
)

echo.
echo ================================================
echo IMPORTANTE: Nova configuração aplicada!
echo ================================================
echo.
echo Com a nova configuração, o projeto precisa ser recompilado.
echo.
echo Escolha uma opção:
echo [1] Recompilar agora e depois instalar
echo [2] Apenas recompilar (sem instalar)
echo [3] Instalar binários antigos (não recomendado)
echo.
echo [0] Cancelar e voltar ao menu
echo.

set "RECOMPILE_CHOICE="
set /p RECOMPILE_CHOICE=Digite sua escolha: 

if "%RECOMPILE_CHOICE%"=="1" (
    goto RECOMPILE_AND_INSTALL_NEW_CONFIG
) else if "%RECOMPILE_CHOICE%"=="2" (
    goto RECOMPILE_ONLY_NEW_CONFIG
) else if "%RECOMPILE_CHOICE%"=="3" (
    echo.
    echo AVISO: Você está instalando binários compilados com configuração diferente!
    echo Isso pode causar problemas no dispositivo.
    echo.
    choice /C SC /M "Tem certeza que deseja [S]eguir ou [C]ancelar"
    if errorlevel 2 (
        echo Operação cancelada.
        pause
        goto MENU
    )
    goto VERIFY_CONFIG
) else if "%RECOMPILE_CHOICE%"=="0" (
    echo Operação cancelada.
    pause
    goto MENU
) else (
    echo Opção inválida.
    pause
    goto CHANGE_CONFIG_FOR_INSTALL
)

:RECOMPILE_ONLY_NEW_CONFIG
echo.
echo ================================================
echo Recompilando projeto com nova configuração...
echo ================================================
echo.

REM Inicializar o ambiente do ESP-IDF
echo Inicializando o ambiente do ESP-IDF na versão %SELECTED_IDF_VERSION%...

REM Definir arquivo temporário para captura da saída de export.bat
set "EXPORT_LOG=%TEMP%\esp_export_log.txt"
call "%IDF_PATH%\export.bat" > "%EXPORT_LOG%" 2>&1
set EXPORT_ERRORLEVEL=%ERRORLEVEL%

REM Verificar se ocorreu erro de ambiente python não encontrado
findstr /C:"ESP-IDF Python virtual environment not found" "%EXPORT_LOG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Ambiente python ESP-IDF não encontrado, executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo após instalar Python.
        pause
        goto MENU
    )
) else (
    if %EXPORT_ERRORLEVEL% NEQ 0 (
        echo Falha ao inicializar o ambiente ESP-IDF.
        pause
        goto MENU
    )
)

del "%EXPORT_LOG%" 2>nul

REM Criar python3 no ambiente Python do ESP-IDF
echo Configurando alias python3...
for /f "delims=" %%I in ('where python') do (
    set "IDF_PYTHON=%%I"
    goto :FOUND_IDF_PYTHON_RECOMPILE
)
:FOUND_IDF_PYTHON_RECOMPILE
if defined IDF_PYTHON (
    for %%D in ("!IDF_PYTHON!") do set "IDF_PYTHON_DIR=%%~dpD"
    if not exist "!IDF_PYTHON_DIR!python3.exe" (
        copy /y "!IDF_PYTHON!" "!IDF_PYTHON_DIR!python3.exe" > NUL 2>&1
        if !ERRORLEVEL! equ 0 (
            echo Alias python3 criado com sucesso.
        ) else (
            echo Aviso: Não foi possível criar alias python3.
        )
    ) else (
        echo Alias python3 já existe.
    )
)

REM ============================================================
REM IMPORTANTE: Deletar sdkconfig antigo para forçar regeneração
REM ============================================================
if exist "%cd%\sdkconfig" (
    echo Removendo sdkconfig antigo...
    del /f /q "%cd%\sdkconfig"
)
if exist "%cd%\sdkconfig.old" (
    del /f /q "%cd%\sdkconfig.old"
)
REM ============================================================

REM Limpar o diretório de build
echo Limpando build anterior...
idf.py fullclean

REM Compilar o projeto
echo Compilando o projeto...
idf.py build 2>&1
if %ERRORLEVEL% neq 0 (
    echo Falha na compilação do projeto.
    pause
    goto MENU
)

REM Extrair os binários após a compilação
echo Extraindo binários...
if not exist "%cd%\bin_jade" mkdir "%cd%\bin_jade"

copy /y "build\bootloader\bootloader.bin" "bin_jade\"
copy /y "build\jade.bin" "bin_jade\"
copy /y "build\ota_data_initial.bin" "bin_jade\"
copy /y "build\partition_table\partition-table.bin" "bin_jade\"

echo.
echo ================================================
echo Compilação concluída com sucesso!
echo ================================================
echo Binários extraídos para: bin_jade\
echo.
pause
goto MENU

:RECOMPILE_AND_INSTALL_NEW_CONFIG
echo.
echo ================================================
echo Recompilando projeto com nova configuração...
echo ================================================
echo.

REM Inicializar o ambiente do ESP-IDF
echo Inicializando o ambiente do ESP-IDF na versão %SELECTED_IDF_VERSION%...

REM Definir arquivo temporário para captura da saída de export.bat
set "EXPORT_LOG=%TEMP%\esp_export_log.txt"
call "%IDF_PATH%\export.bat" > "%EXPORT_LOG%" 2>&1
set EXPORT_ERRORLEVEL=%ERRORLEVEL%

REM Verificar se ocorreu erro de ambiente python não encontrado
findstr /C:"ESP-IDF Python virtual environment not found" "%EXPORT_LOG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Ambiente python ESP-IDF não encontrado, executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo após instalar Python.
        pause
        goto MENU
    )
) else (
    if %EXPORT_ERRORLEVEL% NEQ 0 (
        echo Falha ao inicializar o ambiente ESP-IDF.
        pause
        goto MENU
    )
)

del "%EXPORT_LOG%" 2>nul

REM Criar python3 no ambiente Python do ESP-IDF
echo Configurando alias python3...
for /f "delims=" %%I in ('where python') do (
    set "IDF_PYTHON=%%I"
    goto :FOUND_IDF_PYTHON_RECOMPILE_INSTALL
)
:FOUND_IDF_PYTHON_RECOMPILE_INSTALL
if defined IDF_PYTHON (
    for %%D in ("!IDF_PYTHON!") do set "IDF_PYTHON_DIR=%%~dpD"
    if not exist "!IDF_PYTHON_DIR!python3.exe" (
        copy /y "!IDF_PYTHON!" "!IDF_PYTHON_DIR!python3.exe" > NUL 2>&1
        if !ERRORLEVEL! equ 0 (
            echo Alias python3 criado com sucesso.
        ) else (
            echo Aviso: Não foi possível criar alias python3.
        )
    ) else (
        echo Alias python3 já existe.
    )
)

REM ============================================================
REM IMPORTANTE: Deletar sdkconfig antigo para forçar regeneração
REM ============================================================
if exist "%cd%\sdkconfig" (
    echo Removendo sdkconfig antigo...
    del /f /q "%cd%\sdkconfig"
)
if exist "%cd%\sdkconfig.old" (
    del /f /q "%cd%\sdkconfig.old"
)
REM ============================================================

REM Limpar o diretório de build
echo Limpando build anterior...
idf.py fullclean

REM Compilar o projeto
echo Compilando o projeto...
idf.py build 2>&1
if %ERRORLEVEL% neq 0 (
    echo Falha na compilação do projeto.
    pause
    goto MENU
)

REM Extrair os binários após a compilação
echo Extraindo binários...
if not exist "%cd%\bin_jade" mkdir "%cd%\bin_jade"

copy /y "build\bootloader\bootloader.bin" "bin_jade\"
copy /y "build\jade.bin" "bin_jade\"
copy /y "build\ota_data_initial.bin" "bin_jade\"
copy /y "build\partition_table\partition-table.bin" "bin_jade\"

echo Binários extraídos com sucesso.
echo.
echo ================================================
echo Compilação concluída! Prosseguindo para instalação...
echo ================================================
echo.

REM Selecionar porta COM
call :SELECT_COM_PORT

REM Verificar se o usuário escolheu abortar
if "%SELECTED_PORT%"=="ABORT" (
    echo Operação cancelada pelo usuário.
    pause
    goto MENU
)

REM Flashar o dispositivo
echo Instalando o software no dispositivo...
if "%SELECTED_PORT%"=="" (
    idf.py flash
) else (
    idf.py -p %SELECTED_PORT% flash
)

REM Após a conclusão, retornar ao menu
pause
goto MENU

:PROCEED_WITH_INSTALL
REM Inicializar o ambiente do ESP-IDF
echo.
echo Inicializando o ambiente do ESP-IDF na versão %SELECTED_IDF_VERSION%...

REM Definir arquivo temporário para captura da saída de export.bat
set "EXPORT_LOG=%TEMP%\esp_export_log.txt"
call "%IDF_PATH%\export.bat" > "%EXPORT_LOG%" 2>&1
set EXPORT_ERRORLEVEL=%ERRORLEVEL%

REM Verificar se ocorreu erro de ambiente python não encontrado
findstr /C:"ESP-IDF Python virtual environment not found" "%EXPORT_LOG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Ambiente python ESP-IDF não encontrado, executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo após instalar Python.
        pause
        goto MENU
    )
) else (
    if %EXPORT_ERRORLEVEL% NEQ 0 (
        echo Falha ao inicializar o ambiente ESP-IDF.
        pause
        goto MENU
    )
)

del "%EXPORT_LOG%" 2>nul

REM Verificar se a inicialização foi bem-sucedida
if errorlevel 1 (
    echo Falha ao inicializar o ambiente do ESP-IDF.
    pause
    goto MENU
)

REM Selecionar porta COM
call :SELECT_COM_PORT

REM Verificar se o usuário escolheu abortar
if "%SELECTED_PORT%"=="ABORT" (
    echo Operação cancelada pelo usuário.
    pause
    goto MENU
)

REM ============================================================
REM VERIFICAÇÃO: Detectar compatibilidade de chip
REM ============================================================
echo.
echo Verificando compatibilidade do chip...

REM Detectar chip do build (do CMakeCache.txt)
set "BUILD_CHIP=unknown"
if exist "%cd%\build\CMakeCache.txt" (
    for /f "tokens=2 delims==" %%i in ('findstr /C:"IDF_TARGET:STRING=" "%cd%\build\CMakeCache.txt" 2^>nul') do set "BUILD_CHIP=%%i"
)

echo Build compilado para: %BUILD_CHIP%

REM Detectar chip conectado (usando esptool)
set "CONNECTED_CHIP=unknown"
if not "%SELECTED_PORT%"=="" (
    echo Detectando chip conectado na porta %SELECTED_PORT%...
    
    REM Usar read_mac diretamente - mais confiável
    for /f "tokens=*" %%i in ('python -m esptool --port %SELECTED_PORT% read_mac 2^>^&1') do (
        echo %%i | findstr /C:"Chip is" >nul
        if !ERRORLEVEL! EQU 0 (
            echo %%i | findstr /C:"ESP32-S3" >nul && set "CONNECTED_CHIP=esp32s3"
            echo %%i | findstr /C:"ESP32-S2" >nul && set "CONNECTED_CHIP=esp32s2"
            echo %%i | findstr /C:"ESP32-C3" >nul && set "CONNECTED_CHIP=esp32c3"
            echo %%i | findstr /C:"ESP32-C6" >nul && set "CONNECTED_CHIP=esp32c6"
            echo %%i | findstr /C:"ESP32-H2" >nul && set "CONNECTED_CHIP=esp32h2"
            if "!CONNECTED_CHIP!"=="unknown" (
                echo %%i | findstr /C:"ESP32" >nul && set "CONNECTED_CHIP=esp32"
            )
        )
    )
    echo Chip conectado: %CONNECTED_CHIP%
)

REM Comparar chips
if not "%BUILD_CHIP%"=="%CONNECTED_CHIP%" (
    if not "%CONNECTED_CHIP%"=="unknown" (
        echo.
        echo ================================================
        echo AVISO: INCOMPATIBILIDADE DETECTADA!
        echo ================================================
        echo.
        echo Build compilado para: %BUILD_CHIP%
        echo Chip conectado:       %CONNECTED_CHIP%
        echo.
        echo O firmware foi compilado para um chip diferente
        echo do que está conectado. Isso causará erro ao flashear.
        echo.
        echo Recomendação: Recompile com a configuração correta.
        echo.
        choice /C RC /M "Deseja [R]ecompilar agora ou [C]ancelar"
        if errorlevel 2 (
            echo Operação cancelada.
            pause
            goto MENU
        )
        REM Voltar para trocar configuração
        goto CHANGE_CONFIG_FOR_INSTALL
    )
)

echo Chips compatíveis. Prosseguindo com instalação...
REM ============================================================

REM Flashar o dispositivo
echo Instalando o software no dispositivo...
if "%SELECTED_PORT%"=="" (
    idf.py flash
) else (
    idf.py -p %SELECTED_PORT% flash
)

REM Após a conclusão, retornar ao menu
pause
goto MENU

:EXIT_SCRIPT
echo Saindo...
endlocal
exit /b 0