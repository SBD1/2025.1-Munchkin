from usecases.aplicar_penalidades_monstro import aplicar_penalidades
from usecases.aplicar_recompensas_monstro import aplicar_recompensas

def resolver_combate(console, cursor, id_partida, id_carta):
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
    """, (id_carta,))
    nivel_monstro = cursor.fetchone()[0]

    # Verifica quem venceu o combate
    if total_jogador >= nivel_monstro:
        console.print(f"\n[bold green]🏆 Você venceu o combate! ({total_jogador} vs {nivel_monstro})[/bold green]")
        cursor.execute("""
            UPDATE combate
            SET vitoria = TRUE
            WHERE id_partida = %s AND id_carta = %s;
        """, (id_partida, id_carta))

        aplicar_recompensas(console, cursor, id_partida, id_carta)

        # 🧭 Registrar progresso do reino vencido
        cursor.execute("""
            SELECT id_reino FROM carta_partida
            WHERE id_partida = %s AND id_carta = %s;
        """, (id_partida, id_carta))
        resultado = cursor.fetchone()

        if resultado:
            id_reino = resultado[0]
            cursor.execute("""
                INSERT INTO progresso_reino (id_partida, id_reino)
                SELECT %s, %s
                WHERE NOT EXISTS (
                    SELECT 1 FROM progresso_reino
                    WHERE id_partida = %s AND id_reino = %s
                );
            """, (id_partida, id_reino, id_partida, id_reino))

    else:
        console.print(f"\n[bold red]💥 Você perdeu o combate! ({total_jogador} vs {nivel_monstro})[/bold red]")
        console.print("⚠️ Prepare-se para sofrer a coisa ruim...")

        cursor.execute("""
            UPDATE combate
            SET vitoria = FALSE, coisa_ruim_aplicada = TRUE
            WHERE id_partida = %s AND id_carta = %s;
        """, (id_partida, id_carta))

        aplicar_penalidades(console, cursor, id_partida, id_carta)
