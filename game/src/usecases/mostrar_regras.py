from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich import box

console = Console()

def mostrar_regras(console):
    secoes = [
        {
            "title": "\U0001F3AF Objetivo do Jogo",
            "body": Text()
                .append("Alcance o ", style="white")
                .append("n\u00edvel 10", style="bold green")
                .append(" derrotando monstros e sobrevivendo aos desafios da masmorra.\n", style="white")
                .append("Voc\u00ea come\u00e7a no n\u00edvel ", style="white")
                .append("1", style="bold yellow")
                .append(", com ", style="white")
                .append("3 vidas", style="bold red")
                .append(" e sem cartas.", style="white")
        },
        {
            "title": "\U0001F4E6 Prepara\u00e7\u00e3o Inicial",
            "body": Text()
                .append("Existem dois tipos de cartas: ", style="white")
                .append("Porta", style="bold cyan")
                .append(" e ", style="white")
                .append("Tesouro", style="bold magenta")
                .append(".\n\n", style="white")
                .append("Tipos de cartas dispon\u00edveis:\n", style="bold white")
                .append("- \U0001F9DD Cartas de Ra\u00e7a (Ex: Elfo, An\u00e3o)\n", style="white")
                .append("- \U0001F6E1 Cartas de Classe (Ex: Cl\u00e9rigo, Guerreiro)\n", style="white")
                .append("- \u2694\uFE0F Cartas de Item (com b\u00f4nus de combate)\n", style="white")
                .append("- \U0001F47F Cartas de Monstro\n\n", style="white")
                .append("Voc\u00ea come\u00e7a com ", style="white")
                .append("4 cartas de cada tipo", style="bold yellow")
                .append(", formando sua m\u00e3o inicial.\n\n", style="white")
                .append("Zonas de cartas:\n", style="bold blue")
                .append("\U0001F590 m\u00e3o: ainda n\u00e3o jogadas\n", style="bold yellow")
                .append("\u2705 equipado: ativas no personagem\n", style="bold green")
                .append("\U0001F392 mochila: guardadas, n\u00e3o ativas\n", style="bold red")
                .append("\u274C descartada: fora do jogo\n", style="dim")
                .append("\nVoc\u00ea come\u00e7a como ", style="white")
                .append("humano", style="italic")
                .append(", sem ra\u00e7a ou classe.", style="white")
        },
        {
            "title": "\U0001F501 Estrutura do Turno",
            "body": Text()
                .append("Cada turno tem 5 fases:\n", style="bold blue")
                .append("1. \U0001F8BE Prepara\u00e7\u00e3o: jogue cartas de m\u00e3o (classe, ra\u00e7a, itens)\n", style="white")
                .append("2. \U0001F6AA Chutar a Porta: revele carta do baralho de Porta.\n", style="white")
                .append("   - Se for monstro: combate\n", style="bold red")
                .append("   - Se for outra: vai para a m\u00e3o\n", style="white")
                .append("3. \U0001F4A3 Procurar Encrenca (opcional): jogue monstro da m\u00e3o.\n", style="bold red")
                .append("4. \U0001F381 Saque da Sala: se n\u00e3o houve combate, compre uma carta.\n", style="bold green")
                .append("5. \U0001F450 Caridade: descarte at\u00e9 ter 5 cartas na m\u00e3o.\n", style="bold magenta")
        },
        {
            "title": "\u2694\uFE0F Combate",
            "body": Text()
                .append("Some seu n\u00edvel com os b\u00f4nus de equipamentos.\n", style="white")
                .append("Compare com o n\u00edvel do monstro:\n\n", style="white")
                .append("\u2705 Vit\u00f3ria: se for maior\n", style="bold green")
                .append("- Ganho de n\u00edvel\n- Recompensas (tesouros)\n\n", style="white")
                .append("\u274C Derrota: se perder\n", style="bold red")
                .append("- Perda de vidas, descarte ou penalidades\n", style="white")
        },
        {
            "title": "\U0001F480 Morte",
            "body": Text()
                .append("Se perder todas as vidas, a partida termina em ", style="white")
                .append("derrota", style="bold red")
                .append(".\n\nVoc\u00ea pode tentar novamente criando uma nova partida.", style="white")
        },
        {
            "title": "\U0001F3C6 Vit\u00f3ria",
            "body": Text()
                .append("Chegue ao ", style="white")
                .append("n\u00edvel 10", style="bold green")
                .append(" e derrote um monstro para vencer!\n\n", style="white")
                .append("Boa sorte, aventureiro!", style="bold yellow")
        },
    ]

    for secao in secoes:
        panel = Panel(
            secao["body"],
            title=secao["title"],
            border_style="cyan",
            box=box.ROUNDED
        )
        console.print(panel)
        console.print("[bold green]Pressione ENTER para continuar...[/bold green]")
        input()
