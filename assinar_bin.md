# Assinar _.bin_ com Secure Boot ativo

Este tutorial resume o processo completo para compilar uma **atualização** de firmware para a Jade DIY com **Secure Boot V1 ou V2** já ativo e automatizar a atualização de badges no GitHub.

## Parte 1: Fundamentos da Atualização com Secure Boot

O objetivo é criar um pacote de firmware que será aceito por uma placa que já está travada com a sua chave de segurança.

### 🔑 A Chave Mestra Original (`.pem`)

-   **REGRA DE OURO:** Para assinar uma nova atualização, você **DEVE** usar a mesma chave **`secure_boot_signing_key_v1.pem`** ou **`secure_boot_signing_key_v2.pem`** que foi usada para travar a placa pela primeira vez.
    
-   Essa chave é gerada uma única vez. Guarde-a como se fosse a seed da sua carteira. Se você perdê-la, as placas travadas com ela nunca mais poderão ser atualizadas.
    

## Parte 2: Compilando e Assinando o Firmware de Atualização

O processo de compilação é padrão e o `idf.py` é inteligente o suficiente para assinar de forma automática antes de fazer o flash, mas a assinatura do arquivo que vamos disponibilizar é um passo manual crucial.

### ⚙️ Configuração Essencial (`idf.py menuconfig`)

Antes de compilar, confirme estas configurações no seu projeto:

1.  **Secure Boot Ativo**
	1.1. _**T-Display:**_
	- Vá em `Security features` --->
    - Marque a opção `[*] Enable hardware Secure Boot in bootloader`.
    - Mude para **`Reflashable`** em `Secure bootloader mode (Reflashable)`.
    - Verifique a chave utilizada **`secure_boot_signing_key_v1.pem`**

	1.2. _**T-Display S3**_
	- Vá em `Security features` --->
    - Marque a opção `[*] Enable hardware Secure Boot in bootloader`.
    - Verifique a chave utilizada **`secure_boot_signing_key_v2.pem`**
    - Marque a opção `[*] Flash bootloader along with other artifacts when using the default flash command`.

2.  **Compatibilidade de Hardware:**
    2.1. _**T-Display:**_
    -   Vá em `Serial Flasher Config` --->
    -   `Flash SPI mode`: Mude para **`DIO`**.
    -   `Flash SPI speed`: Mude para **`40MHz`**.
    -   _Essa combinação (`DIO` + `40MHz`) é a mais compatível e evita a maioria dos erros de `flash read err`._

    2.2. _**T-Display S3:**_
    -   Vá em `Serial Flasher Config` --->
    -   `Flash SPI mode`: Mude para **`DIO`**.
    -   `Flash SPI speed`: Mude para **`80MHz`**.

### 📦 Compilando e Assinando Manualmente

1.  **Limpe builds antigos (Opcional, mas recomendado):**
    
    ```py
    idf.py fullclean
    ```

2.  **Compile o projeto:**

    ```py
    idf.py build
    ```

    Isso vai gerar um arquivo **não assinado** em `build/jade.bin`.

	### ⚠️ Atenção: Importante!!!

	Redobre a atenção ao assinar o arquivo **`jade.bin`**. 
	**A *T-Display* aceita Secure Boot V1 e a *T-Display S3* o Secure Boot V2**.

3.  **Assine o Firmware Manualmente:** Agora, use o `espsecure.py` para assinar o arquivo gerado com sua chave mestra.

    ```py
    # T-Display com Secure Boot V1 
    espsecure.py sign_data --version 1 --keyfile secure_boot_signing_key_v1.pem -o build/jade-signed.bin build/jade.bin

    # T-Display S3 com Secure Boot V2 
    espsecure.py sign_data --version 2 --keyfile secure_boot_signing_key_v2.pem -o build/jade-signed.bin build/jade.bin
    ```

    -   **Importante:** O arquivo que você vai usar é o `build/jade-signed.bin`. Coloque na sua pasta de firmware para manter a consistência.

