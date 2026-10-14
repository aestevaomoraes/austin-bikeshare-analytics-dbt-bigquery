# 🚲 Austin Bikeshare Analytics: Modern Data Stack com dbt Core & Google BigQuery

[![dbt](https://img.shields.io/badge/dbt-Core%20v1.8-orange?logo=dbt)](https://www.getdbt.com/)
[![BigQuery](https://img.shields.io/badge/Google%20Cloud-BigQuery-blue?logo=googlecloud)](https://cloud.google.com/bigquery)
[![SQL](https://img.shields.io/badge/Dialect-Google%20SQL-yellow)](https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Pipeline analítico de engenharia de dados de ponta a ponta construído com **dbt Core** e **Google BigQuery**, modelando e transformando mais de **2,9 milhões de registros** do sistema público de compartilhamento de bicicletas de Austin (*Austin Bikeshare*).

O projeto implementa arquitetura modular em camadas analíticas (**Medallion / dbt canonical architecture**), governança com testes automatizados de dados, orquestração multi-ambiente (**Dev vs. Prod**) e documentação com grafo acíclico dirigido (**DAG**).

---

## 🏛️ Arquitetura da Solução & Camadas de Dados

O pipeline segue as melhores práticas da engenharia analítica moderna, separando expressamente a ingestão bruta, a padronização, as regras de enriquecimento e o consumo dimensional:

```
[bigquery-public-data] 
        │
        ▼
   STAGING (Views)
   ├── stg_austin_bikeshare__trips
   └── stg_austin_bikeshare__stations
        │
        ▼
 INTERMEDIATE (Views)
   └── int_trips_enriched
        │
        ├─────────────────────────────┐
        ▼                             ▼
   MARTS (Tables)               MARTS (Tables)
   ├── dim_stations             └── fct_station_monthly_summary
   └── fct_trips
```

### 1. Camada Staging (`models/staging/`)
* **Materialização:** `view` (zero custo de armazenamento adicional e sincronização imediata com os dados de origem).
* **Responsabilidade:** Sanitização atômica 1:1, tipagem de dados rigorosa (`cast` explícito de identificadores para `STRING`), renomeação de colunas para padronização de nomenclatura analítica e isolamento da fonte bruta via Jinja `{{ source() }}`.
* **Modelos:**
  * `stg_austin_bikeshare__trips`: Tratamento de mais de 2.9M de registros de partidas, chegadas e identificadores de viagens.
  * `stg_austin_bikeshare__stations`: Padronização do cadastro, localização e docas das estações.

### 2. Camada Intermediate (`models/intermediate/`)
* **Materialização:** `view`.
* **Responsabilidade:** Enriquecimento analítico sem agregações dimensionais finais, isolando a complexidade lógica de regras de negócio.
* **Transformações aplicadas (`int_trips_enriched`):**
  * **Extração temporal:** Ano, mês, dia, hora e dia da semana.
  * **Classificação de final de semana:** Flag booleana `is_weekend`.
  * **Turnos de operação:** Categorização do período (`Manhã`, `Tarde`, `Noite`, `Madrugada`).
  * **Classificação de rotas:** Identificação de corridas circulares (`is_round_trip`).
  * **Buckets de duração:** Faixas de duração analítica para estudo de comportamento (`0-10 min`, `11-30 min`, `31-60 min`, `>60 min`).

### 3. Camada Marts (`models/marts/`)
* **Materialização:** `table` (tabelas físicas de alta performance para consulta direta em BI e dashboards sem recomputação onerosa).
* **Modelagem Dimensional:**
  * **`dim_stations` (Dimensão):** Visão cadastral das estações, infraestrutura de docas com tratamento de nulos (`coalesce(total_docks, 0)`) e status operacional.
  * **`fct_trips` (Fato Granular):** Fato transacional de viagens (2.9M linhas) interligada às chaves dimensionais de estações e atributos temporais.
  * **`fct_station_monthly_summary` (Fato Agregada / Datamart):** Agregação mensal por estação consolidando volumetria de corridas, tempo médio de duração, corridas avulsas (*Walk Up*), rotas circulares e uso em fins de semana.

---

## 🛡️ Governança e Qualidade de Dados (`Data Tests`)

A integridade do pipeline é auditada automaticamente através de contratos de dados e testes de schema (`schema.yml`):

* **Unicidade (`unique`):** Garantia de integridade para chaves primárias em `trip_id` e `station_id`.
* **Não Nulidade (`not_null`):** Aplicação de regras estritas em campos críticos como timestamps de início, IDs e métricas de docas.
* **Execução Paralela:** Orquestração de auditoria com paralelismo configurado via `threads: 4` no conector do BigQuery.

---

## ⚙️ Ambientes e Orquestração (Dev / Prod)

O projeto conta com segregação de ambientes configurada nativamente no `profiles.yml`:

| Ambiente | Target | Dataset no BigQuery | Propósito |
| :--- | :--- | :--- | :--- |
| **Desenvolvimento** | `dev` | `dbt_austin_bikeshare` | Iteração, prototipagem e testes de modelos no Codespaces |
| **Produção** | `prod` | `prod_austin_bikeshare` | Execução automatizada e materialização das tabelas finais de negócio |

Comando executado para build completo do pipeline em produção:
```bash
dbt build --target prod
```
*Gera todas as views, constrói tabelas físicas e valida 18 testes automatizados em um único grafo atômico.*

---

## 📊 Grafo de Dependências (Lineage / DAG)

O pipeline garante rastreabilidade completa (*Data Lineage*), permitindo análise de impacto e auditoria de metadados:

```
austin_bikeshare (sources)
 ├── bikeshare_stations ──► stg_austin_bikeshare__stations ──► dim_stations ──┐
 │                                                                            ▼
 └── bikeshare_trips    ──► stg_austin_bikeshare__trips ────► int_trips_enriched ──► fct_trips ──► fct_station_monthly_summary
```

A documentação interativa e o catálogo de dados são compilados e servidos através dos comandos:
```bash
dbt docs generate
dbt docs serve --port 8080
```

---

## 🛠️ Tecnologias Utilizadas

* **Armazenamento e Processamento:** Google BigQuery (Google Cloud Platform)
* **Transformação & Testes:** dbt Core (v1.8) com adapter `dbt-bigquery`
* **Linguagens:** SQL (Google Standard SQL) e Jinja templating
* **Ambiente de Desenvolvimento:** GitHub Codespaces (Linux/Debian)
* **Controle de Versão:** Git & GitHub

---

## 🚀 Como Reproduzir este Projeto

### 1. Clonar o repositório
```bash
git clone https://github.com/aestevaomoraes/austin-bikeshare-analytics-dbt-bigquery.git
cd austin-bikeshare-analytics-dbt-bigquery/austin_bikeshare
```

### 2. Configurar o Ambiente Virtual e Dependências
```bash
python3 -m venv venv
source venv/bin/activate
pip install dbt-bigquery
```

### 3. Autenticação com o BigQuery
Crie uma Service Account no Google Cloud Console com permissões de BigQuery Admin/User, baixe a chave JSON e configure seu `~/.dbt/profiles.yml`.

### 4. Executar e Testar o Pipeline
```bash
# Validar conexão
dbt debug

# Compilar e materializar no ambiente de desenvolvimento
dbt run

# Executar bateria de testes de qualidade
dbt test

# Construir pipeline completo no ambiente de produção
dbt build --target prod
```

---

## 👤 Autor

Desenvolvido por **Antonio Estevão Moraes**  
*Analytics Engineering | Data Analytics | Cloud Data Warehousing*  
[LinkedIn](https://www.linkedin.com/in/aestevaomoraes/) • [GitHub](https://github.com/aestevaomoraes)