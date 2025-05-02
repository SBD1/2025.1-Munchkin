## Modelo Entidade-Relacionamento (MER)

O Modelo Entidade-Relacionamento (MER) é uma descrição textual das entidades e relacionamentos que compõem a estrutura de um banco de dados. Diferentemente do DER, o MER apresenta as informações de forma textual, facilitando a compreensão e detalhamento dos componentes.

## Tabelas e Atributos

### **Jogador**

- `id_jogador` (PK): Identificador único do jogador.
- `nome`: Nome do jogador.

### **Partida**

- `id_partida` (PK): Identificador único da partida.
- `id_jogador` (FK): Referência ao jogador proprietário da partida.
- `data_inicio`: Data e hora em que a partida começou.
- `turno_atual`: Número atual do turno.
- `estado_partida`: Estado da partida (ex: "em_andamento", "pausada", "encerrada").
- `primeira_rodada` (bool): Indica se está na primeira fase da partida.
- `finalizada` (bool): Define se a partida foi concluída.
- `vitoria` (bool): Define se o jogador venceu a partida.
- `nivel`: Nível atual do jogador dentro dessa partida.
- `vida_restantes`: Quantidade de vidas restantes (máx. 3).

### **CartaPartida**

- `id_carta_partida` (PK): Identificador único da relação entre carta e partida.
- `id_partida` (FK): Referência à partida onde a carta está sendo usada.
- `id_carta` (FK): Referência à carta associada.
- `zona`: Define onde a carta está na partida. Pode ser:
  - `mao`
  - `equipado`
  - `mochila`
  - `descartada`

### **Carta**

- `id_carta` (PK): Identificador único da carta.
- `nome`: Nome da carta (ex: "Elfo", "Dentadura", "Goblin Aleijado").
- `tipo_carta`: Tipo geral da carta:
  - `porta`
  - `tesouro`
- `subtipo`: Subcategoria da carta:
  - `classe`, `raça`, `item`, `monstro`
- `descricao`: Descrição da carta, visível ao jogador.
- `disponivel_para_virar`: Indica se a carta pode ser sorteada do baralho no início de um turno.

#### **CartaRaca**
- `id_carta` (PK, FK → Carta): Referência à carta que representa uma raça.
- `nome_raca`: Nome da raça (ex: Elfo, Anão, Orc, Halfling).
- `descricao`: Texto descritivo da raça.


##### **PoderRaca**
- `id_poder_raca` (PK): Identificador único do poder.
- `id_raca` (FK → CartaRaca): Referência à carta de raça que possui esse poder.
- `nome`: Nome do poder (ex: Fuga Extra, Resistência à Maldição).
- `descricao`: Descrição do efeito de alto nível.


##### **PoderFugaCondicional**
- `id_poder_raca` (PK, FK → PoderRaca): Relacionamento com o poder da raça.
- `nova_tentativa` (bool): Se permite nova tentativa de fuga.
- `condicao_tipo`: Condição exigida (ex: `descartar_carta`, `usar_item`, `sem_condicao`).
- `quantidade`: Quantidade exigida (ex: descartar 1 carta).


##### **PoderMaldicao**
- `id_poder_raca` (PK, FK → PoderRaca): Relacionamento com o poder da raça.
- `ignora_maldicao` (bool): Se pode ignorar maldições.
- `penalidade_substituta`: Penalidade aplicada no lugar da maldição (ex: perder 1 nível).
- `nivel_minimo`: Nível mínimo para a substituição (ex: 2 ou mais).


##### **PoderRecompensaCondicional**
- `id_poder_raca` (PK, FK → PoderRaca): Relacionamento com o poder da raça.
- `bonus_tipo`: Tipo de bônus recebido (ex: `tesouro_extra`, `nivel`).
- `bonus_quantidade`: Quantidade do bônus (ex: +1 tesouro).
- `condicao_tipo`: Condição para ativar (ex: `nivel_menor_que_monstro`, `multi_monstros`).


##### **PoderLimiteDeMao**
- `id_poder_raca` (PK, FK → PoderRaca): Relacionamento com o poder da raça.
- `limite_cartas_mao`: Novo limite de cartas na mão no fim do turno (ex: 6 para o Anão).

#### **CartaClasse**
- `id_carta` (PK, FK → Carta): Referência à carta que representa uma classe.
- `nome_classe`: Nome da classe (ex: Guerreiro, Mago, Clérigo).

##### **PoderClasse**
- `id_poder_classe` (PK): Identificador único do poder da classe.
- `id_carta_classe` (FK → CartaClasse): Referência à carta de classe.
- `nome`: Nome do poder.
- `descricao`: Descrição geral do efeito da classe.

##### **PoderCombate**
- `id_poder_classe` (PK, FK → PoderClasse): Referência ao poder de classe.
- `tipo_bonus`: Tipo de bônus recebido (ex: `combate`, `nivel_extra`).
- `max_cartas`: Quantidade máxima de cartas que podem ser descartadas.
- `afeta`: Quem é afetado pelo poder (ex: `monstro_morto_vivo`, `qualquer`).
- `bonus_por_carta`: Quantidade de bônus por carta descartada.

##### **PoderFuga**
- `id_poder_classe` (PK, FK → PoderClasse): Referência ao poder de classe.
- `auto_fuga` (bool): Se permite escapar automaticamente.
- `max_descartes`: Número máximo de cartas que podem ser descartadas para tentar fugir.

##### **PoderFugaComBonus**
- `id_poder_classe` (PK, FK → PoderClasse): Referência ao poder de classe.
- `bonus_por_carta`: Bônus obtido por cada carta descartada.
- `max_descartes`: Número máximo de cartas descartadas.

