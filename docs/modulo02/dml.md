## Data Manipulation Language (DML)

### Introdução

O Data Manipulation Language (DML) é um subconjunto da linguagem SQL responsável por manipular os dados armazenados nas estruturas criadas pelo DDL. Segundo Elmasri e Navathe, o DML permite inserir, consultar, atualizar e excluir dados de tabelas. Este documento apresenta a inserção de dados iniciais para o sistema de gerenciamento de partidas com cartas, seguindo a mesma estrutura de versionamento definida no DDL.

### V1_insert_core_game_data 
<details><summary>Comandos</summary>

```sql

-- Inserção de jogadores
INSERT INTO jogador (nome) VALUES 
-- ('Ana Luiza Komatsu'),
-- ('Breno Fernandes'),
-- ('Maria Clara Sena'),
-- ('Mylena Trindade');

-- Inserção de partidas
INSERT INTO partida (
    id_jogador, data_inicio, turno_atual, estado_partida,
    primeira_rodada, finalizada, vitoria, nivel, vida_restantes
) VALUES
-- (1, NOW(), 1, 'em andamento', TRUE, FALSE, TRUE, 1, 3),
-- (2, NOW(), 2, 'pausada', TRUE, FALSE, FALSE, 2, 2);

-- Inserção de cartas
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

```

</details>

### V2_insert_carta_partida_data 
<details><summary>Comandos</summary>

```sql
INSERT INTO carta_partida (id_partida, id_carta, zona)
VALUES 
-- (1, 1, 'mao'),
-- (1, 2, 'mochila');

```

</details>

### V3_insert_cartas_especificas_data 
<details><summary>Comandos</summary>

```sql
-- Carta Item
INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (1, 1, 200, 'arma', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (2, 3, 0, 'acessório', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (3, 1, 200, 'armadura', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (4, 2, 400, 'armadura', 'pe', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (5, 2, 400, 'arma', '1_mao', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (6, 1, 200, 'armadura', 'cabeca', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (7, 2, 400, 'armadura', 'corpo', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (8, 3, 600, 'arma', '2_maos', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (9, 4, 600, 'armadura', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (10, 3, 400, 'acessório', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (11, 3, 400, 'armadura', 'armadura', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (12, 4, 800, 'arma', '2_maos', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (13, 3, 400, 'arma', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (14, 3, 600, 'armadura', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (15, 4, 600, 'arma', '1_mao', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (16, 4, 600, 'arma', '1_mao', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (17, 3, 400, 'cabeca', TRUE);

-- Carta Classe
INSERT INTO carta_classe (id_carta, nome_classe, descricao)
VALUES (22, 'clérigo', NULL);

INSERT INTO carta_classe (id_carta, nome_classe, descricao)
VALUES (23, 'guerreiro', NULL);

INSERT INTO carta_classe (id_carta, nome_classe, descricao)
VALUES (24, 'mago', NULL);

-- Carta Raça
INSERT INTO carta_raca (id_carta, nome_raca, descricao)
VALUES (18, 'anao', NULL);

INSERT INTO carta_raca (id_carta, nome_raca, descricao)
VALUES (19, 'elfo', NULL);

INSERT INTO carta_raca (id_carta, nome_raca, descricao)
VALUES (20, 'halfling', NULL);

INSERT INTO carta_raca (id_carta, nome_raca, descricao)
VALUES (21, 'orc', NULL);

-- Carta Monstro
INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (1, 25, 2, FALSE, 1, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (2, 26, 4, TRUE, 2, 'morto_vivo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (3, 27, 6, TRUE, 2, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (4, 28, 8, TRUE, 2, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (5, 29, 10, TRUE, 3, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (6, 30, 12, TRUE, 3, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (7, 31, 14, TRUE, 4, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (8, 32, 16, TRUE, 4, 'morto_vivo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (9, 33, 18, TRUE, 5, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (10, 34, 20, TRUE, 5, 'sem_tipo');

```

</details>

### V4_insert_poder_raca_data 
<details><summary>Comandos</summary>

