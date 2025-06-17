def aplicar_recompensas(console, cursor, id_partida, id_carta):
    # Buscar recompensa do monstro
    cursor.execute("""
        SELECT recompensa
        FROM carta_monstro
        WHERE id_carta = %s;
    """, (id_carta,))
    recompensa = cursor.fetchone()[0]

    # Atualizar nível do jogador
    cursor.execute("""
        SELECT nivel
        FROM partida
        WHERE id_partida = %s;
    """, (id_partida,))
    nivel_atual = cursor.fetchone()[0]

    novo_nivel = nivel_atual + recompensa
    cursor.execute("""
        UPDATE partida
        SET nivel = %s
        WHERE id_partida = %s;
    """, (novo_nivel, id_partida))

    console.print(f"\n[bold yellow]🎁 Recompensa: Você ganhou +{recompensa} nível(is)! Agora está no nível {novo_nivel}.[/bold yellow]")
