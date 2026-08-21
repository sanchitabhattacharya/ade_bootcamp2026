# dbt training project — hotel booking analytics

A working sample project for onboarding new hires to dbt: medallion
architecture, YAML configuration files, tests, macros, and materializations.
Domain: hotel bookings (hotels, customers, bookings, payments, reviews).

---

## 1. Snowflake setup (do this BEFORE running dbt)

dbt does not create your source data or your base databases/warehouse — it
only creates the schemas/tables it's configured to build. Before the first
`dbt run`, someone with admin rights on Snowflake needs to run
`snowflake_setup/01_setup_and_sample_data.sql`, which:

1. Creates a warehouse (`DBT_TRAINING_WH`) and a role (`DBT_TRAINING_ROLE`)
2. Creates the **RAW** database with schema **`LND_SB_SCHEMA`** — this holds
   the source tables (`hotels`, `customers`, `bookings`, `payments`, `reviews`)
   loaded with sample data. dbt only ever *reads* from here via `source()`.
3. Everything lives in a single **SANDBOX** database, with dbt creating
   these schemas the first time it runs:

   | Schema (in SANDBOX) | Created by                                    | Contains |
   |----------------------|------------------------------------------------|----------|
   | `DBT_RAW`            | *(pre-existing, loaded by ingestion, not dbt)* | raw source tables |
   | `DBT_STAGE`          | `models/staging/`                              | bronze views |
   | `DBT_INTR`           | `models/intermediate/`                         | silver views |
   | `DBT_MART`           | `models/marts/core/` + `models/marts/reporting/` | gold dimensions, fact table, and reporting tables — all in one schema |

   Note: intermediate models are `view` here (not `ephemeral` as in the
   original design) since the team wanted DBT_INTR queryable directly for
   debugging. Trade-off: slightly more storage/compute, but easier to
   troubleshoot mid-pipeline.

   Exactly which schema names get used is controlled by
   `macros/generate_schema_name.sql` — see section 4.

Once that script has run, configure your Snowflake connection — see
`snowflake_setup/profiles_sample.yml` for a local dbt-core example (goes in
`~/.dbt/profiles.yml`). In dbt Cloud, the same account/database/warehouse/role
fields are entered in the project's **Connection** settings instead.

Then:
```bash
dbt deps      # installs packages.yml (dbt_utils)
dbt seed      # loads seeds/payment_method_reference.csv
dbt run       # builds staging -> intermediate -> marts
dbt test      # runs all tests
```

---

## 2. Medallion architecture, mapped to dbt folders

| Medallion tier | dbt folder | Materialization | Purpose |
|---|---|---|---|
| **Bronze** (raw, cleaned) | `models/staging/` | `view` | 1:1 with source tables. Rename columns, cast types, trim strings. No joins, no business logic. |
| **Silver** (conformed) | `models/intermediate/` | `ephemeral` | Joins across staging models, applies business rules (e.g. status categorization). Not directly queryable in Snowflake — inlined into whatever references it. |
| **Gold** (consumption-ready) | `models/marts/core/` and `models/marts/reporting/` | `table` / `incremental` | Dimensions, fact tables, and pre-aggregated reporting tables that BI tools query directly. |

Why this layering matters for new hires:
- **Bronze** isolates you from source-system quirks (column renames, type
  drift) in one place.
- **Silver** is where reusable business logic lives, so it isn't duplicated
  across five different gold tables.
- **Gold** is the only layer non-engineers should ever query — it's stable,
  documented, and tested.

---

## 3. The YAML files, and what each one is for

| File | Purpose |
|---|---|
| `dbt_project.yml` | Project-wide config: default materializations per folder, paths, variables. |
| `packages.yml` | Third-party dbt packages (here: `dbt_utils` for generic tests + macros). |
| `models/staging/_stg_sources.yml` | Declares the raw Snowflake tables (`source()`), plus source freshness checks. |
| `models/staging/_stg_models.yml` | Descriptions + generic tests for staging models. |
| `models/intermediate/_int_models.yml` | Descriptions + tests for intermediate (ephemeral) models. |
| `models/marts/core/_marts_core.yml` | Descriptions + tests for dimension/fact tables. |
| `models/marts/reporting/_marts_reporting.yml` | Descriptions + tests for reporting marts. |

