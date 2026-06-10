# 🚀 PROMPT MASTER — SmartSales Enterprise (Salesforce Apex)
# Cole este prompt no Claude Code para construir o projeto completo

---

## CONTEXTO GERAL

Você é um Salesforce Developer Sênior especialista em arquitetura enterprise.
Vamos construir juntos o projeto **SmartSales Enterprise** — um CRM B2B completo
no Salesforce que serve como portfólio profissional de alto nível.

O projeto simula uma empresa de tecnologia que vende software B2B, com pipeline
de vendas, automações, integrações com APIs externas, IA com Einstein/Agentforce
e OpenAI, LWC modernos, testes completos e CI/CD.

**Ambiente:**
- VS Code com Salesforce Extension Pack
- SF CLI instalado (`sf` command)
- Projeto localizado em: `C:\projetos\SmartSalesEnterprise`
- Org Salesforce Developer Edition (alias: fechanegocio)
- Git + GitHub configurados

**Regras gerais que você deve seguir em TODO o projeto:**
1. Sempre usar padrão **TriggerHandler** — nunca lógica direto no trigger
2. Sempre usar **Service Layer** — separar regras de negócio
3. Sempre usar **Selector/Repository Pattern** — queries SOQL isoladas
4. Todo Apex deve ter **classe de teste correspondente** com mínimo 95% coverage
5. Todos os callouts devem usar **Named Credentials** — nunca hardcode de URL/token
6. Sempre verificar **CRUD e FLS** antes de DML operations
7. Nomenclatura clara: sufixos `__c` em objetos custom, `Service`, `Handler`, `Selector`, `Test`
8. Comentários explicativos em português em blocos complexos
9. Cada passo deve ser **deployável e funcional** antes de avançar

---

## PASSO 1 — Setup do Projeto e Estrutura de Pastas

### Objetivo
Criar o projeto SFDX, conectar na org e montar toda a estrutura de pastas.

### Tarefas

1. Crie o projeto Salesforce com o comando:
```bash
sf project generate --name SmartSalesEnterprise --template standard --output-dir C:\projetos
```

2. Conecte na org Developer Edition:
```bash
sf org login web --alias fechanegocio --set-default
```

3. Crie a seguinte estrutura de pastas dentro de `force-app/main/default/`:

```
classes/
  handlers/         ← Trigger Handlers
  services/         ← Regras de negócio
  selectors/        ← Queries SOQL isoladas
  batch/            ← Batch Apex
  schedulable/      ← Scheduled Jobs
  rest/             ← REST API endpoints
  callouts/         ← Chamadas para APIs externas
  ai/               ← Serviços de IA (Einstein, OpenAI)
  utils/            ← Classes utilitárias
  tests/            ← Todas as classes de teste
lwc/                ← Lightning Web Components
flows/              ← Flows de automação
objects/            ← Objetos e campos custom
permissionsets/     ← Permission Sets
namedCredentials/   ← Credenciais de API
platformEvents/     ← Platform Events
customMetadata/     ← Custom Metadata Types
staticresources/    ← Recursos estáticos
```

4. Configure o `sfdx-project.json` com:
   - `sourceApiVersion`: "61.0"
   - `packageDirectories` apontando para `force-app`
   - `namespace`: vazio (sem namespace)

5. Crie o `.gitignore` adequado para projetos Salesforce

6. Inicialize o repositório Git e faça o primeiro commit com a mensagem:
   `feat: initial project setup - SmartSales Enterprise`

7. Crie o `README.md` com título, descrição e seções: Sobre, Tecnologias, Estrutura, Como rodar, Funcionalidades (pode deixar como TODO por enquanto)

**Resultado esperado:** Projeto criado, conectado na org, estrutura de pastas pronta, primeiro commit feito.

---

## PASSO 2 — Data Model (Objetos e Campos Customizados)

### Objetivo
Criar todos os objetos customizados e os relacionamentos entre eles.

### Objetos a criar

#### 2.1 `Product_Proposal__c` — Proposta Comercial
Campos:
- `Name` (padrão — usar como número da proposta ex: PROP-0001)
- `Opportunity__c` — Lookup para Opportunity
- `Account__c` — Lookup para Account
- `Contact__c` — Lookup para Contact
- `Total_Value__c` — Currency
- `Discount_Percentage__c` — Percent
- `Final_Value__c` — Currency (formula: Total_Value * (1 - Discount))
- `Status__c` — Picklist: Rascunho, Enviada, Aprovada, Rejeitada, Expirada
- `Valid_Until__c` — Date
- `Proposal_Notes__c` — Long Text Area
- `AI_Summary__c` — Long Text Area (gerado por IA)
- `Sent_Date__c` — DateTime
- `Approved_By__c` — Lookup para User

