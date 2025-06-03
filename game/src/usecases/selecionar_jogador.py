from database import obter_cursor
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

def selecionar_jogador(console: Console):
    """🎯 Permite ao usuário selecionar um jogador existente no banco."""

    try:
        with obter_cursor() as cursor:
            cursor.execute("SELECT id_jogador, nome FROM Jogador ORDER BY id_jogador;")
            jogadores = cursor.fetchall()

        if not jogadores:
            console.print(Panel("[bold yellow]Nenhum jogador cadastrado ainda.[/bold yellow]", title="⚠️ Atenção"))
            return None

        tabela = Table(title="👥 Jogadores Disponíveis")
        tabela.add_column("Opção", justify="center", style="cyan")
        tabela.add_column("ID", justify="center")
        tabela.add_column("Nome", style="green")

        for i, (id_jogador, nome) in enumerate(jogadores, 1):
            tabela.add_row(str(i), str(id_jogador), nome)

        console.print(tabela)

        escolha = input("Digite o número do jogador que deseja selecionar: ").strip()

        if escolha.isdigit():
            index = int(escolha) - 1
            if 0 <= index < len(jogadores):
                return jogadores[index]  # retorna (id_jogador, nome)
            else:
                console.print("[red]⚠ Opção fora do intervalo.[/red]")
        else:
            console.print("[red]⚠ Entrada inválida. Digite apenas números.[/red]")

    except Exception as e:
        console.print(Panel(f"[bold red]Erro ao selecionar jogador: {e}[/bold red]", title="❌ Erro"))

    return None
