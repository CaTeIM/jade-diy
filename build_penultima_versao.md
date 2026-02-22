## 🛠️ Como Compilar a Última Versão Estável do Blockstream Jade (ESP-IDF)

**Cenário:** O `idf.py build` define a versão do firmware com base no estado atual do Git (`git describe`). Se você estiver na branch principal, ele compilará a versão mais recente em desenvolvimento (ex: `1.0.39-beta2`). Para compilar o código do **exato commit antes da última versão oficial lançada**, automatizamos a busca da tag via PowerShell.

**Ambiente:** Windows 11 | PowerShell | ESP-IDF 5.4

### Passo a Passo

**1. Checkout no último commit antes da tag atual (Automático)**
Use o script abaixo no PowerShell. Ele descobre sozinho a última tag lançada (ex: `1.0.38`) e volta o código exatamente um passo antes dela (`^`), cravando a versão desejada no build. Dessa forma teremos a versão 1.0.38-XX compilada ao invés da última.
```powershell
$tag = git describe --tags --abbrev=0
git checkout "$tag^"
```

**2. Sincronize os Submódulos (Crítico)**
O código do Jade depende de submódulos de terceiros. Se você não sincronizá-los com o commit que acabou de fazer checkout, a compilação vai quebrar.

```bash
git submodule update --init --recursive
```

**3. Limpe os resíduos (Fullclean)**
Zere o cache do ESP-IDF para garantir que nenhum arquivo objeto da versão mais nova (que já estava compilada) atrapalhe o build da versão antiga.

```bash
idf.py fullclean
```

**4. Compile e Flasheie**
Com o repositório cravado na versão certa e o cache limpo, é só compilar e gravar na placa.

```bash
idf.py build flash
```