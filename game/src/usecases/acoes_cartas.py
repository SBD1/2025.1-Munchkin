# usecases/acoes_cartas.py

# IMPORTANTE: As funções neste arquivo são chamadas pelo gerenciar_cartas.py
# para processar ações específicas em cartas baseadas em sua zona atual:
# - tratar_equipar: Move carta da 'mao' para 'equipado' (raça/classe/item)
# - tratar_voltar: Move carta de 'equipado' para 'mao' (desequipar)
# - tratar_venda: Move carta de qualquer zona para 'descartada' (apenas itens)

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
            # ETAPA 2: Usar function segura em vez de UPDATE direto perigoso
            try:
                cursor.execute("""
                    SELECT * FROM atualizar_limite_mao_seguro(%s, %s);
                """, (id_partida, limite_mao))
                
                result = cursor.fetchone()
                if result and result[0]:  # sucesso = True
                    console.print(f"[bold green]🧬 {result[1]}[/bold green]")
                else:
                    console.print(f"[red]❌ Erro ao atualizar limite de mão: {result[1] if result else 'Erro desconhecido'}[/red]")
                    return None
                    
            except Exception as e:
                error_message = str(e)
                if "não permitido" in error_message:
                    console.print(f"[red]🛡️ Operação bloqueada por segurança: {error_message}[/red]")
                    console.print("[yellow]💡 Use apenas functions seguras para atualizar partida![/yellow]")
                else:
                    console.print(f"[red]❌ Erro ao atualizar limite de mão: {error_message}[/red]")
                return None

    elif subtipo == 'item':
        cursor.execute("""
            SELECT tipo_item, slot, bonus_combate
            FROM carta_item
            WHERE id_carta = %s
        """, (id_carta,))
        resultado = cursor.fetchone()

        if resultado:
            # Verifica restrições do item
            cursor.execute("""
                SELECT tipo_alvo, valor_alvo, permitido
                FROM restricao_item
                WHERE id_carta_item = %s
            """, (id_carta,))
            restricoes = cursor.fetchall()

            for tipo_alvo, valor_alvo, permitido in restricoes:
                if tipo_alvo == 'classe':
                    # Verifica se o jogador tem a classe exigida
                    cursor.execute("""
                        SELECT 1
                        FROM carta_partida cp
                        JOIN carta_classe cc ON cc.id_carta = cp.id_carta
                        WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND cc.nome_classe = %s
                    """, (id_partida, valor_alvo))
                    possui = cursor.fetchone()
                    
                    if permitido and not possui:
                        console.print(f"[bold red]❌ Este item só pode ser usado por um personagem da classe '{valor_alvo.upper()}', mas você não está com essa classe equipada.[/bold red]")
                        return None
                    if not permitido and possui:
                        console.print(f"[bold red]❌ Personagens da classe '{valor_alvo.upper()}' não podem usar este item.[/bold red]")
                        return None

                elif tipo_alvo == 'raca':
                    # Verifica se o jogador tem a raça exigida
                    cursor.execute("""
                        SELECT 1
                        FROM carta_partida cp
                        JOIN carta_raca cr ON cr.id_carta = cp.id_carta
                        WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND cr.nome_raca = %s
                    """, (id_partida, valor_alvo))
                    possui = cursor.fetchone()
                    
                    if permitido and not possui:
                        console.print(f"[bold red]❌ Este item só pode ser usado por um personagem da raça '{valor_alvo.upper()}', mas você não está com essa raça equipada.[/bold red]")
                        return None
                    if not permitido and possui:
                        console.print(f"[bold red]❌ Personagens da raça '{valor_alvo.upper()}' não podem usar este item.[/bold red]")
                        return None
                    
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
            try:
                cursor.execute("""
                    SELECT * FROM aplicar_bonus_combate_seguro(%s, %s);
                """, (id_partida, bonus_combate))
                
                result = cursor.fetchone()
                if result and result[0]:  # sucesso = True
                    console.print(f"[bold green]🪖 Item equipado no slot '{slot.upper()}'! {result[1]}[/bold green]")
                else:
                    console.print(f"[red]❌ Erro ao aplicar bônus de combate: {result[1] if result else 'Erro desconhecido'}[/red]")
                    return None
                    
            except Exception as e:
                error_message = str(e)
                if "não permitido" in error_message:
                    console.print(f"[red]🛡️ Operação bloqueada por segurança: {error_message}[/red]")
                    console.print("[yellow]💡 Use apenas functions seguras para atualizar partida![/yellow]")
                else:
                    console.print(f"[red]❌ Erro ao aplicar bônus de combate: {error_message}[/red]")
                return None

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
                try:
                    cursor.execute("""
                        SELECT * FROM atualizar_limite_mao_seguro(%s, 5);
                    """, (id_partida,))
                    
                    result = cursor.fetchone()
                    if result and result[0]:  # sucesso = True
                        console.print(f"[bold yellow]🔄 {result[1]} (poder de raça removido)[/bold yellow]")
                    else:
                        console.print(f"[red]❌ Erro ao resetar limite de mão: {result[1] if result else 'Erro desconhecido'}[/red]")
                        
                except Exception as e:
                    error_message = str(e)
                    if "não permitido" in error_message:
                        console.print(f"[red]🛡️ Operação bloqueada por segurança: {error_message}[/red]")
                    else:
                        console.print(f"[red]❌ Erro ao resetar limite de mão: {error_message}[/red]")

    elif subtipo == 'item':
        # Verifica se o item tem bônus de combate que precisa ser removido
        cursor.execute("""
            SELECT bonus_combate, slot
            FROM carta_item
            WHERE id_carta = %s
        """, (id_carta,))
        resultado = cursor.fetchone()

        if resultado:
            bonus_combate, slot = resultado
            
            # Remove o bônus de combate (aplicar o valor negativo)
            if bonus_combate != 0:
                try:
                    cursor.execute("""
                        SELECT * FROM aplicar_bonus_combate_seguro(%s, %s);
                    """, (id_partida, -bonus_combate))
                    
                    result = cursor.fetchone()
                    if result and result[0]:  # sucesso = True
                        console.print(f"[bold yellow]🪖 Item desequipado do slot '{slot.upper()}'! {result[1]}[/bold yellow]")
                    else:
                        console.print(f"[red]❌ Erro ao remover bônus de combate: {result[1] if result else 'Erro desconhecido'}[/red]")
                        return None
                        
                except Exception as e:
                    error_message = str(e)
                    if "não permitido" in error_message:
                        console.print(f"[red]🛡️ Operação bloqueada por segurança: {error_message}[/red]")
                        console.print("[yellow]💡 Use apenas functions seguras para atualizar partida![/yellow]")
                    else:
                        console.print(f"[red]❌ Erro ao remover bônus de combate: {error_message}[/red]")
                    return None
            else:
                console.print(f"[bold cyan]🔄 Item '{slot.upper()}' desequipado (sem bônus de combate).[/bold cyan]")

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

    # 5. Atualiza o ouro e nível acumulado usando function segura
    try:
        cursor.execute("""
            SELECT * FROM processar_venda_segura(%s, %s);
        """, (id_partida, valor_final))
        
        result = cursor.fetchone()
        if result and result[0]:  # sucesso = True
            sucesso, mensagem, ouro_anterior, ouro_atual, nivel_anterior, nivel_atual, niveis_ganhos = result
            console.print(f"💰 {mensagem}")
            
            if niveis_ganhos > 0:
                console.print(f"[bold green]⬆️ Você subiu {niveis_ganhos} nível(s)! (Nível {nivel_anterior} -> {nivel_atual})[/bold green]")
        else:
            console.print(f"[red]❌ Erro ao processar venda: {result[1] if result else 'Erro desconhecido'}[/red]")
            return None
            
    except Exception as e:
        error_message = str(e)
        if "não permitido" in error_message:
            console.print(f"[red]🛡️ Operação bloqueada por segurança: {error_message}[/red]")
            console.print("[yellow]💡 Use apenas functions seguras para atualizar partida![/yellow]")
        else:
            console.print(f"[red]❌ Erro ao processar venda: {error_message}[/red]")
        return None

    return "descartada"
