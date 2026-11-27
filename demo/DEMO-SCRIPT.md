# Demo script: DBmaestro × GitHub Actions

Built for **Supademo interactive capture** (browser extension: screenshot + hotspot), like the
Loop and GitLab demos. Wait times don't matter, because the extension captures on click.

**What's proven and what isn't.** Every workflow outcome, PR comment and annotation quoted below
came from real runs on 2026-11-26/27 (PRs #1–#3, packages V3–V5, same objects as the recording
packages except where noted). The **GitHub click paths have not been walked yet**. They follow
github.com's current UI, so do one silent rehearsal of each act before recording. Places to look
at closely are marked ⚠️.

| Tab | URL |
|---|---|
| GitHub | `https://github.com/DBMaestroDev/DBmaestro-GitHub-Integration` |
| DBmaestro DOP | `http://localhost:8081/project/9/pipeline` (project **Github-Integration**) |

The spine is GitHub: *GitHub runs the release, DBmaestro decides what's safe to run.* Open the
DOP tab only where the script says so.

---

## The argument the demo makes

| Act | What's shown | Guardrail |
|---|---|---|
| 1 | The repo, the two workflows, the environments, where it runs | — |
| 2 | A good change: PR → package → precheck → comment → merge → RS → QA → approve → Prod | precheck in the PR |
| 3 | Someone patched Release Source by hand → the release stops at the first stage | **Pre-Validation** (environment *state*) |
| 4 | A `DROP TABLE` passes RS and QA, stopped at Prod | **Policy Engine** (change *content*) |

What GitHub adds over the GitLab demo: **DBmaestro's verdict is on the GitHub console itself**,
not only in job logs.

- A **PR comment** from the workflow with DBmaestro's precheck result per package, updated in place
  on every push.
- **Annotations** on the run page and on the PR's checks: `⛔ blocked by policy`,
  `⛔ drift detected`, `⚠ policy warning`, with the DBmaestro rule names and the script.
- A **job summary** table per stage, with a link to the project in DBmaestro.
- **Environments and deployments**: Release_Source, QA and Prod are GitHub Environments, and
  Prod's approval is GitHub's own **Review deployments** button.

The same two points as GitLab land here too:

- **The PR already knows.** In Act 4 the PR comment flags the `DROP TABLE` as a *Warning*
  before anyone merges. The same rule is a *Block* in Prod.
- **The precheck can't see drift.** In Act 3 the PR is green. The precheck checks the change,
  not the environment, so drift only shows up when the release deploys.

---

## Before you hit record

1. **Cluster up.** Docker Desktop k8s running, DOP pods ready (`kubectl get pods -n dop`). If
   the workloads were scaled to 0, scale `db-repo` up first, then the rest.
2. **Runner online.** `kubectl get pods -n github-runner` shows the pod Running. On GitHub, the
   org's *Settings → Actions → Runners* lists `dop-k8s-runner` as **Idle**.
3. **UI forwards** (only needed for the DOP tab): `powershell -File C:\git\dop-pf.ps1`.
4. **Starting state is consistent.** `demo/drift.sh show` lists the same tables and columns for
   `github_rs`, `github_qa` and `github_prod`. Right now all three are at V1–V4, with
   `customers_legacy` present everywhere.
