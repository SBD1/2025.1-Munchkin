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

    elif subtipo == 'item':
        cursor.execute("""
            SELECT tipo_item, slot, bonus_combate
            FROM carta_item
            WHERE id_carta = %s
        """, (id_carta,))
        resultado = cursor.fetchone()

        if resultado:
            tipo_item, slot, bonus_combate = resultado

            if slot != 'nenhum':
                # Verificar se já há outro item no mesmo slot
                cursor.execute("""
                    SELECT 1
                    FROM carta_partida cp
                    JOIN carta_item ci ON ci.id_carta = cp.id_carta
                    WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND ci.slot = %s
                """, (id_partida, slot))
                conflito = cursor.fetchone()

                if conflito:
                    console.print(f"[bold red]❌ Você já tem um item equipado no slot '{slot}'. Remova-o antes de equipar outro.[/bold red]")
                    return None  # Bloqueia o equipamento se houver conflito

            # Agora sim, aplica o bônus e equipa
            cursor.execute("""
                UPDATE partida
                SET nivel = nivel + %s
                WHERE id_partida = %s
            """, (bonus_combate, id_partida))

            console.print(f"[bold green]🪖 Item equipado! Bônus de combate +{bonus_combate} aplicado ao seu nível.[/bold green]")

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

    # 1. Buscar valor do item
    cursor.execute("""
        SELECT valor_ouro FROM carta_item WHERE id_carta = %s
    """, (id_carta,))
    valor = cursor.fetchone()
    if not valor:
        console.print("[red]Erro ao buscar valor do item.[/red]")
        return None

    valor_ouro = valor[0]

    # 2. Buscar ouro, nível e turno atual da partida
    cursor.execute("""
        SELECT ouro_acumulado, nivel, turno_atual FROM partida WHERE id_partida = %s
    """, (id_partida,))
    partida_info = cursor.fetchone()
    if not partida_info:
        console.print("[red]Erro ao acessar os dados da partida.[/red]")
        return None

    ouro_atual, nivel_atual, turno_atual = partida_info

    # 3. Verifica se o jogador tem uma raça com o poder de venda multiplicada equipada
    cursor.execute("""
        SELECT pr.id_carta, pvm.multiplicador, pvm.limite_vezes_por_turno
        FROM carta_partida cp
        JOIN poder_raca pr ON cp.id_carta = pr.id_carta
        JOIN poder_venda_multiplicada pvm ON pr.id_poder_raca = pvm.id_poder_raca
        WHERE cp.id_partida = %s AND cp.zona = 'equipado'
    """, (id_partida,))
    poder = cursor.fetchone()

    # 4. Se tiver esse poder e ainda não atingiu o limite de usos no turno, aplica o multiplicador
    if poder:
        id_carta_raca, multiplicador, limite = poder

        cursor.execute("""
            SELECT usos FROM uso_poder_venda
            WHERE id_partida = %s AND id_carta = %s AND turno = %s
        """, (id_partida, id_carta_raca, turno_atual))
        uso = cursor.fetchone()

        if not uso or uso[0] < limite:
            valor_final = valor_ouro * multiplicador

            # Atualiza ou insere uso
            if uso:
                cursor.execute("""
                    UPDATE uso_poder_venda
                    SET usos = usos + 1
                    WHERE id_partida = %s AND id_carta = %s AND turno = %s
                """, (id_partida, id_carta_raca, turno_atual))
            else:
                cursor.execute("""
                    INSERT INTO uso_poder_venda (id_partida, id_carta, turno, usos)
                    VALUES (%s, %s, %s, 1)
                """, (id_partida, id_carta_raca, turno_atual))

            console.print(f"[bold green]🪙 Poder de raça ativado! Item vendido por {valor_final} de ouro (x{multiplicador}).[/bold green]")
        else:
            valor_final = valor_ouro
            console.print("[yellow]⚠️ Poder de venda já usado neste turno. Venda normal aplicada.[/yellow]")
    else:
        valor_final = valor_ouro

    # 5. Atualiza o ouro e nível acumulado
    novo_ouro = ouro_atual + valor_final

    subir_nivel = 0
    while novo_ouro >= 1000:
        subir_nivel += 1
        novo_ouro -= 1000

    cursor.execute("""
        UPDATE partida
        SET ouro_acumulado = %s, nivel = nivel + %s
        WHERE id_partida = %s
    """, (novo_ouro, subir_nivel, id_partida))

    console.print(f"💰 Item vendido por {valor_final} de ouro.")
    if subir_nivel > 0:
        console.print(f"[bold green]⬆️ Você subiu {subir_nivel} nível(is)![/bold green]")

    return "descartada"
