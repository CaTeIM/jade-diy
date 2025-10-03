# Script para automatizar a cópia dos arquivos de firmware da Jade Wallet
#
# COMO USAR:
# 1. Compile e assine seu firmware normalmente (gerando o 'jade-signed.bin').
# 1.1 Secure Boot V1 --> espsecure.py sign_data --version 1 --keyfile secure_boot_signing_key.pem -o build/jade-signed.bin build/jade.bin
# 1.2 Secure Boot V2 --> espsecure.py sign_data --version 2 --keyfile secure_boot_signing_key_v2.pem -o build/jade-signed.bin build/jade.bin
# 2. Abra um terminal PowerShell, navegue até a pasta do projeto e execute: .\deploy_firmware.ps1
#

# --- CONFIGURAÇÕES ---
# Altere estes caminhos para corresponderem ao seu ambiente
$buildDir = "D:\GitHub\Jade"
$githubDir = "D:\CaTeIM\Google Drive\GitHub\jade-diy"

# --- INÍCIO DO SCRIPT ---

# Limpa a tela para uma melhor visualização
Clear-Host

Write-Host "--- Script de Deploy para Firmware Jade DIY ---" -ForegroundColor Cyan

# 1. Pergunta ao usuário as informações necessárias
$placa = Read-Host -Prompt "Qual o nome da placa? (ex: tdisplay ou tdisplays3)"
if ([string]::IsNullOrWhiteSpace($placa)) {
    Write-Host "Nome da placa não pode ser vazio. Abortando." -ForegroundColor Red
    Read-Host "Pressione Enter para sair..."
    exit
}

$versao = Read-Host -Prompt "Qual a versão do novo firmware? (ex: 1.0.xx-yy-wbatt)"
if ([string]::IsNullOrWhiteSpace($versao)) {
    Write-Host "Versão não pode ser vazia. Abortando." -ForegroundColor Red
    Read-Host "Pressione Enter para sair..."
    exit
}

Write-Host "`nConfigurando para Placa: '$placa' | Versão: '$versao'" -ForegroundColor Green

# 2. Define os caminhos de origem e destino
$destinoDir = Join-Path -Path $githubDir -ChildPath "firmware\$placa\$versao"
$fonteBuildDir = Join-Path -Path $buildDir -ChildPath "build"

# 3. Cria a pasta de destino se ela não existir
if (-not (Test-Path $destinoDir)) {
    Write-Host "Criando diretório de destino: $destinoDir"
    New-Item -Path $destinoDir -ItemType Directory | Out-Null
} else {
    Write-Host "Diretório de destino já existe. Os arquivos serão sobrescritos." -ForegroundColor Yellow
}

# 4. Lista de arquivos para copiar e seus nomes de destino
$arquivosParaCopiar = @{
    (Join-Path $fonteBuildDir 'jade-signed.bin')                     = "jade-signed.bin";
    (Join-Path $fonteBuildDir 'ota_data_initial.bin')                = "ota_data_initial.bin";
    (Join-Path $fonteBuildDir 'partition_table\partition-table.bin') = "partition-table.bin";
}

# 5. Copia os arquivos
Write-Host "`nIniciando cópia dos arquivos .bin..."
foreach ($fonte in $arquivosParaCopiar.Keys) {
    $destinoArquivo = Join-Path -Path $destinoDir -ChildPath $arquivosParaCopiar[$fonte]
    
    if (Test-Path $fonte) {
        Copy-Item -Path $fonte -Destination $destinoArquivo -Force
        Write-Host "  [OK] Copiado '$($arquivosParaCopiar[$fonte])'" -ForegroundColor Green
    } else {
        Write-Host "  [ERRO] Arquivo de origem não encontrado: $fonte" -ForegroundColor Red
    }
}

# --- FIM DO SCRIPT ---
Write-Host "`n--- Processo Concluído! ---" -ForegroundColor Cyan
Write-Host "Verifique a pasta '$destinoDir' para confirmar os arquivos."

# Pausa o script e aguarda o usuário pressionar Enter
Write-Host "`n"
Read-Host "Pressione Enter para fechar o terminal..."