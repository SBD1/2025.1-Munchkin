-- Cria função para inserir jogador com nome
CREATE OR REPLACE FUNCTION insert_munchkin_jogador(nome TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO jogador (nome) VALUES (nome);
END;
$$ LANGUAGE plpgsql;

INSERT INTO jogador (nome) VALUES
('Breno'),
('Maria');

-- Cria função para iniciar uma nova partida
CREATE OR REPLACE FUNCTION insert_munchkin_partida(p_id_jogador INT)
RETURNS INT AS $$
DECLARE
    nova_partida_id INT;
BEGIN
    INSERT INTO partida (
        id_jogador,
        data_inicio,
        estado_partida,
        vida_restantes,
        ouro_acumulado,
        limite_mao_atual
    )
    VALUES (
        p_id_jogador,
        NOW(),
        'em andamento',
        3,
        0,
        5
    )
    RETURNING id_partida INTO nova_partida_id;

    RETURN nova_partida_id;
END;
$$ LANGUAGE plpgsql;


-- Inserção de partidas (DESCOMENTE apenas se tiver jogadores inseridos com id 1 e 2)
INSERT INTO partida (
    id_jogador, data_inicio, turno_atual, estado_partida,
    finalizada, vitoria, nivel, vida_restantes, ouro_acumulado, limite_mao_atual
) VALUES
(1, NOW(), 1, 'em andamento', FALSE, TRUE, 1, 3, 0, 5),
(2, NOW(), 2, 'encerrada', TRUE, FALSE, 2, 2, 0, 5);


-- Inserção de cartas iniciais
INSERT INTO carta (id_carta, nome, tipo_carta, subtipo, disponivel_para_virar)
VALUES 
(1, 'dentadura postiça aterrorizante', 'tesouro', 'item', TRUE),
(2, 'Título realmente impressiionante', 'tesouro', 'item', TRUE),
(3, 'joelheiras pontiagudas', 'tesouro', 'item', TRUE),
(4, 'botas de chutas a bunda', 'tesouro', 'item', TRUE),
(5, 'broquel da bravata', 'tesouro', 'item', TRUE),
(6, 'elmo da coragem', 'tesouro', 'item', TRUE),
(7, 'armadura flamejante', 'tesouro', 'item', TRUE),
(8, 'serra elétrica de mutilação sangrenta', 'tesouro', 'item', TRUE),
(9, 'manto das sombras', 'tesouro', 'item', TRUE),
(10, 'livro muito sagrado', 'tesouro', 'item', TRUE),
(11, 'armadura rechonchuda', 'tesouro', 'item', TRUE),
(12, 'arco com fitinhas', 'tesouro', 'item', TRUE),
(13, 'escada de mão', 'tesouro', 'item', TRUE),
(14, 'meia calça da força do gigante', 'tesouro', 'item', TRUE),
(15, 'escudo onipresente', 'tesouro', 'item', TRUE),
(16, 'espada muito estranha', 'tesouro', 'item', TRUE),
(17, 'chapéu de bruxo do poder', 'tesouro', 'item', TRUE),
(18, 'anão', 'porta', 'raca', TRUE),
(19, 'elfo', 'porta', 'raca', TRUE),
(20, 'halfling', 'porta', 'raca', TRUE),
(21, 'orc', 'porta', 'raca', TRUE),
(22, 'clérigo', 'porta', 'classe', TRUE),
(23, 'guerreiro', 'porta', 'classe', TRUE),
(24, 'mago', 'porta', 'classe', TRUE),
(25, 'rãs voadoras', 'porta', 'monstro', TRUE),
(26, 'cavalo zumbi', 'porta', 'monstro', TRUE),
(27, 'nerd histérico', 'porta', 'monstro', TRUE),
(28, 'chupa cara', 'porta', 'monstro', TRUE),
(29, 'nariz flutuante', 'porta', 'monstro', TRUE),
(30, 'pé grande', 'porta', 'monstro', TRUE),
(31, 'horror aterrorizante indescritivelmente indescritível', 'porta', 'monstro', TRUE),
(32, 'rei tut', 'porta', 'monstro', TRUE),
(33, 'balrog', 'porta', 'monstro', TRUE),
(34, 'dragão de plutônio', 'porta', 'monstro', TRUE);

<<<<<<< HEAD
<<<<<<< HEAD
INSERT INTO mapa ( id_reino, nome, descricao) 
VALUES
(1, '🏰Abismo da Masmorra Sombria', 'Criaturas deformadas espreitam nas sombras em corredores esquecidos'),
(2, '🌲Selva de Espinhos Eternos', 'A floresta vive, sussurra e caça os que ousam entrar'),
(3, '🧙Cúpula dos Arquimagos', 'Feitiços antigos moldaram monstros que guardam segredos arcanos'),
(4, '🔥Fornalha do Trono Carmesim', 'Chamas vivas e legiões demoníacas defendem a entrada do inferno'),
(5, '👑Coração do Deus Quebrado', 'Um palácio partido onde o Chefão Final aguarda em ruína sagrada');
=======
=======
>>>>>>> cb8e53a56d569e911da7c6bddfc64f6d657c7dca

INSERT INTO mapa (id_reino, nome, descricao, nivel_min, nivel_max, ordem) 
VALUES
(1, '🏰Abismo da Masmorra Sombria', 'Criaturas deformadas espreitam nas sombras em corredores esquecidos', 2, 6, 1),
(2, '🌲Selva de Espinhos Eternos', 'A floresta vive, sussurra e caça os que ousam entrar', 6, 10, 2),
(3, '🧙Cúpula dos Arquimagos', 'Feitiços antigos moldaram monstros que guardam segredos arcanos', 10, 14, 3),
(4, '🔥Fornalha do Trono Carmesim', 'Chamas vivas e legiões demoníacas defendem a entrada do inferno', 14, 18, 4),
(5, '👑Coração do Deus Quebrado', 'Um palácio partido onde o Chefão Final aguarda em ruína sagrada', 20, 20, 5);
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> 5cb1407 (adicionando colunas no banco do mapa)
=======
=======
>>>>>>> cb8e53a56d569e911da7c6bddfc64f6d657c7dca


INSERT INTO progresso_reino (id_partida, id_reino)
VALUES
(1, 1);
<<<<<<< HEAD
>>>>>>> 81678e1 (Feat: adicionando funcionalidades no mapa)
=======
>>>>>>> cb8e53a56d569e911da7c6bddfc64f6d657c7dca
