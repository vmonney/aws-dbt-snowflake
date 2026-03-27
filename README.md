# aws-dbt-snowflake

## dbt CLI: load Snowflake credentials from `.env`

This dbt project uses `env_var('SNOWFLAKE_ACCOUNT')` / `env_var('SNOWFLAKE_PASSWORD')` in `aws_dbt_snowflake_project/profiles.yml`.

`dbt` does **not** automatically read `aws_dbt_snowflake_project/.env` in your regular terminal session. If you run `dbt` without exporting those variables, you'll get errors like:
`Env var required but not provided: 'SNOWFLAKE_ACCOUNT'`.

From the repo root (`aws-dbt-snowflake/`), run this once per new terminal session:

```zsh
export DBT_PROFILES_DIR="$PWD/aws_dbt_snowflake_project"
set -a
source aws_dbt_snowflake_project/.env
set +a
```

Then you can run `dbt` normally, for example:

```zsh
dbt run --select models/demo
```

Note: the `vscode-dbt-power-user` extension can load the `.env` automatically via its own environment handling, so you may not need these steps in Power User.

## dbt hierarchy: where configs live

- `dbt_project.yml`: project-level configuration (including default model settings under the `models:` key).
- `models/`: your model SQL files (declares dependencies via `ref()` / `source()`), plus any YAML alongside them (for docs, tests, and model-specific `config:` blocks).
- Inline config in model SQL: `{{ config(...) }}` at the top of a `.sql` file when you need model-specific overrides.

## Config precedence (what wins when settings conflict)

dbt will pick the most specific configuration. From highest to lowest specificity:
1. Inline `{{ config(...) }}` in the model `.sql` file
2. `config:` in `.yml` files (for example `schema.yml`)
3. `dbt_project.yml` under the `models:` key (least specific)

Within `dbt_project.yml`, the `models:` tree is hierarchical: deeper keys (more specific folders/models) override broader defaults. In `dbt_project.yml`, the `+` prefix marks “resource configs” that apply to that directory and inherit to subdirectories.

In this repo, `dbt_project.yml` sets:
- `models/demo/**` to `materialized: table` via `models: aws_dbt_snowflake_project: demo: +materialized: table`.

Some configs are merged instead of clobbered (fully replaced). Common examples:
- `tags` are additive (combined across levels)
- `meta` and `freshness` are merged (specific values override less specific ones)
- `pre-hook` / `post-hook` are additive

## Best practices

- Put defaults in `dbt_project.yml` (for example `+materialized`, `+tags`, and `+schema`) so most models share consistent conventions.
- Use inline `{{ config(...) }}` only for true exceptions where a single model needs different behavior than the project defaults.
- Use YAML (`schema.yml`) primarily for documentation and tests; use YAML `config:` sparingly for model-specific overrides.
- Keep a clear “config source of truth”: avoid having multiple places set the same thing unless you deliberately rely on precedence.
- Keep model SQL focused on transformations (`ref()` / `source()`, clean CTEs); treat configuration as metadata.