```sql
-- Poderes de Raça
INSERT INTO poder_raca (id_poder_raca, id_carta, descricao)
VALUES (1, 18, 'Você ganha, uma vez por turno, 50 peças de ouro');

INSERT INTO poder_raca (id_poder_raca, id_carta, descricao)
VALUES (2, 18, 'Você pode ficar com 6 cartas na sua mão no final de seu turno');

INSERT INTO poder_raca (id_poder_raca, id_carta, descricao)
VALUES (3, 19, '+1 para fugir');

INSERT INTO poder_raca (id_poder_raca, id_carta, descricao)
VALUES (4, 19, 'Você ganha 1 Tesouro a mais para cada monstro que matar');

INSERT INTO poder_raca (id_poder_raca, id_carta, descricao)
VALUES (5, 20, 'Você ganha, uma vez por turno, 20 peças de ouro');

INSERT INTO poder_raca (id_poder_raca, id_carta, descricao)
VALUES (6, 20, 'Se você falhar em sua primeira tentativa de Fuga, pode descartar uma carta para tentar fugir novamente');

INSERT INTO poder_raca (id_poder_raca, id_carta, descricao)
VALUES (7, 21, 'Um orc que for alvo de uma maldição pode decidir ignorá-la, perdendo 1 nível em troca (a não ser que já esteja no nível 1)');

INSERT INTO poder_raca (id_poder_raca, id_carta, descricao)
VALUES (8, 21, 'Quando um orc vence um combate tendo o nível menor que o do monstro, ele sobe um nível adicional');

```

</details>

### V5_insert_poderes_raca_especificos_data 
<details><summary>Comandos</summary>

```sql
-- poder_fuga_condicional
INSERT INTO poder_fuga_condicional (id_poder_raca, nova_tentativa, quantidade, condicao_tipo)
VALUES (3, TRUE, 1, 'sem_condicao');

INSERT INTO poder_fuga_condicional (id_poder_raca, nova_tentativa, quantidade, condicao_tipo)
VALUES (6, TRUE, 1, 'descartar_carta');

-- poder_maldicao
INSERT INTO poder_maldicao (id_poder_raca, ignora_maldicao, penalidade_substituta, nivel_minimo)
VALUES (7, TRUE, 'Perde 1 nível em vez de descartar', 1);

-- poder_recompensa_condicional
INSERT INTO poder_recompensa_condicional (id_poder_raca, bonus_tipo, bonus_quantidade, condicao_tipo)
VALUES (4, 'tesouro_extra', 1, 'matar_monstro');

INSERT INTO poder_recompensa_condicional (id_poder_raca, bonus_tipo, bonus_quantidade, condicao_tipo)
VALUES (8, 'nivel', 1, 'nivel_menor_que_monstro');

-- poder_limite_de_mao
INSERT INTO poder_limite_de_mao (id_poder_raca, limite_carta_mao)
VALUES (2, 6);

-- poder_pecas_ouro
INSERT INTO poder_pecas_ouro (id_poder_raca, quantidade)
VALUES (1, 50);

INSERT INTO poder_pecas_ouro (id_poder_raca, quantidade)
VALUES (5, 20);
```

</details>

### V6_insert_poder_classe_data 
<details><summary>Comandos</summary>

```sql
-- Poder Classe
-- poder_classe
INSERT INTO poder_classe (id_poder_classe, id_carta_classe, descricao)
VALUES (1, 22, 'Você pode comprar uma carta tesouro ou porta, tendo que descartar uma outra da sua mão');

INSERT INTO poder_classe (id_poder_classe, id_carta_classe, descricao)
VALUES (2, 22, 'Você pode descartar até três cartas durante um combate contra um morto-vivo. cada carta descartada te dá até +3 de bônus');

INSERT INTO poder_classe (id_poder_classe, id_carta_classe, descricao)
VALUES (3, 23, 'Você pode descartar até 3 cartas durante o combate , cada uma te dá um bônus de +1');

INSERT INTO poder_classe (id_poder_classe, id_carta_classe, descricao)
VALUES (4, 23, 'Você vence os combates mesmo no empate');

INSERT INTO poder_classe (id_poder_classe, id_carta_classe, descricao)
VALUES (5, 24, 'Você pode descartar até três cartas enquanto estiver fugindo, cada uma delas te dá um bônus de +1 para a fuga');

INSERT INTO poder_classe (id_poder_classe, id_carta_classe, descricao)
VALUES (6, 24, 'Você pode descartar a sua mão inteira para enfeitiçar um único monstro em vez de lutar contra ele, descarte o monstro');
```

</details>


### V7_insert_poder_classe_especificos_data 
<details><summary>Comandos</summary>

```sql

-- descarta_para_efeito
INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (1, 'compra carta', 1);

INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (2, '+3 de bônus em combate contra mortos-vivos', 3);

INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (3, '+1 de bônus em combate', 3);

INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (5, '+1 de fuga em combate', 3);

INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (6, 'enfeitiçar um único monstro em vez de lutar contra ele', 0);

-- empata_vence
INSERT INTO empata_vence (id_poder_classe, vence_empata)
VALUES (4, TRUE);


```

</details>

### V8_insert_restricao_item_data 
<details><summary>Comandos</summary>

