from usecases.obter_detalhes_carta import buscar_detalhes_por_subtipo

ZONAS = ['mao', 'equipado', 'descartada']

def ver_cartas_por_zona(console, jogador_id):
    from database import obter_cursor
    with obter_cursor() as cursor:
        # Buscar a partida atual do jogador
        cursor.execute("""
            SELECT id_partida FROM partida
            WHERE id_jogador = %s AND estado_partida = 'em andamento'
            ORDER BY id_partida DESC LIMIT 1;
        """, (jogador_id,))
        resultado = cursor.fetchone()

        if not resultado:
            console.print("[bold red]❌ Nenhuma partida em andamento encontrada.[/bold red]")
            return

        id_partida = resultado[0]

        emoji_zona = {
            'mao': '🖐️',
            'equipado': '🛡️',
            'descartada': '🗑️'
        }

        for zona in ZONAS:
            # Buscar cartas daquela zona
            cursor.execute("""
                SELECT c.id_carta, c.nome, c.tipo_carta, c.subtipo
                FROM carta_partida cp
                JOIN carta c ON c.id_carta = cp.id_carta
                WHERE cp.id_partida = %s AND cp.zona = %s;
            """, (id_partida, zona))
            cartas = cursor.fetchall()

            console.print(f"\n[bold magenta]{emoji_zona[zona]} Cartas em: {zona.upper()}[/bold magenta]")

            if not cartas:
                console.print(f"[italic yellow]Você não tem nenhuma carta em {zona}.[/italic yellow]")
                continue

            for i, (id_carta, nome, tipo, subtipo) in enumerate(cartas, start=1):
                console.print(f"\n{i}. [bold]{nome}[/bold] [cyan]({tipo} - {subtipo})[/cyan]")

                detalhes = buscar_detalhes_por_subtipo(cursor, id_carta, subtipo)

                if subtipo == 'item' and detalhes:
                    bonus, ouro, tipo_item, slot, dupla, restricoes = detalhes
                    console.print(f"   ➕ Bônus: {bonus}, 💰 Ouro: {ouro}, Tipo: {tipo_item}, Slot: {slot}")

                    if restricoes:
                        for tipo_alvo, valor_alvo, permitido in restricoes:
                            emoji = "✅" if permitido else "🚫"
                            console.print(f"   {emoji} {'Somente' if permitido else 'Exceto'} para {tipo_alvo.upper()}: {valor_alvo}")

                elif subtipo == 'monstro' and detalhes:
                    (nivel, pode_fugir, recompensa, tipo_monstro), efeitos = detalhes
                    console.print(f"   👹 Nível: {nivel}, 🎁 Recompensa: {recompensa}, Fuga? {'Sim' if pode_fugir else 'Não'}, Tipo: {tipo_monstro}")
                    for ef in efeitos:
                        console.print(f"   ⚠️ Efeito: {ef}")

                elif subtipo == 'raca' and detalhes:
                    nome_raca, poder = detalhes
                    console.print(f"   🧬 Raça: {nome_raca}")
                    if poder:
                        console.print(f"   ✨ Poder: {poder}")

                elif subtipo == 'classe' and detalhes:
                    (nome_classe,), poderes = detalhes
                    console.print(f"   🛡️ Classe: {nome_classe}")
                    for p in poderes:
                        console.print(f"   ✨ Poder: {p}")

        input("[green]✅ Pressione ENTER para continuar...[/green]")
