---
name: smartsales-enterprise
description: >
  Contexto completo do projeto Salesforce SmartSales Enterprise para portfólio.
  Use este skill SEMPRE que o usuário mencionar: SmartSales, projeto Salesforce, 
  Apex portfólio, triggers, LWC, callouts, Einstein, Agentforce, batch jobs, 
  flows, permission sets, CI/CD Salesforce, ou qualquer dúvida sobre o projeto.
  Também acionar quando perguntar sobre padrões como TriggerHandler, Service Layer, 
  Selector Pattern no contexto Salesforce, ou pedir para continuar/avançar algum 
  passo do projeto.
---

# SmartSales Enterprise — Skill de Contexto Completo

Este skill dá ao Claude Code todo o contexto necessário para ajudar no projeto
**SmartSales Enterprise**, um CRM B2B enterprise completo em Salesforce para portfólio.

---

## 👤 Desenvolvedor

- **Nome:** Denison
- **GitHub:** `Dentheo-Dev`
- **Nível:** Pleno (estudando para PD1)
- **Linguagem de comunicação:** Português brasileiro informal
- **Explicações:** sempre claras, sem jargão desnecessário

---

## 🗂️ Ambiente Local

```
Projeto:   C:\projetos\SmartSalesEnterprise
Org alias: fechanegocio  (Developer Edition)
CLI:       sf (Salesforce CLI moderno)
Editor:    VS Code + Salesforce Extension Pack
Git:       configurado, remote no GitHub (Dentheo-Dev/SmartSalesEnterprise)
API Ver.:  61.0
```

**Comandos mais usados — sempre sugerir estes:**
```bash
# Deploy
sf project deploy start --source-dir force-app

# Testes
sf apex run test --test-level RunLocalTests --code-coverage --result-format human

# Abrir org
sf org open --target-org fechanegocio

# Pull da org
sf project retrieve start --source-dir force-app

# Executar Apex anônimo
sf apex run --file scripts/nome-do-script.apex
```

---

## 🏗️ Arquitetura em Camadas

```
┌─────────────────────────────────────────────┐
│              LWC (Interface)                │
├─────────────────────────────────────────────┤
│         Flows + Approval Process            │
├──────────────┬──────────────────────────────┤
│   Triggers   │    REST API Endpoints        │
│   Handlers   │    (@RestResource)           │
├──────────────┴──────────────────────────────┤
│              Service Layer                  │
├──────────────┬──────────────────────────────┤
│  Selectors   │   Callout Services           │
│  (SOQL)      │   (APIs Externas + IA)       │
├──────────────┴──────────────────────────────┤
│   Custom Metadata Types  │  Platform Events │
├──────────────────────────┴──────────────────┤
│         Custom Objects (Data Model)         │
└─────────────────────────────────────────────┘
```

---

## 📦 Estrutura de Pastas

```
force-app/main/default/
├── classes/
│   ├── handlers/       → Trigger Handlers (ex: OpportunityTriggerHandler.cls)
│   ├── services/       → Regras de negócio (ex: LeadScoringService.cls)
│   ├── selectors/      → Queries SOQL isoladas (ex: OpportunitySelector.cls)
│   ├── batch/          → Batch Apex (ex: CustomerHealthBatch.cls)
│   ├── schedulable/    → Scheduled Jobs (ex: ContractRenewalScheduled.cls)
│   ├── rest/           → REST endpoints (ex: SmartSalesAccountResource.cls)
│   ├── callouts/       → APIs externas (ex: SendGridCalloutService.cls)
│   ├── ai/             → IA (ex: OpenAICalloutService.cls, AgentActions)
│   ├── utils/          → Utilitários (ex: SecurityUtils.cls, HttpCalloutService.cls)
│   └── tests/          → Testes (ex: LeadScoringServiceTest.cls)
├── lwc/                → 5 componentes LWC
├── flows/              → 5 flows de automação
├── objects/            → 5 objetos custom + campos em objetos padrão
├── permissionsets/     → 3 permission sets
├── namedCredentials/   → 5 credenciais de API
├── platformEvents/     → Deal_Alert__e, Health_Update__e
└── customMetadata/     → Commission_Rule__mdt, Lead_Score_Rule__mdt, Integration_Config__mdt
```

