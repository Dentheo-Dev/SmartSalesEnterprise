# SmartSales Enterprise

![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)
![Apex](https://img.shields.io/badge/Apex-1776C1?style=for-the-badge)
![LWC](https://img.shields.io/badge/LWC-E44D26?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## Sobre

CRM B2B enterprise completo desenvolvido em Salesforce como portfólio profissional de alto nível.
Simula uma empresa de tecnologia que vende software B2B, com pipeline de vendas, automações,
integrações com APIs externas, IA com OpenAI e Agentforce, LWC modernos, testes completos e CI/CD.

## Tecnologias

- **Salesforce Apex** — Service Layer, TriggerHandler Pattern, Selector Pattern
- **Lightning Web Components (LWC)** — 5 componentes modernos e responsivos
- **Salesforce Flows** — 5 flows de automação declarativa
- **OpenAI GPT-4o** — Insights de IA e geração de e-mails personalizados
- **Agentforce** — AI Agent customizado para suporte ao vendedor
- **Einstein** — Lead Scoring, Opportunity Scoring, Activity Capture
- **Platform Events** — Comunicação assíncrona entre sistemas
- **GitHub Actions** — CI/CD automatizado com validação e deploy

## Arquitetura

```
┌─────────────────────────────────────────────┐
│              LWC (Interface)                │
├─────────────────────────────────────────────┤
│         Flows + Approval Process            │
├──────────────┬──────────────────────────────┤
│   Triggers   │      REST API Endpoints      │
│   Handlers   │      (@RestResource)         │
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

## Estrutura de Pastas

```
force-app/main/default/
├── classes/
│   ├── handlers/       → Trigger Handlers
│   ├── services/       → Regras de negócio
│   ├── selectors/      → Queries SOQL isoladas
│   ├── batch/          → Batch Apex
│   ├── schedulable/    → Scheduled Jobs
│   ├── rest/           → REST endpoints
│   ├── callouts/       → APIs externas
│   ├── ai/             → IA (OpenAI, Agentforce)
│   ├── utils/          → Utilitários
│   └── tests/          → Classes de teste
├── lwc/                → 5 componentes LWC
├── flows/              → 5 flows de automação
├── objects/            → Objetos e campos custom
├── permissionsets/     → 3 permission sets
├── namedCredentials/   → Credenciais de API
├── platformEvents/     → Platform Events
├── customMetadata/     → Custom Metadata Types
└── staticresources/    → Recursos estáticos
```

## Funcionalidades

### Data Model
- [ ] `Product_Proposal__c` — Proposta comercial com ciclo de vida completo
- [ ] `Contract_Renewal__c` — Gestão de renovações de contrato
- [ ] `Customer_Health__c` — Score de saúde do cliente (0-100)
- [ ] `Commission__c` — Cálculo automático de comissões
- [ ] `Integration_Log__c` — Log de todas as chamadas de API

### Automações
- [ ] Lead Scoring automático ao criar/atualizar lead
- [ ] Cálculo de comissão ao fechar oportunidade
- [ ] Alerta no Slack ao fechar deal
- [ ] Expiração automática de propostas
- [ ] Renovação de contrato com alertas 30 dias antes

### Integrações
| API | Named Credential | Finalidade |
|-----|-----------------|------------|
| ViaCEP | `ViaCEP_API` | Endereço automático por CEP |
| SendGrid | `SendGrid_API` | Envio de e-mail de propostas |
| Slack | `Slack_Webhook` | Alerta de deals fechados |
| ERP Mock | `ERP_API` | Integração com sistema financeiro |
| OpenAI | `OpenAI_API` | Insights e e-mails com IA |

### IA
- [ ] Insights de cliente com GPT-4o
- [ ] Geração de e-mail de follow-up personalizado
- [ ] Resumo de propostas em linguagem clara
- [ ] Agentforce: SmartSales Assistant
- [ ] Einstein Lead & Opportunity Scoring

## Como Rodar

```bash
# 1. Clone o repositório
git clone https://github.com/Dentheo-Dev/SmartSalesEnterprise

# 2. Autentique na org
sf org login web --alias fechanegocio --set-default

# 3. Deploy
sf project deploy start --source-dir force-app

# 4. Rode os testes
sf apex run test --test-level RunLocalTests --code-coverage --result-format human

# 5. Abra a org
sf org open --target-org fechanegocio
```

## Próximos Passos

- TODO: Data Model (objetos e campos)
- TODO: Trigger Handlers
- TODO: Service Layer
- TODO: Selector Layer
- TODO: Integrações externas
- TODO: IA (OpenAI + Agentforce)
- TODO: Batch Jobs
- TODO: REST API
- TODO: Platform Events
- TODO: LWC
- TODO: Flows
- TODO: Permission Sets
- TODO: Custom Metadata
- TODO: CI/CD GitHub Actions

---

*Projeto SmartSales Enterprise — Portfólio Salesforce Enterprise*  
*Desenvolvido por Denison | [github.com/Dentheo-Dev](https://github.com/Dentheo-Dev)*
