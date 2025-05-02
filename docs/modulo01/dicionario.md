# Dicionário de Dados

## Introdução

O dicionário de dados descreve detalhadamente a estrutura do banco de dados do projeto, incluindo os nomes das tabelas, atributos, tipos de dados, valores permitidos, chaves primárias e estrangeiras, e restrições de domínio. Essa documentação é essencial para garantir consistência, integridade e clareza no desenvolvimento e manutenção do sistema.

## Objetivo

O objetivo deste dicionário é fornecer uma referência completa das tabelas utilizadas no banco de dados do jogo **Munchkin – Modo Solo**, com foco na definição dos campos, seus tipos e regras de negócio associadas, promovendo assim maior organização e entendimento técnico do modelo lógico.

## Estrutura

Para cada tabela serão apresentados:

- **Nome da Tabela**
- **Descrição**: Função principal da tabela no sistema.
- **Observações**: Regras adicionais ou dependências com outras tabelas.
- **Tabela de Campos**:
  - **Nome**: Nome do campo.
  - **Descrição**: Significado e uso do campo.
  - **Tipo de Dado**: Tipo armazenado (ex: INTEGER, VARCHAR, BOOLEAN, etc.).
  - **Valores Permitidos**: Enumerações ou intervalos aceitos.
  - **Chave**: Indicação se é PK (chave primária) ou FK (chave estrangeira).
  - **Restrições de Domínio**: Regras adicionais (ex: not null, unique, etc.).

---

A seguir, cada entidade será documentada em uma tabela com suas respectivas características.

## Tabelas e Relações

### Tabela: **Jogador**
![Tabela Jogador](../assets/Jogador.png)

### Tabela: **Partida**
![Tabela Partida](../assets/Partida.png)

### Tabela: **Carta**
![Tabela Carta](../assets/Carta.png)

### Tabela: **CartaPartida**
![Tabela CartaPartida](../assets/CartaPartida.png)

### Tabela: **CartaRaca**
![Tabela CartaRaca](../assets/CartaRaca.png)

### Tabela: **PoderRaca**
![Tabela PoderRaca](../assets/PoderRaca.png)

### Tabela: **PoderFugaCondicional**
![Tabela PoderFugaCondicional](../assets/PoderFugaCondicional.png)

### Tabela: **PoderMaldicao**
![Tabela PoderMaldicao](../assets/PoderMaldicao.png)

### Tabela: **PoderRecompensaCondicional**
![Tabela PoderRecompensaCondicional](../assets/PoderRecompensaCondicional.png)

### Tabela: **PoderLimiteDeMao**
![Tabela PoderLimiteDeMao](../assets/PoderLimiteDeMao.png)

### Tabela: **CartaClasse**
![Tabela CartaClasse](../assets/CartaClasse.png)

### Tabela: **PoderClasse**
![Tabela PoderClasse](../assets/PoderClasse.png)

### Tabela: **PoderCombate**
![Tabela PoderCombate](../assets/PoderCombate.png)

### Tabela: **PoderFuga**
![Tabela PoderFuga](../assets/PoderFuga.png)

### Tabela: **PoderFugaComBonus**
![Tabela PoderFugaComBonus](../assets/PoderFugaComBonus.png)

### Tabela: **PoderDescartaParaEfeito**
![Tabela PoderDescartaParaEfeito](../assets/PoderDescartaParaEfeito.png)

### Tabela: **PoderRecuperaDescarte**
![Tabela PoderRecuperaDescarte](../assets/PoderRecuperaDescarte.png)

### Tabela: **PoderEmpateVence**
![Tabela PoderEmpateVence](../assets/PoderEmpateVence.png)

### Tabela: **CartaItem**
![Tabela CartaItem](../assets/CartaItem.png)

### Tabela: **RestricaoItem**
![Tabela RestricaoItem](../assets/RestricaoItem.png)

### Tabela: **CartaMonstro**
![Tabela CartaMonstro](../assets/CartaMonstro.png)

### Tabela: **EfeitoMonstro**
![Tabela EfeitoMonstro](../assets/EfeitoMonstro.png)

### Tabela: **ModificadorContraAlvo**
![Tabela ModificadorContraAlvo](../assets/ModificadorContraAlvo.png)

### Tabela: **PenalidadePerdaNivel**
![Tabela PenalidadePerdaNivel](../assets/PenalidadePerdaNivel.png)

### Tabela: **PenalidadeItem**
![Tabela PenalidadeItem](../assets/PenalidadeItem.png)

### Tabela: **PenalidadeTransformacao**
![Tabela PenalidadeTransformacao](../assets/PenalidadeTranformacao.png)

### Tabela: **PenalidadeCondicional**
![Tabela PenalidadeCondicional](../assets/PenalidadeCondicional.png)

### Tabela: **Combate**
![Tabela Combate](../assets/Combate.png)

## Histórico de Versão

| Data       | Descrição                              | Autor                                                                 |
|------------|----------------------------------------|-----------------------------------------------------------------------|
| 25/04/2025 | Criação do artefato                    | [Breno Fernandes](https://github.com/Brenofrds)                      |
| 02/05/2025 | Colaboração na construção do dicionário de dados |[Breno Fernandes](https://github.com/Brenofrds),[Maria Clara Sena](https://github.com/mclarasena), [Ana Luiza](https://github.com/luluaroeira), [Mylena Mendonça](https://github.com/MylenaTrindade) |
