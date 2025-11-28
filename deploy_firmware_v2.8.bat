@echo off

chcp 65001 > NUL
setlocal enabledelayedexpansion

:: Elevar privilégios automaticamente
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Elevando privilégios para administrador...
    powershell -Command "Start-Process -FilePath '%COMSPEC%' -ArgumentList '/c %~f0' -Verb runAs"
    exit /b
)

@echo off
REM Script para automatizar a cópia dos arquivos de firmware da Jade Wallet
REM
REM COMO USAR:
REM 1. Compile e assine seu firmware normalmente
REM 2. Execute o arquivo deploy_firmware.bat diretamente (duplo clique ou via cmd)
REM

REM --- CONFIGURAÇÕES ---
REM Altere estes caminhos para corresponderem ao seu ambiente
set "buildDirtdisplay=D:\GitHub\tdisplay\Jade"
set "buildDirtdisplays3=D:\GitHub\tdisplays3\Jade"
set "buildDirwaveshares3=D:\GitHub\waveshares3\Jade"
set "githubDir=D:\CaTeIM\Google Drive\GitHub\jade-diy"

REM --- INÍCIO DO SCRIPT ---
cls

:INICIO
REM Limpa variáveis para evitar cache
set "placa="
set "versao="
set "confirmar="
set "buildDir="
set "placaNome="
set "placaExibicao="
set "sobrescrever="

echo.
echo --- Script de Deploy para Firmware Jade DIY ---
echo.

:SELECAO_PLACA
echo Selecione uma opção de placa:
echo.
echo [1] T-Display
echo [2] T-Display S3
echo [3] Waveshare S3
echo.
echo [0] Sair
echo.

REM 1. Pergunta ao usuário qual placa
set "placa="
set /p placa="Digite o número e pressione Enter: "

if "%placa%"=="0" (
    echo.
    echo Saindo do script. Nenhuma ação será realizada.
    pause
    exit /b
)

if "%placa%"=="" (
    echo.
    echo [ERRO] Você precisa selecionar uma opção válida!
    echo.
    timeout /t 2 >nul
    cls
    goto INICIO
)

REM 2. Define o diretório de build e nome da placa baseado na seleção
if "%placa%"=="1" (
    set "buildDir=%buildDirtdisplay%"
    set "placaNome=tdisplay"
    set "placaExibicao=T-Display"
)
if "%placa%"=="2" (
    set "buildDir=%buildDirtdisplays3%"
    set "placaNome=tdisplays3"
    set "placaExibicao=T-Display S3"
)
if "%placa%"=="3" (
    set "buildDir=%buildDirwaveshares3%"
    set "placaNome=waveshares3"
    set "placaExibicao=Waveshare S3"
)

if not defined buildDir (
    echo.
    echo [ERRO] Opção inválida. Escolha apenas 1, 2 ou 3.
    echo.
    timeout /t 2 >nul
    cls
    goto INICIO
)

REM 3. Confirma a seleção da placa
echo.
echo ========================================
echo Placa selecionada: %placaExibicao%
echo ========================================
echo.
set "confirmar="
set /p confirmar="Deseja prosseguir com esta placa? (S=Sim / N=Voltar): "

if "%confirmar%"=="" (
    echo [ERRO] Você precisa digitar S ou N!
    timeout /t 2 >nul
    cls
    goto INICIO
)

if /i "%confirmar%"=="N" (
    cls
    goto INICIO
)

if /i not "%confirmar%"=="S" (
    echo [ERRO] Opção inválida. Digite apenas S ou N.
    timeout /t 2 >nul
    cls
    goto INICIO
)

:PERGUNTA_VERSAO
REM 4. Pergunta a versão do firmware
echo.
set "versao="
set /p versao="Digite a versão do novo firmware (ex: 1.0.xx-yy-nolog): "

if "%versao%"=="" (
    echo.
    echo [ERRO] A versão não pode ser vazia! Digite um nome válido.
    echo.
    timeout /t 2 >nul
    goto PERGUNTA_VERSAO
)

REM 5. Define os caminhos de origem e destino
set "destinoDir=%githubDir%\firmware\%placaNome%\%versao%"
set "fonteBuildDir=%buildDir%\build"

REM 6. VERIFICAÇÃO PRÉVIA: Valida se todos os arquivos de origem existem
echo.
echo Verificando arquivos de origem...
echo.

set "arquivosOk=1"

if not exist "%fonteBuildDir%\bootloader\bootloader.bin" (
    echo   [ERRO] Arquivo não encontrado: bootloader.bin
    set "arquivosOk=0"
)

