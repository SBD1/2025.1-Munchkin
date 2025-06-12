from rich.console import Console
from rich.panel import Panel
from rich.align import Align
from usecases.mapa import obter_reinos, obter_posicao_jogador, atualizar_posicao_jogador


console = Console()

# Reinos
reinos = [
    "🏰 Masmorra",
    "🌲 Floresta",
    "🧙 Feiticeiros",
    "🔥 Inferno",
    "⚙️ Engrenagens"
]

descricoes = [
    "Monstros e armadilhas ocultas.",
    "Duendes, árvores vivas e magia natural.",
    "Magos anciãos e portais perigosos.",
    "Chefes cruéis e burocracia mortal.",
    "Máquinas conscientes e enigmas lógicos."
]

def desenhar_mapa_vertical(posicao_atual):
    linhas = []
    for i, nome in enumerate(reinos):
        marcador = "👤" if i == posicao_atual else "  "
        linhas.append(f"{marcador} [{i+1}] {nome}")
    return "\n".join(linhas)

def mostrar_mapa(console, id_jogador):
    reinos = obter_reinos()
    posicao_atual = obter_posicao_jogador(id_jogador) - 1  # índice 0-based

    while True:
        console.clear()

        linhas = []
        for i, (id_reino, nome, _) in enumerate(reinos):
            marcador = "👤" if i == posicao_atual else "  "
            linhas.append(f"{marcador} [{i+1}] {nome}")

        nome_reino, desc_reino = reinos[posicao_atual][1], reinos[posicao_atual][2]

        painel = Panel(
            Align.left("\n".join(linhas) + f"\n\n[bold]Você está em:[/bold] {nome_reino}\n[italic]{desc_reino}[/italic]"),
            title="🗺️ Mapa dos Reinos",
            width=60
        )
        console.print(painel)

        console.print("\nUse [bold]A[/bold] (subir), [bold]D[/bold] (descer), [bold]S[/bold] (sair do mapa)")
        comando = input("Comando: ").strip().lower()

        if comando == "a":
            if posicao_atual > 0:
                posicao_atual -= 1
        elif comando == "d":
            if posicao_atual < len(reinos) - 1:
                posicao_atual += 1
        elif comando == "s":
            atualizar_posicao_jogador(id_jogador, reinos[posicao_atual][0])
            console.print("[green]Saindo do mapa...[/green]")
            break
        else:
            console.print("[red]Comando inválido![/red]")
