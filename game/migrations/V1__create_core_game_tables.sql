CREATE TABLE jogador (
    id_jogador SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL);

CREATE TABLE partida (
    id_partida SERIAL PRIMARY KEY, -- substitui AUTO_INCREMENT por SERIAL
    id_jogador INT,
    data_inicio TIMESTAMP NOT NULL, -- substitui DATETIME
    turno_atual INT DEFAULT 1,
    estado_partida VARCHAR(20) CHECK (estado_partida IN ('em andamento', 'encerrada')),
    finalizada BOOLEAN DEFAULT FALSE,
    vitoria BOOLEAN DEFAULT FALSE,
    nivel INT DEFAULT 1,
    vida_restantes SMALLINT CHECK (vida_restantes BETWEEN 0 AND 3), -- substitui TINYINT por SMALLINT
    ouro_acumulado INT DEFAULT 0,
    limite_mao_atual INT DEFAULT 5,
    FOREIGN KEY (id_jogador) REFERENCES jogador(id_jogador));

-- restrição parcial para que não possa existir mais de uma partida em andamento para o mesmo jogador
CREATE UNIQUE INDEX idx_unico_jogador_partida_em_andamento
ON partida(id_jogador)
WHERE estado_partida = 'em andamento';

CREATE TYPE tipo_carta_enum AS ENUM ('porta', 'tesouro');
CREATE TYPE subtipo_carta_enum AS ENUM ('classe', 'raca', 'item', 'monstro');

CREATE TABLE carta (
    id_carta SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    tipo_carta tipo_carta_enum NOT NULL,
    subtipo subtipo_carta_enum NOT NULL,
    disponivel_para_virar BOOLEAN NOT NULL);

CREATE TABLE slot_equipamento (
    nome VARCHAR PRIMARY KEY, 
    capacidade INT NOT NULL,  
    grupo_exclusao VARCHAR,   
    descricao TEXT
);

CREATE TABLE mapa (
    id_reino SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL,
    descricao TEXT NOT NULL
);

