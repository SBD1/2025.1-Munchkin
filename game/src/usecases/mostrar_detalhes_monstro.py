# usecases/mostrar_detalhes_monstro.py

def mostrar_detalhes_monstro(console, cursor, id_carta):
    # Buscar dados principais do monstro
    cursor.execute("""
        SELECT c.nome, m.nivel, m.pode_fugir, m.recompensa, m.tipo_monstro
        FROM carta_monstro m
        JOIN carta c ON c.id_carta = m.id_carta
        WHERE m.id_carta = %s;
    """, (id_carta,))
    monstro = cursor.fetchone()

    if not monstro:
        console.print("[red]❌ Erro: Monstro não encontrado no banco.[/red]")
        return

    nome, nivel, pode_fugir, recompensa, tipo_monstro = monstro

    console.print("\n[bold red]👹 Detalhes do Monstro:[/bold red]")
    console.print(f"📛 Nome: [bold]{nome}[/bold]")
    console.print(f"🧠 Nível: [bold]{nivel}[/bold]")
    console.print(f"🏃 Pode Fugir? {'✅ Sim' if pode_fugir else '❌ Não'}")
    console.print(f"📦 Recompensa: [bold green]+{recompensa}[/bold green] tesouro(s)")
    console.print(f"💀 Tipo: {tipo_monstro}")

    # Buscar efeitos corretamente
    cursor.execute("""
        SELECT e.id_efeito_monstro, e.descricao
        FROM efeito_monstro e
        JOIN carta_monstro m ON m.id_carta_monstro = e.id_carta_monstro
        WHERE m.id_carta = %s;
    """, (id_carta,))
    efeitos = cursor.fetchall()

    if efeitos:
        console.print("\n[bold yellow]⚠️ Coisas Ruins se Perder:[/bold yellow]")
        for _, descricao in efeitos:
            console.print(f"- {descricao}")
    else:
        console.print("\n[italic]Este monstro não tem efeitos especiais registrados.[/italic]")
