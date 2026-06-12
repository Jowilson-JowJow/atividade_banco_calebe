# Tutorial: CSV → MySQL — Suicídios 2010–2019

## Visão geral do processo

```
CSV (500 linhas)
    │
    ▼
Python (pandas + mysql-connector)
    │
    ├─► Estados
    ├─► Estado_civil
    ├─► Escolaridade
    ├─► Causas
    └─► Suicidios  ◄── tabela fato (chaves estrangeiras)
```

---

## PASSO 1 — Instalar as dependências Python

Abra o terminal no VSCode (`Ctrl + J`) e execute:

```bash
pip install pandas mysql-connector-python
```

---

## PASSO 2 — Criar o banco de dados no MySQL

### 2.1 Abrir o MySQL no terminal

```bash
mysql -u root -p
```

Digite sua senha quando solicitado.

### 2.2 Executar o arquivo de schema

Ainda dentro do MySQL, execute o arquivo `01_schema.sql`:

```sql
SOURCE caminho_completo/01_schema.sql;
```

Ou, direto pelo terminal (sem entrar no MySQL interativo):

```bash
mysql -u root -p < 01_schema.sql
```

### 2.3 Confirmar que as tabelas foram criadas

```sql
USE suicidios_brasil;
SHOW TABLES;
```

Resultado esperado:
```
+---------------------------+
| Tables_in_suicidios_brasil|
+---------------------------+
| Causas                    |
| Escolaridade              |
| Estado_civil              |
| Estados                   |
| Suicidios                 |
+---------------------------+
```

### 2.4 Entender o modelo

| Tabela        | Função                                      | Chave PK           |
|---------------|---------------------------------------------|--------------------|
| Estados       | Siglas dos estados (AC, AL, AM…)            | id_estado          |
| Estado_civil  | Solteiro/a, Casado/a, Viúvo/a…              | id_estado_civil    |
| Escolaridade  | 1 a 3 anos, 4 a 7 anos…                     | id_escolaridade    |
| Causas        | Código CID (X780, X720…)                    | id_causa           |
| Suicidios     | Fato central; referencia todas as tabelas   | id                 |

> **Tabela fato vs tabela dimensão:** As 4 primeiras são "dimensões" —
> guardam valores únicos sem repetição. `Suicidios` é a "fato" — tem
> uma linha por ocorrência e usa chaves estrangeiras para referenciar
> as dimensões. Isso evita duplicar strings como "Solteiro/a" 500 vezes.

---

## PASSO 3 — Configurar o script Python

Abra o arquivo `02_importar_csv.py` no VSCode e edite o bloco:

```python
DB_CONFIG = {
    "host":     "localhost",
    "port":     3306,
    "user":     "root",       # ← seu usuário MySQL
    "password": "sua_senha",  # ← sua senha MySQL
    "database": "suicidios_brasil",
}

CSV_PATH = "suicidios_2010_a_2019.csv"  # ← caminho para o arquivo CSV
```

Se o CSV estiver em outra pasta, use o caminho absoluto:
```python
CSV_PATH = r"C:\Users\voce\Downloads\suicidios_2010_a_2019.csv"
```

---

## PASSO 4 — Executar a importação

No terminal do VSCode:

```bash
python 02_importar_csv.py
```

Saída esperada:

```
[1/4] Lendo os primeiros 500 registros do CSV...
      500 linhas carregadas.
[2/4] Conectando ao MySQL...
      Conexão OK.
[3/4] Inserindo registros...
      Inseridos: 450 | Ignorados: 50   ← ignorados = linhas com dados faltantes críticos
[4/4] Verificação rápida...
      Estados: 5 registros
      Estado_civil: 5 registros
      Escolaridade: 5 registros
      Causas: 20 registros
      Suicidios: 450 registros

Importação concluída!
```

---

## PASSO 5 — Conferir no MySQL

Execute no cliente MySQL ou em qualquer ferramenta visual (MySQL Workbench, DBeaver, extensão do VSCode):

```sql
USE suicidios_brasil;

-- Quantos registros por estado
SELECT e.sigla_estado, COUNT(*) AS total
FROM Suicidios s
JOIN Estados e ON s.estado_id = e.id_estado
GROUP BY e.sigla_estado
ORDER BY total DESC;

-- Distribuição por sexo
SELECT sexo, COUNT(*) AS total
FROM Suicidios
GROUP BY sexo;

-- Média de idade
SELECT ROUND(AVG(idade), 1) AS media_idade
FROM Suicidios
WHERE idade IS NOT NULL;

-- Causas mais frequentes
SELECT c.causabas, COUNT(*) AS ocorrencias
FROM Suicidios s
JOIN Causas c ON s.causa_id = c.id_causa
GROUP BY c.causabas
ORDER BY ocorrencias DESC
LIMIT 10;
```

---

## O que o script faz por dentro (explicação conceitual)

### Tabelas de dimensão — `get_or_insert`

Para cada campo como `ESTCIV` ("Solteiro/a"), o script:
1. Verifica se o valor já existe na tabela `Estado_civil`.
2. Se sim, retorna o `id` existente.
3. Se não, insere o valor e retorna o novo `id`.

Isso garante que "Solteiro/a" apareça **uma única vez** na tabela de dimensão,
e que `Suicidios` só guarde o número (ex: `2`).

### Cálculo de idade

A idade **não está no CSV** — existe apenas a data de nascimento (`DTNASC`)
e a data do óbito (`DTOBITO`). O script calcula:

```
idade = ano_óbito - ano_nascimento
        (ajustado se o aniversário ainda não ocorreu no ano do óbito)
```

Linhas com datas ausentes ou malformadas ficam com `idade = NULL`.

### Tratamento de NULLs

- `ESTCIV`, `ESC` podem ser nulos no CSV → o script aceita e insere `NULL`
  na tabela fato (as FKs permitem NULL nessas colunas).
- `CAUSABAS` / `CAUSABAS_O` nunca deveriam ser nulos; se forem, a linha
  é ignorada com aviso.

---

## Erros comuns e soluções

| Erro | Causa | Solução |
|------|-------|---------|
| `Access denied for user 'root'` | Senha errada | Verificar senha no DB_CONFIG |
| `Unknown database 'suicidios_brasil'` | Schema não criado | Executar o PASSO 2 primeiro |
| `No module named 'mysql'` | Dependência ausente | `pip install mysql-connector-python` |
| `No module named 'pandas'` | Dependência ausente | `pip install pandas` |
| `FileNotFoundError` no CSV | Caminho incorreto | Usar caminho absoluto em CSV_PATH |
| Muitos "ignorados" | Dados faltantes no CSV | Normal; verificar os AVISOs no terminal |