---

## 🗄️ Data Model — Objetos Customizados

| Objeto | Finalidade | Relacionamento |
|---|---|---|
| `Product_Proposal__c` | Proposta comercial | Lookup → Opportunity, Account, Contact |
| `Contract_Renewal__c` | Renovação de contrato | Lookup → Account |
| `Customer_Health__c` | Score de saúde do cliente | Master-Detail → Account |
| `Commission__c` | Comissão do vendedor | Lookup → Opportunity, User |
| `Integration_Log__c` | Log de chamadas de API | Standalone (auto-number) |

**Campos custom em objetos padrão:**
- `Opportunity`: `AI_Next_Step__c`, `Commission_Calculated__c`, `Health_Risk__c`
- `Lead`: `Lead_Score__c`, `Score_Reason__c`, `Company_Size__c`, `Annual_Revenue_Estimate__c`
- `Account`: `CEP__c`, `Bairro__c`, `Customer_Since__c`, `Current_Health_Score__c`

---

## ⚙️ Regras Obrigatórias de Código

Estas regras devem ser seguidas em TODO arquivo gerado:

1. **TriggerHandler Pattern** — lógica NUNCA direto no trigger
2. **Service Layer** — regras de negócio separadas dos triggers
3. **Selector Pattern** — queries SOQL sempre em classes Selector isoladas
4. **Named Credentials** — NUNCA hardcode de URL, token ou senha
5. **CRUD + FLS** — verificar antes de toda operação DML (usar `SecurityUtils.cls`)
6. **Sem SOQL em loop** — queries sempre fora de `for`
7. **Testes obrigatórios** — toda classe pública tem teste correspondente (mínimo 95%)
8. **Callout Mocks** — testes de callout usam `HttpCalloutMock`
9. **Comentários em português** — blocos complexos explicados em PT-BR
10. **Commit a cada passo** — deploy + commit antes de avançar

---

## 🔌 Integrações Externas

| Serviço | Named Credential | Para quê |
|---|---|---|
| ViaCEP | `ViaCEP_API` | Preencher endereço por CEP (gratuito, BR) |
| SendGrid | `SendGrid_API` | Envio de e-mail de proposta |
| Slack | `Slack_Webhook` | Alerta quando deal é fechado |
| ERP Mock | `ERP_API` | Simular integração com sistema financeiro |
| OpenAI | `OpenAI_API` | Gerar insights e e-mails com IA |

**Classe base de callout:** `HttpCalloutService.cls`
- Toda integração herda desta classe
- Salva log automático em `Integration_Log__c`
- Retorna objeto `CalloutResult` com: success, statusCode, body, errorMessage

---

## 🤖 Camada de IA

### OpenAI (via Callout)
Classe: `OpenAICalloutService.cls`
- `generateCustomerInsight(Account, List<Opportunity>)` → salva em `AI_Health_Analysis__c`
- `generateFollowUpEmail(Opportunity, Contact)` → salva em `AI_Next_Step__c`
- `generateProposalSummary(Product_Proposal__c)` → salva em `AI_Summary__c`
- Modelo: `gpt-4o` | max_tokens: 500 | temperatura: 0.7
- Batch semanal: `AIInsightBatch.cls` (toda segunda às 7h)

### Agentforce
Agente: **SmartSales Assistant**
- Apex Actions (InvocableMethod):
  - `AgentGetCustomerSummary.cls` — resumo completo do cliente
  - `AgentSuggestNextStep.cls` — próximo passo com IA
- Prompt Template: `FollowUpEmailTemplate` (e-mail em português)

### Einstein (declarativo)
- Einstein Lead Scoring (configurado no Setup)
- Einstein Opportunity Scoring
- Einstein Activity Capture