#### 2.2 `Contract_Renewal__c` — Renovação de Contrato
Campos:
- `Name` (padrão — número da renovação)
- `Account__c` — Lookup para Account
- `Original_Contract_End__c` — Date
- `New_Contract_End__c` — Date
- `Renewal_Value__c` — Currency
- `Status__c` — Picklist: Pendente, Em Negociação, Renovado, Cancelado
- `Days_Until_Expiration__c` — Number (formula)
- `Renewal_Probability__c` — Percent
- `Owner__c` — Lookup para User
- `Notes__c` — Long Text Area

#### 2.3 `Customer_Health__c` — Score de Saúde do Cliente
Campos:
- `Name` (padrão)
- `Account__c` — Master-Detail para Account
- `Health_Score__c` — Number (0-100)
- `Health_Status__c` — Picklist: Crítico (0-30), Em Risco (31-60), Saudável (61-80), Excelente (81-100)
- `Open_Cases__c` — Number
- `Last_Purchase_Days__c` — Number
- `NPS_Score__c` — Number
- `Payment_Delays__c` — Number
- `Last_Calculated__c` — DateTime
- `AI_Health_Analysis__c` — Long Text Area (gerado por IA)

#### 2.4 `Commission__c` — Comissão do Vendedor
Campos:
- `Name` (padrão)
- `Opportunity__c` — Lookup para Opportunity
- `Sales_Rep__c` — Lookup para User
- `Commission_Rate__c` — Percent
- `Commission_Amount__c` — Currency
- `Status__c` — Picklist: Calculada, Aprovada, Paga
- `Payment_Date__c` — Date
- `Period__c` — Text (ex: 2024-01)
- `Notes__c` — Text Area

#### 2.5 `Integration_Log__c` — Log de Integrações
Campos:
- `Name` (padrão — auto number)
- `Service_Name__c` — Text (ex: SendGrid, Slack, OpenAI)
- `Request_Body__c` — Long Text Area
- `Response_Body__c` — Long Text Area
- `Status_Code__c` — Number
- `Success__c` — Checkbox
- `Error_Message__c` — Text Area
- `Duration_Ms__c` — Number
- `Related_Record_Id__c` — Text
- `Created_At__c` — DateTime

### Campos custom em objetos PADRÃO

#### Em `Opportunity`:
- `Lead_Source_Detail__c` — Text
- `Expected_Close_Reason__c` — Text Area
- `Competitor__c` — Text
- `AI_Next_Step__c` — Long Text Area (sugestão de IA)
- `Commission_Calculated__c` — Checkbox
- `Health_Risk__c` — Checkbox

#### Em `Lead`:
- `Lead_Score__c` — Number (0-100)
- `Score_Reason__c` — Text Area
- `Company_Size__c` — Picklist: 1-10, 11-50, 51-200, 201-1000, 1000+
- `Annual_Revenue_Estimate__c` — Currency
- `Source_Campaign__c` — Text

#### Em `Account`:
- `CEP__c` — Text (CEP brasileiro)
- `Bairro__c` — Text
- `Customer_Since__c` — Date
- `Total_Revenue__c` — Currency (rollup)
- `Current_Health_Score__c` — Number (formula do último Customer_Health__c)

### Validações e regras a configurar:
- `Product_Proposal__c`: Desconto não pode ser maior que 50% sem aprovação
- `Commission__c`: Commission_Rate não pode ser negativa
- `Contract_Renewal__c`: New_Contract_End deve ser depois de Original_Contract_End

**Resultado esperado:** Todos os objetos e campos criados na org e nos metadados locais. Fazer deploy e commit: `feat: data model - custom objects and fields`

---

## PASSO 3 — Trigger Handlers (Padrão Enterprise)

### Objetivo
Criar a estrutura de triggers seguindo o padrão TriggerHandler profissional.

### 3.1 Criar a classe base `TriggerHandler.cls`
Classe abstrata com os métodos:
- `beforeInsert()`
- `beforeUpdate()`
- `beforeDelete()`
- `afterInsert()`
- `afterUpdate()`
- `afterDelete()`
- `afterUndelete()`
- Método `run()` que chama o método certo baseado em `Trigger.operationType`
- Suporte a bypass por nome de classe (para testes)

### 3.2 Criar os Triggers e Handlers

#### `OpportunityTrigger.trigger` + `OpportunityTriggerHandler.cls`
Lógica no handler:
- `afterInsert`: Chamar `CommissionCalculatorService` para criar registro de comissão
- `afterUpdate`: Se Stage mudou para "Closed Won" → chamar `SlackCalloutService` para notificar time
- `afterUpdate`: Se Amount mudou → recalcular comissão
- `beforeInsert/Update`: Validar que Close Date não é no passado

#### `LeadTrigger.trigger` + `LeadTriggerHandler.cls`
Lógica no handler:
- `afterInsert`: Chamar `LeadScoringService` para calcular score
- `afterUpdate`: Se Email mudou → recalcular score
- `beforeInsert`: Normalizar telefone para formato brasileiro

