from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from database import obter_cursor

def criar_jogador(console: Console):
    """
    🎮 Cria um novo jogador no banco de dados solicitando o nome ao usuário.
    Requer que a função insert_munchkin_jogador(nome TEXT) exista no banco.
    """

    # Exibe painel solicitando nome
    console.print(Panel(
        Text("Digite o nome do novo jogador:", style="bold cyan"),
        title="📝 Criação de Jogador",
        border_style="blue",
        expand=False
    ))

    nome_jogador = input("🎭 Nome do jogador: ").strip()

    if not nome_jogador:
        console.print(Panel(
            Text("❌ Nome inválido! O nome do jogador não pode estar vazio.", style="bold red"),
            title="⚠️ Erro",
            border_style="red",
            expand=False
        ))
        return

    try:
        with obter_cursor() as cursor:
            cursor.execute("SELECT insert_munchkin_jogador(%s);", (nome_jogador,))

        console.print(Panel(
            Text(f"✅ Jogador '{nome_jogador}' criado com sucesso! 🎉", style="bold green"),
            title="🏆 Novo Jogador Criado!",
            border_style="green",
            expand=False
        ))

    except Exception as e:
        console.print(Panel(
            Text(f"❌ Erro ao criar jogador: {e}", style="bold red"),
            title="⚠️ Erro",
            border_style="red",
            expand=False
        ))
