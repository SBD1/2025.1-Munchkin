from datetime import datetime
from database import obter_cursor
from usecases.mostrar_regras import mostrar_regras
from usecases.ver_cartas import ver_cartas_por_zona
from usecases.gerenciar_cartas import gerenciar_cartas
from usecases.mostrar_mapa import mostrar_mapa

def ver_status(console, jogador_id):
    with obter_cursor() as cursor:
        cursor.execute("""
            SELECT nivel, vida_restantes, estado_partida, finalizada, vitoria, data_inicio, turno_atual, ouro_acumulado
            FROM partida
            WHERE id_jogador = %s
            ORDER BY id_partida DESC
            LIMIT 1;
        """, (jogador_id,))
        
        partida = cursor.fetchone()
        
        if not partida:
            console.print(f"[bold red]❌ Nenhuma partida encontrada para o jogador {jogador_id}.[/bold red]")
            return

        nivel, vida, estado, finalizada, vitoria, data_inicio, turno, ouro = partida

        console.print("[bold cyan]📊 Status da Partida:[/bold cyan]")
        console.print(f"🔢 Nível: [bold green]{nivel}[/bold green]")
        console.print(f"❤️ Vidas restantes: [bold red]{vida}[/bold red] de 3")
        console.print(f"💰 Ouro acumulado: [bold yellow]{ouro}[/bold yellow] / 1000")
        console.print(f"🎲 Turno atual: [bold yellow]{turno}[/bold yellow]")
        console.print(f"📅 Iniciada em: {data_inicio.strftime('%d/%m/%Y %H:%M')}")
        console.print(f"📌 Estado: [bold]{estado}[/bold]")
        console.print(f"🏁 Finalizada: {'✅' if finalizada else '❌'}")
        console.print(f"🏆 Vitória: {'🎉 Sim!' if vitoria else '😢 Ainda não'}")


def obter_acoes_disponiveis(jogador_id):
    opcoes = [
        ("[bold green]📜 Ver Todas as Cartas do Jogador[/bold green]", ver_cartas_por_zona),
        ("[bold blue]🛠️ Gerenciar Cartas (Equipar, Descartar, etc.)[/bold blue]", gerenciar_cartas),
        ("[bold cyan]🧙 Ver Status do Jogador[/bold cyan]", ver_status),
        ("[bold yellow]📖 Ver Regras do Jogo[/bold yellow]", lambda console, _: mostrar_regras(console)),
        ("[bold dark_orange]🧭 Ver mapa[/bold dark_orange]", mostrar_mapa),
        ("[bold red]❌ Sair do Menu de Ações[/bold red]", None),
    ]
    return opcoes