Convention used here: one `_<folder>_models.yml` (or `_sources.yml`) per
folder rather than one giant `schema.yml` — keeps things easy to find as the
project grows.

---

## 4. Macros

| Macro | What it teaches |
|---|---|
| `macros/generate_schema_name.sql` | Overriding a **dbt built-in macro** — controls the actual schema names dbt creates in Snowflake. Without this override, dbt would prefix every custom schema with your target schema (e.g. `dbt_sbhattacharya_marts`); this override gives clean names in `prod` while keeping personal sandboxes namespaced in `dev`. |
| `macros/booking_status_category.sql` | A **DRY business-logic macro** — write a `case` statement once, call it from multiple models (`int_bookings_enriched`, and indirectly `fct_bookings`), so a rule change only needs one edit. |
| `macros/generate_booking_payment_key.sql` | **Wrapping a package macro** — composes `dbt_utils.generate_surrogate_key()` into a project-specific macro, so model authors don't need to remember the exact column list. |

---

## 5. Tests

**Generic tests** (reusable, declared in YAML) — used throughout: `unique`,
`not_null`, `accepted_values`, `relationships` (foreign-key checks), plus
`dbt_utils.expression_is_true` for a row-level business rule
(`check_out_date > check_in_date` on `stg_bookings`).

**Singular tests** (one-off SQL, in `tests/`) — a plain `.sql` file whose
name *is* the test name. The query should return zero rows when the check
passes:
- `tests/assert_positive_booking_amount.sql` — active bookings must have a
  positive amount.
- `tests/assert_checkin_after_booking_date.sql` — check-in date can never
  precede the date the booking was made.

Run `dbt test` to execute everything, or `dbt test --select stg_bookings` to
scope to one model.

---

## 6. Materializations used in this project

| Materialization | Used on | Why |
|---|---|---|
| `view` | all `staging/` models AND all `intermediate/` models | Cheap, always reflects the latest source data, no storage cost. Intermediate models are views here (not the more typical `ephemeral`) so DBT_INTR is queryable directly for debugging — see the note on trade-offs in section 1. |
| `table` | `dim_hotels`, `dim_customers`, `mart_hotel_performance`, `mart_customer_ltv` | Rebuilt in full each run. Right choice for tables that are small/medium and where a full rebuild is cheap and simplicity beats micro-optimizing compute. |
| `incremental` | `fct_bookings` | The fact table grows continuously; incremental + `merge` strategy means only new/changed rows (by `booking_date`/`updated_at`) get processed each run instead of scanning the whole history every time. |

`fct_bookings` is the one model to walk new hires through carefully — it
shows `config()`, `is_incremental()`, `unique_key`, and `incremental_strategy`
together, which is usually the most confusing materialization for people new
to dbt.

To force a full rebuild of an incremental model (e.g. after changing its
logic): `dbt run --select fct_bookings --full-refresh`

---

## 7. Suggested training flow for new hires

1. Run the Snowflake setup script, walk through what RAW vs ANALYTICS means.
2. `dbt run` the whole project, then open the generated `target/` and
   `ANALYTICS` schemas in Snowflake side by side — see the bronze/silver/gold
   split physically.
3. `dbt docs generate && dbt docs serve` — show the auto-generated lineage
   graph; it visually confirms the medallion flow.
4. Break something on purpose (e.g. insert a booking with `booking_amount = 0`)
   and re-run `dbt test` to see a singular test fail.
5. Change `booking_status_category` logic in the macro and re-run — show how
   one edit propagates to every downstream model that uses it.
6. Add a new column to `stg_reviews` and a matching generic test, as a
   hands-on exercise.
