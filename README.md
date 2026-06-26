# SmartSales Enterprise

> **CRM B2B completo na plataforma Salesforce** — portfólio enterprise demonstrando arquitetura de produção com 16 camadas implementadas: Data Model, Triggers, Service Layer, Selectors, Integrações, IA, Batch Jobs, REST API, Platform Events, LWC, Flows, Security, Custom Metadata e CI/CD.

---

## Visão Geral

SmartSales Enterprise simula o CRM de uma empresa de tecnologia que vende software B2B. O projeto foi construído seguindo padrões enterprise de mercado — cada camada é deployável de forma independente e testada com cobertura mínima de 95%.

### Tecnologias e Padrões

| Categoria | Tecnologias |
|---|---|
| **Plataforma** | Salesforce (API 61.0) |
| **Back-end** | Apex, SOQL, Platform Events |
| **Front-end** | Lightning Web Components (LWC) |
| **Automação** | Salesforce Flows (Record-Triggered, Screen, Scheduled) |
| **IA** | OpenAI API + Agentforce |
| **Integrações** | Slack Webhooks, ViaCEP |
| **CI/CD** | GitHub Actions + sfdx-git-delta |
| **Padrões** | TriggerHandler, Service Layer, Selector/Repository, Custom Metadata |

---

## Arquitetura

```
SmartSales Enterprise
├── Data Model (6 objetos custom + campos em Opportunity/Lead)
├── Trigger Layer (TriggerHandler pattern — sem lógica direta no trigger)
├── Service Layer (regras de negócio desacopladas)
├── Selector Layer (SOQL isolado — nunca inline)
├── Integration Layer (Slack, ViaCEP, logs automáticos)
├── AI Layer (OpenAI + Agentforce Actions)
├── Batch Jobs (recálculo periódico + renovações)
├── REST API (4 endpoints públicos)
├── Platform Events (comunicação assíncrona)
├── LWC (5 componentes Lightning)
├── Flows (4 automações declarativas)
├── Security (3 Permission Sets com FLS granular)
├── Custom Metadata (3 tipos configuráveis sem deploy)
└── CI/CD (validação em PR + delta deploy em main)
```

---

## Objetos Customizados

| Objeto | Finalidade |
|---|---|
| `Commission__c` | Registro de comissões por vendedor/oportunidade |
| `Customer_Health__c` | Score de saúde do cliente (NPS, casos, pagamentos) |
| `Product_Proposal__c` | Propostas comerciais com aprovação |
| `Contract_Renewal__c` | Controle de renovações com alertas antecipados |
| `Integration_Log__c` | Log automático de todas as chamadas externas |
| `AI_Settings__c` | Configurações da integração com OpenAI |

**Campos custom em objetos padrão:**

- **Opportunity:** `Lead_Source_Detail__c`, `Competitor__c`, `AI_Next_Step__c`, `Commission_Calculated__c`, `Health_Risk__c`, `Expected_Close_Reason__c`
- **Lead:** `Lead_Score__c`, `Score_Reason__c`, `Company_Size__c`, `Annual_Revenue_Estimate__c`, `Source_Campaign__c`

---

## Camadas Implementadas

### 1. Trigger Handler Pattern

```
force-app/main/default/classes/handlers/
├── TriggerHandler.cls          ← base class abstrata
├── OpportunityTriggerHandler.cls
├── LeadTriggerHandler.cls
└── CaseTriggerHandler.cls
```

Nenhuma lógica de negócio direta nos triggers — todos delegam para o handler correspondente.

### 2. Service Layer

```
force-app/main/default/classes/services/
├── LeadScoringService.cls      ← score automático por origem/tamanho/receita
├── CommissionService.cls       ← cálculo de comissão com regras configuráveis
├── CustomerHealthService.cls   ← score de saúde do cliente
└── ProposalService.cls         ← criação e aprovação de propostas
```

### 3. Selector Layer

```
force-app/main/default/classes/selectors/
├── OpportunitySelector.cls
├── LeadSelector.cls
├── CommissionSelector.cls
├── CustomerHealthSelector.cls
└── ProposalSelector.cls
```

Todo SOQL passa pelo selector — zero queries inline em handlers ou services.

### 4. Integration Layer

```
force-app/main/default/classes/integrations/
├── SlackCalloutService.cls     ← notificações de oportunidades ganhas
├── ViaCEPService.cls           ← enriquecimento de endereço por CEP
└── IntegrationLogger.cls       ← log automático de toda chamada HTTP
```

Named Credentials configuradas via `Integration_Endpoint__mdt` — nenhuma URL hardcoded.

### 5. AI Layer

```
force-app/main/default/classes/ai/
├── OpenAIService.cls           ← cliente HTTP para a API do OpenAI
├── LeadInsightAction.cls       ← Agentforce Action: análise de lead
├── ProposalSummaryAction.cls   ← Agentforce Action: resumo de proposta
└── CustomerHealthAction.cls    ← Agentforce Action: risco do cliente
```

### 6. Batch Jobs

```
force-app/main/default/classes/batch/
├── CustomerHealthBatchJob.cls     ← recalcula score de saúde diariamente
├── CommissionCalculationBatch.cls ← processa comissões do período
└── ContractRenewalBatch.cls       ← verifica contratos próximos do vencimento
```

### 7. REST API

| Endpoint | Método | Descrição |
|---|---|---|
| `/services/apexrest/leads` | GET, POST | Listagem e criação de leads |
| `/services/apexrest/opportunities` | GET, PATCH | Consulta e atualização de oportunidades |
| `/services/apexrest/proposals` | GET, POST | Gestão de propostas |
| `/services/apexrest/customerhealth` | GET | Score de saúde do cliente |

