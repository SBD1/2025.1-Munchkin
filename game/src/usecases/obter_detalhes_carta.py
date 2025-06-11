def buscar_detalhes_por_subtipo(cursor, id_carta, subtipo):
    # Detalhes de cartas do tipo "item"
    if subtipo == 'item':
        cursor.execute("""
            SELECT bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla
            FROM carta_item WHERE id_carta = %s
        """, (id_carta,))
        return cursor.fetchone()

    # Detalhes de cartas do tipo "monstro" com JOIN para obter efeitos
    elif subtipo == 'monstro':
        cursor.execute("""
            SELECT cm.nivel, cm.pode_fugir, cm.recompensa, cm.tipo_monstro,
                   em.descricao
            FROM carta_monstro cm
            LEFT JOIN efeito_monstro em ON cm.id_carta_monstro = em.id_carta_monstro
            WHERE cm.id_carta = %s
        """, (id_carta,))
        resultados = cursor.fetchall()

        if not resultados:
            return (None, [])

        # A primeira linha traz os dados do monstro
        info = resultados[0][:4]  # nivel, pode_fugir, recompensa, tipo_monstro
        efeitos = [row[4] for row in resultados if row[4] is not None]
        return (info, efeitos)

    # Detalhes de cartas do tipo "raca" com JOIN para obter poder
    elif subtipo == 'raca':
        cursor.execute("""
            SELECT cr.nome_raca, pr.descricao
            FROM carta_raca cr
            LEFT JOIN poder_raca pr ON cr.id_carta = pr.id_carta
            WHERE cr.id_carta = %s
        """, (id_carta,))
        resultado = cursor.fetchone()

        if resultado:
            nome_raca, poder = resultado
        else:
            nome_raca, poder = "Raça desconhecida", None

        return (nome_raca, poder)

    # Detalhes de cartas do tipo "classe" com JOIN para obter poderes
    elif subtipo == 'classe':
        cursor.execute("""
            SELECT cc.nome_classe, pc.descricao
            FROM carta_classe cc
            LEFT JOIN poder_classe pc ON cc.id_carta = pc.id_carta_classe
            WHERE cc.id_carta = %s
        """, (id_carta,))
        resultados = cursor.fetchall()

        if not resultados:
            return ("Classe desconhecida", [])

        nome_classe = resultados[0][0]
        poderes = [row[1] for row in resultados if row[1] is not None]
        return ((nome_classe,), poderes)

    # Retorno padrão para subtipos desconhecidos
    return None