5. **Demo branches are already pushed** (no PRs yet):
   `V6-customer-loyalty-tier`, `V7-orders-customer-index`, `V8-retire-customers-legacy`.
   To re-cut them, see [Reset](#after-recording-put-the-environments-back).
6. ⚠️ **Opening each PR.** GitHub's yellow *Compare & pull request* banner only appears for an
   hour after a push. Use **Pull requests → New pull request → compare: `V6-…`** instead, or
   open `…/compare/main...V6-customer-loyalty-tier` directly. The PR title comes from the
   single commit (`V6: add loyalty_tier to customers`), so nothing is typed on camera.
7. **No refresh between acts.** PR checks run on GitHub's merge commit, so a branch cut before
   the previous merge still shows only its own package. That's unlike GitLab, where
   `refresh-branch.sh` was needed.
8. **You approve Prod yourself on camera**, as the required reviewer. *Prevent self-review* must
   stay **off** on the Prod environment, because you also merged the PR.

### Things to keep off camera
- *Settings → Secrets and variables → Actions* with a value revealed. The **list** is fine,
  because `DBMAESTRO_PASSWORD` shows as a secret.
- Any terminal showing `gh auth token`, and the `github-token` secret in the `github-runner`
  namespace.
- DOP report links inside job logs point at `http://localhost:88/...`, which is wrong on this
  install (the UI is on 8081). Don't click those. Use the **View deployment** links and the
  summary links, which use 8081.

---

## Act 1: The setup (~5 captures, nothing changes)

1. **Repository home**
   > A normal application repo. Database changes live in `packages/`: one folder per release,
   > with upgrade and downgrade scripts.

   ⚠️ The right sidebar has a **Deployments** section listing `Prod`, `QA` and `Release_Source`.
   Hover it but keep it for capture 4.

2. Open **`packages/`**, then **`V4/github_rs/Upgrade/`**, then the SQL file.
   > A package is just SQL in git. Reviewed like code, versioned like code.

3. Open **`.github/workflows/`**. Show `database-precheck.yml` and `database-release.yml`.
   > Two workflows. Pull requests get a DBmaestro precheck. Merging releases the change:
   > Release Source, then QA, then Prod behind an approval.
   >
   > The steps come from DBmaestro's CI/CD library. The same building blocks exist for GitLab
   > and Azure DevOps.

4. Sidebar **Deployments**, or `…/deployments`.
   > Three GitHub Environments: Release_Source, QA and Prod. Every database release is a
   > GitHub deployment, so GitHub records what went where.

5. *Switch to the DOP tab* (Github-Integration pipeline view).
   > And the same three environments in DBmaestro, same order, with the packages GitHub
   > delivered.

   ⚠️ The package list also shows the rehearsal's **V5** (deployed nowhere, the blocked DROP) and
   **V3 / V3 (Rev. 1)**. Frame the environment cards, not the package list.

---

## Act 2: A good change ships (~10 captures)

6. **Pull requests → New pull request**, compare `V6-customer-loyalty-tier` →
   **Create pull request** (twice: once to open the form, once to submit it).
   > A developer adds a `loyalty_tier` column to customers.

7. The PR's checks box: **Database Precheck / Detect changed packages** and **Database Precheck /
   DBmaestro package & precheck**, both running and then ✓.
   > Two checks: find the package that changed, then create it in DBmaestro and check it
   > against the policies.

8. Scroll the **Conversation** tab to the comment from `github-actions`:
   > **DBmaestro accepted this change, with policy warnings.** Review them before merging.
   >
   > | Package | Step | Result | Details |
   > |---|---|---|---|
   > | V6 | Package created in DBmaestro | ✅ Passed | — |
   > | V6 | Precheck | ✅ Passed with 1 policy warning(s) | ⚠️ `Warning: 'Data Loss Risk', 'Drop col Logical or Physical is not allowed', 'Contains Drop Column'` in `01-v6-customer-loyalty-tier-rollback.sql` |

   > DBmaestro checked V6 before anyone merged it, *including the rollback*. The downgrade drops
   > the column, so it's flagged as a data-loss risk. A warning, not a block: the merge can go
   > ahead.

   (Proven on V3, the same change with a different column name. The comment links to the
   workflow run and to the project in DBmaestro.)

9. ⚠️ Optional: **Checks** tab → *DBmaestro package & precheck*. The same warning appears as a
   yellow annotation titled `DBmaestro · V6 · Precheck — policy warning`.

10. **Merge pull request → Confirm merge.**

11. **Actions → Database Release** → the new run (⚠️ appears a few seconds after the merge,
    refresh once). The graph: *Detect changed packages → Release Source → QA → Production*.
    > Release Source, then QA, automatically. Production waits for a person.

12. When QA is green, Production shows **Waiting**. Click **Review deployments**, tick **Prod**,
    add a comment, then **Approve and deploy**.
    > This is the approval. A named reviewer owns the decision to touch production, and GitHub
    > keeps the record.

13. Run all green. Scroll to the **Production summary**:
    > | Package | Step | Result |
    > |---|---|---|
    > | V6 | Deploy to Prod | ✅ Passed |

    The header links to the project in DBmaestro.

14. Click **View deployment** on the Production job (it opens the DOP tab), or switch to DOP:
    Prod now shows V6.
    > Same release, seen from DBmaestro.

---

## Act 3: Drift stops the release (~8 captures)

15. *[slide/image]* the hotfix:
    ```sql
    -- on Release Source, by hand
    ALTER TABLE customers ADD COLUMN hotfix_by_dba TEXT;
    ```
    Run it with `demo/drift.sh add` (off camera).
    > A DBA patches Release Source directly. The pipeline never saw it.

16. **New pull request**, compare `V7-orders-customer-index` → **Create pull request**.
    > Meanwhile, a normal change: an index on orders.

17. PR checks: **both green**. The DBmaestro comment says **DBmaestro accepted this change**,
    with no warnings.
    > The precheck passed. It checks the *change*, and the change is fine. It doesn't look at
    > what someone did to the environment.

18. **Merge** → **Actions → Database Release**: **Release Source ✗**, QA and Production
    **skipped**.
    > It doesn't even reach QA.

19. The run page's **Annotations** box:
    > ⛔ **DBmaestro · V7 · Deploy to Release_Source — drift detected**
    > Release_Source was changed outside the release pipeline. DBmaestro stopped the deployment
    > before touching it: drift detected on the Release Source, 1 object(s) differ from label
    > 'V6-post': TABLE github_rs.customers

    > **The best frame of the demo.** DBmaestro compared Release Source with the state it
    > recorded after the last release. It didn't match, so nothing ran. It even names the
    > table someone touched, and it isn't the table this change was about.

    ⚠️ This message format was added after the rehearsal (commit 725e3c9). The rehearsal run showed
    the older text "…Pre-Validation: Comparing schema 'github_rs' to label 'V3 (Rev. 1)-post'".
    The server line it now quotes is from the rehearsal log, and the parsing was tested on that
    line, but no real run has shown the new annotation yet. The Release Source summary table shows
    the same text under ⛔ *Drift detected*.

20. *Switch to the DOP tab* → refresh. The Release_Source card shows the failed upgrade. Open
    the red **Upgrade** activity → **Details** → **Pre Validate** report.
    > The same failure in DBmaestro's own words: the diff shows `hotfix_by_dba` as the extra
    > column.

    (In the GitLab demo this card had an orange border with a `!` badge, and Structure Analysis →
    👁 showed the diff. ⚠️ Check that it looks the same here.)

21. *[slide/image]* `demo/drift.sh remove` (off camera). Back in GitHub, on the failed run click
    **Re-run jobs → Re-run failed jobs**.
    > Fix the environment, re-run, and the release picks up where it stopped.

22. Release Source ✓, QA ✓, Production waiting → **Review deployments → Approve and deploy** →
    all green.

---

## Act 4: A destructive change is stopped at the Prod gate (~7 captures)

23. *[slide/image]* the SQL in `packages/V8/`:
    ```sql
    DROP TABLE customers_legacy;
    ```
    > Someone retires a legacy table. It's a legitimate package.

24. **New pull request**, compare `V8-retire-customers-legacy` → **Create pull request**. Checks
    green.

25. The DBmaestro PR comment:
    > **DBmaestro accepted this change, with policy warnings.** Review them before merging. The
    > same rules may block it in Production.
    >
    > | V8 | Precheck | ✅ Passed with 1 policy warning(s) | ⚠️ `Warning: 'Data Loss Risk', 'Drop Table is not allowed', 'Contains Drop Table'` in `01-v8-retire-customers-legacy.sql` |

    > DBmaestro flags it *in the pull request*, so the reviewer sees the data-loss risk before
    > approving. Here it's a warning, because outside Prod it's allowed.

26. **Merge** → Database Release: Release Source ✓, QA ✓, Production waiting.
    > It passes Release Source. It passes QA.

27. **Review deployments → Prod → Approve and deploy** → Production **✗**.
    > Even with a human approval, production says no.

28. **Annotations**:
    > ⛔ **DBmaestro · V8 · Deploy to Prod — blocked by policy**
    > Block: 'Data Loss Risk', 'Drop Table is not allowed', 'Contains Drop Table'
    > (script: 01-v8-retire-customers-legacy.sql)

    > Same rule, same script. A warning in the pull request, a block in production. This time
    > it's the *Policy Engine* that stops it, the mirror image of Act 3.

    The Production summary shows ⛔ *Blocked by DBmaestro Policy Engine*. A second annotation,
    "Process completed with exit code 1", is GitHub's own; skip it.

29. *[slide/image]* `demo/drift.sh show`: `customers_legacy` gone from RS and QA, **still there
    in Prod**.
    > The DROP never reached production.

**Closing line:**
> Same GitHub workflow. Same pull requests. DBmaestro decides what's safe to run in production.

---

## After recording: put the environments back

This project **deploys by tasks**, so `-Rollback -PackageName Vn` undoes **that one package**,
not "everything back to Vn". Learned the hard way on 2026-11-27.

Roll packages back **in reverse order**, newest first. Release Source's drift check compares
against the post-label of the **newest package still deployed** there. Rolling back an older
package while a newer one is still deployed leaves Release Source different from that label,
so the next release stops on drift.

Minimum, to restore `customers_legacy` after Act 4 (V8's downgrade recreates it):

```bash
java -jar DBmaestroAgent.jar -Rollback -ProjectName Github-Integration -EnvName QA \
  -PackageName V8 -Server localhost:8017 -UseSSL False \
  -AuthType DBmaestroAccount -UserName superuser@dbmaestro.com -Password '<password>'
# then the same with -EnvName Release_Source
demo/drift.sh show      # all three identical again
```

(Or ask Claude to run the rollbacks through the dbmaestro MCP tools.)

To **re-record** with the same objects, also roll back **V7, then V6**, on Release_Source, QA
and Prod, so `orders_customer_idx` and `loyalty_tier` no longer exist. Then:

```bash
demo/prepare-branches.sh 9 10 11
```

Package numbers can't be reused: a deployed package is closed in DBmaestro.

---

## If something fails mid-recording

- **No checks on the PR.** The PR doesn't touch `packages/`. Both workflows only run for
  package changes.
- **Jobs stuck "Queued".** The runner is offline (`kubectl get pods -n github-runner`, and the
  cluster must be up). Or the runner group lost access to the repo: the org's *Settings →
  Actions → Runner groups → dbmaestro-github-demo* must list this repository and allow public
  repositories.
- **Runner pod crash-looping after a while.** It tried to self-update. The image is pinned and
  started with `--disableupdate`. If GitHub drops support for 2.338.2, bump the tag in
  `runner/runner.yaml`.
- **`User not allowed`** in a job. `github-ci@dbmaestro.com` needs its role on Github-Integration,
  including *API Access*. If the DOP project was recreated, the role assignment went with it.
- **`Cannot create a new revision of Vn: package is closed`**: that number was already deployed.
  Use new numbers.
- **Release Source stops on drift you didn't cause.** Something was rolled back out of order (see
  above), or `drift.sh remove` wasn't run. `demo/drift.sh show` and the Pre Validate report in DOP
  name the object.
- **Review deployments refuses your approval.** *Prevent self-review* is on for Prod
  (*Settings → Environments → Prod*). Turn it off for the demo.
