# Script para automatizar a cópia dos arquivos de firmware da Jade DIY
#
# COMO USAR:
# 1. Compile e assine seu firmware normalmente (gerando o 'jade-signed.bin').
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
$placa = Read-Host -Prompt "Qual o nome da placa? (ex: tdisplay)"
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
    # MUDANÇA: Agora o destino também é 'jade-signed.bin'
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

# 6. Cria o arquivo manifest.json
Write-Host "`nGerando manifest.json..."
$manifestContent = [ordered]@{
    name = "Jade DIY $versao for $placa"
    builds = @(
        [ordered]@{
            chipFamily = "ESP32"
            parts = @(
                [ordered]@{ path = "jade-signed.bin"; offset = 65536 },
                [ordered]@{ path = "ota_data_initial.bin"; offset = 57344 },
                [ordered]@{ path = "partition-table.bin"; offset = 36864 }
            )
        }
    )
}

# Converte para JSON e salva no arquivo
$manifestJson = $manifestContent | ConvertTo-Json -Depth 5
$manifestPath = Join-Path -Path $destinoDir -ChildPath "manifest.json"
$manifestJson | Out-File -FilePath $manifestPath -Encoding utf8

Write-Host "  [OK] manifest.json criado com sucesso!" -ForegroundColor Green

# --- FIM DO SCRIPT ---
Write-Host "`n--- Processo Concluído! ---" -ForegroundColor Cyan
Write-Host "Verifique a pasta '$destinoDir' para confirmar os arquivos."
Write-Host "Próximo passo: Não se esqueça de atualizar o arquivo 'index.html' com a nova versão!" -ForegroundColor Yellow

# Pausa o script e aguarda o usuário pressionar Enter
Write-Host "`n"
Read-Host "Pressione Enter para fechar o terminal..."