4. **Verificando o Secure Boot (Opcional)**: Se você ativou o Secure Boot, é uma boa ideia verificar se o processo funcionou e se a sua placa está realmente segura.

	4.1.  **Execute o comando de resumo do eFuse** (substitua `COM5` pela sua porta):

    ```py
    espefuse.py -p COM5 summary
    ```

	4.2.  **Analise a Saída:** Procure por estas duas linhas na seção `Security fuses`:

    ```c
    ABS_DONE_0 (BLOCK0)      Secure boot V1 is enabled for bootloader image   = True R/W (0b1)
    ...
    BLOCK2 (BLOCK2)          Security boot key
      = ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? -/-
    ```

    * `ABS_DONE_0 = True`: Confirma que o "interruptor" do Secure Boot foi ligado.
    * `BLOCK2 = ?? ... -/-`: Confirma que a sua chave está gravada e protegida contra leitura e escrita.

Se a sua saída for igual a essa, o Secure Boot está ativo e funcionando. ✅

## Parte 3: Automação do Badge no README

Para que o badge de firmware no `README.md` se atualize sozinho, usamos uma GitHub Action. (Esta parte permanece inalterada, pois já está correta).

### 🤖 O Workflow (`.github/workflows/update-badge.yml`)

Este script roda a cada `push`, lê a última versão adicionada na pasta contendo o `firmware` e atualiza o `atualizar_jade_*.md`.

```yml
# Nome da nossa automação
name: Update All Firmware Badges

on:
  # Aciona a automação em qualquer push para a branch 'main'
  push:
    branches:
      - main

# Adiciona a permissão de escrita para o bot poder fazer o commit
permissions:
  contents: write

jobs:
  update-badge:
    # Não roda o job se o último commit foi feito pelo bot, para evitar loops infinitos
    if: "${{ !contains(github.event.head_commit.message, 'Bot:') }}"

    runs-on: ubuntu-latest

    # A MATRIZ: O cérebro da operação.
    # Define as configurações para cada placa que queremos atualizar.
    strategy:
      matrix:
        device:
          # Configuração para a primeira placa
          - name: tdisplay
            file: atualizar_jade_tdisplay.md
          # Configuração para a segunda placa
          - name: tdisplays3
            file: atualizar_jade_tdisplays3.md

    steps:
      # 1. Baixa o código do seu repositório
      - name: Checkout code
        uses: actions/checkout@v4

      # 2. A NOVA LÓGICA: Acha a última versão olhando as pastas
      - name: Get latest firmware version for ${{ matrix.device.name }}
        id: get_version
        run: |
          # Procura na pasta específica da placa, ordena por versão e pega a última
          DEVICE_PATH="firmware/${{ matrix.device.name }}"
          if [ -d "$DEVICE_PATH" ]; then
            LATEST_VERSION=$(ls -v "$DEVICE_PATH" | tail -n 1)
          else
            LATEST_VERSION=""
          fi

          if [ -z "$LATEST_VERSION" ]; then
            LATEST_VERSION="not-found"
          fi
          
          echo "Found version for ${{ matrix.device.name }}: $LATEST_VERSION"
          # Prepara a versão para o formato do badge (shields.io usa '--' para '-')
          BADGE_VERSION=$(echo $LATEST_VERSION | sed 's/-/--/g')
          
          # Salva as variáveis para os próximos passos
          echo "version=$LATEST_VERSION" >> $GITHUB_OUTPUT
          echo "badge_version=$BADGE_VERSION" >> $GITHUB_OUTPUT

      # 3. Atualiza o arquivo .md específico da placa
      - name: Update ${{ matrix.device.file }}
        run: |
          # Usa o 'sed' para encontrar a linha do badge e substituir a versão no arquivo correto
          sed -i "s|img.shields.io/badge/Firmware-.*-blue|img.shields.io/badge/Firmware-${{ steps.get_version.outputs.badge_version }}-blue|g" ${{ matrix.device.file }}

      # 4. Faz o commit e push das mudanças (se houver alguma)
      - name: Commit and push if changed
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          # Mensagem de commit dinâmica, informando qual placa foi atualizada
          commit_message: "Bot: Auto-update badge for ${{ matrix.device.name }} to v${{ steps.get_version.outputs.version }}"
          branch: main
          # O padrão de arquivo a ser verificado para commit também é dinâmico
          file_pattern: ${{ matrix.device.file }}
```
