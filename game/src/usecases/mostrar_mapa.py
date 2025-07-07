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
        return

    if not reinos:
        console.print("[red]❌ Nenhum reino foi encontrado no banco de dados.[/red]")
        return

    posicao_atual = 0

    while True:
        console.clear()

        # Obter id_partida atual do jogador
        with obter_cursor() as cursor:
            cursor.execute("""
                SELECT id_partida FROM partida
                WHERE id_jogador = %s
                ORDER BY id_partida DESC
                LIMIT 1;
            """, (jogador_id,))
            resultado = cursor.fetchone()
            id_partida = resultado[0] if resultado else None

        # Construir lista de reinos com progresso
        linhas = []
        for i, (id_reino, nome, _, nivel_min, nivel_max, ordem) in enumerate(reinos):
            with obter_cursor() as cursor:
                cursor.execute("""
                    SELECT 1 FROM progresso_reino
                    WHERE id_partida = %s AND id_reino = %s;
                """, (id_partida, id_reino))
                desbloqueado = cursor.fetchone() is not None

            marcador = "👤" if i == posicao_atual else "  "
            status = "✓" if desbloqueado else "🔒"
            linhas.append(f"{marcador} {status} [{ordem}] {nome} (níveis {nivel_min}-{nivel_max})")

        # Detalhes do reino atual
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
            if posicao_atual < len(reinos) - 1:
                id_reino_proximo = reinos[posicao_atual + 1][0]

                with obter_cursor() as cursor:
                    cursor.execute("""
                        SELECT 1 FROM progresso_reino
                        WHERE id_partida = %s AND id_reino = %s;
                    """, (id_partida, id_reino_proximo))
                    desbloqueado = cursor.fetchone() is not None

                if desbloqueado:
                    posicao_atual += 1
                else:
                    console.print("[red]⛔ Você precisa vencer um combate neste reino antes de acessá-lo.[/red]")
            else:
                console.print("[yellow]⛔ Você já está no último reino.[/yellow]")

        elif cmd == "s":
            console.print("[green]Saindo do mapa...[/green]")
            break

        else:
            console.print("[red]Comando inválido![/red]")
