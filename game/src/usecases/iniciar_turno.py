# usecases/iniciar_turno.py
from database import obter_cursor
from usecases.chutar_a_porta import chutar_a_porta

def iniciar_turno(console, jogador_id):
    with obter_cursor() as cursor:
        # Obter a partida em andamento do jogador
        cursor.execute("""
            SELECT id_partida, limite_mao_atual, turno_atual
            FROM partida
            WHERE id_jogador = %s AND estado_partida = 'em andamento'
            ORDER BY id_partida DESC LIMIT 1;
        """, (jogador_id,))
        partida = cursor.fetchone()

        if not partida:
            console.print("[bold red]❌ Nenhuma partida em andamento encontrada.[/bold red]")
            return

        id_partida, limite_mao_atual, turno_atual = partida

        # Contar quantas cartas estão na mão
        cursor.execute("""
            SELECT COUNT(*) FROM carta_partida
            WHERE id_partida = %s AND zona = 'mao';
        """, (id_partida,))
        qtd_mao = cursor.fetchone()[0]

        if qtd_mao > limite_mao_atual:
            console.print(f"[bold yellow]👐 Caridade obrigatória! Você tem {qtd_mao} cartas na mão, o limite é {limite_mao_atual}. Descarte/equipe/venda até ficar com {limite_mao_atual} cartas.[/bold yellow]")
            return

        # Inicia novo turno
        cursor.execute("""
            UPDATE partida
            SET turno_atual = turno_atual + 1
            WHERE id_partida = %s
        """, (id_partida,))

        console.print(f"[bold green]🚪 Novo turno iniciado! Este é o turno {turno_atual + 1}.[/bold green]")

        # Etapa 2: Chutar a Porta
        chutar_a_porta(console, cursor, id_partida)
