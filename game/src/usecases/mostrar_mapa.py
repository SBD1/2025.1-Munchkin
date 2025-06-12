from database import obter_cursor
from rich.console import Console
from rich.panel import Panel
from rich.align import Align

console = Console()

def mostrar_mapa(console, jogador_id):
    try:
        with obter_cursor() as cursor:
            cursor.execute("SELECT id_reino, nome, descricao FROM mapa ORDER BY id_reino;")
            reinos = cursor.fetchall()
    except Exception as e:
        console.print(f"[red]❌ Erro ao buscar reinos do banco: {e}[/red]")
        return

    if not reinos:
        console.print("[red]❌ Nenhum reino foi encontrado no banco de dados.[/red]")
        return


    posicao_atual = 0  # posição inicial (ainda sem salvar por jogador)

    while True:
        console.clear()

        # Construir lista de reinos com destaque para o atual
        linhas = []
        for i, (id_reino, nome, _) in enumerate(reinos):
            marcador = "👤" if i == posicao_atual else "  "
            linhas.append(f"{marcador} [{i+1}] {nome}")

        # Informações do reino atual
        nome_reino = reinos[posicao_atual][1]
        desc_reino = reinos[posicao_atual][2]

        painel = Panel(
            Align.left("\n".join(linhas) + f"\n\n[bold]Você está em:[/bold] {nome_reino}\n[italic]{desc_reino}[/italic]"),
            title="🗺️ Mapa dos Reinos",
            width=70
        )
        console.print(painel)

        console.print("\nUse [bold]A[/bold] (subir), [bold]D[/bold] (descer), [bold]S[/bold] (sair do mapa)")
        comando = input("Comando: ").strip().lower()

        if comando == "a":
            if posicao_atual > 0:
                posicao_atual -= 1
            else:
                console.print("[yellow]⛔ Você já está no primeiro reino.[/yellow]")
        elif comando == "d":
            if posicao_atual < len(reinos) - 1:
                posicao_atual += 1
            else:
                console.print("[yellow]⛔ Você já está no último reino.[/yellow]")
        elif comando == "s":
            console.print("[green]Saindo do mapa...[/green]")
            break
        else:
            console.print("[red]Comando inválido![/red]")