#### `CaseTrigger.trigger` + `CaseTriggerHandler.cls`
Lógica no handler:
- `afterInsert`: Atualizar `Open_Cases__c` no `Customer_Health__c` da Account
- `afterUpdate`: Se Status mudou para Closed → recalcular health score
- `afterInsert`: Se Priority = High → criar Task urgente para o dono da Account

### 3.3 Criar `TriggerHandlerTest.cls`
Testes unitários para a classe base TriggerHandler.

**Resultado esperado:** 3 triggers funcionando com handlers separados. Deploy + commit: `feat: trigger handlers - opportunity, lead, case`

---

## PASSO 4 — Service Layer (Regras de Negócio)

### Objetivo
Criar todas as classes de serviço com as regras de negócio do sistema.

### 4.1 `LeadScoringService.cls`
Calcula score de 0-100 para um Lead baseado em:
- Tem email corporativo (não gmail/hotmail): +20 pontos
- Company_Size__c é 201-1000 ou 1000+: +25 pontos
- Annual_Revenue_Estimate__c > 1.000.000: +20 pontos
- Tem telefone preenchido: +10 pontos
- LeadSource é "Web" ou "Referral": +15 pontos
- Título contém "CEO", "CTO", "Director", "VP": +10 pontos
- Método principal: `scoreLeads(List<Lead> leads)`
- Preencher `Lead_Score__c` e `Score_Reason__c`

### 4.2 `CommissionCalculatorService.cls`
Calcula comissão baseada em regras:
- Deal < R$10.000: 3%
- Deal R$10.001 a R$50.000: 5%
- Deal R$50.001 a R$200.000: 7%
- Deal > R$200.000: 10%
- Cria registro `Commission__c` automaticamente
- Método: `calculateCommission(List<Opportunity> opps)`

### 4.3 `CustomerHealthService.cls`
Calcula score de saúde do cliente (0-100):
- Open Cases > 5: -30 pontos
- Last Purchase > 365 dias: -25 pontos
- Payment Delays > 2: -20 pontos
- NPS Score > 8: +20 pontos
- NPS Score < 5: -20 pontos
- Score base: 70
- Cria/atualiza `Customer_Health__c` e define `Health_Status__c`
- Método: `calculateHealth(List<Id> accountIds)`

### 4.4 `ProposalService.cls`
Gerencia ciclo de vida das propostas:
- `createProposal(Id opportunityId)`: Cria proposta a partir de uma Opportunity
- `sendProposal(Id proposalId)`: Muda status para Enviada, seta Sent_Date, dispara e-mail
- `expireProposals()`: Método para ser chamado pelo Batch — expira propostas vencidas
- `validateDiscount(Product_Proposal__c proposal)`: Valida regras de desconto

### 4.5 Criar testes para cada Service:
- `LeadScoringServiceTest.cls`
- `CommissionCalculatorServiceTest.cls`
- `CustomerHealthServiceTest.cls`
- `ProposalServiceTest.cls`

Cada teste deve ter:
- `@TestSetup` com criação de dados de teste
- Cenários positivos (caminho feliz)
- Cenários negativos (erros e exceções)
- Verificação de todos os campos calculados

**Resultado esperado:** 4 services completos com testes. Deploy + commit: `feat: service layer - scoring, commission, health, proposal`

---

## PASSO 5 — Selector Layer (Queries SOQL Isoladas)

### Objetivo
Centralizar todas as queries SOQL em classes Selector para reuso e testabilidade.

### Classes a criar

#### `OpportunitySelector.cls`
- `getByAccountId(Set<Id> accountIds)` — busca opp por conta com campos principais
- `getClosedWonThisMonth()` — oportunidades fechadas no mês atual
- `getAtRiskOpportunities()` — opps com Close Date nos próximos 7 dias ainda abertas
- `getWithCommission(Set<Id> oppIds)` — opp com Commission__c relacionada

#### `LeadSelector.cls`
- `getUnscored()` — leads sem score calculado
- `getBySource(String source)` — leads por origem
- `getRecentLeads(Integer days)` — leads criados nos últimos N dias

#### `AccountSelector.cls`
- `getWithHealthScore(Set<Id> accountIds)` — accounts com Customer_Health__c
- `getCustomersWithoutRecentActivity(Integer days)` — clientes sem atividade
- `getByCEP(String cep)` — busca por CEP

#### `CaseSelector.cls`
- `getOpenByAccount(Set<Id> accountIds)` — cases abertos por conta
- `getHighPriorityOpen()` — cases de alta prioridade em aberto

**Padrão obrigatório em todos os Selectors:**
- Verificar FLS antes de cada query
- Métodos estáticos
- Documentação com `@param` e `@return`

