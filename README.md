# 📊 Suicídios Brasil 2010–2019 — Banco de Dados MySQL

Projeto de modelagem, importação e consulta de dados sobre suicídios no Brasil entre 2010 e 2019, desenvolvido como atividade prática de banco de dados.

---

## 🗂️ Estrutura do repositório

```
├── 01_schema.sql        # Criação do banco e das tabelas
├── 02_importar_csv.py   # Script Python para importar os dados do CSV
├── 03_views.sql         # Criação das views de consulta
└── README.md            # Este arquivo
```

---

## 🛠️ Tecnologias utilizadas

- Python 3
- MySQL 8+
- pandas
- mysql-connector-python

---

## ⚙️ Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- [Python 3](https://www.python.org/downloads/)
- [MySQL](https://dev.mysql.com/downloads/mysql/)
- As bibliotecas Python necessárias:

```bash
pip install pandas mysql-connector-python
```

---

## 🗃️ Modelo do banco de dados

O banco segue um modelo **estrela** com uma tabela fato e quatro tabelas de dimensão:

```
Suicidios (tabela fato)
  ├── estado_id        → Estados       (id_estado, sigla_estado)
  ├── estado_civil_id  → Estado_civil  (id_estado_civil, estciv)
  ├── escolaridade_id  → Escolaridade  (id_escolaridade, esc)
  └── causa_id         → Causas        (id_causa, causabas, causabas_o)
```

### Tabelas

| Tabela | Descrição |
|--------|-----------|
| `Estados` | Siglas dos estados brasileiros |
| `Estado_civil` | Situação civil do indivíduo |
| `Escolaridade` | Nível de escolaridade |
| `Causas` | Código CID da causa do óbito |
| `Suicidios` | Registro central de cada ocorrência |

---

## 🚀 Passo a passo para executar o projeto

### Passo 1 — Clonar o repositório

```bash
git clone https://github.com/seu-usuario/nome-do-repositorio.git
cd nome-do-repositorio
```

### Passo 2 — Instalar as dependências Python

```bash
pip install pandas mysql-connector-python
```

### Passo 3 — Criar o banco de dados e as tabelas

Execute o arquivo `01_schema.sql` no MySQL:

```bash
mysql -u root -p < 01_schema.sql
```

Ou, dentro do cliente MySQL:

```sql
SOURCE 01_schema.sql;
```

Verifique se as tabelas foram criadas:

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

### Passo 4 — Configurar o script de importação

Abra o arquivo `02_importar_csv.py` e edite o bloco de configuração:

```python
DB_CONFIG = {
    "host":     "localhost",
    "port":     3306,
    "user":     "root",          # seu usuário MySQL
    "password": "sua_senha",     # sua senha MySQL
    "database": "suicidios_brasil",
}

CSV_PATH = "suicidios_2010_a_2019.csv"  # caminho para o arquivo CSV
```

### Passo 5 — Executar a importação

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
      Inseridos: 450 | Ignorados: 50
[4/4] Verificação rápida...
      Estados: 5 registros
      Estado_civil: 5 registros
      Escolaridade: 5 registros
      Causas: 20 registros
      Suicidios: 450 registros

Importação concluída!
```

> Registros "ignorados" são linhas com dados críticos ausentes (causabas nulo, por exemplo). É comportamento esperado.

### Passo 6 — Criar as views

```bash
mysql -u root -p < 03_views.sql
```

---

## 🔍 Consultas disponíveis (via views)

Após executar o `03_views.sql`, as seguintes views estarão disponíveis:

### 1. Listar idade, sexo e estado
```sql
SELECT * FROM vw_idade_sexo_estado LIMIT 20;
```

### 2. Total de casos por estado
```sql
SELECT * FROM vw_total_por_estado;
```

### 3. Top 10 estados com mais casos
```sql
SELECT * FROM vw_top_estados LIMIT 10;
```

### 4. Casos por nível de escolaridade
```sql
SELECT * FROM vw_casos_por_escolaridade;
```

### 5. Casos por estado civil
```sql
SELECT * FROM vw_casos_por_estado_civil;
```

### 6. Média de idade por estado
```sql
SELECT * FROM vw_media_idade_por_estado;
```

### 7. Relatório completo
```sql
SELECT * FROM vw_relatorio_completo;
```

---

## 📋 O que o script de importação faz

- Lê os primeiros **500 registros** do CSV usando a biblioteca `pandas`
- Calcula a **idade** de cada indivíduo a partir da data de nascimento (`DTNASC`) e data do óbito (`DTOBITO`)
- Popula as **tabelas de dimensão** (Estados, Estado_civil, Escolaridade, Causas) sem duplicatas, usando a estratégia `get_or_insert`
- Insere cada ocorrência na **tabela fato** `Suicidios` com as chaves estrangeiras correspondentes
- Trata `NULL` nas colunas opcionais (estado civil, escolaridade)

---

## ⚠️ Problemas comuns

| Erro | Causa | Solução |
|------|-------|---------|
| `Access denied for user 'root'` | Senha incorreta | Verificar senha no `DB_CONFIG` |
| `Unknown database 'suicidios_brasil'` | Schema não criado | Executar o Passo 3 antes do Passo 5 |
| `No module named 'mysql'` | Dependência ausente | `pip install mysql-connector-python` |
| `No module named 'pandas'` | Dependência ausente | `pip install pandas` |
| `FileNotFoundError` | Caminho do CSV errado | Usar caminho absoluto em `CSV_PATH` |

---

## 👨‍💻 Autor

Desenvolvido como projeto prático de banco de dados — Faculdade Senac.
