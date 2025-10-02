# Criando Atualizador Web para Jade DIY com Secure Boot

Este tutorial resume o processo completo para compilar uma **atualização** de firmware para a Jade DIY com **Secure Boot V1** já ativo, criar um atualizador web com `esp-web-tools` e automatizar a atualização de badges no GitHub.

## Parte 1: Fundamentos da Atualização com Secure Boot

O objetivo é criar um pacote de firmware que será aceito por uma placa que já está travada com a sua chave de segurança.

### 🔑 A Chave Mestra Original (`.pem`)

-   **REGRA DE OURO:** Para assinar uma nova atualização, você **DEVE** usar a mesma chave `secure_boot_signing_key.pem` que foi usada para travar a placa pela primeira vez.
    
-   Essa chave é gerada uma única vez. Guarde-a como se fosse a seed da sua carteira. Se você perdê-la, as placas travadas com ela nunca mais poderão ser atualizadas.
    

## Parte 2: Compilando e Assinando o Firmware de Atualização

O processo de compilação é padrão, mas a assinatura é um passo manual crucial.

### ⚙️ Configuração Essencial (`idf.py menuconfig`)

Antes de compilar, confirme estas configurações no seu projeto:

1.  **Secure Boot Ativo:**
    
    -   Vá em `Security features` --->
    -   Garanta que a opção `[x] Enable hardware Secure Boot in bootloader` esteja **MARCADA**.
        
2.  **Compatibilidade de Hardware:**
    
    -   Vá em `Serial Flasher Config` --->
    -   `Flash SPI mode`: Mude para **`DIO`**.
    -   `Flash SPI speed`: Mude para **`40MHz`**.
    -   _Essa combinação (`DIO` + `40MHz`) é a mais compatível e evita a maioria dos erros de `flash read err`._
        

### 📦 Compilando e Assinando Manualmente

1.  **Limpe builds antigos (Opcional, mas recomendado):**
    
    ```bash
    idf.py fullclean
    ```

2.  **Compile o projeto:**

    ```bash
    idf.py build
    ```

    Isso vai gerar um arquivo **não assinado** em `build/jade.bin`.

3.  **Assine o Firmware Manualmente:** Agora, use o `espsecure.py` para assinar o arquivo gerado com sua chave mestra.

    ```bash
    espsecure.py sign_data --version 1 --keyfile secure_boot_signing_key.pem -o build/jade-signed.bin build/jade.bin
    ```

    -   **Importante:** O arquivo que você vai usar é o `build/jade-signed.bin`. Coloque na sua pasta de firmware para manter a consistência.

## Parte 3: Criando o Atualizador Web

A ideia é ter uma página que permita ao usuário escolher a placa e a versão do firmware para atualizar.

### 📁 Estrutura de Arquivos para Atualização

A organização para um **update** é mais simples. Note a ausência do `bootloader.bin`!

```
📂 assets/
	📂 update
	🖼️ logos.png
📂 firmware/
	📂 [nome_da_placa]/
		📂 [versao_do_firmware]/
			🔐 jade-signed.bin
			📦 ota_data_initial.bin
			📦 partition-table.bin
			📄 manifest.json
📄 LICENSE
📄 README.md
📄 assinar_secure_boot.md
📄 atualizar_jade_wallet.md
⚙️ deploy_firmware.ps1
```

### `manifest.json` (O Mapa da Instalação)

Este arquivo é o coração do atualizador. Ele **NÃO DEVE** incluir o bootloader. Ele lista apenas os 3 arquivos necessários para a atualização.

```json
{
  "name": "Jade DIY 1.0.36-87-wbatt for T-Display",
  "builds": [
    {
      "chipFamily": "ESP32",
      "parts": [
        { "path": "jade.bin", "offset": 65536 },
        { "path": "ota_data_initial.bin", "offset": 57344 },
        { "path": "partition-table.bin", "offset": 36864 }
      ]
    }
  ]
}
```

### `index.html` (A Interface)

O `index.html` contém o HTML, CSS e JavaScript que cria os menus dinâmicos. A parte mais importante é o objeto `firmwares` no script, onde você cadastra as novas versões.

```js
// ... dentro da tag <script> do index.html
const firmwares = {
    tdisplay: [
        { version: '1.0.36-87-wbatt', path: 'firmware/tdisplay/1.0.36-87-wbatt/manifest.json' },
        // Adicione novas versões aqui
    ],
};
// ...
```

Não se esqueça do atributo `no-erase` no botão. Ele ajuda a prevenir que a ferramenta apague acidentalmente o setor do bootloader.

```html
<esp-web-install-button id="installButton" no-erase></esp-web-install-button>
```

## Parte 4: Automação do Badge no README

Para que o badge de firmware no `README.md` se atualize sozinho, usamos uma GitHub Action. (Esta parte permanece inalterada, pois já está correta).

### 🤖 O Workflow (`.github/workflows/update-readme-badge.yml`)

Este script roda a cada `push`, lê a última versão adicionada no `index.html` e atualiza o `README.md`.

```yml
# Nome da nossa automação
name: Update Firmware Version Badge

on:
  push:
    branches:
      - main

permissions:
  contents: write

jobs:
  update-badge:
    if: "${{ !contains(github.event.head_commit.message, 'Bot:') }}"
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Get latest firmware version
        id: get_version
        run: |
          LATEST_VERSION=$(grep -v "^ *//" index.html | grep -o "version: *'[^']*'" | tail -n 1 | sed "s/version: *'//;s/'$//")
          if [ -z "$LATEST_VERSION" ]; then
            LATEST_VERSION="not-found"
          fi
          echo "version=$LATEST_VERSION" >> $GITHUB_OUTPUT
          BADGE_VERSION=$(echo $LATEST_VERSION | sed 's/-/--/g')
          echo "badge_version=$BADGE_VERSION" >> $GITHUB_OUTPUT

      - name: Update README.md
        run: |
          sed -i "s|img.shields.io/badge/Firmware-.*-blue|img.shields.io/badge/Firmware-${{ steps.get_version.outputs.badge_version }}-blue|g" README.md

      - name: Commit and push if changed
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: "Bot: Auto-update firmware badge to v${{ steps.get_version.outputs.version }}"
          branch: main
          file_pattern: README.md
```