**Resultado esperado:** 4 selectors criados. Deploy + commit: `feat: selector layer - SOQL queries isolated`

---

## PASSO 6 — Integrações com APIs Externas (Callouts)

### Objetivo
Criar todas as integrações com APIs externas usando Named Credentials e padrão profissional.

### 6.1 Criar `HttpCalloutService.cls` (classe base)
Classe utilitária base para todos os callouts:
- Método `sendRequest(String namedCredential, String endpoint, String method, String body)`
- Trata erros HTTP (4xx, 5xx)
- Salva log em `Integration_Log__c` automaticamente
- Retorna objeto `CalloutResult` com: success, statusCode, body, errorMessage

### 6.2 `ViaCEPCalloutService.cls`
Integração com a API gratuita brasileira ViaCEP:
- Named Credential: `ViaCEP_API` (URL base: https://viacep.com.br)
- Método: `getAddressByCEP(String cep)`
- Retorna: logradouro, bairro, cidade, estado
- Usado pelo trigger/flow para preencher endereço automático na Account
- Mock para testes: `ViaCEPMock.cls`

### 6.3 `SendGridCalloutService.cls`
Integração para envio de e-mail via SendGrid:
- Named Credential: `SendGrid_API`
- Método: `sendEmail(String toEmail, String toName, String subject, String htmlBody)`
- Usado por `ProposalService` ao enviar proposta
- Template HTML básico de proposta como String
- Mock para testes: `SendGridMock.cls`

### 6.4 `SlackCalloutService.cls`
Integração com Slack via Webhook:
- Named Credential: `Slack_Webhook`
- Método: `sendDealAlert(String opportunityName, Decimal amount, String ownerName)`
- Formata mensagem com emoji e detalhes do deal
- Chamado quando Opportunity vai para Closed Won
- Mock para testes: `SlackMock.cls`

### 6.5 `MockERPCalloutService.cls`
Simula integração com ERP externo (usando mocky.io ou requestbin):
- Named Credential: `ERP_API`
- Método: `syncOrder(Id opportunityId)` — envia dados da opp para ERP
- Método: `getOrderStatus(String externalOrderId)` — consulta status no ERP
- Retorna objeto com: externalId, status, message
- Mock para testes: `ERPMock.cls`

### Named Credentials a configurar nos metadados:
```
ViaCEP_API → https://viacep.com.br
SendGrid_API → https://api.sendgrid.com
Slack_Webhook → https://hooks.slack.com
ERP_API → https://run.mocky.io (mock URL)
OpenAI_API → https://api.openai.com (para o próximo passo)
```

### Testes:
- `HttpCalloutServiceTest.cls`
- `ViaCEPCalloutServiceTest.cls`
- `SendGridCalloutServiceTest.cls`
- `SlackCalloutServiceTest.cls`
- `MockERPCalloutServiceTest.cls`

Todos os testes de callout devem usar `Test.setMock(HttpCalloutMock.class, new XxxMock())`

**Resultado esperado:** 5 integrações funcionando com mocks e logs. Deploy + commit: `feat: external API integrations - ViaCEP, SendGrid, Slack, ERP`

---

## PASSO 7 — Inteligência Artificial

### Objetivo
Integrar IA de três formas: Einstein nativo, OpenAI via callout e Agentforce.

### 7.1 `OpenAICalloutService.cls`
Integração com a API do ChatGPT (GPT-4o):
- Named Credential: `OpenAI_API`
- Método: `generateCustomerInsight(Account acc, List<Opportunity> opps)` — analisa perfil do cliente e gera recomendações para o vendedor
- Método: `generateFollowUpEmail(Opportunity opp, Contact contact)` — gera e-mail de follow-up personalizado
- Método: `generateProposalSummary(Product_Proposal__c proposal)` — resume a proposta em linguagem clara
- Payload: modelo `gpt-4o`, max_tokens: 500, temperatura: 0.7
- Salvar resultado nos campos `AI_*` dos objetos correspondentes
- Mock: `OpenAIMock.cls`

**Prompt exemplo para generateCustomerInsight:**
```
Você é um assistente de vendas B2B. Com base nos dados do cliente abaixo, 
forneça 3 insights objetivos e 2 próximos passos recomendados para o vendedor.

Cliente: {nome}
Segmento: {industry}
Receita: {annual_revenue}
Oportunidades abertas: {open_opps}
Health Score: {health_score}
Último contato: {last_activity}

Responda em português, de forma concisa e prática.
```

### 7.2 `AIInsightBatch.cls`
Batch que roda semanalmente para gerar insights de IA para todos os clientes ativos:
- Processa accounts em chunks de 10 (para não estourar callout limits)
- Chama `OpenAICalloutService.generateCustomerInsight()` para cada account
- Salva em `AI_Health_Analysis__c` no `Customer_Health__c`
- Scheduled: toda segunda-feira às 7h

### 7.3 Einstein Configuration (Declarativo — documentar no README)
Documentar como configurar no Setup da org:
- **Einstein Lead Scoring**: Como ativar e mapear campos
- **Einstein Opportunity Scoring**: Como ativar para previsão de fechamento
- **Einstein Activity Capture**: Como conectar com Gmail/Outlook

### 7.4 Agentforce — AI Agent Customizado
Criar um Agente chamado **"SmartSales Assistant"**:

**Definição do Agente (em YAML/metadados):**
- Nome: SmartSales Assistant
- Descrição: Assistente de vendas que ajuda o vendedor a entender seus clientes e oportunidades
- Canal: Salesforce (sidebar)

**Apex Actions que o agente pode chamar:**

`AgentGetCustomerSummary.cls` — Invocable Method:
```
@InvocableMethod(label='Obter Resumo do Cliente' description='Retorna resumo completo de um cliente incluindo health score e oportunidades')
public static List<String> getCustomerSummary(List<Id> accountIds)
```

`AgentSuggestNextStep.cls` — Invocable Method:
```
@InvocableMethod(label='Sugerir Próximo Passo' description='Usa IA para sugerir o próximo passo em uma oportunidade')
public static List<String> suggestNextStep(List<Id> opportunityIds)
```

**Prompt Template** `FollowUpEmailTemplate`:
- Tipo: Sales Email
- Grounding: Opportunity, Account, Contact
- Instrução: gerar e-mail de follow-up profissional em português

### Testes:
- `OpenAICalloutServiceTest.cls`
- `AIInsightBatchTest.cls`
- `AgentGetCustomerSummaryTest.cls`
- `AgentSuggestNextStepTest.cls`

**Resultado esperado:** IA funcionando via callout + Agentforce configurado. Deploy + commit: `feat: AI integration - OpenAI callouts, Einstein config, Agentforce agent`

---

## PASSO 8 — Batch Apex e Scheduled Jobs

### Objetivo
Criar todos os jobs que rodam automaticamente em background.

### 8.1 `LeadCleanupBatch.cls`
- Implementa `Database.Batchable<SObject>` e `Database.Stateful`
- Scope: 200 registros
- Lógica: inativa Leads sem atividade há mais de 90 dias (Status = 'Unqualified', adiciona nota)
- Teste: `LeadCleanupBatchTest.cls`

### 8.2 `CustomerHealthBatch.cls`
- Recalcula `Customer_Health__c` para todas as Accounts ativas
- Chama `CustomerHealthService.calculateHealth()`
- Roda toda noite às 2h
- Escopo: 50 accounts por vez (por causa de callouts)
- Teste: `CustomerHealthBatchTest.cls`

### 8.3 `CommissionSummaryBatch.cls`
- Consolida e totaliza comissões do mês para cada vendedor
- Cria um relatório sumário como `ContentNote` na org
- Roda no primeiro dia de cada mês às 8h
- Teste: `CommissionSummaryBatchTest.cls`

### 8.4 `ContractRenewalScheduled.cls`
- Implementa `Schedulable`
- Verifica `Contract_Renewal__c` com `Original_Contract_End__c` nos próximos 30 dias
- Cria Task para o dono: "Entrar em contato para renovação"
- Envia e-mail via `SendGridCalloutService`
- Roda toda segunda-feira às 9h
- Teste: `ContractRenewalScheduledTest.cls`

### 8.5 `ProposalExpirationBatch.cls`
- Verifica `Product_Proposal__c` com `Valid_Until__c` passada e Status = 'Enviada'
- Muda Status para 'Expirada'
- Notifica o dono da proposta por e-mail
- Roda todo dia à meia-noite
- Teste: `ProposalExpirationBatchTest.cls`

### Classe de agendamento `BatchScheduler.cls`
Classe utilitária com método estático `scheduleAll()` que agenda todos os jobs acima de uma vez. Documentar como executar no Developer Console:
```apex
BatchScheduler.scheduleAll();
```

**Resultado esperado:** 5 jobs funcionando e agendáveis. Deploy + commit: `feat: batch jobs and schedulers - cleanup, health, commission, renewal, proposals`

---

## PASSO 9 — REST API (Salesforce como Servidor)

### Objetivo
Expor endpoints REST para sistemas externos consultarem e enviarem dados.

### 9.1 `SmartSalesAccountResource.cls`
```
@RestResource(urlMapping='/SmartSales/v1/accounts/*')
```
Endpoints:
- `GET /accounts/{id}` — retorna dados da Account com health score e oportunidades
- `GET /accounts?cep={cep}` — busca accounts por CEP
- `POST /accounts` — cria nova Account com enriquecimento via ViaCEP

### 9.2 `SmartSalesOpportunityResource.cls`
```
@RestResource(urlMapping='/SmartSales/v1/opportunities/*')
```
Endpoints:
- `GET /opportunities/{id}` — retorna oportunidade com proposta e comissão
- `POST /opportunities` — cria oportunidade via sistema externo
- `PATCH /opportunities/{id}/stage` — atualiza stage via API

### 9.3 `SmartSalesLeadResource.cls`
```
@RestResource(urlMapping='/SmartSales/v1/leads')
```
Endpoints:
- `POST /leads` — recebe lead de site externo/formulário, calcula score automaticamente
- Retorna: id, score, status, nextStep

### Padrão de resposta JSON para todos os endpoints:
```json
{
  "success": true,
  "data": { ... },
  "message": "OK",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Testes:
- `SmartSalesAccountResourceTest.cls`
- `SmartSalesOpportunityResourceTest.cls`
- `SmartSalesLeadResourceTest.cls`

Usar `RestContext.request` e `RestContext.response` nos testes.

**Resultado esperado:** 3 endpoints REST prontos. Deploy + commit: `feat: REST API endpoints - accounts, opportunities, leads`

---

## PASSO 10 — Platform Events

### Objetivo
Usar Platform Events para comunicação assíncrona entre sistemas.

### 10.1 Criar Platform Events:

`Deal_Alert__e`:
- `Opportunity_Name__c` — Text
- `Amount__c` — Currency
- `Stage__c` — Text
- `Owner_Name__c` — Text
- `Account_Name__c` — Text

`Health_Update__e`:
- `Account_Id__c` — Text
- `New_Score__c` — Number
- `Old_Score__c` — Number
- `Health_Status__c` — Text

### 10.2 `PlatformEventService.cls`
- `publishDealAlert(Opportunity opp)` — publica `Deal_Alert__e`
- `publishHealthUpdate(Id accountId, Decimal newScore, Decimal oldScore)` — publica `Health_Update__e`

### 10.3 Flow Trigger em `Deal_Alert__e`
- Quando `Deal_Alert__e` for publicado com Amount > 50000
- Criar Task de alta prioridade para o gerente de vendas
- Enviar notificação customizada (Custom Notification)

### Testes:
- `PlatformEventServiceTest.cls`

**Resultado esperado:** Events publicando e consumidos por Flow. Deploy + commit: `feat: platform events - deal alerts and health updates`

---

## PASSO 11 — Lightning Web Components (LWC)

### Objetivo
Criar os componentes visuais modernos da interface.

### 11.1 `opportunityDashboard` — Dashboard do Pipeline
Localização: App Page ou Home Page
Funcionalidades:
- Mostra total de oportunidades abertas por Stage (usando `@wire` com SOQL)
- Cards com: Total Pipeline, Closed Won Mês, Taxa de Conversão
- Gráfico de barras simples com CSS puro (sem biblioteca externa)
- Botão "Atualizar" que chama método Apex imperativo
- Responsivo para mobile

### 11.2 `leadScoreCard` — Card de Score do Lead
Localização: Lead Record Page
Funcionalidades:
- Mostra `Lead_Score__c` com barra de progresso visual (CSS)
- Cor muda conforme score: vermelho (<40), amarelo (40-70), verde (>70)
- Exibe `Score_Reason__c` formatado
- Botão "Recalcular Score" que chama `LeadScoringService` via Apex

### 11.3 `proposalWizard` — Wizard de Criação de Proposta
Localização: Opportunity Record Page
Funcionalidades:
- Step 1: Dados da proposta (valor, desconto, validade)
- Step 2: Prévia com valor final calculado
- Step 3: Confirmação e criação
- Validação de campos em cada step
- Chama `ProposalService.createProposal()` ao finalizar
- Exibe mensagem de sucesso com link para a proposta criada

### 11.4 `aiInsightPanel` — Painel de IA
Localização: Account Record Page (sidebar)
Funcionalidades:
- Botão "Gerar Insight com IA" 
- Mostra spinner enquanto carrega
- Exibe resultado formatado do `OpenAICalloutService`
- Exibe data/hora da última geração
- Cache de 24h (não chama API se já gerou hoje)

### 11.5 `customerHealthCard` — Card de Saúde do Cliente
Localização: Account Record Page
Funcionalidades:
- Score grande e colorido no centro
- Status com ícone (✅ Excelente, ⚠️ Em Risco, 🔴 Crítico)
- Mini métricas: Cases Abertos, Dias desde última compra, NPS
- Botão "Recalcular" que chama `CustomerHealthService`

### Padrão obrigatório em todos os LWC:
- Usar `@wire` para dados que não mudam frequentemente
- Usar `@api` para propriedades configuráveis no App Builder
- Tratamento de erro com mensagem amigável ao usuário
- Loading state com `lightning-spinner`
- Comentários em português no JS

**Resultado esperado:** 5 componentes funcionando nas record pages. Deploy + commit: `feat: LWC components - dashboard, lead score, proposal wizard, AI panel, health card`

---

## PASSO 12 — Flows de Automação

### Objetivo
Criar os flows de automação declarativa.

### 12.1 Flow: `Lead_Conversion_Task` (Record-Triggered)
- Trigger: Lead convertido (IsConverted = true)
- Ação: Criar Task "Fazer onboarding do novo cliente" para o dono da Account criada
- Due Date: 3 dias após conversão

### 12.2 Flow: `High_Value_Deal_Alert` (Record-Triggered)
- Trigger: Opportunity atualizada com Amount > 50.000 e StageName mudou
- Ação: Publicar `Deal_Alert__e` via Platform Event
- Condição: Apenas se Amount > 50000

### 12.3 Flow: `Proposal_Approval_Request` (Screen Flow)
- Tela 1: Exibe dados da proposta e desconto atual
- Decisão: Se desconto > 20%, ir para tela de justificativa
- Tela 2 (se desconto > 20%): Campo de justificativa obrigatório
- Ação: Submete para Approval Process se desconto > 20%, caso contrário aprova direto

### 12.4 Flow: `Contract_Expiration_Check` (Scheduled)
- Agenda: Diário às 8h
- Query: Contract_Renewal__c com dias até expiração entre 0 e 30
- Loop: Para cada contrato, criar Task para o Owner
- Subflow: Chamar flow de envio de e-mail

### 12.5 Flow: `Account_CEP_Enrichment` (Record-Triggered)
- Trigger: Account criada ou CEP__c atualizado
- Ação: Chamar Apex Action que invoca `ViaCEPCalloutService`
- Preenche: BillingStreet, BillingCity, BillingState automaticamente

**Resultado esperado:** 5 flows ativos. Deploy + commit: `feat: automation flows - lead conversion, deal alert, proposal approval, contract check, CEP enrichment`

---

## PASSO 13 — Segurança e Permission Sets

### Objetivo
Configurar segurança enterprise com perfis e permissões.

### Permission Sets a criar:

#### `SmartSales_Sales_Rep.permissionset`
Vendedor padrão:
- Read/Create/Edit em: Opportunity, Lead, Contact, Account, Product_Proposal__c
- Read em: Commission__c (apenas os próprios), Customer_Health__c
- Sem acesso a: Integration_Log__c, campos de configuração de sistema

#### `SmartSales_Sales_Manager.permissionset`
Gerente de vendas (herda do Sales Rep +):
- Read/Create/Edit/Delete em todos os objetos custom
- Acesso a: Commission__c de todos os vendedores
- Approve em: Approval Process de desconto
- Acesso a: Integration_Log__c (read only)

#### `SmartSales_Admin.permissionset`
Administrador (acesso total):
- Modify All em todos os objetos
- Acesso a: Named Credentials, Batch Jobs, Setup
- Pode chamar manualmente: `BatchScheduler.scheduleAll()`

### Validações de segurança no código:
Criar `SecurityUtils.cls` com métodos utilitários:
- `checkFLSRead(Schema.SObjectType, List<String> fields)` — verifica permissão de leitura
- `checkFLSWrite(Schema.SObjectType, List<String> fields)` — verifica permissão de escrita
- `checkObjectAccess(Schema.SObjectType, String accessType)` — verifica acesso ao objeto
- Lançar `SecurityException` customizada se falhar

**Resultado esperado:** 3 permission sets + SecurityUtils. Deploy + commit: `feat: security - permission sets and FLS validation utilities`

---

## PASSO 14 — Custom Metadata Types

### Objetivo
Usar Custom Metadata para configurações que podem mudar sem deploy de código.

### CMDTs a criar:

#### `Commission_Rule__mdt`
- `Min_Amount__c` — Currency
- `Max_Amount__c` — Currency
- `Commission_Rate__c` — Percent
- `Description__c` — Text

Registros:
- Tier_1: 0 a 10.000 → 3%
- Tier_2: 10.001 a 50.000 → 5%
- Tier_3: 50.001 a 200.000 → 7%
- Tier_4: 200.001+ → 10%

(Substituir os valores hardcoded em `CommissionCalculatorService` por query nesta CMDT)

#### `Lead_Score_Rule__mdt`
- `Field_Name__c` — Text
- `Condition__c` — Text
- `Points__c` — Number
- `Description__c` — Text

Registros: uma linha para cada regra de pontuação do LeadScoringService.

#### `Integration_Config__mdt`
- `Service_Name__c` — Text
- `Is_Active__c` — Checkbox
- `Timeout_Ms__c` — Number
- `Max_Retries__c` — Number

Registros: ViaCEP, SendGrid, Slack, ERP, OpenAI

Usar esta CMDT no `HttpCalloutService` para verificar se a integração está ativa antes de fazer o callout.

**Resultado esperado:** 3 CMDTs com registros. Deploy + commit: `feat: custom metadata - commission rules, lead scoring, integration config`

---

## PASSO 15 — CI/CD com GitHub Actions

### Objetivo
Configurar pipeline de CI/CD profissional.

### 15.1 Criar `.github/workflows/ci.yml`
Pipeline de validação que roda em todo Pull Request para `main`:

```yaml
Passos:
1. Checkout do código
2. Instalar SF CLI
3. Autenticar na org usando JWT (SFDX_AUTH_URL como GitHub Secret)
4. Validar o deploy (--check-only) sem fazer deploy de fato
5. Rodar todos os testes Apex
6. Verificar se coverage >= 95%
7. Comentar no PR com resultado dos testes
```

### 15.2 Criar `.github/workflows/deploy.yml`
Pipeline de deploy que roda ao fazer merge para `main`:

```yaml
Passos:
1. Checkout
2. Instalar SF CLI
3. Autenticar
4. Deploy completo para org
5. Rodar testes pós-deploy
6. Enviar notificação Slack de sucesso/falha
```

### 15.3 Criar `package.xml` completo
Listando todos os metadados do projeto para deploy controlado.

### 15.4 Documentar no README:
- Como configurar o GitHub Secret `SFDX_AUTH_URL`
- Como gerar o JWT para autenticação headless
- Como rodar os testes localmente

**Resultado esperado:** CI/CD funcional. Commit: `feat: CI/CD pipeline - GitHub Actions for validation and deployment`

---

## PASSO 16 — README Final e Documentação

### Objetivo
Criar documentação profissional que impressione quem ver o portfólio.

### README.md deve conter:

1. **Badge** de cobertura de testes, último deploy, licença
2. **GIF ou screenshot** da interface (descrever onde capturar)
3. **Sobre o projeto** — problema que resolve, contexto de negócio
4. **Arquitetura** — diagrama ASCII da estrutura de camadas:
```
┌─────────────────────────────────────────────┐
│              LWC (Interface)                │
├─────────────────────────────────────────────┤
│         Flows + Approval Process            │
├──────────────┬──────────────────────────────┤
│   Triggers   │      REST API Endpoints      │
│   Handlers   │                              │
├──────────────┴──────────────────────────────┤
│              Service Layer                  │
├──────────────┬──────────────────────────────┤
│  Selectors   │   Callout Services           │
│  (SOQL)      │   (APIs Externas + IA)       │
├──────────────┴──────────────────────────────┤
│         Custom Objects (Data Model)         │
└─────────────────────────────────────────────┘
```
5. **Tecnologias usadas** com badges
6. **Funcionalidades** — lista completa com checkmarks ✅
7. **Integrações** — tabela com cada API e o que faz
8. **Como instalar** — passo a passo com comandos
9. **Como rodar os testes** — comando único
10. **Estrutura de pastas** — árvore comentada
11. **Decisões técnicas** — por que TriggerHandler, por que Service Layer, etc.
12. **Próximos passos** — o que poderia ser adicionado

**Resultado esperado:** README de nível profissional. Commit final: `docs: complete project documentation and README`

---

## CHECKLIST FINAL

Antes de considerar o projeto completo, verificar:

### Código
- [ ] Todos os triggers usam TriggerHandler pattern
- [ ] Nenhuma query SOQL dentro de loop
- [ ] Nenhum hardcode de ID, URL ou token
- [ ] Todos os callouts usam Named Credentials
- [ ] FLS verificado em todas as operações DML
- [ ] Todos os métodos públicos têm comentário de documentação

### Testes
- [ ] Coverage >= 95% em todas as classes
- [ ] Testes de callout usam HttpCalloutMock
- [ ] Cenários negativos testados
- [ ] @TestSetup usado para criação de dados

### Segurança
- [ ] Permission Sets criados e documentados
- [ ] SecurityUtils.cls sendo usado
- [ ] Named Credentials para todas as APIs

### DevOps
- [ ] GitHub Actions configurado
- [ ] package.xml completo
- [ ] .gitignore adequado
- [ ] README profissional

### IA
- [ ] OpenAI callout funcionando com mock
- [ ] Agentforce agent configurado
- [ ] Einstein documentado no README

---

## COMANDOS ÚTEIS (referência rápida)

```bash
# Deploy completo
sf project deploy start --source-dir force-app

# Rodar testes
sf apex run test --test-level RunLocalTests --code-coverage --result-format human

# Ver cobertura
sf apex run test --test-level RunLocalTests --code-coverage --result-format json

# Abrir org no browser
sf org open --target-org fechanegocio

# Pull metadados da org
sf project retrieve start --source-dir force-app

# Executar Apex anônimo
sf apex run --file scripts/schedule-jobs.apex
```

---

*Projeto SmartSales Enterprise — Portfólio Salesforce Enterprise*
*Desenvolvido por Denison | github.com/Dentheo-Dev*