---

## ⚡ LWC — Componentes

| Componente | Onde fica | O que faz |
|---|---|---|
| `opportunityDashboard` | Home/App Page | Dashboard do pipeline com KPIs |
| `leadScoreCard` | Lead Record Page | Score visual com barra de progresso |
| `proposalWizard` | Opportunity Record Page | Wizard 3 passos para criar proposta |
| `aiInsightPanel` | Account Record Page (sidebar) | Insights de IA com cache de 24h |
| `customerHealthCard` | Account Record Page | Score de saúde colorido com métricas |

**Padrão obrigatório nos LWC:**
- `@wire` para dados frequentes
- `@api` para props configuráveis no App Builder
- `lightning-spinner` durante carregamento
- Tratamento de erro com mensagem amigável

---

## 🔄 Batch Jobs e Schedules

| Classe | Frequência | O que faz |
|---|---|---|
| `LeadCleanupBatch` | Diário 1h | Inativa leads sem atividade 90+ dias |
| `CustomerHealthBatch` | Diário 2h | Recalcula health score de todas as accounts |
| `CommissionSummaryBatch` | Dia 1 do mês 8h | Consolida comissões do mês |
| `ContractRenewalScheduled` | Toda segunda 9h | Alerta sobre contratos expirando em 30 dias |
| `ProposalExpirationBatch` | Diário 0h | Expira propostas com Valid_Until passado |
| `AIInsightBatch` | Toda segunda 7h | Gera insights de IA para clientes ativos |

**Para agendar tudo de uma vez:**
```apex
BatchScheduler.scheduleAll();
```

---

## 🔐 Segurança

| Permission Set | Para quem | Acesso |
|---|---|---|
| `SmartSales_Sales_Rep` | Vendedor | CRCE em Opp, Lead, Contact, Account, Proposal |
| `SmartSales_Sales_Manager` | Gerente | Tudo do Rep + Commission de todos + Integration_Log (read) |
| `SmartSales_Admin` | Admin | Modify All + Setup + Batch manual |

**`SecurityUtils.cls`** — verificar antes de todo DML:
- `checkFLSRead()`, `checkFLSWrite()`, `checkObjectAccess()`

---

## 📋 Os 16 Passos do Projeto

Consultar `references/passos.md` para o detalhamento completo de cada passo.

| # | Passo | Status sugerido |
|---|---|---|
| 1 | Setup + GitHub | ✅ Fazer primeiro |
| 2 | Data Model (objetos e campos) | |
| 3 | Triggers + TriggerHandlers | |
| 4 | Service Layer | |
| 5 | Selector Layer | |
| 6 | Integrações REST externas | |
| 7 | IA (OpenAI + Einstein + Agentforce) | |
| 8 | Batch + Scheduled Jobs | |
| 9 | REST API (Salesforce como servidor) | |
| 10 | Platform Events | |
| 11 | LWC Components | |
| 12 | Flows de automação | |
| 13 | Segurança + Permission Sets | |
| 14 | Custom Metadata Types | |
| 15 | CI/CD GitHub Actions | |
| 16 | README final | |

---

## 🚦 Como Usar Esta Skill

Quando o Denison pedir ajuda em qualquer parte do projeto:

1. **Identifique o passo atual** — pergunte se não souber
2. **Consulte `references/passos.md`** para o detalhamento do passo
3. **Aplique as regras obrigatórias** de código sempre
4. **Gere código completo e funcional** — não esqueletos
5. **Inclua o teste correspondente** junto com cada classe
6. **Termine sugerindo o comando de deploy e o commit**
7. **Sugira o próximo passo** ao finalizar

**Ao gerar qualquer código Apex, sempre verificar:**
- Tem classe de teste junto?
- Tem SOQL em loop? (NUNCA pode ter)
- Tem hardcode de ID/URL/token? (NUNCA pode ter)
- Verifica FLS antes do DML? (SEMPRE deve ter)