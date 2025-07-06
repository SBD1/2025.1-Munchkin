def aplicar_penalidades(console, cursor, id_partida, id_carta):
    cursor.execute("""
        SELECT id_efeito_monstro
        FROM efeito_monstro
        WHERE id_carta_monstro = %s;
    """, (id_carta,))
    resultado = cursor.fetchone()

    if not resultado:
        return

    id_efeito = resultado[0]

    aplicar_penalidade_item(console, cursor, id_partida, id_efeito)
    aplicar_penalidade_transformacao(console, cursor, id_partida, id_efeito)
    aplicar_penalidade_perda_nivel(console, cursor, id_partida, id_efeito)
    aplicar_penalidade_morte(console, cursor, id_partida, id_efeito)


def aplicar_penalidade_item(console, cursor, id_partida, id_efeito):
    cursor.execute("""
        SELECT local_item
        FROM penalidade_item
        WHERE id_efeito_monstro = %s;
    """, (id_efeito,))
    penalidade_item = cursor.fetchone()

    if not penalidade_item:
        return

    local_item = penalidade_item[0]

    if local_item.strip().lower() == 'todos':
        console.print("\n[bold red]💥 Penalidade: Você perdeu todos os itens equipados![/bold red]")
        cursor.execute("""
            DELETE FROM carta_partida
            WHERE id_partida = %s AND zona = 'equipado';
        """, (id_partida,))
    else:
        console.print(f"\n[bold red]💥 Penalidade: Você perdeu o item equipado no slot {local_item}.[/bold red]")
        cursor.execute("""
            DELETE FROM carta_partida
            WHERE id_partida = %s AND zona = 'equipado'
            AND id_carta IN (
                SELECT ci.id_carta
                FROM carta_item ci
                WHERE ci.slot = %s
            );
        """, (id_partida, local_item))


def aplicar_penalidade_transformacao(console, cursor, id_partida, id_efeito):
    cursor.execute("""
        SELECT perde_classe, perde_raca
        FROM penalidade_transformacao
        WHERE id_efeito_monstro = %s;
    """, (id_efeito,))
    penalidade = cursor.fetchone()

    if not penalidade:
        return

    perde_classe, perde_raca = penalidade

    if perde_classe:
        console.print("\n[bold red]💥 Penalidade: Você perdeu sua classe![/bold red]")
        cursor.execute("""
            DELETE FROM carta_partida
            WHERE id_partida = %s AND zona = 'equipado'
            AND id_carta IN (
                SELECT id_carta FROM carta WHERE subtipo = 'classe'
            );
        """, (id_partida,))

    if perde_raca:
        console.print("\n[bold red]💥 Penalidade: Você perdeu sua raça![/bold red]")
        cursor.execute("""
            DELETE FROM carta_partida
            WHERE id_partida = %s AND zona = 'equipado'
            AND id_carta IN (
                SELECT id_carta FROM carta WHERE subtipo = 'raca'
            );
        """, (id_partida,))


def aplicar_penalidade_morte(console, cursor, id_partida, id_efeito):
    cursor.execute("""
        SELECT morte
        FROM penalidade_morte
        WHERE id_efeito_monstro = %s;
    """, (id_efeito,))
    resultado = cursor.fetchone()

    if not resultado or not resultado[0]:
        return

    console.print("\n[bold red]💀 Penalidade: Você morreu! Todos os seus itens, cartas e poderes foram perdidos.[/bold red]")
    console.print("[bold red]⛔ Sua partida foi encerrada por morte. Consulte o histórico para detalhes.[/bold red]")

    cursor.execute("""
        DELETE FROM carta_partida
        WHERE id_partida = %s AND zona IN ('mao', 'equipado', 'mochila');
    """, (id_partida,))

    cursor.execute("""
        UPDATE partida
        SET estado_partida = 'encerrada',
            finalizada = TRUE,
            vitoria = FALSE
        WHERE id_partida = %s;
    """, (id_partida,))


def aplicar_penalidade_perda_nivel(console, cursor, id_partida, id_efeito):
    cursor.execute("""
        SELECT niveis
        FROM penalidade_perda_nivel
        WHERE id_efeito_monstro = %s;
    """, (id_efeito,))
    resultado = cursor.fetchone()

    if not resultado:
        return

    niveis_a_perder = resultado[0]

    cursor.execute("""
        SELECT nivel
        FROM partida
        WHERE id_partida = %s;
    """, (id_partida,))
    nivel_atual = cursor.fetchone()[0]

    novo_nivel = max(1, nivel_atual - niveis_a_perder)
    console.print(f"\n[bold red]💥 Penalidade: Você perdeu {nivel_atual - novo_nivel} nível(is)![/bold red]")

    cursor.execute("""
        UPDATE partida
        SET nivel = %s
        WHERE id_partida = %s;
    """, (novo_nivel, id_partida))
