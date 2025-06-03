# Importa a biblioteca para conectar ao PostgreSQL
import psycopg2

# Importa bibliotecas do sistema operacional para manipular caminhos e variáveis de ambiente
import os

# Importa a função para carregar o conteúdo do arquivo .env
from dotenv import load_dotenv

# Importa decorador para criar contexto (comportamento do "with")
from contextlib import contextmanager

# Define o caminho absoluto do arquivo .env (um nível acima da pasta atual)
dotenv_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".env"))

# Verifica se o arquivo .env existe. Se sim, carrega as variáveis de ambiente
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path) 
else:
    print(f"❌ Arquivo .env não encontrado: {dotenv_path}")

# Função para obter uma conexão com o banco de dados PostgreSQL
def obter_conexao():
    try:
        # Cria a conexão usando os dados carregados do .env
        conn = psycopg2.connect(
            dbname=os.getenv("POSTGRES_DB"),           # Nome do banco
            user=os.getenv("POSTGRES_USER"),           # Usuário
            password=os.getenv("POSTGRES_PASSWORD"),   # Senha
            host=os.getenv("DATABASE_HOST"),           # Host (localhost ou IP)
            port=os.getenv("POSTGRES_PORT"),           # Porta (default 5432)
        )
        conn.autocommit = True  # Aplica as alterações automaticamente (sem precisar dar conn.commit())
        return conn             # Retorna a conexão estabelecida
    except Exception as e:
        # Em caso de erro na conexão, mostra a mensagem e retorna None
        print(f"❌ Erro ao conectar ao banco de dados: {e}")
        return None

# Função que retorna um cursor pronto para uso, usando o comando 'with'
@contextmanager
def obter_cursor():
    """
    Obtém um cursor a partir da conexão do banco de dados.
    Isso permite executar comandos SQL com segurança e sem deixar conexões abertas.
    """
    conexao = obter_conexao()
    if conexao:
        try:
            cursor = conexao.cursor()  # Cria o cursor a partir da conexão
            yield cursor               # Devolve o cursor para o bloco 'with' que chamou
        except Exception as e:
            print(f"❌ Erro ao obter cursor: {e}")
        finally:
            cursor.close()             # Fecha o cursor após uso
            conexao.close()            # Fecha a conexão com o banco
    else:
        print("❌ Erro ao obter cursor: conexão não estabelecida.")
        yield None                     # Retorna None para evitar crash, mas sem conexão
