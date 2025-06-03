-- Cria um usuário de aplicação com superpoderes (para facilitar o desenvolvimento)
CREATE ROLE "aplicacao" WITH SUPERUSER LOGIN PASSWORD 'sbd1_2024.2@munchkin';

-- Permite que ele se conecte ao banco munchkin
GRANT CONNECT ON DATABASE munchkin TO "aplicacao";

-- Permite que ele use o schema public (onde as tabelas serão criadas)
GRANT USAGE ON SCHEMA public TO "aplicacao";

-- Dá permissões totais sobre tabelas, sequências e funções
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "aplicacao";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "aplicacao";
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO "aplicacao";

-- Garante que novas tabelas criadas automaticamente deem esses mesmos privilégios
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT ALL ON TABLES TO "aplicacao";

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT ALL ON SEQUENCES TO "aplicacao";

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT ALL ON FUNCTIONS TO "aplicacao";
