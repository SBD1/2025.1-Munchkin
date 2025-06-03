from database import obter_cursor
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

def listar_jogadores():
    """📋 Lista todos os jogadores cadastrados no banco de dados."""
    console = Console()

    try:
        with obter_cursor() as cursor:
            cursor.execute("SELECT id_jogador, nome FROM Jogador ORDER BY id_jogador;")
            resultados = cursor.fetchall()

        if not resultados:
            console.print(Panel("[bold yellow]Nenhum jogador cadastrado ainda.[/bold yellow]", title="👤 Jogadores"))
            return

        tabela = Table(title="👥 Jogadores Cadastrados")
        tabela.add_column("ID", justify="center", style="cyan")
        tabela.add_column("Nome", style="green")

        for jogador in resultados:
            tabela.add_row(str(jogador[0]), jogador[1])

        console.print(tabela)

    except Exception as e:
        console.print(Panel(f"[bold red]Erro ao listar jogadores: {e}[/bold red]", title="❌ Erro"))
