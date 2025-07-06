# usecases/mostrar_status_combate_jogador.py

def mostrar_status_combate_jogador(console, cursor, id_partida):
    # 1. Obter nível atual do jogador
    cursor.execute("""
        SELECT nivel
        FROM partida
        WHERE id_partida = %s;
    """, (id_partida,))
    nivel = cursor.fetchone()[0]

    # 2. Obter bônus total de combate dos itens equipados
    cursor.execute("""
        SELECT COALESCE(SUM(ci.bonus_combate), 0)
        FROM carta_partida cp
        JOIN carta_item ci ON ci.id_carta = cp.id_carta
        WHERE cp.id_partida = %s AND cp.zona = 'equipado';
    """, (id_partida,))
    bonus = cursor.fetchone()[0]

    # 3. Obter nomes dos itens equipados (opcional)
    cursor.execute("""
        SELECT c.nome, ci.slot
        FROM carta_partida cp
        JOIN carta c ON c.id_carta = cp.id_carta
        JOIN carta_item ci ON ci.id_carta = c.id_carta
        WHERE cp.id_partida = %s AND cp.zona = 'equipado';
    """, (id_partida,))
    itens = cursor.fetchall()

    console.print("\n[bold green]🧙 Status do Jogador:[/bold green]")
    console.print(f"🔢 Nível base: [bold]{nivel}[/bold]")
    console.print(f"🛡️ Bônus de combate por itens: [bold green]+{bonus}[/bold green]")
    console.print(f"⚔️ Total de combate: [bold yellow]{nivel + bonus}[/bold yellow]")

    if itens:
        console.print("🎽 Itens equipados:")
        for nome, slot in itens:
            console.print(f"• {nome} (slot: {slot})")
    else:
        console.print("❌ Nenhum item equipado.")

