# 🔱 Atualizador Jade DIY com Secure Boot

![Firmware](https://img.shields.io/badge/Firmware-1.0.35--v1--sb-blue) ![Secure Boot](https://img.shields.io/badge/Secure%20Boot-V2%20Ready-green) ![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

<p align="center">
  <a href="" target="_blank" rel="noopener noreferrer">
    <img src="https://raw.githubusercontent.com/cateim/jade-diy/main/assets/jade_logo_white_on_transparent_rgb.svg" alt="Logo da Jade" width="250"/>
  </a>
</p>

Uma ferramenta web simples e oficial para atualizar o firmware da sua **Jade DIY montada por nós**, focada em dispositivos que já possuem **Secure Boot ativado**. Chega de linha de comando, chega de complicação. Tudo direto do seu navegador.


## ⚠️ Para Quem é Esta Ferramenta?

Esta ferramenta foi feita para um propósito **muito específico**. Leia com atenção para saber se ela é para você:

* ✅ **Você comprou uma Jade DIY conosco** que já veio com **Secure Boot V2 ativado**.
* ✅ Você quer **ATUALIZAR** o firmware para uma nova versão oficial que estamos disponibilizando.
* ✅ Você está ciente de que o dispositivo foi selado com uma chave de segurança única.

Esta ferramenta **NÃO SERVE** para:

* ❌ Ativar o Secure Boot pela primeira vez.
* ❌ "Destravar" uma placa caso algo dê errado (a chave de segurança é permanente).
* ❌ Instalar um firmware que não seja o oficial fornecido por nós.

## ✨ Como Usar

Atualizar sua Jade nunca foi tão fácil. Sério.

1.  **Acesse o Site:** [**Clique aqui para abrir o atualizador**](https://cateim.github.io/jade-diy/)
2.  **Selecione seu Hardware:** Nos menus, escolha o modelo da sua placa (`LILYGO TTGO T-Display`) e a versão do firmware que você quer instalar.
    ![GIF mostrando a seleção de dispositivo e firmware](https://i.imgur.com/your-gif-here.gif) <!-- Troque pelo link de um GIF ou imagem da sua interface -->
3.  **Conecte a Placa 🔌:** Use um **cabo USB de DADOS** (não um cabo só de carregar) para conectar sua Jade ao computador.
4.  **Clique em INSTALAR:** O botão azul vai aparecer. Clique nele.
5.  **Escolha a Porta Serial:** Uma janela pop-up do navegador vai surgir. Selecione a porta correspondente à sua Jade (geralmente tem "USB Serial" ou "COM" no nome) e clique em "Conectar".
6.  **Pronto!** 🍻 Pegue um café. A ferramenta vai fazer o flash automaticamente. Quando terminar, sua Jade vai reiniciar com o novo firmware.

## 🔐 A Regra de Ouro do Secure Boot

Pensa assim: quando ativamos o Secure Boot na sua Jade, a placa e a nossa chave privada (`.pem`) se "casaram" para sempre. 💍
O chip guarda uma "impressão digital" da nossa chave e nunca mais aceitará um firmware que não tenha a assinatura **exata** dela.

* **Tentou usar um firmware de outra pessoa?** A placa vai rejeitar com o erro `secure boot check fail`.
* **Aconteceu um problema grave e a placa travou?** Infelizmente, ela virou um peso de papel. O Secure Boot é uma via de mão única e não permite recuperação.

**Nós garantimos que o firmware fornecido aqui é seguro e assinado com a chave correta para o seu dispositivo.**

## 🛠️ Para Usuários Avançados (Desenvolvedores e Montadores)

Quer customizar ou adicionar seus próprios firmwares? Moleza.

1.  **Estrutura de Pastas:** O projeto espera a seguinte organização:

    ```
    firmware/
    └── [nome_da_placa]/
        └── [versao_do_firmware]/
            ├── bootloader.bin
            ├── jade.bin (JÁ ASSINADO!)
            ├── ota_data_initial.bin
            ├── partition-table.bin
            └── manifest.json
    ```

2.  **Adicionar uma Nova Versão:**
    * Crie a estrutura de pastas acima.
    * Gere os 4 arquivos `.bin` usando o ESP-IDF v5.4, com as configurações corretas e assinado com sua chave V2.
    * Crie um `manifest.json` dentro da pasta com os caminhos relativos.
    * Abra o `index.html` e adicione a nova versão no objeto `firmwares` dentro da tag `<script>`.

---

### Créditos

* A **Blockstream**, por criar e manter o projeto incrível que é a Jade.
* A galera do **ESPHome** e **`esp-web-tools`**, que criaram a magia de flashear direto do navegador que usamos aqui.
