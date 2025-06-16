# usecases/resolver_combate.py

def resolver_combate(console, cursor, id_partida, id_carta_monstro):
    # Buscar nível do jogador
    cursor.execute("""
        SELECT nivel FROM partida WHERE id_partida = %s;
    """, (id_partida,))
    nivel_jogador = cursor.fetchone()[0]

    # Buscar bônus total do jogador
    cursor.execute("""
        SELECT COALESCE(SUM(ci.bonus_combate), 0)
        FROM carta_partida cp
        JOIN carta_item ci ON ci.id_carta = cp.id_carta
        WHERE cp.id_partida = %s AND cp.zona = 'equipado';
    """, (id_partida,))
    bonus = cursor.fetchone()[0]
    total_jogador = nivel_jogador + bonus

    # Buscar nível do monstro
    cursor.execute("""
        SELECT nivel FROM carta_monstro WHERE id_carta = %s;
    """, (id_carta_monstro,))
    nivel_monstro = cursor.fetchone()[0]

    # Comparação
    if total_jogador >= nivel_monstro:
        console.print(f"\n[bold green]🏆 Você venceu o combate! ({total_jogador} vs {nivel_monstro})[/bold green]")
        cursor.execute("""
            UPDATE combate
            SET vitoria = TRUE
            WHERE id_partida = %s AND id_carta = %s;
        """, (id_partida, id_carta_monstro))
    else:
        console.print(f"\n[bold red]💥 Você perdeu o combate! ({total_jogador} vs {nivel_monstro})[/bold red]")
        console.print("⚠️ Prepare-se para sofrer a coisa ruim...")

        cursor.execute("""
            UPDATE combate
            SET vitoria = FALSE, coisa_ruim_aplicada = TRUE
            WHERE id_partida = %s AND id_carta = %s;
        """, (id_partida, id_carta_monstro))

        # Obter o id_efeito_monstro associado a essa carta
        cursor.execute("""
            SELECT em.id_efeito_monstro
            FROM efeito_monstro em
            JOIN carta_monstro cm ON cm.id_carta_monstro = em.id_carta_monstro
            WHERE cm.id_carta = %s;
        """, (id_carta_monstro,))
        resultado = cursor.fetchone()

        if resultado:
            id_efeito = resultado[0]

            # Verificar se existe penalidade de item
            cursor.execute("""
                SELECT local_item
                FROM penalidade_item
                WHERE id_efeito_monstro = %s;
            """, (id_efeito,))
            penalidade_item = cursor.fetchone()

            if penalidade_item:
                local_item = penalidade_item[0]

                if local_item == 'todos':
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

