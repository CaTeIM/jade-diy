
# 🛠️ Modificação de Hardware – Correção de Travamento do GPIO0 em Placas ESP32 TTGO T-Display (CH9102F)

## 📋 Resumo do Problema

Placas **TTGO T-Display (ESP32)** equipadas com o chip **CH9102F (USB–Serial)** podem apresentar **travamento do pino GPIO0 e do botão de Boot** ao se conectar com certos aplicativos modernos, como **Blockstream Green** ou **SideSwap**.

### 🔍 Sintoma típico
- O **ESP32 inicia normalmente o bootloader** e o firmware.  
- Porém, ao abrir conexão serial (ex: Blockstream, SideSwap), o sistema **trava**.  
- O **GPIO0** fica permanentemente em nível **baixo (LOW)**.  
- O **botão de Boot** deixa de funcionar até que a placa seja desconectada da USB.  
- O bug não é corrigido apenas com o ajuste de *“Disable Modem Handshake”* na porta COM do Windows, pois alguns apps reconfiguram o driver diretamente.

## ⚙️ Análise Técnica (Causa Raiz)

O circuito de auto-programação da TTGO T-Display usa as linhas **DTR** e **RTS** do CH9102F para manipular os pinos de controle do ESP32:

- `EN` (Reset)  
- `IO0` (Boot)

### Circuito original
```
RTS → R19 (10 kΩ) → base de Q2 (PMBT3904 NPN)
coletor de Q2 → GPIO0 do ESP32
emissor → GND
```

O driver “moderno” do Windows e de alguns aplicativos mantém o sinal **RTS em nível DC constante**.  
Isso **satura a base do transistor Q2**, que então conduz permanentemente.  
Resultado: o **GPIO0 é aterrado (LOW)** e o **botão físico deixa de responder**.

## 🧩 Solução Definitiva (Modificação de Hardware)

A solução é **substituir o resistor R19 (10 kΩ)** por um **capacitor cerâmico de 0,1 µF (100 nF)**.

### 🎯 Objetivo
Converter o acoplamento **DC → AC**, bloqueando o nível fixo de RTS, mas mantendo a capacidade de passar os pulsos rápidos usados para reset e entrada no modo de gravação.

## 📍 Localização dos Componentes

| Componente | Função | Localização |
|-------------|---------|-------------|
| **Q2** | Transistor que controla o GPIO0 (modo Boot) | À esquerda do conector USB-C |
| **Q1** | Transistor do Reset (EN) | À direita do conector USB-C |
| **R19** | Entre RTS (CH9102F pino 19) e base de Q2 | Lado traseiro da placa, logo atrás do Q2 |

---

## 🧰 Materiais Necessários
- Ferro de solda com ponta fina (≤ 1 mm)  
- Fluxo de solda e pinça de precisão  
- Capacitor cerâmico **100 nF / 6,3 V ou mais / dielétrico X7R ou X5R / tamanho SMD 0603**  
- Multímetro (modo continuidade)

## 🧪 Procedimento Passo a Passo

1. **Desconecte** a placa da USB e da bateria.  
2. Localize o **R19** na parte traseira da placa (atrás do transistor Q2).  
3. **Remova o resistor** cuidadosamente com ferro e pinça.  
4. **Solde o capacitor de 100 nF** nos mesmos pads.  
5. Opcional: teste continuidade entre o **pino 19 (RTS)** do CH9102F e um dos lados do capacitor para confirmar a ligação.  
6. Reconecte via USB e teste o comportamento no SideSwap/Blockstream.

## 📸 Imagens de Referência

### 1️⃣ Localização do R19 (lado traseiro)
> ![R19 Location](https://raw.githubusercontent.com/cateim/jade-diy/main/assets/mod/1.png)

### 2️⃣ Região dos Transistores Q1 e Q2 (lado frontal)
> ![Q2 and Q1 Front View](https://raw.githubusercontent.com/cateim/jade-diy/main/assets/mod/2.png)

### 3️⃣ Substituição concluída
> ![R19 replaced by 100nF capacitor](https://raw.githubusercontent.com/cateim/jade-diy/main/assets/mod/3.png)

---

## 💡 Resultado

Após a modificação:
- O ESP32 **mantém boot normal** e não sofre interferência do driver moderno.  
- O **GPIO0 e o botão de Boot** permanecem funcionais.  
- Softwares como **Blockstream Green** e **SideSwap** podem abrir a porta serial sem causar travamento.  
- O circuito de gravação automática continua operacional.

## 🔬 Verificação

Para confirmar o sucesso:
1. Conecte a TTGO ao PC.  
2. Abra o SideSwap/Blockstream.  
3. Verifique que o botão de Boot responde normalmente.  
4. A comunicação serial funciona sem o ESP32 travar em modo Bootloader.

## 🧠 Racional Técnico

| Antes (R19 = 10 kΩ) | Depois (C = 100 nF) |
|----------------------|---------------------|
| Acoplamento DC, transistor conduz com RTS constante | Acoplamento AC, transistor só conduz em pulsos |
| GPIO0 e botão travam | GPIO0 e botão operam normalmente |
| Driver moderno interfere | Isolado de sinais DC indesejados |

## 📎 Referências

- Esquemático original **[ESP32-TFT](https://github.com/Xinyuan-LilyGO/TTGO-T-Display/blob/master/schematic/ESP32-TFT(6-26).pdf)**  
- Datasheet **[CH9102F](https://www.wch-ic.com/downloads/CH9102DS1_PDF.html)**


## 🧩 Créditos
Documento técnico e modificação prática por **[Cateim](https://github.com/cateim)**.
