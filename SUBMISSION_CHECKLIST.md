# Palomar submission checklist

A reusable procedure for preparing a repository snapshot for the
[Palomar Registry](https://palomar-registry.org/how-to-submit.html), written against two working
exemplars:

| exemplar | what to copy from it |
|---|---|
| [`teorth/sendov`](https://github.com/teorth/sendov) | root-level layout, `formalization.yaml` shape, `comparator.json`, a `Challenge.lean` that introduces **no definitions of its own**, `scripts/audit.sh` + CI |
| [`anthropics/zeta-23-lean`](https://github.com/anthropics/zeta-23-lean) | the `ChallengeDeps.lean` pattern for when the statement *does* need definitions, and `PrintAxioms.lean` |

Part 1 is the file manifest. Part 2 is the mechanical gate. Part 3 is the submission procedure.
Part 4 is the axiom-audit tooling, including how to stop the audit list from drifting.

---

## Part 1 — files that must exist

Everything below lives in the **selected project directory** (the repository root by default; if
the Lean project is nested, give that repository-relative path on the submission form). The
licence file is the exception: it stays at the repository root even for a nested project.

### Required

| file | notes |
|---|---|
| `lakefile.toml` **or** `lakefile.lean` | exactly one, never both |
| `lake-manifest.json` | **required** for `lakefile.lean` projects; strongly recommended for `lakefile.toml` — commit it |
| `lean-toolchain` | pinned to a supported Lean release or RC. A project-local file beats a repository-root one |
| `Challenge.lean` | the statement of record, with deliberate `sorry` holes. Conventional name |
| `Solution.lean` | the same declarations, proved. Conventional name |
| `comparator.json` | conventional name, at the project root. Names every theorem **and definition** Comparator should compare |
| `formalization.yaml` | required metadata (Part 3). May sit outside a nested project if you give the path |
| `LICENSE` | at the **repository** root, not the project root |

### Strongly recommended

| file | why |
|---|---|
| `PrintAxioms.lean` | run the axiom check without the Comparator binary; see Part 4 |
| `README.md` | may carry the plain-language narrative editorial review needs |
| `scripts/audit.sh` | forbidden-token scan (`sorry` outside Challenge, project `axiom`, `native_decide`, `unsafe`, `Float`) plus the axiom print |
| `.github/workflows/*.yml` | CI running `lake build` and the audit, so the snapshot you submit is one CI has seen green |

### Deliberately absent

- vendored dependency trees or unrelated sub-projects (they inflate the snapshot and the review surface)
- a `Deprecated/` directory containing `sorry`s — even if unbuilt, a reviewer greps
- dependencies nothing imports (check with `grep -rn "import <Dep>"` before trusting the lakefile)

---

## Part 2 — the mechanical gate

Comparator rebuilds the two modules, checks the compared declarations have the **same names and
types**, checks the permitted axioms, and replays the proof through the kernel.

### Axioms

A proved `Solution` declaration may depend on **only** these three:

```
propext        Classical.choice        Quot.sound
```

Not permitted: `sorryAx` (from `sorry`), `Lean.ofReduceBool` (from `native_decide`), any custom
`axiom`, any unnamed missing definition. Ordinary `decide` is fine. `Challenge.lean`, by
contrast, is *expected* to contain `sorry`.

**Conditional results are stated, not assumed.** Write

```lean
theorem euler_product (h : RiemannHypothesis) : … := …
```

never `axiom RiemannHypothesis : …`. With several hypotheses a bundled typeclass reduces
boilerplate — but write `[LiteratureHypotheses]` in each signature that needs it rather than
declaring it with `variable`, which hides which theorems depend on it.

### The Challenge module

- **Hard limits: 1,000 lines and 100 KiB.** Target: 300 lines and 32 KiB.
- Transitive imports must resolve to Lean core, or the pinned allowlisted Mathlib / Tau Ceti
  closure, and nothing else. Importing Tau Ceti marks the entry as having qualified statement
  dependencies.
- **An already-registered Palomar project is not importable** on that basis. An entry fixes a
  reviewable snapshot of its own statement, not a library for later submissions.
- Solution-only dependencies may be arbitrary pinned Git dependencies, and path dependencies are
  allowed when their targets stay inside the same pinned checkout. Neither relaxes the Challenge
  import rule.

If the statement needs definitions Mathlib does not have, do **not** inline them into the proof
library's namespace — use the `ChallengeDeps.lean` pattern: one small module defining them from
Mathlib alone, imported only by `Challenge.lean`, with bodies character-for-character identical
to the library's so the `Solution` delegation typechecks by unfolding.

> **Trap.** Never import both `Challenge` and `Solution` into one file. They declare the same
> root-level names; the sorried Challenge version wins, and an axiom audit will report `sorryAx`
> for a theorem that is in fact proved.

---

## Part 3 — submission procedure

### Metadata: what `formalization.yaml` must carry

Structured fields:

- project name, authors, licence, responsible maintainers
- original vs. source-based; substantive development vs. thin Comparator wrapper
- 1–2 arXiv categories; 1–8 MSC2020 codes
- automation methods used (including `manual`, where that is the truth)
- review status

Narrative for editorial review — may live in the YAML, in Challenge docstrings, or in the
project README:

- a plain-language account of **every** compared theorem
- what is original and what is adapted
- the role of AI and of human review
- any fidelity gaps, extra assumptions, or scope limitations

Sources:

- a source may be a book, article, non-arXiv preprint, web discussion, private communication, or
  folklore — give the most stable reference available
- for each, state whether you **formalize**, **adapt**, **independently prove**, or merely use it
  as **background**
- record prior formalizations separately
- `sources[].authors` is for bibliographic authorship only; credit other roles (editor, problem
  proposer, …) via `sources[].contributors`, each a name plus a free-form role
- a thin wrapper must identify the substantive formalization repository at an immutable commit
- a formalization first presenting a new result may legitimately have no source

Submit only as a responsible author or maintainer of the substantive formalization, or with
approval from one — for a wrapper, that means the people behind the underlying work.

### The snapshot

```bash
git add -A && git commit && git push          # uncommitted changes are excluded
git rev-parse HEAD                            # copy the full 40 characters
```

Palomar reviews an immutable commit, not a branch or tag. On GitHub you can instead use the
"Copy the full SHA" clipboard icon in the commits list. The commit must be pushed to a **public**
repository.

### The form

1. Enter repository + full 40-character SHA. Leave the project / Comparator-config / metadata
   paths blank for a root layout; fill them only for a nested or non-default one.
2. Declare whether you maintain the substantive formalization or have approval.
3. Prove write access. **Browser:** GitHub sign-in — Palomar checks the account can push, then
   discards the token. **Agent:** push a tag at the submitted commit and post a gist carrying the
   same challenge. The agent route is deliberately weaker: it shows *someone* who can write to the
   repo submitted it and that *an* account named itself, not that they are the same account.
   Neither route is proof of authorship, which is why the relationship question is asked separately.
4. **Keep the status page URL.** It is the only way back — no email, no account.

### After submission

- Mechanical verification runs first, in a **public** GitHub Actions workflow. Its inputs and logs
  are as public as the run.
- If it passes, editorial review follows; the target is one hour, not a guarantee.
- `review-failed` means an operator or tool fault, not a decision — it can be rerun.
- The review appears on your status page and nowhere else, with reasons and comments. *Changes
  requested* means reconsiderable after specific fixes; *rejected* means a fundamental semantic,
  provenance, or editorial failure. Either way, revised source is a **new submission at a new SHA**.
- **Nothing is registered until you ask.** Identifying no blocking problem is not registration;
  the entry appears only once the database pull request is merged.
- Registration is meant to be permanent — withdrawal is unavailable afterwards; you get a further
  version or the lawful-request process instead.

### What is public

| | |
|---|---|
| public from verification onward | repository, commit, submission identifier, declared authorization relationship, any approval evidence you wrote, the ID of a record you are correcting |
| public only if you register | the automated review and its findings, and the registry record |
| never published | your identity as submitter — the record has no field for it |

"Private" means not public, not confidential: reviews are readable by Palomar operators, GitHub,
and the model provider, and are retained indefinitely. **Do not put anything sensitive in the
notes field.**

### Versioning

Corrections and dependency updates become new versions of the same Palomar ID, and every earlier
version stays resolvable. A new mathematical result gets a new ID. A bare ID resolves to the
newest version, so cite the version explicitly — `PALOMAR-2026-07-29-000001 v1`, not
`PALOMAR-2026-07-29-000001`. The entry page URL always names the version being viewed.

---

## Part 4 — the axiom audit, and how to keep it honest

`#print axioms` only *prints*. A regression scrolls past in a green build, because nothing about
a printed line makes a build fail. And a hand-written transcript silently falls behind the
config it is supposed to mirror. Neither risk is hypothetical: in the `zeta-23-lean` snapshot
vendored here, three Comparator configs name 33 distinct compared theorems between them, while
the hand-written `PrintAxioms.lean` lists the 15 from `config.json` — **18 compared declarations
are not covered by the transcript at all**, and nothing in the repository notices.

Three ways to fix it, in increasing order of how little there is left to maintain.

### Option 1 — read the config (recommended)

Make `comparator.json` the single source of truth and have Lean read it at elaboration time. No
second list, and nothing to regenerate:

```lean
#audit_axioms "comparator.json"
```

The command parses the config, resolves each name in `theorem_names`, calls `collectAxioms`, and
`throwError`s if anything is missing or uses an axiom outside `permitted_axioms`. `throwError`
means a non-zero exit, so CI actually fails. Implementation: `comparator/PrintAxioms.lean`.

The whole mechanism is four Lean APIs:

| API | role |
|---|---|
| `Lean.collectAxioms : Name → m (Array Name)` | what `#print axioms` itself calls (`Lean/Elab/Print.lean`) |
| `Lean.Json.parse` + `Json.getObjValAs? (Array String)` | read the config |
| `IO.FS.readFile` in `CommandElabM` | `CommandElabM` lifts `IO`, so no ceremony |
| `elab "#audit_axioms" cfg:str : command => …` | one-line syntax declaration |

```lean
def auditOne (permitted : Array Name) (n : Name) : CommandElabM Bool := do
  if ((← getEnv).find? n).isNone then
    logError m!"missing declaration: {n}"; return false
  let axs := (← collectAxioms n).qsort Name.lt
  let bad := axs.filter fun a => !permitted.contains a
  if bad.isEmpty then
    logInfo m!"ok   '{n}' depends on axioms: {axs.toList}"; return true
  else
    logError m!"FAIL '{n}' uses forbidden axioms: {bad.toList}"; return false
```

### Option 2 — no list at all

Even a correct config can omit a theorem someone added to `Solution.lean`. Enumerate the module
instead, via the environment's constant-to-module map:

```lean
#audit_module "Solution" "comparator.json"
```

```lean
let some idx := env.getModuleIdx? modName | throwError "module not found: {modName}"
for (n, i) in env.const2ModIdx.toList do
  if i == idx && !n.isInternal && !isPrivateName n then
    if let some (.thmInfo _) := env.find? n then targets := targets.push n
```

Run both: Option 1 checks that everything promised is proved, Option 2 that everything proved was
promised.

Both commands take one config and one module, so a repository with several Comparator configs
invokes them once per config — and the `#audit_module` line is what catches the config you
forgot:

```lean
#audit_axioms "comparator.json"
#audit_axioms "comparator-multiplicity.json"
#audit_module "Solution" "comparator.json"
```

### Option 3 — generate the static transcript

If you want a checked-in `#print axioms` transcript anyway, generate it from the config rather
than typing it, so the two cannot disagree:

```
lake env lean comparator/GeneratePrintAxioms.lean
```

`#emit_print_axioms "comparator.json" "Solution" "comparator/PrintAxiomsGenerated.lean"` reads
`theorem_names` and writes one `#print axioms` line per entry. Elaboration-time `IO.FS.writeFile`
is what makes this work — which is also why it lives in a separate developer-tool file that the
build does not run.

### Verify the audit can fail

An audit that cannot fail is decoration. Confirm the negative control once:

```bash
lake env lean comparator/PrintAxioms.lean ; echo "exit=$?"     # expect 0
# then temporarily point it at a module containing a sorry — expect FAIL and exit=1
```

---

## The gate, in ten lines

```bash
lake build                                              # library, Challenge, Solution
lake env lean comparator/PrintAxioms.lean               # exit 0, no forbidden axiom
bash scripts/audit.sh                                   # forbidden tokens, if you have one
grep -rn "\bsorry\b" --include="*.lean" . | grep -v Challenge.lean    # expect prose only
# formalization.yaml: status complete, known_gaps [], narrative present
# LICENSE at repository root; lake-manifest.json committed; lean-toolchain pinned
git add -A && git commit && git push
git rev-parse HEAD                                      # the 40 characters to submit
```
