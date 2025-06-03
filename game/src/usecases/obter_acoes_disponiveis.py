# Função de exemplo
def ver_status(console, jogador_id):
    console.print(f"[cyan]🧙 Verificando status do jogador {jogador_id}... (simulação)[/cyan]")

def usar_carta(console, jogador_id):
    console.print(f"[green]📜 Usando uma carta da mão... (simulação)[/green]")

def obter_acoes_disponiveis(jogador_id):
    opcoes = [
        ("[bold green]📜 Usar Carta da Mão[/bold green]", usar_carta),
        ("[bold cyan]🧙 Ver Status do Jogador[/bold cyan]", ver_status),
        ("[bold red]❌ Sair do Menu de Ações[/bold red]", None),
    ]
    return opcoes
