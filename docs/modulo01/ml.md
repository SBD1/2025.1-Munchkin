# Modelo Lógico

## Introdução

O Modelo Lógico é uma representação intermediária entre o Modelo Conceitual (MER) e a implementação física do banco de dados. Ele refina as entidades, atributos e relacionamentos descritos anteriormente, traduzindo-os em estruturas mais próximas das tabelas e chaves que serão implementadas em um Sistema Gerenciador de Banco de Dados (SGBD).

Nesta etapa, são definidas as tabelas, os tipos de dados, as chaves primárias (PK), as chaves estrangeiras (FK), e as restrições de integridade que garantem a consistência das informações armazenadas.


## Objetivo

O objetivo do Modelo Lógico é:

- Representar, de forma formal e estruturada, como os dados serão armazenados no banco de dados.
- Garantir a integridade relacional entre as entidades do jogo.
- Preparar o sistema para a geração dos scripts SQL que serão utilizados na criação das tabelas no banco.
- Permitir a implementação do jogo no modo solo com base nos requisitos funcionais mapeados anteriormente.

Este modelo serve como base para a implementação prática do banco de dados relacional, mantendo fidelidade à lógica de jogo e suas dinâmicas, como combates, partidas, cartas e poderes.


## Estrutura

As tabelas foram organizadas com base nas especializações de cartas (`Classe`, `Raça`, `Monstro`, `Item`) e nas interações do jogador com o ambiente, como `Partida`, `Combate`, e `CartaPartida`. Além disso, foram adicionadas tabelas auxiliares para tratar efeitos condicionais e regras específicas do jogo Munchkin no modo solo.

As próximas seções detalham individualmente cada tabela e sua finalidade.


## Modelo logico

**Figura 1 - Modelo Lógico Versão 1.0**

![Primeira versão do modelo logico](../assets/ML1.0.png)

**Fonte:** [Breno Fernandes](https://github.com/Brenofrds)

## Modelo logico

**Figura 2 - Modelo Lógico Versão 2.0**

![Segunda versão do modelo logico](../assets/Lógico_2.0.png)

**Fonte:** [Breno Fernandes](https://github.com/Brenofrds)

## Modelo logico

**Figura 3 - Modelo Lógico Versão 3.0**

![Terceira versão do modelo logico](../assets/Lógico_3.0.png)

**Fonte:** [Mylena Mendonça](https://github.com/MylenaTrindade)

## Bibliografia

> Diagrama Entidade Relacionamento Stardew Valley. Disponível em: https://github.com/SBD1/2023.2-Grupo01-StardewValley/blob/main/docs/Entrega-01/DER_StardewValley_v1.0.md. Acesso em 26 de abril de 2025.

> Diagrama Entidade Relacionamento Fear and Hunger. Disponível em: https://github.com/SBD1/2023.2_Fear_and_Hunger/blob/main/docs/modulo_01/assets/DERv/DERv2.3.png. Acesso em 26 de abril de 2025.

> Diagrama Entidade Relacionamento Cavaleiros do Zodiaco. Disponível em: https://github.com/SBD1/2024.2_Cavaleiros_do_Zodiaco/blob/main/docs/assets/der/DER%202.0.png. Acesso em 26 de abril de 2025.

## Histórico de Versão

| Data       | Descrição                          | Autor                                                                 |
|------------|------------------------------------|-----------------------------------------------------------------------|
| 25/04/2025 | Criação do artefato                | [Breno Fernandes](https://github.com/Brenofrds)                      |
| 02/05/2025 | Colaboração na construção do Modelo Logico   | [Breno Fernandes](https://github.com/Brenofrds), [Maria Clara Sena](https://github.com/mclarasenaa), [Ana Luiza](https://github.com/luluaroeira), [Mylena Mendonça](https://github.com/MylenaTrindade) |
| 07/07/2025 | Atualizações finais | [Mylena Mnedonça](https://github.com/MylenaTrindade), [Maria Clara Sena](https://github.com/mclarasenaa), [Ana Luiza](https://github.com/luluaroeira)
