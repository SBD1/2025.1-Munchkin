from datetime import datetime
from database import obter_cursor
from usecases.mostrar_regras import mostrar_regras

def ver_status(console, jogador_id):
    with obter_cursor() as cursor:
        cursor.execute("""
            SELECT nivel, vida_restantes, estado_partida, finalizada, vitoria, data_inicio, turno_atual
            FROM partida
            WHERE id_jogador = %s
            ORDER BY id_partida DESC
            LIMIT 1;
        """, (jogador_id,))
        
        partida = cursor.fetchone()
        
        if not partida:
            console.print(f"[bold red]❌ Nenhuma partida encontrada para o jogador {jogador_id}.[/bold red]")
            return

        nivel, vida, estado, finalizada, vitoria, data_inicio, turno = partida

        console.print("[bold cyan]📊 Status da Partida:[/bold cyan]")
        console.print(f"🔢 Nível: [bold green]{nivel}[/bold green]")
        console.print(f"❤️ Vidas restantes: [bold red]{vida}[/bold red] de 3")
        console.print(f"🎲 Turno atual: [bold yellow]{turno}[/bold yellow]")
        console.print(f"📅 Iniciada em: {data_inicio.strftime('%d/%m/%Y %H:%M')}")
        console.print(f"📌 Estado: [bold]{estado}[/bold]")
        console.print(f"🏁 Finalizada: {'✅' if finalizada else '❌'}")
        console.print(f"🏆 Vitória: {'🎉 Sim!' if vitoria else '😢 Ainda não'}")

def ver_carta(console, jogador_id):
    with obter_cursor() as cursor:
        # Buscar partida atual
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

        # Buscar cartas da mão
        cursor.execute("""
            SELECT c.id_carta, c.nome, c.tipo_carta, c.subtipo
            FROM carta_partida cp
            JOIN carta c ON c.id_carta = cp.id_carta
            WHERE cp.id_partida = %s AND cp.zona = 'mao';
        """, (id_partida,))
        cartas = cursor.fetchall()

        if not cartas:
            console.print("[yellow]📭 Você não tem cartas na mão.[/yellow]")
            return

        console.print("[bold magenta]🃏 Suas Cartas na Mão:[/bold magenta]")
        for i, (id_carta, nome, tipo, subtipo) in enumerate(cartas, start=1):
            console.print(f"\n{i}. [bold]{nome}[/bold] [cyan]({tipo} - {subtipo})[/cyan]")

            detalhes = buscar_detalhes_por_subtipo(cursor, id_carta, subtipo)

            if subtipo == 'item' and detalhes:
                bonus, ouro, tipo_item, slot, dupla = detalhes
                console.print(f"   ➕ Bônus: {bonus}, 💰 Ouro: {ouro}, Tipo: {tipo_item}, Slot: {slot}, Dupla? {'Sim' if dupla else 'Não'}")

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


def buscar_detalhes_por_subtipo(cursor, id_carta, subtipo):
    if subtipo == 'item':
        cursor.execute("""
            SELECT bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla
            FROM carta_item WHERE id_carta = %s
        """, (id_carta,))
        return cursor.fetchone()

    elif subtipo == 'monstro':
        cursor.execute("""
            SELECT nivel, pode_fugir, recompensa, tipo_monstro
            FROM carta_monstro WHERE id_carta = %s
        """, (id_carta,))
        info = cursor.fetchone()

        cursor.execute("""
            SELECT descricao FROM efeito_monstro
            WHERE id_carta_monstro = (SELECT id_carta_monstro FROM carta_monstro WHERE id_carta = %s)
        """, (id_carta,))
        efeitos = [row[0] for row in cursor.fetchall()]

        return (info, efeitos)

    elif subtipo == 'raca':
        # Nome da raça (opcional, só para exibir "Raça: Elfo")
        cursor.execute("""
            SELECT nome_raca FROM carta_raca WHERE id_carta = %s
        """, (id_carta,))
        resultado = cursor.fetchone()
        nome_raca = resultado[0] if resultado else "Raça desconhecida"

        # Descrição única do poder (apenas uma)
        cursor.execute("""
            SELECT descricao FROM poder_raca WHERE id_carta = %s
        """, (id_carta,))
        resultado = cursor.fetchone()
        poder = resultado[0] if resultado else None

        return (nome_raca, poder)

    elif subtipo == 'classe':
        cursor.execute("""
            SELECT nome_classe FROM carta_classe WHERE id_carta = %s
        """, (id_carta,))
        classe = cursor.fetchone()

        cursor.execute("""
            SELECT descricao FROM poder_classe WHERE id_carta_classe = %s
        """, (id_carta,))
        poderes = [row[0] for row in cursor.fetchall()]

        return (classe, poderes)

    return None


def obter_acoes_disponiveis(jogador_id):
    opcoes = [
        ("[bold green]📜 Ver Carta do joador[/bold green]", ver_carta),
        ("[bold cyan]🧙 Ver Status do Jogador[/bold cyan]", ver_status),
        ("[bold yellow]📖 Ver Regras do Jogo[/bold yellow]", lambda console, _: mostrar_regras(console)),
        ("[bold red]❌ Sair do Menu de Ações[/bold red]", None),
    ]
    return opcoes
