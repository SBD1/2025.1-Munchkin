## Data Definition Language (DDL)

### Introdução

O Data Definition Language (DDL) é um subconjunto da linguagem SQL, responsável pela definição e manipulação da estrutura de um banco de dados. Segundo Elmasri e Navathe, no livro "Sistemas de Banco de Dados", o DDL permite criar, modificar e remover elementos da estrutura de um banco, como tabelas, esquemas, visões e restrições de integridade. Esse conjunto de comandos define o formato e a organização dos dados, garantindo coerência e segurança na manipulação das informações.

### Objetivos

Este documento descreve a implementação e o uso da linguagem DDL no sistema, explicando suas funções, vantagens e aplicabilidade no contexto da administração de dados. As migrações realizadas por meio do DDL viabilizam uma estrutura sólida para o banco, permitindo a criação, atualização e gerenciamento das tabelas e demais componentes essenciais para o funcionamento do jogo.

### V0_init

Define o papel "user" com permissões no banco de dados e no esquema "public".

<details>
    <summary>Migrações</summary>

    ```sql
    -- Cria um usuário de aplicação com superpoderes (para facilitar o desenvolvimento)
    CREATE ROLE "aplicacao" WITH SUPERUSER LOGIN PASSWORD 'sbd1_2024.2@munchkin';

    -- Permite que ele se conecte ao banco munchkin
    GRANT CONNECT ON DATABASE munchkin TO "aplicacao";

    -- Permite que ele use o schema public (onde as tabelas serão criadas)
    GRANT USAGE ON SCHEMA public TO "aplicacao";

    -- Dá permissões totais sobre tabelas, sequências e funções
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "aplicacao";
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "aplicacao";
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO "aplicacao";

    -- Garante que novas tabelas criadas automaticamente deem esses mesmos privilégios
    ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT ALL ON TABLES TO "aplicacao";

    ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT ALL ON SEQUENCES TO "aplicacao";

    ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT ALL ON FUNCTIONS TO "aplicacao";
    ```

</details>

### V1_create_core_game_tables

Cria as tabelas principais do sistema de gerenciamento de partidas: Jogador, Partida e Carta, com seus respectivos atributos e relacionamentos via chave estrangeira.

<details>
    <summary>Migrações</summary>

    ```sql
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


    ```

</details>

### V2_create_carta_partida_table

Cria a tabela CartaPartida e define o relacionamento com Carta e Partida.

<details>
    <summary>Migrações</summary>

    ```sql
    CREATE TYPE enum_zona AS ENUM ('mao', 'equipado', 'mochila', 'descartada');

    CREATE TABLE carta_partida (
        id_carta_partida SERIAL PRIMARY KEY,
        id_partida INT NOT NULL,
        id_carta INT NOT NULL,
        zona enum_zona NOT NULL,
        FOREIGN KEY (id_partida) REFERENCES partida(id_partida),
        FOREIGN KEY (id_carta) REFERENCES carta(id_carta));
    ```

</details>

### V3_create_cartas_especificas_table

Cria as tabelas especializadas CartaRaca, CartaClasse, CartaItem e CartaMonstro, relacionando cada uma delas à tabela Carta.

<details>
    <summary>Migrações</summary>

    ```sql

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
        ocupacao_dupla BOOLEAN DEFAULT FALSE,
        slot VARCHAR(20),
        FOREIGN KEY (slot) REFERENCES slot_equipamento(nome),
        FOREIGN KEY (id_carta) REFERENCES carta(id_carta));

    CREATE TABLE carta_monstro (
        id_carta_monstro SERIAL PRIMARY KEY,
        id_carta INT UNIQUE NOT NULL,
        nivel INT,
        pode_fugir BOOLEAN,
        recompensa INT,
        tipo_monstro VARCHAR(50) CHECK (tipo_monstro IN ('morto_vivo', 'sem_tipo')),
        FOREIGN KEY (id_carta) REFERENCES carta(id_carta));
        
    ```

</details>

### V4_create_poder_raca_tables

Cria a tabela PoderRaca que possui relação com a CartaRaca.

<details>
    <summary>Migrações</summary>

    ```sql
    CREATE TABLE poder_raca (
        id_poder_raca SERIAL PRIMARY KEY,
        id_carta INT NOT NULL,
        descricao VARCHAR(200),
        FOREIGN KEY (id_carta) REFERENCES carta_raca(id_carta));
    ```

</details>

### V5_create_poderes_raca_especificos_table

Cria as tabelas especializadas de `poder_raca`, que detalham os tipos específicos de habilidades que podem estar associadas a uma raça. Todas elas herdam o `id_poder_raca` como chave primária e estrangeira.

<details>
    <summary>Migrações</summary>

    ```sql
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

    -- Controle de uso do poder de venda multiplicada por turno
    CREATE TABLE uso_poder_venda (
        id_partida INT REFERENCES partida(id_partida),
        id_carta INT REFERENCES carta(id_carta),
        turno INT,
        usos INT DEFAULT 0,
        PRIMARY KEY (id_partida, id_carta, turno)
    );

  ```

