CREATE TABLE jogador (
    id_jogador SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL);

CREATE TABLE partida (
    id_partida SERIAL PRIMARY KEY, -- substitui AUTO_INCREMENT por SERIAL
    id_jogador INT,
    data_inicio TIMESTAMP NOT NULL, -- substitui DATETIME
    turno_atual INT DEFAULT 1,
    estado_partida VARCHAR(20) CHECK (estado_partida IN ('em andamento', 'pausada', 'encerrada')),
    primeira_rodada BOOLEAN DEFAULT TRUE,
    finalizada BOOLEAN DEFAULT FALSE,
    vitoria BOOLEAN DEFAULT TRUE,
    nivel INT DEFAULT 1,
    vida_restantes SMALLINT CHECK (vida_restantes BETWEEN 0 AND 3), -- substitui TINYINT por SMALLINT
    FOREIGN KEY (id_jogador) REFERENCES jogador(id_jogador));

CREATE TYPE tipo_carta_enum AS ENUM ('porta', 'tesouro');
CREATE TYPE subtipo_carta_enum AS ENUM ('classe', 'raca', 'item', 'monstro');

CREATE TABLE carta (
    id_carta SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    tipo_carta tipo_carta_enum NOT NULL,
    subtipo subtipo_carta_enum NOT NULL,
    disponivel_para_virar BOOLEAN NOT NULL);