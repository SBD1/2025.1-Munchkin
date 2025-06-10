-- Recompensa condicional (ex: Elfo e Orc)
CREATE TABLE poder_recompensa_condicional (
    id_poder_raca INT PRIMARY KEY,
    bonus_tipo VARCHAR(20) CHECK (bonus_tipo IN ('nivel', 'tesouro_extra')),
    bonus_quantidade INT NOT NULL,
    condicao_tipo VARCHAR(30) CHECK (condicao_tipo IN (
        'matar_monstro',
        'nivel_monstro_maior_10'
    )),
    FOREIGN KEY (id_poder_raca) REFERENCES poder_raca(id_poder_raca)
);

-- Limite de mão extra (Anão)
CREATE TABLE poder_limite_de_mao (
    id_poder_raca INT PRIMARY KEY,
    limite_cartas_mao INT NOT NULL,
    FOREIGN KEY (id_poder_raca) REFERENCES poder_raca(id_poder_raca)
);

-- Venda multiplicada (Halfling)
CREATE TABLE poder_venda_multiplicada (
    id_poder_raca INT PRIMARY KEY,
    multiplicador INT NOT NULL DEFAULT 2,
    limite_vezes_por_turno INT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_poder_raca) REFERENCES poder_raca(id_poder_raca)
);
