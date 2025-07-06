from database import obter_cursor
from rich.console import Console
from rich.panel import Panel
from rich.align import Align

console = Console()

def mostrar_mapa(console, jogador_id):
    try:
        with obter_cursor() as cursor:
            cursor.execute("""
                SELECT
                  id_reino,
                  nome,
                  descricao,
                  nivel_min,
                  nivel_max,
                  ordem
                FROM mapa
                ORDER BY ordem
            """)
            reinos = cursor.fetchall()
    except Exception as e:
        console.print(f"[red]❌ Erro ao buscar reinos do banco: {e}[/red]")
        return   # <- impede usar 'reinos' indefinido

    if not reinos:
        console.print("[red]❌ Nenhum reino foi encontrado no banco de dados.[/red]")
        return

    posicao_atual = 0

    while True:
        console.clear()

        # Monta lista destacando posição
        linhas = []
        for i, (_, nome, _, nivel_min, nivel_max, ordem) in enumerate(reinos):
            marcador = "👤" if i == posicao_atual else "  "
            linhas.append(f"{marcador} [{ordem}] {nome} (níveis {nivel_min}-{nivel_max})")

        # Detalhes do reino selecionado
        _, nome_reino, desc_reino, nivel_min, nivel_max, ordem = reinos[posicao_atual]
        detalhes = (
            f"[bold]{nome_reino}[/bold]\n"
            f"[italic]{desc_reino}[/italic]  🔸 Níveis: {nivel_min}–{nivel_max}"
        )

        painel = Panel(
            Align.left("\n".join(linhas) + "\n\n" + detalhes),
            title="🗺️ Mapa dos Reinos",
            width=70
        )
        console.print(painel)

        console.print("\nUse [bold]A[/bold] (acima), [bold]D[/bold] (abaixo), [bold]S[/bold] (sair)")
        cmd = input("Comando: ").strip().lower()

        if cmd == "a":
            posicao_atual = max(0, posicao_atual - 1)
        elif cmd == "d":
            posicao_atual = min(len(reinos)-1, posicao_atual + 1)
        elif cmd == "s":
            console.print("[green]Saindo do mapa...[/green]")
            break
        else:
            console.print("[red]Comando inválido![/red]")
