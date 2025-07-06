from rich.console import Console
from rich.table import Table
from database import obter_cursor

def listar_jogadores_para_exclusao(console):
    """Lista todos os jogadores disponíveis para exclusão"""
    try:
        with obter_cursor() as cursor:
            cursor.execute("SELECT id_jogador, nome FROM jogador ORDER BY nome;")
            jogadores = cursor.fetchall()
            
            if not jogadores:
                console.print("[yellow]⚠ Nenhum jogador encontrado no banco de dados.[/yellow]")
                return []
            
            # Criar tabela visual dos jogadores
            tabela = Table(title="📋 Jogadores Disponíveis para Exclusão")
            tabela.add_column("ID", style="cyan", no_wrap=True)
            tabela.add_column("Nome", style="magenta")
            
            for jogador in jogadores:
                tabela.add_row(str(jogador[0]), jogador[1])
            
            console.print(tabela)
            return jogadores
            
    except Exception as e:
        console.print(f"[red]❌ Erro ao listar jogadores: {e}[/red]")
        return []

def excluir_jogador(console):
    """Exclui um jogador usando a procedure segura"""
    console.print("\n[bold red]🗑️ EXCLUIR JOGADOR[/bold red]")
    console.print("[yellow]⚠️ ATENÇÃO: Esta operação irá excluir PERMANENTEMENTE o jogador e TODOS os seus dados (partidas, cartas, combates, etc.)[/yellow]")
    
    # Listar jogadores disponíveis
    jogadores = listar_jogadores_para_exclusao(console)
    if not jogadores:
        return
    
    # Solicitar ID do jogador
    try:
        id_jogador = input("\n🎯 Digite o ID do jogador que deseja excluir (ou 'cancelar' para voltar): ").strip()
        
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
            console.print(f"[red]❌ Jogador com ID {id_jogador} não encontrado.[/red]")
            return
        
        # Confirmação final
        nome_jogador = jogador_encontrado[1]
        console.print(f"\n[bold red]⚠️ CONFIRMAÇÃO FINAL ⚠️[/bold red]")
        console.print(f"Você está prestes a excluir permanentemente:")
        console.print(f"🎮 Jogador: [bold]{nome_jogador}[/bold] (ID: {id_jogador})")
        console.print(f"📊 Todas as partidas associadas")
        console.print(f"🃏 Todas as cartas das partidas")
        console.print(f"⚔️ Todos os combates realizados")
        console.print(f"✨ Todos os poderes utilizados")
        
        confirmacao = input(f"\nDigite 'CONFIRMAR' para excluir o jogador {nome_jogador}: ").strip()
        
        if confirmacao != 'CONFIRMAR':
            console.print("[blue]🔙 Operação cancelada. Nenhum dado foi excluído.[/blue]")
            return
        
        # Executar a procedure segura
        with obter_cursor() as cursor:
            cursor.execute("CALL excluir_jogador_completo(%s);", (id_jogador,))
                        
        console.print(f"[bold green]✅ Jogador '{nome_jogador}' foi excluído com sucesso![/bold green]")
        console.print("[green]🛡️ Todos os dados relacionados foram removidos de forma segura.[/green]")
        
    except ValueError:
        console.print("[red]❌ ID inválido. Digite apenas números.[/red]")
    except Exception as e:
        console.print(f"[red]❌ Erro ao excluir jogador: {e}[/red]")
