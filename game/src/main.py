from rich.console import Console
from rich.panel import Panel
from database import obter_cursor

from usecases.obter_acoes_disponiveis import obter_acoes_disponiveis
from usecases.criar_jogador import criar_jogador
from usecases.selecionar_jogador import selecionar_jogador
from usecases.iniciar_partida import iniciar_partida 
from usecases.mostrar_regras import mostrar_regras
from usecases.excluir_jogador import excluir_jogador
from usecases.excluir_partidas_jogador import excluir_partidas_jogador

# Variável global para armazenar o jogador selecionado na sessão atual
jogador_selecionado_id = None


def executar_com_interface(console, func, *args, **kwargs):
    func(console, *args, **kwargs)
    console.print("\n[bold green]✅ Pressione ENTER para continuar...[/bold green]")
    input()

# Exibe o menu de ações para o jogador e executa a função escolhida
def mostrar_menu_acoes(console):
    global jogador_selecionado_id

    # Buscar nome do jogador no banco
    nome_jogador = "Desconhecido"
    try:
        with obter_cursor() as cursor:
            cursor.execute("SELECT nome FROM Jogador WHERE id_jogador = %s;", (jogador_selecionado_id,))
            resultado = cursor.fetchone()
            if resultado:
                nome_jogador = resultado[0]
    except Exception as e:
        console.print(f"[red]⚠ Erro ao buscar nome do jogador: {e}[/red]")

    while True:
        console.print(f"\n[bold yellow]🎮 Menu de Ações - Turno do Jogador: [green]{nome_jogador}[/green][/bold yellow]")
        opcoes = obter_acoes_disponiveis(jogador_selecionado_id)

        for i, (nome, _) in enumerate(opcoes, 1):
            console.print(f"{i}. {nome}")

        escolha = input("\nDigite o número da ação desejada: ").strip()

        # Verifica se a entrada é um número válido
        if escolha.isdigit():
            escolha_num = int(escolha)

            if 1 <= escolha_num <= len(opcoes):
                nome_acao, func_acao = opcoes[escolha_num - 1]

                # Se a ação for "sair", termina o loop
                if func_acao is None:
                    console.print("[bold red]🚪 Saindo do menu de ações...[/bold red]")
                    break

                executar_com_interface(console, func_acao, jogador_selecionado_id)

            else:
                console.print("[red]⚠ Opção fora do intervalo. Tente novamente.[/red]")
        else:
            console.print("[red]⚠ Entrada inválida. Digite apenas números.[/red]")

# ✅ Nova função: menu principal extraído de main()
def run():
    """
    Menu principal do jogo. Responsável por criação, seleção e início da partida.
    """
    global jogador_selecionado_id
    console = Console()

    console.print(Panel("[bold green]🃏 Munchkin - Modo Solo[/bold green]", expand=False))

    while True:
        console.print("\n[bold yellow]Menu Principal[/bold yellow]")
        console.print("1️⃣ Criar Novo Jogador")
        console.print("2️⃣ Selecionar Jogador Existente")
        console.print("3️⃣ Iniciar Jogo")
        console.print("4️⃣ Ver Regras do Jogo")
        console.print("5️⃣ Excluir Jogador")
        console.print("6️⃣ Excluir Partidas de Jogador")
        console.print("7️⃣ Sair")

        escolha = input("\nDigite o número da opção desejada: ").strip()

        if escolha == "1":
            executar_com_interface(console, criar_jogador)

        elif escolha == "2":
            jogador = selecionar_jogador(console)
            if jogador:
                jogador_selecionado_id = jogador[0]
                console.print(f"[green]Jogador selecionado: {jogador[1]}[/green]")

        elif escolha == "3":
            if jogador_selecionado_id is None:
                console.print("[red]⚠ Você precisa selecionar um jogador primeiro![/red]")
            else:
                iniciar_partida(console, jogador_selecionado_id)
                mostrar_menu_acoes(console)
        
        elif escolha == '4':
            mostrar_regras(console)

        elif escolha == "5":
            executar_com_interface(console, excluir_jogador)
            # Se o jogador excluído era o selecionado, limpar a seleção
            if jogador_selecionado_id:
                try:
                    with obter_cursor() as cursor:
                        cursor.execute("SELECT COUNT(*) FROM jogador WHERE id_jogador = %s;", (jogador_selecionado_id,))
                        if cursor.fetchone()[0] == 0:
                            jogador_selecionado_id = None
                            console.print("[yellow]ℹ️ Jogador selecionado foi excluído. Selecione outro jogador.[/yellow]")
                except:
                    pass

        elif escolha == "6":
            executar_com_interface(console, excluir_partidas_jogador)

        elif escolha == "7":
            console.print("[bold red]👋 Saindo do jogo. Até a próxima![/bold red]")
            break

        else:
            console.print("[red]⚠ Opção inválida. Tente novamente.[/red]")

# ✅ Ponto de entrada do programa
def main():
    run()

if __name__ == "__main__":
    main()