-- ==========================================
-- TABELA PARA CACHE DE MENSAGENS DO CHAT
-- Execute este script no SQL Editor do Supabase
-- ==========================================

-- Criar tabela de mensagens
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_user BOOLEAN NOT NULL DEFAULT false,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para otimização
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id ON chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp ON chat_messages(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_timestamp ON chat_messages(session_id, timestamp);

-- Comentários
COMMENT ON TABLE chat_messages IS 'Armazena histórico de mensagens do chat por sessão';
COMMENT ON COLUMN chat_messages.session_id IS 'Identificador único da sessão do usuário';
COMMENT ON COLUMN chat_messages.message IS 'Conteúdo da mensagem';
COMMENT ON COLUMN chat_messages.is_user IS 'True se mensagem do usuário, False se do assistente';
COMMENT ON COLUMN chat_messages.timestamp IS 'Data e hora da mensagem';

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================

-- Habilita RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Política para permitir inserção de qualquer usuário (API anon)
CREATE POLICY "Permitir inserção de mensagens"
ON chat_messages
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Política para permitir leitura de qualquer usuário (API anon)
CREATE POLICY "Permitir leitura de mensagens"
ON chat_messages
FOR SELECT
TO anon, authenticated
USING (true);

-- Política para permitir exclusão de mensagens (API anon)
CREATE POLICY "Permitir exclusão de mensagens"
ON chat_messages
FOR DELETE
TO anon, authenticated
USING (true);

-- ==========================================
-- TABELA DE SESSÕES (OPCIONAL - PARA ANALYTICS)
-- ==========================================

CREATE TABLE IF NOT EXISTS chat_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL UNIQUE,
    first_message TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    message_count INT DEFAULT 0,
    user_agent TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_chat_sessions_session_id ON chat_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_created_at ON chat_sessions(created_at DESC);

-- RLS para sessões
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir acesso a sessões"
ON chat_sessions
FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- ==========================================
-- FUNÇÃO PARA ATUALIZAR ESTATÍSTICAS DE SESSÃO
-- ==========================================

CREATE OR REPLACE FUNCTION update_session_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualiza ou insere estatísticas da sessão
    INSERT INTO chat_sessions (session_id, first_message, last_message, message_count)
    VALUES (NEW.session_id, NEW.timestamp, NEW.timestamp, 1)
    ON CONFLICT (session_id) 
    DO UPDATE SET 
        last_message = NEW.timestamp,
        message_count = chat_sessions.message_count + 1;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar estatísticas
CREATE TRIGGER trg_update_session_stats
AFTER INSERT ON chat_messages
FOR EACH ROW
EXECUTE FUNCTION update_session_stats();

-- ==========================================
-- VIEW PARA ANÁLISE DE CONVERSAS
-- ==========================================

CREATE OR REPLACE VIEW vw_chat_analytics AS
SELECT 
    cs.session_id,
    cs.first_message,
    cs.last_message,
    cs.message_count,
    COUNT(DISTINCT CASE WHEN cm.is_user = true THEN cm.id END) as user_messages,
    COUNT(DISTINCT CASE WHEN cm.is_user = false THEN cm.id END) as assistant_messages,
    EXTRACT(EPOCH FROM (cs.last_message - cs.first_message)) / 60 as duration_minutes
FROM chat_sessions cs
LEFT JOIN chat_messages cm ON cs.session_id = cm.session_id
GROUP BY cs.session_id, cs.first_message, cs.last_message, cs.message_count
ORDER BY cs.last_message DESC;

-- ==========================================
-- FUNÇÃO PARA LIMPAR MENSAGENS ANTIGAS
-- ==========================================

CREATE OR REPLACE FUNCTION cleanup_old_messages(days_to_keep INT DEFAULT 30)
RETURNS TABLE(deleted_count BIGINT) AS $$
DECLARE
    rows_deleted BIGINT;
BEGIN
    -- Remove mensagens antigas
    DELETE FROM chat_messages 
    WHERE timestamp < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    -- Remove sessões órfãs
    DELETE FROM chat_sessions
    WHERE session_id NOT IN (SELECT DISTINCT session_id FROM chat_messages);
    
    RETURN QUERY SELECT rows_deleted;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- CONSULTAS ÚTEIS
-- ==========================================

-- Ver últimas conversas
-- SELECT * FROM vw_chat_analytics LIMIT 10;

-- Estatísticas gerais
-- SELECT 
--     COUNT(DISTINCT session_id) as total_sessions,
--     COUNT(*) as total_messages,
--     COUNT(*) FILTER (WHERE is_user = true) as user_messages,
--     COUNT(*) FILTER (WHERE is_user = false) as assistant_messages,
--     AVG(LENGTH(message)) as avg_message_length
-- FROM chat_messages;

-- Mensagens de hoje
-- SELECT * FROM chat_messages 
-- WHERE DATE(timestamp) = CURRENT_DATE
-- ORDER BY timestamp DESC;

-- Sessões ativas (última mensagem nas últimas 24h)
-- SELECT * FROM chat_sessions
-- WHERE last_message > NOW() - INTERVAL '24 hours'
-- ORDER BY last_message DESC;

-- Limpar mensagens com mais de 30 dias
-- SELECT * FROM cleanup_old_messages(30);

-- ==========================================
-- STORED PROCEDURE PARA EXPORTAR CONVERSA
-- ==========================================

CREATE OR REPLACE FUNCTION export_conversation(p_session_id VARCHAR)
RETURNS TABLE(
    message_number INT,
    sender VARCHAR,
    message TEXT,
    sent_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY cm.timestamp)::INT as message_number,
        CASE 
            WHEN cm.is_user THEN 'Usuário'
            ELSE 'Assistente IA'
        END as sender,
        cm.message,
        cm.timestamp as sent_at
    FROM chat_messages cm
    WHERE cm.session_id = p_session_id
    ORDER BY cm.timestamp;
END;
$$ LANGUAGE plpgsql;

-- Exemplo de uso:
-- SELECT * FROM export_conversation('session_1234567890_abc123');

-- ==========================================
-- OBSERVAÇÕES
-- ==========================================

/*
1. As políticas RLS estão configuradas para permitir acesso público (anon)
   Se quiser restringir, modifique as políticas conforme necessário

2. A função cleanup_old_messages pode ser executada periodicamente via cron job

3. Para melhor performance com muitos dados, considere:
   - Particionar a tabela por data
   - Implementar arquivamento de conversas antigas
   - Usar índices GIN para busca full-text se necessário

4. Para adicionar busca full-text nas mensagens:
   ALTER TABLE chat_messages ADD COLUMN search_vector tsvector;
   CREATE INDEX idx_search ON chat_messages USING GIN(search_vector);
   
   CREATE TRIGGER trg_update_search
   BEFORE INSERT OR UPDATE ON chat_messages
   FOR EACH ROW EXECUTE FUNCTION
   tsvector_update_trigger(search_vector, 'pg_catalog.portuguese', message);

5. Backup recomendado via Supabase Dashboard ou CLI
*/