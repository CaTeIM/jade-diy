# 🔱 Atualizador Jade Wallet com Secure Boot

![Firmware](https://img.shields.io/badge/Firmware-1.0.36--v1--sb-blue) ![Secure Boot](https://img.shields.io/badge/Secure%20Boot-V1-green) ![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

<p align="center">
  <a href="" target="_blank" rel="noopener noreferrer">
    <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/jade_logo_white_on_transparent_rgb.svg" alt="Logo da Jade" width="250"/>
  </a>
</p>

Uma ferramenta web simples e oficial para atualizar o firmware da sua **Jade Wallet montada por nós**, focada em dispositivos que já possuem **Secure Boot ativado**. Chega de linha de comando, chega de complicação. Tudo direto do seu navegador.

## ⚠️ Para Quem é Esta Ferramenta?

Esta ferramenta foi feita para um propósito **muito específico**. Leia com atenção para saber se ela é para você:

* ✅ **Você comprou uma Jade Wallet conosco** que já veio com **Secure Boot ativado**.
* ✅ Você quer **ATUALIZAR** o firmware para uma nova versão oficial que estamos disponibilizando.
* ✅ Você está ciente de que o dispositivo foi selado com uma chave de segurança única.

Esta ferramenta **NÃO SERVE** para:

* ❌ Ativar o Secure Boot pela primeira vez.
* ❌ "Destravar" uma placa caso algo dê errado (a chave de segurança é permanente).
* ❌ Instalar um firmware que não seja o oficial fornecido por nós.

## ✨ Como Usar

Atualizar sua Jade Wallet nunca foi tão fácil. Sério.

## 🔁 Atualizar Jade Wallet

Guia direto para atualizar o firmware da sua Jade DIY. Tenha os **3 arquivos `.bin`** prontos e um cabo USB. ⚠️ Leia atentamente antes de começar.

## ⚠️ Atenção: Importante!!!

Este firmware da Jade Wallet está configurado com **Secure Boot ativo**.  
👉 Isso significa que **somente este firmware pode ser usado** para atualizar sua carteira.  
⚠️ **Se tentar instalar qualquer outro firmware diferente, a Jade pode travar de forma irreversível, resultando em perda total da wallet.**  

Mantenha este firmware como a única opção de atualização para evitar problemas graves. ❌💀

## ✅ Checklist antes de começar
- Cabo USB funcionando (não só carregamento). 🔌  
- Os **3 arquivos `.bin`** baixados (veja link abaixo). ⬇️  
- PC com navegador compatível (Chrome/Edge recomendados). 🖥️

**Baixe os arquivos**:  
[**Firmware Jade Wallet**](https://github.com/CaTeIM/jade-diy/tree/main/firmware)

## 1️⃣ Conectar ao ESP TOOL (Web)
1. Abra o site: https://espressif.github.io/esptool-js  
2. Conecte sua ESP32 ao PC via USB. 🔌  
3. Em **`Baudrate`** selecione **`115200`** e clique **`Connect`**.

<p align="center">
  <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/update/step_1.webp" alt="Connect no ESP Tool — passo 1" />
</p>

## 2️⃣ Selecionar porta / parear
Quando clicar **`Connect`**, escolha a porta/dispositivo que apareceu e confirme **Conectar**. 🔗

<p align="center">
  <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/update/step_2.webp" alt="Selecionar dispositivo/porta" />
</p>

**Se não aparecer porta:**  
- Troque o cabo USB.  
- Tente outra porta USB.  
- Se a placa tiver, segure o botão `BOOT` enquanto conecta (dependendo da placa). 🔧

## 3️⃣ Confirmação de conexão
Tela preta mostrará logs e vai aparecer **`Connected to device`** no topo quando OK. 🟢

<p align="center">
  <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/update/step_3.webp" alt="Connected to device" />
</p>

## 4️⃣ Adicionar os 3 arquivos
O site abre com 1 slot só. Clique **`Add File`** até ter **3 vagas**.

<p align="center">
  <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/update/step_4.webp" alt="Adicionar 4 arquivos" />
</p>

## 5️⃣ Carregar arquivos e definir Flash Address
Coloque cada arquivo na ordem abaixo (use **`Escolher arquivo`**):

📁 **Arquivos (ordem):**
```py
jade-signed.bin
ota_data_initial.bin
partition-table.bin
```

⚙️ **Flash Addresses (defina exatamente):**

| Flash Address | File                     |
| :------------ | :----------------------- |
| ~~`0x1000`~~      | ~~`bootloader.bin`~~         |
| `0x10000`     | `jade-signed.bin`               |
| `0xE000`      | `ota_data_initial.bin`   |
| `0x9000`      | `partition-table.bin`    |

<p align="center">
  <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/update/step_5.webp" alt="Definir flash addresses" />
</p>

## 6️⃣ Programar (gravar)
Clique **`Program`** para iniciar a gravação. ▶️

**IMPORTANTE:** **NÃO** desconecte o cabo nem desligue o computador enquanto o processo estiver em andamento. ⚠️  
Desconectar pode danificar a placa e torná-la inutilizável. ❌

<p align="center">
  <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/update/step_6.webp" alt="Clique Program para iniciar" />
</p>

## 7️⃣ Finalização
Acompanhe o log na tela. Quando aparecer **"Leaving…"** o dispositivo reinicia sozinho. Se não reiniciar, pressione o botão de reset na placa. 🔁

Ao reiniciar corretamente, o seu dispositivo estará com a Jade instalada. 💎

<p align="center">
  <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/update/step_7.webp" alt="Processo concluído" />
</p>

## 🔧 Problemas comuns (rápido)
- **Não conecta:** troque o cabo, tente outra porta, veja drivers no PC.  
- **Program travou:** cancele, reconecte e tente novamente.  
- **Não inicia depois:** pressione `RESET`/botão lateral.  

## 🔐 A Regra de Ouro do Secure Boot

Pensa assim: quando ativamos o Secure Boot na sua Jade, a placa e a nossa chave privada (`.pem`) se "casaram" para sempre. 💍
O chip guarda uma "impressão digital" da nossa chave e nunca mais aceitará um firmware que não tenha a assinatura **exata** dela.

* **Tentou usar um firmware de outra pessoa?** A placa vai rejeitar com o erro `secure boot check fail`.
* **Aconteceu um problema grave e a placa travou?** Infelizmente, ela virou um peso de papel. O Secure Boot é uma via de mão única e não permite recuperação.

**Nós garantimos que o firmware fornecido aqui é seguro e assinado com a chave correta para o seu dispositivo.**

## 🛠️ Para Usuários Avançados (Desenvolvedores e Montadores)

Quer customizar ou adicionar seus próprios firmwares?

1.  **Estrutura de Pastas:** O projeto espera a seguinte organização:

    ```
	📂 firmware/
		📂 [nome_da_placa]/
			📂 [versao_do_firmware]/
				🔐 jade-signed.bin
				📦 ota_data_initial.bin
				📦 partition-table.bin
				📄 manifest.json
    ```

## 📌 Créditos

* A **Blockstream**, por criar e manter o projeto incrível que é a Jade.
* A galera do **ESPHome** e **`esp-web-tools`**, que criaram a magia de flashear direto do navegador que usamos aqui.
* Ao DIG P2P pois esse guia foi inspirado nesse arquivo: [Instalação e manuseio Passo-a-passo Jade DIY](https://medium.com/@digp2p/instala%C3%A7%C3%A3o-e-manuseio-passo-a-passo-jade-diy-b20220df5970)
