from database import obter_cursor

def obter_reinos():
    with obter_cursor() as cursor:
        cursor.execute("SELECT id_reino, nome, descricao FROM Reino ORDER BY id_reino;")
        return cursor.fetchall()

def obter_posicao_jogador(id_jogador):
    with obter_cursor() as cursor:
        cursor.execute("SELECT id_reino FROM PosicaoJogador WHERE id_jogador = %s;", (id_jogador,))
        resultado = cursor.fetchone()
        return resultado[0] if resultado else 1  # padrão: reino 1

def atualizar_posicao_jogador(id_jogador, id_reino):
    with obter_cursor() as cursor:
        cursor.execute("""
            INSERT INTO PosicaoJogador (id_jogador, id_reino)
            VALUES (%s, %s)
            ON CONFLICT (id_jogador)
            DO UPDATE SET id_reino = EXCLUDED.id_reino;
        """, (id_jogador, id_reino))
