# usecases/acoes_cartas.py

def tratar_equipar(console, cursor, id_carta, subtipo, id_partida):
    if subtipo == 'monstro':
        console.print("[bold red]❌ Você não pode equipar cartas do tipo MONSTRO.[/bold red]")
        return None

    nova_zona = "equipado"

    if subtipo == 'raca':
        cursor.execute("""
            SELECT pr.id_poder_raca, pl.limite_cartas_mao
            FROM poder_raca pr
            JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
            WHERE pr.id_carta = %s
        """, (id_carta,))
        resultado = cursor.fetchone()

        if resultado:
            limite_mao = resultado[1]
            cursor.execute("""
                UPDATE partida
                SET limite_mao_atual = %s
                WHERE id_partida = %s
            """, (limite_mao, id_partida))
            console.print(f"[bold green]🧬 Limite de cartas na mão atualizado para {limite_mao} devido ao poder da raça.[/bold green]")

    return nova_zona

def tratar_voltar(console, cursor, id_carta, subtipo, id_partida):
    nova_zona = "mao"

    if subtipo == 'raca':
        # Verifica se essa carta que está saindo tinha um poder de limite de mão
        cursor.execute("""
            SELECT pr.id_poder_raca
            FROM poder_raca pr
            JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
            WHERE pr.id_carta = %s
        """, (id_carta,))
        resultado = cursor.fetchone()

        if resultado:
            # Agora verifica se ainda há outra raça equipada com esse poder
            cursor.execute("""
                SELECT 1
                FROM carta_partida cp
                JOIN poder_raca pr ON cp.id_carta = pr.id_carta
                JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
                WHERE cp.id_partida = %s AND cp.zona = 'equipado'
            """, (id_partida,))
            ainda_tem = cursor.fetchone()

            if not ainda_tem:
                cursor.execute("""
                    UPDATE partida
                    SET limite_mao_atual = 5
                    WHERE id_partida = %s
                """, (id_partida,))
                console.print(f"[bold yellow]🔄 Nenhuma raça com poder ativo. Limite de cartas na mão retornado para 5.[/bold yellow]")

    return nova_zona

def tratar_venda(console, cursor, id_carta, subtipo, id_partida):
    if subtipo != 'item':
        console.print("[bold red]❌ Apenas cartas do tipo ITEM podem ser vendidas.[/bold red]")
        return None

    # Buscar valor do item
    cursor.execute("""
        SELECT valor_ouro FROM carta_item WHERE id_carta = %s
    """, (id_carta,))
    valor = cursor.fetchone()
    if not valor:
        console.print("[red]Erro ao buscar valor do item.[/red]")
        return None

    ouro_item = valor[0]

    # Buscar ouro atual e nível
    cursor.execute("""
        SELECT ouro_acumulado, nivel FROM partida WHERE id_partida = %s
    """, (id_partida,))
    dados_partida = cursor.fetchone()
    if not dados_partida:
        console.print("[red]Erro ao acessar os dados da partida.[/red]")
        return None

    ouro_atual, nivel_atual = dados_partida
    novo_ouro = ouro_atual + ouro_item

    # Verifica se deve subir de nível
    subir_nivel = 0
    while novo_ouro >= 1000:
        subir_nivel += 1
        novo_ouro -= 1000

    # Atualiza ouro e nível
    cursor.execute("""
        UPDATE partida
        SET ouro_acumulado = %s, nivel = nivel + %s
        WHERE id_partida = %s
    """, (novo_ouro, subir_nivel, id_partida))

    console.print(f"💰 Item vendido por {ouro_item} de ouro.")
    if subir_nivel > 0:
        console.print(f"[bold green]⬆️ Você acumulou ouro suficiente e subiu {subir_nivel} nível(is)![/bold green]")

    return "descartada"
