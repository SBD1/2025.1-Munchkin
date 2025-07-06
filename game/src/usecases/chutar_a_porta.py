# usecases/chutar_a_porta.py
from usecases.mostrar_detalhes_monstro import mostrar_detalhes_monstro
from usecases.mostrar_status_combate_jogador import mostrar_status_combate_jogador
from usecases.resolver_combate import resolver_combate

def chutar_a_porta(console, cursor, id_partida):
    # 1. Buscar uma carta do tipo porta disponível
    cursor.execute("""
        SELECT id_carta, nome, subtipo FROM carta
        WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE
        ORDER BY RANDOM() LIMIT 1;
    """)
    carta = cursor.fetchone()

    if not carta:
        console.print("[red]⚠️ Não há mais cartas disponíveis no baralho de Porta.[/red]")
        return

    id_carta, nome_carta, subtipo = carta

    # 2. Marcar a carta como usada (indisponível)
    cursor.execute("""
        UPDATE carta
        SET disponivel_para_virar = FALSE
        WHERE id_carta = %s;
    """, (id_carta,))

    console.print(f"\n[bold yellow]🚪 Você chutou a porta e revelou:[/bold yellow] [bold]{nome_carta}[/bold] ({subtipo})")

    if subtipo == 'monstro':
        # 3. Iniciar combate
        cursor.execute("""
            INSERT INTO combate (id_partida, id_carta, monstro_vindo_do_baralho, data_ocorrido)
            VALUES (%s, %s, TRUE, NOW());
        """, (id_partida, id_carta))

        console.print("[bold red]👹 É um monstro! Prepare-se para o combate.[/bold red]")

        mostrar_detalhes_monstro(console, cursor, id_carta)
        # mostrar os atributos do jogador para comparação
        mostrar_status_combate_jogador(console, cursor, id_partida)

        console.input("\n[bold cyan]✅ Pressione ENTER para resolver o combate...[/bold cyan]")
        resolver_combate(console, cursor, id_partida, id_carta)
    else:
        # 4. Enviar carta para a mão do jogador
        cursor.execute("""
            INSERT INTO carta_partida (id_partida, id_carta, zona)
            VALUES (%s, %s, 'mao');
        """, (id_partida, id_carta))

        console.print("[green]📥 A carta foi adicionada à sua mão.[/green]")