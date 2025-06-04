CREATE TABLE carta_classe (
    id_carta INT PRIMARY KEY,
    nome_classe VARCHAR(20) NOT NULL,
    FOREIGN KEY (id_carta) REFERENCES carta(id_carta));

CREATE TABLE carta_raca (
    id_carta INT PRIMARY KEY,
    nome_raca VARCHAR(20) NOT NULL,
    descricao VARCHAR(200),
    FOREIGN KEY (id_carta) REFERENCES carta(id_carta));

CREATE TABLE carta_item (
    id_carta INT PRIMARY KEY,
    bonus_combate INT,
    valor_ouro INT,
    tipo_item VARCHAR(20) CHECK (tipo_item IN ('arma', 'armadura', 'acessório')),
    slot VARCHAR(20) CHECK (slot IN ('cabeca', 'pe', 'corpo', '1_mao', '2_maos', 'nenhum')),
    ocupacao_dupla BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_carta) REFERENCES carta(id_carta));

CREATE TABLE carta_monstro (
    id_carta_monstro SERIAL PRIMARY KEY,
    id_carta INT UNIQUE NOT NULL,
    nivel INT,
    pode_fugir BOOLEAN,
    recompensa INT,
    tipo_monstro VARCHAR(50) CHECK (tipo_monstro IN ('morto_vivo', 'sem_tipo')),
    FOREIGN KEY (id_carta) REFERENCES carta(id_carta));