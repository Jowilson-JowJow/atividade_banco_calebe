"""
02_importar_csv.py
==================
Lê os primeiros 500 registros do CSV de suicídios e insere no MySQL.

Dependências:
    pip install pandas mysql-connector-python

Configuração:
    Ajuste as variáveis no bloco DB_CONFIG abaixo antes de executar.
"""

import pandas as pd
import mysql.connector
from datetime import datetime

# ── Configurações de conexão ──────────────────────────────────────────────────
DB_CONFIG = {
    "host":     "localhost",
    "port":     3306,
    "user":     "root",          # troque pelo seu usuário MySQL
    "password": "",     # troque pela sua senha MySQL
    "database": "suicidios_brasil",
}

CSV_PATH   = "suicidios_2010_a_2019.csv"  # ajuste o caminho se necessário
LIMITE     = 500                           # quantos registros importar

# ── Helpers ───────────────────────────────────────────────────────────────────

def calcular_idade(dtobito_str, dtnasc_str):
    """Retorna a idade em anos completos, ou None se datas inválidas."""
    try:
        obito = datetime.strptime(str(dtobito_str), "%Y-%m-%d")
        nasc  = datetime.strptime(str(dtnasc_str),  "%Y-%m-%d")
        return (obito.year - nasc.year
                - ((obito.month, obito.day) < (nasc.month, nasc.day)))
    except Exception:
        return None


def get_or_insert(cursor, table, id_col, val_col, value):
    """
    Busca o id de 'value' na tabela. Se não existir, insere e retorna o novo id.
    Útil para popular as tabelas de dimensão de forma idempotente.
    """
    if pd.isna(value):
        return None

    cursor.execute(
        f"SELECT {id_col} FROM {table} WHERE {val_col} = %s", (value,)
    )
    row = cursor.fetchone()
    if row:
        return row[0]

    cursor.execute(
        f"INSERT INTO {table} ({val_col}) VALUES (%s)", (value,)
    )
    return cursor.lastrowid


def get_or_insert_causa(cursor, causabas, causabas_o):
    """Idem para Causas (duas colunas formam a chave única)."""
    cursor.execute(
        "SELECT id_causa FROM Causas WHERE causabas = %s AND causabas_o = %s",
        (causabas, causabas_o),
    )
    row = cursor.fetchone()
    if row:
        return row[0]

    cursor.execute(
        "INSERT INTO Causas (causabas, causabas_o) VALUES (%s, %s)",
        (causabas, causabas_o),
    )
    return cursor.lastrowid


# ── Script principal ──────────────────────────────────────────────────────────

def main():
    # 1. Ler o CSV
    print(f"[1/4] Lendo os primeiros {LIMITE} registros do CSV...")
    df = pd.read_csv(CSV_PATH, nrows=LIMITE, encoding="utf-8")
    print(f"      {len(df)} linhas carregadas.")

    # 2. Conectar ao MySQL
    print("[2/4] Conectando ao MySQL...")
    conn   = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()
    print("      Conexão OK.")

    # 3. Inserir registros
    print("[3/4] Inserindo registros...")
    inseridos  = 0
    ignorados  = 0

    for idx, row in df.iterrows():
        try:
            # — Dimensões —
            estado_id = get_or_insert(
                cursor, "Estados", "id_estado", "sigla_estado", row["estado"]
            )
            estciv_id = get_or_insert(
                cursor, "Estado_civil", "id_estado_civil", "estciv", row["ESTCIV"]
            )
            esc_id = get_or_insert(
                cursor, "Escolaridade", "id_escolaridade", "esc", row["ESC"]
            )
            causa_id = get_or_insert_causa(
                cursor, row["CAUSABAS"], row["CAUSABAS_O"]
            )

            # — Idade calculada —
            idade = calcular_idade(row["DTOBITO"], row["DTNASC"])

            # — Sexo: normalizar valores inesperados —
            sexo = row["SEXO"] if row["SEXO"] in ("Masculino", "Feminino") else "Ignorado"

            # — Fato —
            cursor.execute(
                """
                INSERT INTO Suicidios
                    (ano, idade, sexo, estado_id, estado_civil_id, escolaridade_id, causa_id)
                VALUES
                    (%s,  %s,    %s,   %s,        %s,              %s,              %s)
                """,
                (
                    int(row["ano"]),
                    int(idade) if idade is not None else None,
                    sexo,
                    estado_id,
                    estciv_id,
                    esc_id,
                    causa_id,
                ),
            )
            inseridos += 1

        except Exception as e:
            print(f"      AVISO linha {idx}: {e}")
            ignorados += 1
            conn.rollback()
            continue

    conn.commit()
    print(f"      Inseridos: {inseridos} | Ignorados: {ignorados}")

    # 4. Verificação rápida
    print("[4/4] Verificação rápida...")
    for tabela in ("Estados", "Estado_civil", "Escolaridade", "Causas", "Suicidios"):
        cursor.execute(f"SELECT COUNT(*) FROM {tabela}")
        qtd = cursor.fetchone()[0]
        print(f"      {tabela}: {qtd} registros")

    cursor.close()
    conn.close()
    print("\nImportação concluída!")


if __name__ == "__main__":
    main()
