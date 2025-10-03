# Guia de Uso: Jade Wallet

Parabéns por ter conquistado uma **Jade Wallet**! Você adquiriu uma hardware wallet e poderá gerar sua **cold wallet** em segurança. Agora, vamos aprender a usá-la nos diferentes sistemas, porque um projeto customizado tem suas peculiaridades.

## 🚀 Atualize sua Jade Wallet

Para garantir que sua carteira esteja sempre segura e funcional, mantenha o firmware atualizado.

👉 [Atualizar Jade T-Display](https://github.com/CaTeIM/jade-diy/blob/main/atualizar_jade_tdisplay.md)

👉 [Atualizar Jade T-Display S3](https://github.com/CaTeIM/jade-diy/blob/main/atualizar_jade_tdisplays3.md)

### ⚠️ ATENÇÃO: A Primeira Vez é com a Blockstream

Independente do sistema que você vai usar no dia a dia, a **primeira inicialização da carteira** (o processo de criar uma nova carteira ou restaurar um backup) **precisa ser feita pelo aplicativo oficial Blockstream**.

Isso garante que a "conversa" inicial entre o app e a Jade ocorra como esperado, evitando problemas de sincronização no futuro. Depois de criada, você pode usá-la onde quiser.

## <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/windows11/windows11-original.svg" width="20" height="20"/> Usando no Windows: Step-by-step

No Windows, a comunicação USB tem suas manhas por causa do famoso bug do DTR. Veja como domá-lo.

#### **Para usar com Blockstream:**

É obrigatório aplicar a **"Solução de Driver"** que documentamos no tutorial de instalação. Sem isso, a Jade não será reconhecida corretamente.

* **Lembrete Rápido:** Vá em `Gerenciador de Dispositivos` → `Portas (COM & LPT)` → `Propriedades da porta CH9102` → `Port Settings` → `Advanced...` e marque a opção **`Disable ModemHandShake`**.

[**Instalar**](https://blockstream.com/app/) Blockstream

#### **Para usar com SideSwap:**

O **SideSwap** pode não respeitar a configuração do driver e ainda ativar o DTR, travando um dos botões. Mas não se preocupe, nosso firmware foi preparado para isso!

Você vai operar a Jade no **"Modo de Um Botão"**:

* **Botão da Esquerda (`Prev` / `GPIO0`):** Ficará **travado** e não responderá. Ignore-o.
* **Botão da Direita (`Next` / `GPIO35`):** Será seu único controle.
    * **Clique Curto:** Navega pelas opções (geralmente para frente/para baixo).
    * **Clique Longo (segurar por 1 segundo):** **Confirma / Seleciona / OK**.

Com este **bypass**, você consegue assinar transações e fazer tudo o que precisa no **SideSwap**, mesmo com o bug do DTR ativo.

[**Instalar**](https://sideswap.io/downloads/) SideSwap

## <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/android/android-original.svg" width="25" height="25"/> Usando no Android: Mode Easy

Android é a plataforma mais tranquila para a nossa Jade Wallet. A conexão Bluetooth geralmente funciona de primeira tanto com o **Blockstream** quanto com o **SideSwap**.

#### 💡 Dica de Ouro: A Conexão Falhou?

Se por algum motivo a conexão Bluetooth começar a falhar ou o app não encontrar a Jade:

1.  Vá até as **Configurações de Bluetooth** do seu celular Android.
2.  Encontre a **"Jade"** na lista de dispositivos pareados.
3.  Clique nela e escolha a opção **"Esquecer"** ou **"Desparear"**.
4.  Tente conectar novamente pelo aplicativo. O processo de pareamento será refeito do zero e geralmente resolve o problema.

[**Blockstream**](https://play.google.com/store/apps/details?id=com.greenaddress.greenbits_android_wallet)

[**SideSwap**](https://play.google.com/store/apps/details?id=io.sideswap)

## ~<img src="https://upload.wikimedia.org/wikipedia/commons/1/1b/Apple_logo_grey.svg" height="25"/> Usando no iOS: QR Code~ ⚠️ ATENÇÃO: MÉTODO NÃO ESTÁ FUNCIONANDO

Aqui temos nosso maior desafio. O app da Blockstream para iOS **não consegue parear via Bluetooth** com nossa placa. Mas, como bons engenheiros de gambiarra, temos uma solução elegante.

O truque é usar o SideSwap para gerar um QR Code da sua chave pública (Xpub) e importá-lo no Blockstream.

**Siga os passos na ordem exata:**

1.  **Conecte na SideSwap Primeiro:** Abra o app SideSwap no seu iPhone e conecte-se à sua Jade via Bluetooth.
2.  **Desbloqueie sua Jade:** Digite seu PIN na Jade para ter acesso à carteira.
3.  **Exporte sua Chave Pública (Xpub):** Na Jade, navegue até o menu:
    * `Options` → `Wallet` → `Export Xpub`
4.  **Escolha o Tipo de Carteira:** Selecione `Singlesig`. A sua Jade irá processar e exibir um QR Code na tela. **Deixe este QR Code visível.**
5.  **Abra o Blockstream :** Sem fechar o SideSwap ou bloquear a Jade, mude para o app da Blockstream.
6.  **Inicie o Fluxo de Conexão via QR:** Siga este caminho no app Blockstream:
    * `Configurar uma carteira nova` → `Conectar Jade` → `Conectar via QR` → `Jade já desbloqueada` → `Escaneie a PubKey`.
7.  **Escaneie e Sincronize:** Aponte a câmera do seu iPhone para a tela da sua LILYGO T-Display. O Blockstream irá ler o QR Code, importar sua chave pública e sincronizar sua carteira.

Pronto! A partir de agora, sua carteira estará configurada no Blockstream para iOS e você poderá usá-la para monitorar saldos. Para assinar transações, você ainda precisará de um app que conecte diretamente, como o SideSwap.

[**Blockstream**](https://apps.apple.com/us/app/green-bitcoin-wallet/id1402243590)

[**SideSwap**](https://apps.apple.com/app/sideswap/id1556476417#?platform=iphone)

## 🛒 Ainda não tem uma Jade Wallet? **ADQUIRA JÁ!**

Compre em nossa loja parceira <span><a href="https://pixgo.org/loja/jade-wallet">PixGO <img src="https://pixgo.org/imgs/logo.png" width="50" align="absmiddle"/></a></span>

---
**Este guia é um documento vivo, fruto de uma jornada de debugging e colaboração. Que ele sirva para fortalecer a comunidade de entusiastas que, como você, constroem a própria soberania. Agora você tem em mãos não apenas uma carteira, mas o conhecimento para dominá-la. Com essas soluções, sua Jade Wallet está pronta para proteger seus satoshis com segurança em qualquer plataforma.**
