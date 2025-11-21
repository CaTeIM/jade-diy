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
powershell -Command "try { $content = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Blockstream/Jade/master/.github/workflows/github-actions-test.yml' -UseBasicParsing).Content; if($content -match 'esp_idf_version:\s*[''\""]?v?([0-9.]+)[''\""]?') { Write-Output $matches[1] } else { Write-Output '5.4' } } catch { Write-Output '5.4' }" > temp_version.txt 2>NUL
set /p DEFAULT_VERSION=<temp_version.txt
del temp_version.txt 2>NUL
if "%DEFAULT_VERSION%"=="" set "DEFAULT_VERSION=5.4"

echo.
echo Versão padrão do ESP-IDF: %DEFAULT_VERSION%
echo.
powershell -Command "$releases = (Invoke-WebRequest -Uri 'https://api.github.com/repos/espressif/idf-installer/releases' -UseBasicParsing | ConvertFrom-Json); $offline = $releases | Where-Object { $_.tag_name -like 'offline-*' } | Select-Object -First 5; $i=1; foreach($r in $offline) { $v = $r.tag_name -replace 'offline-',''; Write-Host \"  [$i] $v\"; $i++ }"
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

REM Definir variáveis do Python
set "PYTHON_INSTALLER=python-3.11.5-amd64.exe"
set "PYTHON_URL=https://www.python.org/ftp/python/3.11.5/%PYTHON_INSTALLER%"

python --version > NUL 2>&1

set "PYTHON_ALREADY_INSTALLED=NO"
set "INSTALL_PYTHON=YES"

if %ERRORLEVEL% equ 0 (
    set "PYTHON_ALREADY_INSTALLED=YES"
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%v"
)

if "%PYTHON_ALREADY_INSTALLED%"=="YES" (
    echo Python !PYTHON_VERSION! já está instalado.
    echo.
    choice /C SN /M "Deseja reinstalar o Python"
    if errorlevel 2 set "INSTALL_PYTHON=NO"
)

if "%INSTALL_PYTHON%"=="NO" (
    echo Pulando instalação do Python.
) else (
    if "%PYTHON_ALREADY_INSTALLED%"=="YES" (
        echo Prosseguindo com a reinstalação...
    ) else (
        echo Python não foi detectado. Procedendo com a instalação...
    )

    if exist "%PYTHON_INSTALLER%" (
        echo O instalador do Python já existe. Pulando download...
    ) else (
        echo Baixando o instalador do Python...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-BitsTransfer -Source '%PYTHON_URL%' -Destination '%PYTHON_INSTALLER%' -Description 'Python Installer' -DisplayName 'Baixando Python'"
        echo Download concluído.
    )
    
    echo Instalando o Python...
    "%PYTHON_INSTALLER%" /passive InstallAllUsers=1 PrependPath=1 Include_test=0
    if !ERRORLEVEL! neq 0 (
        echo Falha na instalação do Python.
        pause
        goto MENU
    )
    echo Python instalado com sucesso.
)

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
    echo [translate:Ambiente python ESP-IDF nao encontrado], executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo apos instalar Python.
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
) else (
    echo Clonando o repositório Jade...
    git clone --recursive %JADE_REPO_URL%
    if %ERRORLEVEL% neq 0 (
        echo Falha ao clonar o repositório Jade. Verifique sua conexão e tente novamente.
        pause
        goto MENU
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

set "SELECTED_CONFIG=!OPTION_%CHOICE%!"
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

echo O processo de configuração foi concluído.
pause
goto MENU

:INSTALL_SOFTWARE
REM -------------------------------------------------------------
REM Opção 3: Instalar o software Jade no seu dispositivo
REM -------------------------------------------------------------

REM Verificar se a pasta Jade existe
if not exist "%~dp0Jade" (
    echo A pasta Jade não foi encontrada. Certifique-se de que você executou as opções 2 e 3 primeiro.
    pause
    goto MENU
)

echo.
echo Por favor, selecione uma opção:
echo.
echo [1] Compilar e Instalar
echo [2] Instalar apenas (sem compilar)
echo [3] Retornar ao menu principal
echo.

set "INSTALL_OPTION="
set /p INSTALL_OPTION=Digite o número da sua escolha e pressione Enter: 

if "%INSTALL_OPTION%"=="" (
    echo Opção inválida. Retornando ao menu principal.
    pause
    goto MENU
)

if "%INSTALL_OPTION%"=="1" (
    goto COMPILE_AND_INSTALL
) else if "%INSTALL_OPTION%"=="2" (
    goto INSTALL_ONLY
) else if "%INSTALL_OPTION%"=="3" (
    goto MENU
) else (
    echo Opção inválida. Retornando ao menu principal.
    pause
    goto MENU
)

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
    echo [translate:Ambiente python ESP-IDF nao encontrado], executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo apos instalar Python.
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
    idf.py flash monitor
) else (
    idf.py -p %SELECTED_PORT% flash monitor
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

REM Inicializar o ambiente do ESP-IDF
echo Inicializando o ambiente do ESP-IDF na versão %SELECTED_IDF_VERSION%...

REM Definir arquivo temporário para captura da saída de export.bat
set "EXPORT_LOG=%TEMP%\esp_export_log.txt"
call "%IDF_PATH%\export.bat" > "%EXPORT_LOG%" 2>&1
set EXPORT_ERRORLEVEL=%ERRORLEVEL%

REM Verificar se ocorreu erro de ambiente python não encontrado
findstr /C:"ESP-IDF Python virtual environment not found" "%EXPORT_LOG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [translate:Ambiente python ESP-IDF nao encontrado], executando install.bat...
    call "%IDF_PATH%\install.bat"
    if ERRORLEVEL 1 (
        echo Falha ao instalar o ambiente Python.
        pause
        goto MENU
    )
    REM Tentar export.bat novamente após instalação
    call "%IDF_PATH%\export.bat"
    if ERRORLEVEL 1 (
        echo Falha ao inicializar o ambiente ESP-IDF mesmo apos instalar Python.
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

REM Navegar para a pasta Jade
cd /d "%cd%\Jade"

REM Verificar se os binários existem
if not exist "%cd%\bin_jade\bootloader.bin" (
    echo Os binários não foram encontrados. Certifique-se de que você compilou o projeto primeiro.
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

REM Flashar o dispositivo
echo Instalando o software no dispositivo...
if "%SELECTED_PORT%"=="" (
    idf.py flash monitor
) else (
    idf.py -p %SELECTED_PORT% flash monitor
)

REM Após a conclusão, retornar ao menu
pause
goto MENU

:EXIT_SCRIPT
echo Saindo...
endlocal
exit /b 0