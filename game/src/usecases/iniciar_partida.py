from datetime import datetime
from database import obter_cursor

from usecases.mostrar_regras import mostrar_regras

def iniciar_partida(console, jogador_id):
    """
    Verifica se o jogador já tem uma partida em andamento.
    Se não tiver, cria uma nova partida e distribui cartas iniciais.
    """
    try:
        with obter_cursor() as cursor:
            cursor.execute("""
                SELECT id_partida FROM partida
                WHERE id_jogador = %s AND estado_partida = 'em andamento'
                LIMIT 1;
            """, (jogador_id,))
            partida = cursor.fetchone()

            if partida:
                console.print(f"[yellow]🎮 Continuando partida existente (ID: {partida[0]})...[/yellow]")
            else:
                cursor.execute("""
                    INSERT INTO partida (id_jogador, data_inicio, estado_partida, vida_restantes)
                    VALUES (%s, %s, 'em andamento', 3)
                    RETURNING id_partida;
                """, (jogador_id, datetime.now()))
                nova_partida_id = cursor.fetchone()[0]
                console.print(f"[green]🆕 Nova partida criada (ID: {nova_partida_id})![/green]")

                # Distribuir 4 cartas de cada tipo (porta e tesouro)
                for tipo in ['porta', 'tesouro']:
                    cursor.execute(f"""
                        SELECT id_carta FROM carta
                        WHERE tipo_carta = %s AND disponivel_para_virar = TRUE
                        ORDER BY RANDOM()
                        LIMIT 4;
                    """, (tipo,))
                    cartas = cursor.fetchall()

                    for carta_id, in cartas:
                        cursor.execute("""
                            INSERT INTO carta_partida (id_partida, id_carta, zona)
                            VALUES (%s, %s, 'mao');
                        """, (nova_partida_id, carta_id))

                # Perguntar se quer ver as regras
                resposta = input("Você conhece as regras do jogo? (s/n): ").strip().lower()
                if resposta == "n":
                    mostrar_regras(console)

    except Exception as e:
        console.print(f"[red]❌ Erro ao iniciar partida: {e}[/red]")