### 8. Platform Events

| Evento | Publicado por | Consumido por |
|---|---|---|
| `Opportunity_Stage_Changed__e` | Trigger + Flow | Trigger Handler (log + Slack) |
| `Lead_Scored__e` | LeadScoringService | Trigger Handler (atualiza score) |
| `Customer_Health_Alert__e` | CustomerHealthBatch | Trigger Handler (cria task) |
| `Contract_Renewal_Alert__e` | ContractRenewalBatch | Trigger Handler (cria task) |

### 9. Lightning Web Components

```
force-app/main/default/lwc/
├── salesDashboard/         ← painel de métricas da equipe
├── leadScoringCard/        ← card de score do lead com indicadores visuais
├── customerHealthGauge/    ← gauge de saúde do cliente
├── proposalManager/        ← gerenciamento de propostas inline
└── commissionTracker/      ← acompanhamento de comissões do vendedor
```

### 10. Flows

| Flow | Tipo | Trigger |
|---|---|---|
| `Opportunity_ClosedWon_Notification` | Record-Triggered (After Save) | StageName muda para "Closed Won" |
| `Lead_Auto_Assignment` | Record-Triggered (Before Save) | Criação de Lead |
| `Lead_Qualification_Wizard` | Screen Flow | Acionado manualmente na página do Lead |
| `Opportunity_FollowUp_Reminder` | Scheduled | Diariamente às 08h UTC |

### 11. Security — Permission Sets

| Permission Set | Perfil | Destaques |
|---|---|---|
| `SmartSales_Sales_Rep` | Representante | CRUD em propostas, leitura de comissão própria, campos AI somente leitura |
| `SmartSales_Sales_Manager` | Gestor | ViewAll/ModifyAll em comissões, aprovação de propostas, Customer Health editável |
| `SmartSales_Admin` | Admin | Acesso total incluindo AI_Settings__c e Integration_Log__c |

### 12. Custom Metadata Types

| Tipo | Finalidade | Registros |
|---|---|---|
| `Lead_Scoring_Config__mdt` | Pesos do scoring de lead | Default, High Touch |
| `Commission_Rule__mdt` | Taxa e valor mínimo por tipo de venda | Standard (5%), Strategic (8%) |
| `Integration_Endpoint__mdt` | Named Credential + timeout por serviço | OpenAI, Slack, ViaCEP |

### 13. CI/CD GitHub Actions

```
.github/workflows/
├── validate-pr.yml     ← validação check-only + RunLocalTests em todo PR
└── deploy-main.yml     ← delta deploy com sfdx-git-delta em push para main
```

**Secrets necessários no repositório:**

| Secret | Descrição |
|---|---|
| `SF_CONSUMER_KEY` | Consumer Key do Connected App (JWT) |
| `SF_USERNAME` | Username do usuário de integração |
| `SF_JWT_PRIVATE_KEY` | Chave privada PEM para autenticação JWT |
| `SF_ORG_URL` | URL da org (ex: `https://login.salesforce.com`) |

---

## Setup Local

### Pré-requisitos

- [Salesforce CLI (sf)](https://developer.salesforce.com/tools/salesforcecli)
- [VS Code](https://code.visualstudio.com/) + [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
- Developer Edition org ou Scratch Org

### Deploy

```bash
# Autenticar na org
sf org login web --alias minha-org

# Deploy completo
sf project deploy start --source-dir force-app --target-org minha-org --wait 20

# Executar todos os testes
sf apex run test --target-org minha-org --test-level RunLocalTests --result-format human --wait 10

# Abrir a org no browser
sf org open --target-org minha-org
```

### Estrutura de Pastas

```
SmartSales Enterprise/
├── .github/
│   └── workflows/
│       ├── validate-pr.yml
│       └── deploy-main.yml
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/
│           │   ├── batch/
│           │   ├── controllers/
│           │   ├── handlers/
│           │   ├── integrations/
│           │   ├── ai/
│           │   ├── rest/
│           │   ├── selectors/
│           │   ├── services/
│           │   └── tests/
│           ├── customMetadata/
│           ├── flows/
│           ├── lwc/
│           ├── objects/
│           ├── permissionsets/
│           └── triggers/
└── sfdx-project.json
```

---

## Padrões e Convenções

- **TriggerHandler pattern** — lógica de negócio zero nos triggers
- **Service Layer** — todas as regras de negócio em classes `*Service`
- **Selector/Repository pattern** — nenhum SOQL inline fora de classes `*Selector`
- **Named Credentials** — nenhuma URL ou token hardcoded
- **Custom Metadata** — parâmetros de negócio configuráveis sem deploy
- **CRUD/FLS verification** — verificação antes de qualquer DML
- **Cobertura mínima de 95%** — todos os testes em `classes/tests/`
- **Comentários em português** — blocos complexos documentados em PT-BR

---

## Commits por Camada

| Commit | Camada |
|---|---|
| `b7e14d9` | Setup inicial |
| `4ffc4ad` | Data Model |
| `f66e686` | Trigger Handlers |
| `156a49c` | Service Layer |
| `b117619` | Selector Layer |
| `bb53c85` | Integration Layer |
| `fa9c624` | AI Layer |
| `9b782cf` | Batch Jobs |
| `dd3b08c` | REST API |
| `b1e2e13` | Platform Events |
| `32fdf57` | LWC |
| `d9232b8` | Flows |
| `10c283b` | Security |
| `9d065c6` | Custom Metadata |
| `e6073e3` | CI/CD |

---

*Desenvolvido por Denison Theodoro como portfólio enterprise Salesforce.*
 
