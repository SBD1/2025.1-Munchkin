from database import obter_cursor

from usecases.mostrar_regras import mostrar_regras

def iniciar_partida(console, jogador_id):
    """
    Inicia partida usando function segura que garante integridade.
    Utiliza iniciar_partida_segura() da migration V24 para operações protegidas.
    """
    try:
        with obter_cursor() as cursor:
            # Usar a function segura da V24
            cursor.execute("""
                SELECT p_id_partida, p_status 
                FROM iniciar_partida_segura(%s);
            """, (jogador_id,))
            
            resultado = cursor.fetchone()
            if not resultado:
                raise Exception("Erro ao obter resultado da procedure")
                
            partida_id, status = resultado
            
            # Tratar diferentes cenários baseados no status
            if status == 'PARTIDA_EXISTENTE':
                console.print(f"[yellow]🎮 Continuando partida existente (ID: {partida_id})...[/yellow]")
                
            elif status == 'NOVA_PARTIDA_CRIADA':
                console.print(f"[green]🆕 Nova partida criada (ID: {partida_id})![/green]")
                console.print("[green]🃏 8 cartas distribuídas com segurança (4 porta + 4 tesouro)![/green]")
                console.print("[green]🛡️ Integridade do jogo garantida pelos triggers![/green]")
                
                # Perguntar se quer ver as regras (apenas para novas partidas)
                resposta = input("\nVocê conhece as regras do jogo? (s/n): ").strip().lower()
                if resposta == "n":
                    mostrar_regras(console)
                    
            else:
                console.print(f"[yellow]⚠️ Status desconhecido: {status}[/yellow]")

    except Exception as e:
        # Tratar erros específicos da procedure
        error_message = str(e)
        
        if "não encontrado" in error_message:
            console.print(f"[red]❌ Jogador inválido: {error_message}[/red]")
        elif "cartas suficientes" in error_message or "Cartas insuficientes" in error_message:
            console.print(f"[red]❌ Problema no baralho: {error_message}[/red]")
            console.print("[yellow]💡 Contate o administrador do jogo![/yellow]")
        elif "não permitida" in error_message:
            console.print(f"[red]🛡️ Operação bloqueada pelos triggers de segurança: {error_message}[/red]")
        else:
            console.print(f"[red]❌ Erro ao iniciar partida: {error_message}[/red]")