if not exist "%fonteBuildDir%\jade.bin" (
    echo   [ERRO] Arquivo não encontrado: jade.bin
    set "arquivosOk=0"
)

if not exist "%fonteBuildDir%\ota_data_initial.bin" (
    echo   [ERRO] Arquivo não encontrado: ota_data_initial.bin
    set "arquivosOk=0"
)

if not exist "%fonteBuildDir%\partition_table\partition-table.bin" (
    echo   [ERRO] Arquivo não encontrado: partition-table.bin
    set "arquivosOk=0"
)

if "%arquivosOk%"=="0" (
    echo.
    echo ========================================
    echo [ERRO CRÍTICO] Arquivos faltando!
    echo ========================================
    echo.
    echo Um ou mais arquivos de build não foram encontrados.
    echo Certifique-se de compilar o firmware antes de executar o deploy.
    echo.
    echo Caminho de origem: %fonteBuildDir%
    echo.
    echo O que deseja fazer?
    echo [1] Tentar outra placa
    echo [0] Sair do script
    echo.
    
    set "escolhaErro="
    set /p escolhaErro="Digite sua escolha: "
    
    if "!escolhaErro!"=="1" (
        cls
        goto INICIO
    ) else (
        goto SAIR
    )
)

echo   [OK] Todos os arquivos foram encontrados!
echo.

REM 7. Verifica se o diretório já existe
if exist "%destinoDir%" (
    echo ========================================
    echo [AVISO] Diretório já existe!
    echo ========================================
    echo Caminho: %destinoDir%
    echo.
    echo O que deseja fazer?
    echo [1] Sobrescrever os arquivos existentes
    echo [2] Alterar o nome da versão
    echo.
    echo [0] Cancelar e voltar ao início
    echo.
    
    :ESCOLHA_SOBRESCREVER
    set "sobrescrever="
    set /p sobrescrever="Digite sua escolha: "
    
    if "!sobrescrever!"=="" (
        echo [ERRO] Você precisa escolher uma opção!
        echo.
        goto ESCOLHA_SOBRESCREVER
    )
    
    if "!sobrescrever!"=="2" (
        echo.
        echo Voltando para digitar novo nome...
        timeout /t 1 >nul
        goto PERGUNTA_VERSAO
    )
    
    if "!sobrescrever!"=="0" (
        cls
        goto INICIO
    )
    
    if "!sobrescrever!"=="1" (
        echo.
        echo [OK] Os arquivos serão sobrescritos.
        echo.
    ) else (
        echo [ERRO] Opção inválida! Escolha 1, 2 ou 0.
        echo.
        goto ESCOLHA_SOBRESCREVER
    )
)

REM 8. Mostra configuração final
echo.
echo ========================================
echo Configuração do Deploy:
echo   Placa: %placaExibicao%
echo   Versão: %versao%
echo   Destino: %destinoDir%
echo ========================================
echo.

REM 9. Cria a pasta de destino se ela não existir
if not exist "%destinoDir%" (
    echo Criando diretório de destino...
    mkdir "%destinoDir%"
    echo.
)

REM 10. Copia os arquivos
echo Iniciando cópia dos arquivos .bin...
echo.

copy /Y "%fonteBuildDir%\bootloader\bootloader.bin" "%destinoDir%\bootloader.bin" >nul
echo   [OK] Copiado 'bootloader.bin'

copy /Y "%fonteBuildDir%\jade.bin" "%destinoDir%\jade.bin" >nul
echo   [OK] Copiado 'jade.bin'

copy /Y "%fonteBuildDir%\ota_data_initial.bin" "%destinoDir%\ota_data_initial.bin" >nul
echo   [OK] Copiado 'ota_data_initial.bin'

copy /Y "%fonteBuildDir%\partition_table\partition-table.bin" "%destinoDir%\partition-table.bin" >nul
echo   [OK] Copiado 'partition-table.bin'

REM --- FIM DO SCRIPT ---
echo.
echo ========================================
echo Processo Concluído!
echo ========================================
echo Verifique a pasta:
echo %destinoDir%
echo.

set "continuar="
set /p continuar="Deseja fazer outro deploy? (S/N): "

if "%continuar%"=="" (
    echo Nenhuma opção selecionada. Encerrando...
    timeout /t 2 >nul
    goto SAIR
)

if /i "%continuar%"=="S" (
    cls
    goto INICIO
)
if /i "%continuar%"=="N" goto SAIR

echo Opção inválida. Encerrando...
timeout /t 2 >nul
goto SAIR

:SAIR
echo.
echo Encerrando o script. Até logo!
pause
exit /b