# DBmaestro × GitHub Actions

Database changes released through GitHub with DBmaestro.

Every database change is a **package**: a folder under `packages/` with upgrade and downgrade
scripts. GitHub carries the change from pull request to production; DBmaestro decides whether
each step is safe to run.

```
Pull request (touches packages/V3/)
  Detect changed packages            which package folders this PR changes
  DBmaestro package & precheck       upload V3 to DBmaestro project "Github-Integration" and check it
                                     against the Policy Engine; result posted as a PR comment

Merge into main
  Release Source  ->  QA  ->  Production (GitHub Environment with required reviewers)
```

What DBmaestro says shows up on the GitHub console itself:

- **PR comment** with the precheck result per package, including policy warnings.
- **Annotations** on the workflow run: `⛔ blocked by policy`, `⛔ drift detected`, `⚠ policy warning`.
- **Job summaries** with a table per package and a link to the project in DBmaestro.
- **Environments / Deployments**: every database release is a GitHub deployment to
  `Release_Source`, `QA` or `Prod`.

The DBmaestro steps come from the [DBmaestro CI/CD library](https://github.com/DBMaestroDev/dbmaestro-cicd)
(`@v1`): change detection uses its `detect-changed-packages` action; packaging, precheck and
upgrade run its core scripts through [`.github/scripts/dbmaestro.sh`](.github/scripts/dbmaestro.sh),
which adds the annotations and summaries.

## Adding a database change

1. Branch from `main`.
2. Add a folder named after the next package, with a subfolder named after the Release Source schema:

   ```
   packages/V3/
   └── github_rs/
       ├── Upgrade/01-v3-customer-segment.sql
       └── Downgrade/01-v3-customer-segment-rollback.sql
   ```

   Scripts run in file-name order. Use **lowercase** file names, unique within the package: the
   DBmaestro CLI lowercases names in the package manifest.
3. Open a pull request. The workflow creates the package in DBmaestro and prechecks it.
4. Merge. Release Source and QA are upgraded automatically; Production waits for a reviewer to
   approve the deployment.

## DBmaestro project

| | |
|---|---|
| Project | `Github-Integration` (PostgreSQL, deploy by tasks) |
| Environments | `Dev` → `Release_Source` → `QA` → `Prod` |
| Databases | `github_dev`, `github_rs`, `github_qa`, `github_prod` |
| Guardrails | Pre-Validation (drift) on every deploy; global policy **Drop Table is not allowed** = *Block* in Production |

## Settings

**Secrets and variables → Actions**

| Name | Kind | Value |
|---|---|---|
| `DBMAESTRO_SERVER` | variable | `agent.dop.svc.cluster.local:80` |
| `DBMAESTRO_USE_SSL` | variable | `False` |
| `DBMAESTRO_USER` | variable | `github-ci@dbmaestro.com` (DBmaestro service account) |
| `DBMAESTRO_UI_URL` | variable | `http://localhost:8081` |
| `CLI_VERSION` | variable | `26.4.0.14192` ([DBmaestroCLI](https://github.com/DBMaestroDev/DBmaestroCLI) release) |
| `DBMAESTRO_PASSWORD` | secret | |

**Environments**: `Release_Source`, `QA`, `Prod` (Prod has required reviewers).

## Runner

A self-hosted runner runs as a pod in the same Kubernetes cluster as DBmaestro, so jobs reach the
DBmaestro agent by its service name. See [`runner/runner.yaml`](runner/runner.yaml).

## Demo

The recording script, with the proven outputs of each act, is [`demo/DEMO-SCRIPT.md`](demo/DEMO-SCRIPT.md).