```sql
INSERT INTO restricao_item (id_carta_item, tipo_alvo, valor_alvo, permitido)
VALUES (17, 'classe', 'mago', TRUE);

INSERT INTO restricao_item (id_carta_item, tipo_alvo, valor_alvo, permitido)
VALUES (14, 'classe', 'guerreiro', FALSE);

INSERT INTO restricao_item (id_carta_item, tipo_alvo, valor_alvo, permitido)
VALUES (15, 'classe', 'guerreiro', TRUE);

INSERT INTO restricao_item (id_carta_item, tipo_alvo, valor_alvo, permitido)
VALUES (10, 'classe', 'clérigo', TRUE);

INSERT INTO restricao_item (id_carta_item, tipo_alvo, valor_alvo, permitido)
VALUES (12, 'raca', 'elfo', TRUE);

INSERT INTO restricao_item (id_carta_item, tipo_alvo, valor_alvo, permitido)
VALUES (13, 'raca', 'halfling', TRUE);

INSERT INTO restricao_item (id_carta_item, tipo_alvo, valor_alvo, permitido)
VALUES (11, 'raca', 'anao', TRUE);

INSERT INTO restricao_item (id_carta_item, tipo_alvo, valor_alvo, permitido)
VALUES (16, 'raca', 'orc', TRUE);

```

</details>

### V9_insert_efeito_monstro_data 
<details><summary>Comandos</summary>

```sql
INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (1, 1, 'Elas mordem! Você perde 2 níveis');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (2, 2, 'Fede, morde e dá coises. Você perde 2 níveis');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (3, 3, 'Você se torna um humano chato e normal. Perde todas as cartas de classe e raça que estiver em jogo');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (4, 4, 'Quando ele chupar a sua cara, levará junto o que estiver usando na cabeça. Descarte tudo que estiver usando na cabeça e perca 1 nível');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (5, 5, 'Você perde 4 níveis');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (6, 6, 'Te pisoteia e come seu chapéu. Você perde qualquer coisa que estiver usando na cabeça');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (7, 7, 'Uma morte terrível aguarda a todos que não conseguirem enfrentá-lo');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (8, 8, 'Você perde todos os itens equipados e todas as cartas de sua mão');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (9, 9, 'Você é esfolado até a morte');

INSERT INTO efeito_monstro (id_efeito_monstro, id_carta_monstro, descricao)
VALUES (10, 10, 'Você é assado e devorado. Está morto!');

```

</details>

### V10_insert_efeitos_monstros_especificos_data
<details><summary>Comandos</summary>

```sql
-- penalidade_perda_nivel
INSERT INTO penalidade_perda_nivel (id_efeito_monstro, niveis)
VALUES (1, 2);

INSERT INTO penalidade_perda_nivel (id_efeito_monstro, niveis)
VALUES (2, 2);

INSERT INTO penalidade_perda_nivel (id_efeito_monstro, niveis)
VALUES (4, 1);

INSERT INTO penalidade_perda_nivel (id_efeito_monstro, niveis)
VALUES (5, 4);

-- penalidade_item
INSERT INTO penalidade_item (id_efeito_monstro, local_item, remove_tudo)
VALUES (4, 'cabeca', FALSE);

INSERT INTO penalidade_item (id_efeito_monstro, local_item, remove_tudo)
VALUES (6, 'cabeca', FALSE);

INSERT INTO penalidade_item (id_efeito_monstro, local_item, remove_tudo)
VALUES (8, 'todos', TRUE);

-- penalidade_transformacao
INSERT INTO penalidade_transformacao (id_efeito_monstro, perde_classe, perde_raca, vira_humano)
VALUES (3, TRUE, TRUE, TRUE);

-- penalidade_morte
INSERT INTO penalidade_morte (id_efeito_monstro, morte)
VALUES (7, TRUE);

INSERT INTO penalidade_morte (id_efeito_monstro, morte)
VALUES (9, TRUE);

INSERT INTO penalidade_morte (id_efeito_monstro, morte)
VALUES (10, TRUE);
```

</details>

### V11_insert_combate_data 
<details><summary>Comandos</summary>

```sql
INSERT INTO combate (id_partida, id_carta_monstro, monstro_vindo_do_baralho, vitoria, coisa_ruim_aplicada, nivel_ganho, data_ocorrido)
-- VALUES (1, 3, TRUE, TRUE, FALSE, 1, NOW());
```

</details>

### Referência Bibliográfica

> [1] ELMASRI, Ramez; NAVATHE, Shamkant B. Sistemas de banco de dados. Tradução: Daniel Vieira. Revisão técnica: Enzo Seraphim; Thatyana de Faria Piola Seraphim. 6. ed. São Paulo: Pearson Addison Wesley, 2011.


### Versionamento

| Versão | Data | Modificação | Autor |
| --- | --- | --- | --- |
|  0.1 | 2/06/2025 | Criação do Documento | Ana Luiza Komatsu |