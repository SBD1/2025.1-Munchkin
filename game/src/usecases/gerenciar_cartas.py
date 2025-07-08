from database import obter_cursor
from usecases.obter_detalhes_carta import buscar_detalhes_por_subtipo

from usecases.acoes_cartas import (
    tratar_equipar,
    tratar_voltar,
    tratar_venda
)

ZONAS_VALIDAS = ['mao', 'equipado', 'descartada']

def gerenciar_cartas(console, jogador_id):
    with obter_cursor() as cursor:
        # Obter partida em andamento
        cursor.execute("""
            SELECT id_partida FROM partida
            WHERE id_jogador = %s AND estado_partida = 'em andamento'
            ORDER BY id_partida DESC LIMIT 1;
        """, (jogador_id,))
        partida = cursor.fetchone()

        if not partida:
            console.print("[bold red]❌ Nenhuma partida em andamento encontrada.[/bold red]")
            return

        id_partida = partida[0]

        # Obter cartas em 'mao' e 'equipado'
        cursor.execute("""
            SELECT c.id_carta, c.nome, c.tipo_carta, c.subtipo, cp.zona
            FROM carta_partida cp
            JOIN carta c ON c.id_carta = cp.id_carta
            WHERE cp.id_partida = %s AND cp.zona IN ('mao', 'equipado')
            ORDER BY cp.zona DESC; -- Mostra equipadas primeiro
        """, (id_partida,))
        cartas = cursor.fetchall()

        if not cartas:
            console.print("[yellow]📭 Você não tem cartas para gerenciar.[/yellow]")
            return

        console.print("\n[bold magenta]🛠️ Gerenciar Cartas do Jogador:[/bold magenta]")

        zona_atual = None
        for i, (id_carta, nome, tipo, subtipo, zona) in enumerate(cartas, start=1):
            if zona != zona_atual:
                console.print(f"\n[bold yellow]🗂️ Cartas em: {zona.upper()}[/bold yellow]")
                zona_atual = zona

            console.print(f"\n{i}. [bold]{nome}[/bold] [cyan]({tipo} - {subtipo})[/cyan]")

            detalhes = buscar_detalhes_por_subtipo(cursor, id_carta, subtipo)

            if subtipo == 'item' and detalhes:
                bonus, ouro, tipo_item, slot, dupla, restricoes = detalhes
                console.print(f"   ➕ Bônus: {bonus}, 💰 Ouro: {ouro}, Tipo: {tipo_item}, Slot: {slot}, Dupla? {'Sim' if dupla else 'Não'}")
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

        try:
            escolha = int(input("\nDigite o número da carta que deseja gerenciar (0 para cancelar): "))
            if escolha == 0:
                return
            carta_escolhida = cartas[escolha - 1]
        except (ValueError, IndexError):
            console.print("[red]Entrada inválida.[/red]")
            return

        id_carta = carta_escolhida[0]
        subtipo = carta_escolhida[3]
        zona_atual = carta_escolhida[4]

        # Ações disponíveis baseadas na zona
        if zona_atual == 'mao':
            acoes = ["Equipar", "Descartar"]
            if subtipo == 'item':
                acoes.append("Vender")
        elif zona_atual == 'equipado':
            acoes = ["Voltar para a Mão"]
        else:
            acoes = []

        if not acoes:
            console.print("[red]Nenhuma ação disponível para esta carta.[/red]")
            return

        console.print("\n[bold green]Escolha uma ação:[/bold green]")
        for i, acao in enumerate(acoes, start=1):
            console.print(f"{i}. {acao}")

        try:
            acao_escolhida = int(input("Digite o número da ação desejada: "))
            if not (1 <= acao_escolhida <= len(acoes)):
                raise ValueError
        except ValueError:
            console.print("[red]Ação inválida.[/red]")
            return

        nova_zona = None
        acao = acoes[acao_escolhida - 1]

        if acao == "Equipar":
            try:
                cursor.execute("""
                    CALL equipar_carta_segura(%s, %s);
                """, (id_partida, id_carta))
                console.print("[bold green]✅ Carta equipada com sucesso![/bold green]")
            except Exception as e:
                msg = str(e).split("\n")[0]
                console.print(f"[bold red]❌ Erro ao equipar carta: {msg}[/bold red]")

        elif acao == "Voltar para a Mão":
            try:
                cursor.execute("""
                    CALL desequipar_carta_segura(%s, %s);
                """, (id_partida, id_carta))
                console.print("[bold green]🔄 Carta devolvida para a mão com sucesso![/bold green]")

                # Mostrar todos os avisos gerados por RAISE NOTICE
                if hasattr(cursor.connection, "notices"):
                    for aviso in cursor.connection.notices:
                        aviso = aviso.strip()
                        if aviso:
                            console.print(f"[blue]{aviso}[/blue]")
                    cursor.connection.notices.clear()

                nova_zona = None  # já foi tratada pela procedure
            except Exception as e:
                msg = str(e).split("\n")[0]
                console.print(f"[bold red]❌ Erro ao devolver carta para a mão: {msg}[/bold red]")

        elif acao == "Descartar":
            nova_zona = "descartada"

        elif acao == "Vender":
            nova_zona = tratar_venda(console, cursor, id_carta, subtipo, id_partida)

        # Chama mover_carta_zona_seguro APENAS se for necessário
        if nova_zona:
            try:
                cursor.execute("""
                    CALL mover_carta_zona_seguro(%s, %s, %s);
                """, (id_partida, id_carta, nova_zona))
                console.print(f"[bold green]✅ Carta movida para: {nova_zona.upper()}[/bold green]")
            except Exception as e:
                console.print(f"[bold red]❌ Erro ao mover carta: {str(e)}[/bold red]")
