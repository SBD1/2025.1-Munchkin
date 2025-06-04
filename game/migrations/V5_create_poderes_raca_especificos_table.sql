CREATE TABLE poder_fuga_condicional (
    id_poder_raca INT PRIMARY KEY,
    nova_tentativa BOOLEAN DEFAULT FALSE, 
    quantidade INT,
    condicao_tipo VARCHAR(20) CHECK (condicao_tipo IN ('sem_condicao', 'descartar_carta')),
    FOREIGN KEY (id_poder_raca) REFERENCES poder_raca(id_poder_raca)
);

CREATE TABLE poder_maldicao (
    id_poder_raca INT PRIMARY KEY,
    ignora_maldicao BOOLEAN DEFAULT FALSE,
    penalidade_substituta VARCHAR(100),
    nivel_minimo INT,
    FOREIGN KEY (id_poder_raca) REFERENCES poder_raca(id_poder_raca)
);

CREATE TABLE poder_recompensa_condicional (
    id_poder_raca INT PRIMARY KEY,
    bonus_tipo VARCHAR(20) CHECK (bonus_tipo IN ('nivel', 'tesouro_extra')),
    bonus_quantidade INT,
    condicao_tipo VARCHAR(30) CHECK (condicao_tipo IN ('nivel_menor_que_monstro', 'matar_monstro')),
    FOREIGN KEY (id_poder_raca) REFERENCES poder_raca(id_poder_raca)
);

CREATE TABLE poder_limite_de_mao (
    id_poder_raca INT PRIMARY KEY,
    limite_carta_mao INT,
    FOREIGN KEY (id_poder_raca) REFERENCES poder_raca(id_poder_raca)
);

CREATE TABLE poder_pecas_ouro (
    id_poder_raca INT PRIMARY KEY,
    quantidade INT,
    FOREIGN KEY (id_poder_raca) REFERENCES poder_raca(id_poder_raca)
);