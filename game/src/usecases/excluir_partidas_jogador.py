from rich.console import Console
from rich.table import Table
from database import obter_cursor

def listar_jogadores_com_partidas(console):
    """Lista todos os jogadores que possuem partidas"""
    try:
        with obter_cursor() as cursor:
            cursor.execute("""
                SELECT j.id_jogador, j.nome, COUNT(p.id_partida) as qtd_partidas
                FROM jogador j
                LEFT JOIN partida p ON j.id_jogador = p.id_jogador
                GROUP BY j.id_jogador, j.nome
                HAVING COUNT(p.id_partida) > 0
                ORDER BY j.nome;
            """)
            jogadores = cursor.fetchall()
            
            if not jogadores:
                console.print("[yellow]⚠ Nenhum jogador com partidas encontrado no banco de dados.[/yellow]")
                return []
            
            # Criar tabela visual dos jogadores
            tabela = Table(title="📋 Jogadores com Partidas")
            tabela.add_column("ID", style="cyan", no_wrap=True)
            tabela.add_column("Nome", style="magenta")
            tabela.add_column("Qtd Partidas", style="green")
            
            for jogador in jogadores:
                partidas_text = f"{jogador[2]} partida{'s' if jogador[2] != 1 else ''}"
                tabela.add_row(str(jogador[0]), jogador[1], partidas_text)
            
            console.print(tabela)
            return jogadores
            
    except Exception as e:
        console.print(f"[red]❌ Erro ao listar jogadores: {e}[/red]")
        return []

def mostrar_detalhes_partidas(console, id_jogador, nome_jogador):
    """Mostra detalhes das partidas de um jogador específico"""
    try:
        with obter_cursor() as cursor:
            cursor.execute("""
                SELECT id_partida, data_inicio, estado_partida, nivel, vitoria
                FROM partida 
                WHERE id_jogador = %s
                ORDER BY data_inicio DESC;
            """, (id_jogador,))
            partidas = cursor.fetchall()
            
            if not partidas:
                console.print(f"[yellow]⚠ Jogador {nome_jogador} não possui partidas.[/yellow]")
                return []
            
            console.print(f"\n[bold cyan]📊 Partidas do Jogador {nome_jogador}:[/bold cyan]")
            
            for partida in partidas:
                id_partida, data_inicio, estado, nivel, vitoria = partida
                
                # Status da partida
                if estado == 'em andamento':
                    status_icon = "🎮"
                    status_color = "yellow"
                elif vitoria:
                    status_icon = "🏆"
                    status_color = "green"
                else:
                    status_icon = "💀"
                    status_color = "red"
                
                # Formatação da data
                data_formatada = data_inicio.strftime("%d/%m/%Y %H:%M")
                
                console.print(f"• {status_icon} Partida #{id_partida} - {data_formatada} - [{status_color}]{estado.title()}[/{status_color}] - Nível {nivel}")
            
            return partidas
            
    except Exception as e:
        console.print(f"[red]❌ Erro ao buscar partidas: {e}[/red]")
        return []

def excluir_partidas_jogador(console):
    """Exclui todas as partidas de um jogador usando a procedure segura"""
    console.print("\n[bold red]🗑️ EXCLUIR PARTIDAS DE JOGADOR[/bold red]")
    console.print("[yellow]⚠️ ATENÇÃO: Esta operação irá excluir PERMANENTEMENTE todas as partidas do jogador (cartas, combates, etc.)[/yellow]")
    console.print("[blue]ℹ️ O jogador permanecerá no sistema, apenas suas partidas serão removidas.[/blue]")
    
    # Listar jogadores com partidas
    jogadores = listar_jogadores_com_partidas(console)
    if not jogadores:
        return
    
    # Solicitar ID do jogador
    try:
        id_jogador = input("\n🎯 Digite o ID do jogador cujas partidas deseja excluir (ou 'cancelar' para voltar): ").strip()
        
        if id_jogador.lower() in ['cancelar', 'c', '']:
            console.print("[blue]🔙 Operação cancelada.[/blue]")
            return
        
        id_jogador = int(id_jogador)
        
        # Verificar se o ID existe na lista
        jogador_encontrado = None
        for jogador in jogadores:
            if jogador[0] == id_jogador:
                jogador_encontrado = jogador
                break
        
        if not jogador_encontrado:
            console.print(f"[red]❌ Jogador com ID {id_jogador} não encontrado ou não possui partidas.[/red]")
            return
        
        nome_jogador = jogador_encontrado[1]
        qtd_partidas = jogador_encontrado[2]
        
        # Mostrar detalhes das partidas
        partidas = mostrar_detalhes_partidas(console, id_jogador, nome_jogador)
        if not partidas:
            return
        
        # Confirmação final
        console.print(f"\n[bold red]⚠️ CONFIRMAÇÃO FINAL ⚠️[/bold red]")
        console.print(f"Você está prestes a excluir permanentemente:")
        console.print(f"🎮 Jogador: [bold]{nome_jogador}[/bold] (ID: {id_jogador}) - [green]SERÁ MANTIDO[/green]")
        console.print(f"📊 Quantidade de partidas: [bold]{qtd_partidas}[/bold]")
        console.print(f"🃏 Todas as cartas das partidas")
        console.print(f"⚔️ Todos os combates realizados")
        console.print(f"✨ Todos os poderes utilizados")
        
        confirmacao = input(f"\nDigite 'CONFIRMAR' para excluir todas as partidas do jogador {nome_jogador}: ").strip()
        
        if confirmacao != 'CONFIRMAR':
            console.print("[blue]🔙 Operação cancelada. Nenhum dado foi excluído.[/blue]")
            return
        
        # Executar a procedure segura
        with obter_cursor() as cursor:
            cursor.execute("CALL excluir_partidas_jogador(%s);", (id_jogador,))
            
        console.print(f"[bold green]✅ Todas as partidas do jogador '{nome_jogador}' foram excluídas com sucesso![/bold green]")
        console.print(f"[green]👤 O jogador '{nome_jogador}' permanece ativo no sistema.[/green]")
        console.print("[green]🛡️ Todos os dados relacionados às partidas foram removidos de forma segura.[/green]")
        
    except ValueError:
        console.print("[red]❌ ID inválido. Digite apenas números.[/red]")
    except Exception as e:
        console.print(f"[red]❌ Erro ao excluir partidas: {e}[/red]")
