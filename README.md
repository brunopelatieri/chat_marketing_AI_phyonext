# 🚀 Chat IA - Assistente de Otimização Empresarial

Sistema de chat inteligente com IA integrado ao n8n, cache persistente no Supabase, tema claro/escuro e design minimalista inspirado no ChatGPT.

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Características](#características)
3. [Configuração](#configuração)
4. [Estrutura do Projeto](#estrutura-do-projeto)
5. [Funcionalidades](#funcionalidades)
6. [Integração n8n](#integração-n8n)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

Sistema de chat empresarial focado em identificar oportunidades de automação e otimização de processos através de Inteligência Artificial. O assistente ajuda empresários a descobrir onde a IA pode ser aplicada para:

- 🤖 Automatizar processos repetitivos
- 💰 Reduzir custos operacionais
- 📈 Aumentar produtividade
- ⚡ Otimizar eficiência

### Arquitetura

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│   Frontend  │────▶│     n8n     │────▶│  Backend IA  │
│  (Browser)  │ WH  │  (Webhook)  │ API │   (GPT/IA)   │
└─────────────┘     └─────────────┘     └──────────────┘
       │
       ▼
┌──────────────┐
│   Supabase   │
│   (Cache)    │
└──────────────┘
```

---

## ✨ Características

### Visual e UX
- ✅ Design minimalista inspirado no ChatGPT
- ✅ Layout full-width (100% da tela)
- ✅ Tema claro e escuro com toggle
- ✅ Animações suaves e modernas
- ✅ 100% responsivo (mobile-first)
- ✅ Bootstrap 5 framework
- ✅ Sem sidebar/menu lateral

### Funcionalidades
- ✅ Chat em tempo real com IA
- ✅ Suporte a mensagens de texto
- ✅ Gravação e envio de áudio
- ✅ Cache persistente no Supabase
- ✅ Histórico de conversas por sessão
- ✅ Sugestões rápidas de início
- ✅ Loading states elegantes
- ✅ Alertas contextuais

### Técnico
- ✅ jQuery para manipulação DOM
- ✅ Supabase Client JS
- ✅ Integração via Webhook (n8n)
- ✅ LocalStorage para sessão
- ✅ Auto-resize textarea
- ✅ Tratamento de erros completo

---

## ⚙️ Configuração

### 1. Configurar Supabase

#### Passo 1: Criar Projeto
1. Acesse [supabase.com](https://supabase.com)
2. Crie um novo projeto
3. Anote a **URL** e **anon key**

#### Passo 2: Criar Tabela
1. Vá em **SQL Editor**
2. Cole o script `create_chat_table.sql`
3. Execute (Run)

#### Passo 3: Verificar RLS
As políticas RLS já estão configuradas para acesso público via anon key.

### 2. Configurar Frontend

Abra o arquivo HTML e configure:

```javascript
// Linha ~260
const SUPABASE_URL = 'https://seu-projeto.supabase.co';
const SUPABASE_KEY = 'sua-anon-key-aqui';
```

### 3. Webhook n8n

O webhook já está configurado:
```javascript
const CHAT_WEBHOOK = 'https://webhook.chatdevendas.online/webhook/iaphyo3451';
```

**Se precisar alterar**, modifique a linha ~257.

---

## 📁 Estrutura do Projeto

```
/projeto-chat/
├── index.html              # Chat completo (HTML + CSS + JS)
├── create_chat_table.sql   # Script SQL para Supabase
└── README.md              # Esta documentação
```

### Arquivo Único

Todo o sistema está em **um único arquivo HTML** para facilitar deploy:
- HTML estrutural
- CSS inline (com variáveis CSS para temas)
- JavaScript com jQuery e Supabase

---

## 🎨 Funcionalidades Detalhadas

### Tema Claro/Escuro

**Toggle manual:**
- Botão no header (ícone 🌙/☀️)
- Salva preferência no localStorage
- Transição suave entre temas

**Variáveis CSS:**
```css
:root {
    --bg-primary: #ffffff;
    --text-primary: #212529;
    /* ... */
}

[data-theme="dark"] {
    --bg-primary: #1a1a1a;
    --text-primary: #e9ecef;
    /* ... */
}
```

### Sistema de Cache (Supabase)

**Salvamento automático:**
- Cada mensagem é salva na tabela `chat_messages`
- Vinculada ao `session_id` único do navegador
- Timestamp para ordenação

**Carregamento:**
- Ao abrir o chat, carrega histórico da sessão
- Ordenado cronologicamente
- Remove empty state se houver mensagens

**Limpeza:**
- Botão "Limpar Conversa" no header
- Deleta mensagens da sessão atual
- Gera novo `session_id`
- Reseta UI para empty state

### Mensagens

**Tipos:**
1. **Texto** - Digitação normal
2. **Áudio** - Gravação via microfone
3. **Loading** - Enquanto aguarda resposta
4. **Erro** - Feedback de falhas

**Formatação:**
- Mensagens do usuário: azul, alinhadas à direita
- Mensagens do assistente: cinza, alinhadas à esquerda
- Avatares com ícones (👤 e 🤖)
- Auto-scroll para última mensagem

### Sugestões Rápidas

No empty state, três pills clicáveis:
- 🤖 Processos Automatizáveis
- 💰 Redução de Custos
- 📈 Aumentar Produtividade

Ao clicar, preenche o input e envia automaticamente.

### Gravação de Áudio

1. Clique no ícone 🎤
2. Concede permissão ao microfone
3. Botão fica vermelho pulsando (⏹️)
4. Clique novamente para parar
5. Áudio é enviado em base64 para webhook

---

## 🔌 Integração n8n

### Formato de Requisição

**Mensagem de Texto:**
```json
{
  "type": "text",
  "message": "Como automatizar meu atendimento?",
  "session_id": "session_1234567890_abc123",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

**Mensagem de Áudio:**
```json
{
  "type": "audio",
  "audio": "base64_encoded_audio_data",
  "format": "webm",
  "session_id": "session_1234567890_abc123",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### Formato de Resposta Esperado

O n8n deve retornar JSON:

```json
{
  "response": "Texto da resposta do assistente..."
}
```

**OU**

```json
{
  "message": "Texto da resposta..."
}
```

**OU** string simples:

```
"Resposta do assistente"
```

### Configuração no n8n

**Workflow sugerido:**

```
Webhook → Function (processar) → HTTP Request (IA) → Respond
```

**Webhook Node:**
- Method: POST
- Path: `/webhook/iaphyo3451`
- Response Mode: Immediately

**Function Node (exemplo):**
```javascript
const type = $input.item.json.body.type;
const message = $input.item.json.body.message;
const sessionId = $input.item.json.body.session_id;

// Processar lógica
// Enviar para IA (OpenAI, Anthropic, etc)

return {
  json: {
    response: "Resposta processada pela IA"
  }
};
```

---

## 🎯 Casos de Uso

### 1. Descoberta de Processos

**Usuário:** "Quais processos posso automatizar?"

**Sistema analisa:**
- Setor da empresa
- Tamanho do time
- Processos repetitivos
- Gargalos operacionais

**Retorna:** Sugestões específicas de automação

### 2. Análise de ROI

**Usuário:** "Quanto economizarei com IA?"

**Sistema calcula:**
- Tempo economizado
- Redução de erros
- Custo vs benefício
- Payback estimado

### 3. Planejamento de Implementação

**Usuário:** "Por onde começar?"

**Sistema sugere:**
- Quick wins (ganhos rápidos)
- Processo piloto
- Roadmap de implementação
- Métricas de sucesso

---

## 🛠️ Customização

### Alterar Cores

Edite as variáveis CSS (linhas ~22-45):

```css
:root {
    --user-msg-bg: #0d6efd;  /* Cor mensagem usuário */
    --assistant-msg-bg: #f8f9fa; /* Cor mensagem assistente */
    /* ... */
}
```

### Alterar Textos

**Empty State** (linha ~325):
```html
<h2 class="empty-state-title">
    Seu Título Aqui
</h2>
<p class="empty-state-description">
    Sua descrição aqui...
</p>
```

**Sugestões** (linha ~333):
```html
<div class="suggestion-pill" data-suggestion="Sua pergunta">
    🤖 Seu Texto
</div>
```

### Alterar Webhook

Linha ~257:
```javascript
const CHAT_WEBHOOK = 'https://seu-webhook.com/endpoint';
```

---

## 🐛 Troubleshooting

### Problema: Mensagens não salvam no Supabase

**Verificar:**
1. URL e Key do Supabase estão corretas?
2. Tabela `chat_messages` foi criada?
3. RLS está habilitado e políticas criadas?
4. Console do navegador mostra erros?

**Solução:**
```javascript
// Teste no console do navegador
console.log(supabase);
```

### Problema: Webhook não responde

**Verificar:**
1. URL do webhook está correta?
2. n8n workflow está ativo?
3. Webhook aceita POST?
4. Network tab mostra status 200?

**Debug:**
```javascript
// Adicione console.log antes do AJAX
console.log('Enviando:', { type, message, session_id });
```

### Problema: Áudio não grava

**Verificar:**
1. Navegador deu permissão ao microfone?
2. Está usando HTTPS (obrigatório para getUserMedia)?
3. Microfone está funcionando?

**Teste:**
```javascript
navigator.mediaDevices.getUserMedia({ audio: true })
  .then(stream => console.log('Microfone OK!'))
  .catch(err => console.error('Erro:', err));
```

### Problema: Tema não muda

**Verificar:**
1. localStorage está habilitado?
2. Toggle está sendo clicado?
3. Variáveis CSS estão carregadas?

**Limpar cache:**
```javascript
localStorage.clear();
location.reload();
```

---

## 📊 Analytics (Opcional)

O SQL criou a tabela `chat_sessions` para analytics.

**Consultas úteis:**

```sql
-- Conversas de hoje
SELECT COUNT(DISTINCT session_id) FROM chat_messages
WHERE DATE(timestamp) = CURRENT_DATE;

-- Média de mensagens por conversa
SELECT AVG(message_count) FROM chat_sessions;

-- Sessões ativas (24h)
SELECT * FROM vw_chat_analytics 
WHERE last_message > NOW() - INTERVAL '24 hours';
```

---

## 🚀 Deploy

### Opção 1: Arquivo Único

1. Faça upload do `index.html` para qualquer servidor
2. Configure as variáveis Supabase
3. Acesse via browser

### Opção 2: Netlify/Vercel

```bash
# Netlify
netlify deploy --prod

# Vercel
vercel --prod
```

### Opção 3: GitHub Pages

1. Commit o arquivo
2. Ative GitHub Pages no repositório
3. Acesse via `username.github.io/repo`

**⚠️ IMPORTANTE:** 
- Use HTTPS para gravação de áudio funcionar
- Configure CORS no n8n se necessário

---

## 📝 Checklist de Deploy

- [ ] Supabase configurado (URL + Key)
- [ ] Tabela `chat_messages` criada
- [ ] RLS habilitado e políticas configuradas
- [ ] Webhook n8n testado e funcionando
- [ ] n8n retornando resposta correta
- [ ] Tema claro/escuro funcionando
- [ ] Cache salvando e carregando
- [ ] Gravação de áudio testada
- [ ] Responsividade verificada (mobile)
- [ ] HTTPS habilitado (se usar áudio)
- [ ] Textos personalizados
- [ ] Cores ajustadas (se necessário)

---

## 🎓 Próximos Passos

### Melhorias Sugeridas:

1. **Autenticação**
   - Login de usuários
   - Múltiplas conversas por usuário
   - Dashboard de histórico

2. **Analytics Avançado**
   - Dashboards de métricas
   - Funil de conversão
   - Tópicos mais discutidos

3. **Recursos Extras**
   - Export de conversa (PDF)
   - Compartilhamento de chat
   - Tags e categorização
   - Busca no histórico

4. **IA Melhorada**
   - Respostas com markdown
   - Sugestões contextuais
   - Análise de sentimento
   - Recomendações personalizadas

---

## 📞 Suporte

**Logs:**
- Console do navegador (F12)
- Supabase Dashboard → Logs
- n8n Executions

**Debug Mode:**
```javascript
// Adicione no início do script
const DEBUG = true;
if (DEBUG) console.log('Debug info:', data);
```

---

## 📄 Licença

Sistema desenvolvido para otimização empresarial com IA.

**Desenvolvido com ❤️ usando Bootstrap, jQuery e Supabase** 🚀

---

## 🎉 Pronto para Usar!

O sistema está **100% funcional** e pronto para deploy. Basta configurar suas credenciais do Supabase e começar a usar!

**Foco:** Ajudar empresários a descobrir como IA pode transformar seus negócios! 💡