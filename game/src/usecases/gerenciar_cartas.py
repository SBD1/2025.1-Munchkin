from database import obter_cursor
from usecases.obter_detalhes_carta import buscar_detalhes_por_subtipo

from usecases.acoes_cartas import (
    tratar_equipar,
    tratar_voltar,
    tratar_venda
)

ZONAS_VALIDAS = ['mao', 'equipado', 'descartada']

def mostrar_detalhes_formatados(console, subtipo, detalhes):
    """Função auxiliar para mostrar detalhes formatados de uma carta"""
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

        # Mostrar cartas disponíveis para gerenciar (mão + equipadas)
        cursor.execute("""
            SELECT c.id_carta, c.nome, c.tipo_carta, c.subtipo, cp.zona
            FROM carta_partida cp
            JOIN carta c ON c.id_carta = cp.id_carta
            WHERE cp.id_partida = %s AND cp.zona IN ('mao', 'equipado')
            ORDER BY cp.zona DESC, c.nome;
        """, (id_partida,))
        cartas = cursor.fetchall()

        if not cartas:
            console.print("[yellow]📭 Você não tem cartas para gerenciar (mão ou equipadas).[/yellow]")
            return

        console.print("\n[bold magenta]🛠️ Gerenciar Cartas:[/bold magenta]")
        
        # Separar cartas por zona para melhor visualização
        cartas_mao = []
        cartas_equipadas = []
        
        for i, (id_carta, nome, tipo, subtipo, zona) in enumerate(cartas):
            if zona == 'mao':
                cartas_mao.append((i+1, id_carta, nome, tipo, subtipo))
            elif zona == 'equipado':
                cartas_equipadas.append((i+1, id_carta, nome, tipo, subtipo))
        
        # Mostrar cartas da mão
        if cartas_mao:
            console.print("\n[bold cyan]🖐️ Na Mão:[/bold cyan]")
            for i, id_carta, nome, tipo, subtipo in cartas_mao:
                console.print(f"\n{i}. [bold]{nome}[/bold] [cyan]({tipo} - {subtipo})[/cyan]")
                # Buscar e mostrar detalhes da carta
                detalhes = buscar_detalhes_por_subtipo(cursor, id_carta, subtipo)
                mostrar_detalhes_formatados(console, subtipo, detalhes)
        
        # Mostrar cartas equipadas
        if cartas_equipadas:
            console.print("\n[bold green]🛡️ Equipadas:[/bold green]")
            for i, id_carta, nome, tipo, subtipo in cartas_equipadas:
                console.print(f"\n{i}. [bold]{nome}[/bold] [green]({tipo} - {subtipo}) - EQUIPADA[/green]")
                # Buscar e mostrar detalhes da carta
                detalhes = buscar_detalhes_por_subtipo(cursor, id_carta, subtipo)
                mostrar_detalhes_formatados(console, subtipo, detalhes)
        try:
            escolha = int(input(f"\nDigite o número da carta (1-{len(cartas)}) ou 0 para cancelar: "))
            if escolha == 0:
                return
            carta_escolhida = cartas[escolha - 1]
        except (ValueError, IndexError):
            console.print("[red]Entrada inválida.[/red]")
            return

        id_carta = carta_escolhida[0]
        subtipo = carta_escolhida[3]
        zona_atual = carta_escolhida[4]  # Nova informação sobre a zona atual

        # Ações baseadas na zona atual da carta
        if zona_atual == 'mao':
            acoes = ["Equipar", "Descartar"]
            if subtipo == 'item':
                acoes.append("Vender")
        elif zona_atual == 'equipado':
            acoes = ["Desequipar (Voltar para Mão)", "Descartar"]
            if subtipo == 'item':
                acoes.append("Vender")

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
            nova_zona = tratar_equipar(console, cursor, id_carta, subtipo, id_partida)

        elif acao in ("Voltar para a Mão", "Desequipar (Voltar para Mão)"):
            nova_zona = tratar_voltar(console, cursor, id_carta, subtipo, id_partida)

        elif acoes[acao_escolhida - 1] == "Descartar":
            nova_zona = "descartada"

        elif acao == "Vender":
            nova_zona = tratar_venda(console, cursor, id_carta, subtipo, id_partida)

        # ETAPA 1: Usar function segura em vez de UPDATE direto perigoso
        if nova_zona:
            try:
                cursor.execute("""
                    SELECT sucesso, mensagem, zona_anterior, zona_atual
                    FROM mover_carta_segura(%s, %s, %s);
                """, (id_partida, id_carta, nova_zona))
                
                resultado = cursor.fetchone()
                if not resultado:
                    console.print("[red]❌ Erro: Não foi possível processar a movimentação.[/red]")
                    return
                    
                sucesso, mensagem, zona_anterior, zona_atual = resultado
                
                if sucesso:
                    console.print(f"[bold green]✅ {mensagem}[/bold green]")
                else:
                    console.print(f"[red]❌ {mensagem}[/red]")
                    
            except Exception as e:
                error_message = str(e)
                if "não permitido" in error_message:
                    console.print(f"[red]🛡️ Operação bloqueada por segurança: {error_message}[/red]")
                    console.print("[yellow]💡 Use apenas functions seguras para mover cartas![/yellow]")
                else:
                    console.print(f"[red]❌ Erro ao mover carta: {error_message}[/red]")