##### **PoderDescartaParaEfeito**
- `id_poder_classe` (PK, FK → PoderClasse): Referência ao poder de classe.
- `efeito`: Efeito ativado ao descartar as cartas (ex: "derrotar monstro").
- `max_cartas`: Número mínimo de cartas necessárias para ativar.

##### **PoderEmpateVence**
- `id_poder_classe` (PK, FK → PoderClasse): Referência ao poder de classe.
- `vence_empate` (bool): Se o jogador vence o combate em caso de empate.

##### **PoderRecuperaDescarte**
- `id_poder_classe` (PK, FK → PoderClasse): Referência ao poder de classe.
- `tipo_descarte`: Onde será feita a recuperação (ex: `descarte_porta`).
- `descarta_para_usar` (bool): Se é necessário descartar carta para ativar.
- `quantidade_descarta`: Número de cartas a descartar para recuperar.
- `permite_escolher` (bool): Se permite escolher qual carta recuperar.

#### **CartaItem**
- `id_carta` (PK, FK → Carta): Referência à carta base que representa um item.
- `bonus_combate`: Quantidade de bônus fornecido ao jogador durante combates.
- `valor_ouro`: Valor em moedas de ouro que esse item possui (usado para vendas ou conversão em níveis).
- `tipo_item`: Tipo do item (ex: `arma`, `armadura`, `acessorio`, etc.).
- `slot`: Indica onde o item pode ser equipado (ex: `cabeca`, `pe`, `corpo`, `1_mao`, `2_maos`, `nenhum`).
- `ocupacao_dupla` (bool): Indica se o item ocupa mais de um espaço de slot (ex: uma arma de duas mãos).

#### **RestricaoItem**
- `id_restricao` (PK): Identificador único da restrição.
- `id_carta_item` (FK → CartaItem): Referência ao item que possui essa restrição.
- `tipo_alvo`: Indica o tipo da restrição (`classe` ou `raca`).
- `valor_alvo`: Valor do alvo restrito (ex: `guerreiro`, `mago`, `orc`, `anao`).
- `permitido` (bool): Define se o item **só pode ser usado** (`true`) ou **não pode ser usado** (`false`) pelo alvo especificado.

#### **CartaMonstro**
- `id_carta` (PK, FK → Carta): Referência à carta que representa um monstro.
- `nivel`: Nível base do monstro.
- `pode_fugir` (bool): Indica se o jogador pode tentar fugir deste monstro.
- `recompensa`: Quantidade de tesouros recebidos ao derrotá-lo.
- `tipo_monstro`: Tipo do monstro (ex: `morto_vivo`, `demonio`, `sem_tipo`).

##### **EfeitoMonstro**
- `id_efeito_monstro` (PK): Identificador único do efeito.
- `id_carta_monstro` (FK → CartaMonstro): Referência ao monstro que possui o efeito.
- `nome`: Nome descritivo do efeito ou penalidade.
- `descricao`: Texto explicativo do efeito ou "coisa ruim".

###### **ModificadorContraAlvo**
- `id_efeito_monstro` (PK, FK → EfeitoMonstro): Referência ao efeito associado.
- `alvo_tipo`: Tipo do alvo afetado (ex: `raca`, `classe`, `jogador`).
- `alvo_valor`: Valor afetado (ex: `elfo`, `anao`, `guerreiro`).
- `bonus_combate`: Bônus de combate que o monstro recebe contra o alvo.

###### **PenalidadePerdaNivel**
- `id_efeito_monstro` (PK, FK → EfeitoMonstro): Referência ao efeito associado.
- `tipo_alvo`: Quem é afetado (ex: `jogador`, `classe`).
- `alvo`: Valor afetado (ex: `qualquer`, `nao_mago`).
- `bonus_poder`: Níveis perdidos (ex: `2`, `3`).

###### **PenalidadeItem**
- `id_efeito_monstro` (PK, FK → EfeitoMonstro): Referência ao efeito associado.
- `local_item`: Local do item afetado (ex: `cabeca`, `mao`, `corpo`).
- `remove_tudo` (bool): Se remove todos os itens daquela zona.

###### **PenalidadeTransformacao**
- `id_efeito_monstro` (PK, FK → EfeitoMonstro): Referência ao efeito associado.
- `perde_classe` (bool): Se o jogador perde sua classe.
- `perde_raca` (bool): Se o jogador perde sua raça.
- `vira_humano` (bool): Se o jogador vira humano (sem classe e raça).

###### **PenalidadeCondicional**
- `id_efeito_monstro` (PK, FK → EfeitoMonstro): Referência ao efeito associado.
- `condicao`: Condição para aplicar a penalidade (ex: `nao_mago`).
- `acao`: Ação ou penalidade resultante (ex: `perder`, `descartar`).
- `valor`: Valor específico da penalidade (ex: `classe`, `nivel`).

### **Combate**

- `id_partida` (FK): Referência à partida onde o combate ocorreu.
- `id_carta_monstro` (FK): Referência à carta do monstro enfrentado.
- `monstro_vindo_do_baralho` (bool): Indica se o monstro veio do baralho (`true`) ou da mão do jogador (`false`).
- `vitoria` (bool): Define se o jogador venceu o combate.
- `coisa_ruim_aplicada` (bool): Define se a penalidade da carta foi aplicada.
- `nivel_ganho`: Quantidade de níveis ganhos após o combate.
- `data_ocorrido`: Data e hora em que o combate foi registrado.


## Histórico de versão

| Data       | Descrição             | Autor                                       |
| ---------- | --------------------- | ------------------------------------------- |
| 25/04/2025 | Criação do artefato   | [Breno Fernandes](https://github.com/Brenofrds) |