</details>


</details>

### V6_create_poder_classe

Cria a tabela `poder_classe`, associada às cartas do subtipo classe, e define o relacionamento com `carta_classe`.

<details>
  <summary>Migrações</summary>

    ```sql
    CREATE TABLE poder_classe (
        id_poder_classe INT PRIMARY KEY,
        id_carta_classe INT,
        descricao VARCHAR(200),

        FOREIGN KEY (id_carta_classe) REFERENCES carta_classe(id_carta)
    );
    ```

</details>

### V7_create_poder_classe_especificos_table
Cria as tabelas especializadas de `poder_classe`, detalhando os tipos específicos de habilidades relacionadas a classe.

<details>
  <summary>Migrações</summary>

    ```sql
    CREATE TABLE descarta_para_efeito (
        id_poder_classe INT PRIMARY KEY,
        efeito VARCHAR(100),
        max_cartas INT,

        FOREIGN KEY (id_poder_classe) REFERENCES poder_classe(id_poder_classe)
    );

    CREATE TABLE empata_vence (
        id_poder_classe INT PRIMARY KEY,
        vence_empata BOOLEAN DEFAULT FALSE,

        FOREIGN KEY (id_poder_classe) REFERENCES poder_classe(id_poder_classe)
    );
    ```

</details>

### V8_create_restricao_item_table

Cria a tabela `restricao_item`, que define as restrições de uso dos itens com base em raça ou classe. Relaciona-se diretamente com a tabela `carta_item`.

<details>
  <summary>Migrações</summary>

    ```sql
    CREATE TABLE restricao_item (
        id_restricao SERIAL PRIMARY KEY,
        id_carta_item INT REFERENCES carta_item(id_carta),
        tipo_alvo VARCHAR(20) CHECK (tipo_alvo IN ('raca', 'classe')),
        valor_alvo VARCHAR(50) CHECK (valor_alvo IN ('mago', 'anao', 'guerreiro', 'orc')),
        permitido BOOLEAN
    );
    ```

</details>

### V9_create_efeito_monstro_table

Cria a tabela `efeito_monstro`, que define os efeitos associados a cartas de monstro.

<details>
  <summary>Migrações</summary>

    ```sql
    CREATE TABLE efeito_monstro (
        id_efeito_monstro SERIAL PRIMARY KEY,
        id_carta_monstro INTEGER REFERENCES carta_monstro(id_carta),
        descricao TEXT
    );
    ```

</details>

### V10_create_efeitos_monstros_especificos_table

Cria tabelas especializadas para os efeitos de monstro, como modificadores, penalidades e condições específicas.

<details>
  <summary>Migrações</summary>

    ```sql
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
        perde_raca BOOLEAN NOT NULL DEFAULT FALSE,
        vira_humano BOOLEAN NOT NULL DEFAULT FALSE
    );

    CREATE TABLE penalidade_morte (
        id_efeito_monstro INTEGER PRIMARY KEY REFERENCES efeito_monstro(id_efeito_monstro),
        morte BOOLEAN NOT NULL DEFAULT FALSE
    );
    ```

</details>

### V11_create_combate_table

Cria a tabela `combate`, que registra os dados dos combates entre jogadores e monstros durante as partidas.

<details>
  <summary>Migrações</summary>

    ```sql
    CREATE TABLE combate (
        id_combate SERIAL PRIMARY KEY,
        id_partida INT NOT NULL,
        id_carta INT NOT NULL,
        monstro_vindo_do_baralho BOOLEAN,
        vitoria BOOLEAN,
        coisa_ruim_aplicada BOOLEAN,
        nivel_ganho INT,
        data_ocorrido TIMESTAMP,
        FOREIGN KEY (id_partida) REFERENCES partida(id_partida),
        FOREIGN KEY (id_carta) REFERENCES carta(id_carta)
        );
    ```

</details>

---

## Referência Bibliográfica

> [1] ELMASRI, Ramez; NAVATHE, Shamkant B. Sistemas de banco de dados. Tradução: Daniel Vieira. Revisão técnica: Enzo Seraphim; Thatyana de Faria Piola Seraphim. 6. ed. São Paulo: Pearson Addison Wesley, 2011.

---

### Versionamento

| Versão | Data | Modificação | Autor |
| --- | --- | --- | --- |
| 0.1 | 14/05/2025 | Criação do Documento | Maria Clara |
| 1.0 | 26/05/2025 | Atualização do DDL | Maria Clara e Breno Fernandes |
| 2.0 | 03/06/2025 | Atualização do DDL | Ana Luiza Komatsu |
| 3.0 | 11/06/2025 | Ajustes do DDL | Mylena Mendonça |
| 4.0 | 11/06/2025 | Ajustes do DDL para a segunda entrega | Mylena Mendonça |