
CREATE DATABASE IF NOT EXISTS suicidios_brasil
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE suicidios_brasil;

CREATE TABLE IF NOT EXISTS Estados (
    id_estado     INT AUTO_INCREMENT PRIMARY KEY,
    sigla_estado  VARCHAR(2) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS Estado_civil (
    id_estado_civil INT AUTO_INCREMENT PRIMARY KEY,
    estciv          VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS Escolaridade (
    id_escolaridade INT AUTO_INCREMENT PRIMARY KEY,
    esc             VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS Causas (
    id_causa    INT AUTO_INCREMENT PRIMARY KEY,
    causabas    VARCHAR(10) NOT NULL,
    causabas_o  VARCHAR(10) NOT NULL,
    UNIQUE KEY uq_causa (causabas, causabas_o)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS Suicidios (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    ano             SMALLINT    NOT NULL,
    idade           TINYINT UNSIGNED,          -- NULL se DTNASC ausente
    sexo            ENUM('Masculino','Feminino','Ignorado') NOT NULL,
    estado_id       INT NOT NULL,
    estado_civil_id INT,                       -- NULL se não informado
    escolaridade_id INT,                       -- NULL se não informado
    causa_id        INT NOT NULL,

    CONSTRAINT fk_suc_estado
        FOREIGN KEY (estado_id)       REFERENCES Estados(id_estado),
    CONSTRAINT fk_suc_estciv
        FOREIGN KEY (estado_civil_id) REFERENCES Estado_civil(id_estado_civil),
    CONSTRAINT fk_suc_esc
        FOREIGN KEY (escolaridade_id) REFERENCES Escolaridade(id_escolaridade),
    CONSTRAINT fk_suc_causa
        FOREIGN KEY (causa_id)        REFERENCES Causas(id_causa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
 show tables;
 select *from Suicidios;
 

-- testando os inserets
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


-- criando as pesquisas
-- 1. Listar idade, sexo e estado onde ocorreu o óbito.
select s.idade, s.sexo, e.sigla_estado from Suicidios s join Estados e on s.estado_id = e.id_estado limit 20;
-- 2. Exibir o total de registros de suicidios por Estado.
SELECT e.sigla_estado, COUNT(*) AS total FROM Suicidios s JOIN Estados e ON s.estado_id = e.id_estado GROUP BY e.sigla_estado;
-- 3. Mostrar os 10 Estados com mais casos.
SELECT
    e.sigla_estado,
    COUNT(*) AS total
FROM Suicidios s
JOIN Estados e ON s.estado_id = e.id_estado
GROUP BY e.sigla_estado
ORDER BY total DESC
LIMIT 10;
-- 4. Exibir quantidade de casos para cada nível de escolaridade.
SELECT
    esc.esc,
    COUNT(*) AS total
FROM Suicidios s
JOIN Escolaridade esc ON s.escolaridade_id = esc.id_escolaridade
GROUP BY esc.esc;
-- 5. Mostrar quantidade de registros por estado civil.
SELECT
    ec.estciv,
    COUNT(*) AS total
FROM Suicidios s
JOIN Estado_civil ec ON s.estado_civil_id = ec.id_estado_civil
GROUP BY ec.estciv;
-- 6. Mostre a média de idade dos casos por estado.
SELECT
    e.sigla_estado,
    ROUND(AVG(s.idade), 1) AS media_idade
FROM Suicidios s
JOIN Estados e ON s.estado_id = e.id_estado
GROUP BY e.sigla_estado;
-- 7. Crie um relatório exibindo as seguintes informações para cada caso: Estado, estado civil, escolaridade, causas e quantidade de casos.
SELECT
    e.sigla_estado,
    ec.estciv,
    esc.esc,
    c.causabas,
    COUNT(*) AS total_casos
FROM Suicidios s
JOIN Estados e        ON s.estado_id        = e.id_estado
JOIN Estado_civil ec  ON s.estado_civil_id  = ec.id_estado_civil
JOIN Escolaridade esc ON s.escolaridade_id  = esc.id_escolaridade
JOIN Causas c         ON s.causa_id         = c.id_causa
GROUP BY e.sigla_estado, ec.estciv, esc.esc, c.causabas
ORDER BY total_casos DESC;

-- fazendo os view


-- 1. Listar idade, sexo e estado onde ocorreu o óbito.
-- LIMIT removido: aplique ao consultar → SELECT * FROM vw_idade_sexo_estado LIMIT 20;
CREATE VIEW vw_idade_sexo_estado AS
SELECT
    s.idade,
    s.sexo,
    e.sigla_estado
FROM Suicidios s
JOIN Estados e ON s.estado_id = e.id_estado;


-- 2. Total de registros de suicídios por Estado.
CREATE VIEW vw_total_por_estado AS
SELECT
    e.sigla_estado,
    COUNT(*) AS total
FROM Suicidios s
JOIN Estados e ON s.estado_id = e.id_estado
GROUP BY e.sigla_estado;


-- 3. 10 Estados com mais casos.
-- LIMIT removido: aplique ao consultar → SELECT * FROM vw_top_estados LIMIT 10;
CREATE VIEW vw_top_estados AS
SELECT
    e.sigla_estado,
    COUNT(*) AS total
FROM Suicidios s
JOIN Estados e ON s.estado_id = e.id_estado
GROUP BY e.sigla_estado
ORDER BY total DESC;


-- 4. Quantidade de casos para cada nível de escolaridade.
CREATE VIEW vw_casos_por_escolaridade AS
SELECT
    esc.esc,
    COUNT(*) AS total
FROM Suicidios s
JOIN Escolaridade esc ON s.escolaridade_id = esc.id_escolaridade
GROUP BY esc.esc;


-- 5. Quantidade de registros por estado civil.
CREATE VIEW vw_casos_por_estado_civil AS
SELECT
    ec.estciv,
    COUNT(*) AS total
FROM Suicidios s
JOIN Estado_civil ec ON s.estado_civil_id = ec.id_estado_civil
GROUP BY ec.estciv;


-- 6. Média de idade dos casos por estado.
CREATE VIEW vw_media_idade_por_estado AS
SELECT
    e.sigla_estado,
    ROUND(AVG(s.idade), 1) AS media_idade
FROM Suicidios s
JOIN Estados e ON s.estado_id = e.id_estado
GROUP BY e.sigla_estado;


-- 7. Relatório completo: Estado, estado civil, escolaridade, causa e quantidade.
CREATE VIEW vw_relatorio_completo AS
SELECT
    e.sigla_estado,
    ec.estciv,
    esc.esc,
    c.causabas,
    COUNT(*) AS total_casos
FROM Suicidios s
JOIN Estados e        ON s.estado_id        = e.id_estado
JOIN Estado_civil ec  ON s.estado_civil_id  = ec.id_estado_civil
JOIN Escolaridade esc ON s.escolaridade_id  = esc.id_escolaridade
JOIN Causas c         ON s.causa_id         = c.id_causa
GROUP BY e.sigla_estado, ec.estciv, esc.esc, c.causabas
ORDER BY total_casos DESC;