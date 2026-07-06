## 🛠️ Como Compilar uma Versão Específica do Blockstream Jade (ESP-IDF)

> **Revisão:** 3 · **Ambiente:** Windows 11 | PowerShell 7 | ESP-IDF 5.5.4

**Cenário:** O `idf.py build` define a versão do firmware com base no estado atual do Git (`git describe`). Na branch principal ele compila a versão mais recente em desenvolvimento (ex: `1.0.40-100-g...`). Para cravar uma versão oficial (a **penúltima** ou uma **específica**), a gente posiciona o Git na tag certa antes de compilar.

**Atenção aos mods locais:** neste projeto DIY os arquivos `main/CMakeLists.txt` e `main/gui.c` costumam estar modificados (adaptação de hardware). Um `git checkout` puro é **abortado** pelo Git nesse caso. Por isso o fluxo abaixo usa `git stash` para guardar e reaplicar seus mods por cima da versão escolhida.

---

### ⚙️ Pré-requisito (configuração única — faça só uma vez)

Sem isso, o build para a placa S3 (T-Display S3 / Waveshare S3) **nem começa**: quebra com `ninja: fatal: CreateProcess: GetLastError() = 87 (is the command line too long?)`. O projeto tem componentes demais e a linha de comando estoura o limite do Windows. Forçar o *response file* resolve de vez.

Rode **uma vez** no PowerShell (grava no seu perfil de usuário, sobrevive à ativação do ambiente):
```powershell
[Environment]::SetEnvironmentVariable("CMAKE_NINJA_FORCE_RESPONSE_FILE","1","User")
```

Feche e reabra o terminal. Para confirmar que pegou (tem que imprimir `1`):
```powershell
echo $env:CMAKE_NINJA_FORCE_RESPONSE_FILE
```

---

### Passo a Passo

**0. Ative o ambiente ESP-IDF**
O `idf.py` só existe depois que o ambiente é carregado. Se abrir um terminal limpo, dá `idf.py não reconhecido`. Ative pelo atalho **ESP-IDF PowerShell** (Menu Iniciar) ou rode o export manualmente (repare no ponto e espaço no início — é dot-sourcing, obrigatório):
```powershell
. D:\Espressif\frameworks\esp-idf-v5.5.4\export.ps1
```
Depois entre na pasta do projeto:
```powershell
cd D:\GitHub\waveshares3\Jade
```

**1. Guarde seus mods locais (stash)**
Guarda todas as suas alterações não commitadas para o checkout não ser abortado. Elas voltam no Passo 4.
```powershell
git stash push -m "mods locais"
```

**2. Crave a versão desejada**
Escolha **UMA** das duas opções abaixo.

**Opção A — Versão específica (recomendado):**
Primeiro liste as tags disponíveis, da mais nova para a mais antiga:
```powershell
git tag --sort=-version:refname
```
Depois faça o checkout da tag exata que você quer (exemplo com `1.0.40`):
```powershell
git checkout 1.0.40
```

**Opção B — Penúltima versão (automático):**
Descobre sozinho a última tag lançada e volta um commit antes dela (`^`), cravando a versão anterior:
```powershell
$tag = git describe --tags --abbrev=0
git checkout "$tag^"
```

> Após o checkout você fica em **"detached HEAD"**. É normal e esperado ao compilar uma versão fixa — você não está num branch, só posicionado naquele commit. O Passo 7 mostra como voltar ao normal.

**3. Sincronize os submódulos (crítico)**
O Jade depende de submódulos de terceiros. O checkout muda os ponteiros deles; se não sincronizar, a compilação quebra.
```powershell
git submodule update --init --recursive
```

**4. Reaplique seus mods (stash pop)**
Traz de volta suas alterações por cima da versão escolhida.
```powershell
git stash pop
```
- **Aplicou limpo** (`Auto-merging...` + `Dropped refs/stash@{0}`) → siga para o Passo 5.
- **Deu `CONFLICT`** (a versão antiga mexeu nos mesmos arquivos) → o Git marca os trechos com `<<<<<<<` / `>>>>>>>`. Resolva à mão em cada arquivo, salve, e siga. Nesse caso o `git status` mostra quais arquivos precisam de atenção.

**5. Limpe os resíduos (fullclean)**
Zera o cache do ESP-IDF para nenhum objeto da versão nova atrapalhar o build da versão antiga.
```powershell
idf.py fullclean
```

**6. Compile e flasheie**
Com a versão cravada e o cache limpo, compile e grave na placa (troque `COM_X` pela porta correta):
```powershell
idf.py build
idf.py -p COM_X flash
```

**7. Volte ao estado normal de trabalho**
Voltar para `master` cai no **mesmo bloqueio do Passo 1** — e agora, além dos seus mods, o build também alterou o arquivo `dependencies.lock.<alvo>` (ex: `dependencies.lock.esp32s3`). Esse lock é gerado pelo build e se regenera sozinho, então **descarte-o**; seus mods de hardware você guarda e reaplica normalmente.

Descarte o lock gerado pelo build (o `*` pega qualquer sufixo de alvo):
```powershell
git checkout -- "dependencies.lock*"
```
Guarde seus mods, volte para `master` e reaplique:
```powershell
git stash push -m "mods locais" main/CMakeLists.txt main/gui.c
git checkout master
git stash pop
```
> Só faça isso **depois** de terminar de usar a versão compilada — ao voltar para `master` você sai do "detached HEAD" e perde a posição naquele commit.

---

### 🧯 Solução de problemas rápida

| Erro | Causa | Correção |
| --- | --- | --- |
| `idf.py não reconhecido` | Ambiente não ativado | Passo 0 (`export.ps1` ou atalho) |
| `GetLastError() = 87 (command line too long)` | Response file não forçado | Pré-requisito (`CMAKE_NINJA_FORCE_RESPONSE_FILE`) + `idf.py fullclean` |
| `Your local changes ... would be overwritten by checkout` | Mods locais (ou lock gerado pelo build) não guardados | `git stash push` antes de **qualquer** checkout — vale pro Passo 1 (ir pra versão) e pro Passo 7 (voltar pra master) |