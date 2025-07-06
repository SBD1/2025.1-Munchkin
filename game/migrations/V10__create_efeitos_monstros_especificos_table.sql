CREATE TABLE penalidade_perda_nivel (
    id_efeito_monstro INTEGER PRIMARY KEY REFERENCES efeito_monstro(id_efeito_monstro),
    niveis INT NOT NULL
);

CREATE TABLE penalidade_item (
    id_efeito_monstro INTEGER PRIMARY KEY REFERENCES efeito_monstro(id_efeito_monstro),
    local_item VARCHAR(50) CHECK (local_item IN ('mao', 'corpo', 'cabeca', 'todos')) NOT NULL
);

CREATE TABLE penalidade_transformacao (
    id_efeito_monstro INTEGER PRIMARY KEY REFERENCES efeito_monstro(id_efeito_monstro),
    perde_classe BOOLEAN NOT NULL DEFAULT FALSE,
    perde_raca BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE penalidade_morte (
    id_efeito_monstro INTEGER PRIMARY KEY REFERENCES efeito_monstro(id_efeito_monstro),
    morte BOOLEAN NOT NULL DEFAULT FALSE
);