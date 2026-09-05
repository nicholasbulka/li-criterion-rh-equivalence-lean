# Palomar comparator bundle — Li's criterion for the Riemann Hypothesis

This directory packages the Li-criterion development for submission to the
[Palomar registry](https://palomar-registry.org/about.html), following the comparator
convention used by [`teorth/sendov`](https://github.com/teorth/sendov) and
[`anthropics/zeta-23-lean`](https://github.com/anthropics/zeta-23-lean).

## What is claimed

Two theorems are compared. The first is **Li's criterion for the Riemann zeta function**:

```
RiemannHypothesis  ↔  (∀ n : ℕ, 0 ≤ (taylorCoeff riemannXi n).re)
```

`RiemannHypothesis` is Mathlib's. `riemannXi` is the entire completed ξ, and
`taylorCoeff riemannXi n` is the zero-indexed analytic coefficient corresponding to Li's
classical `λ_{n+1}` — the `n`-th Taylor coefficient at `0` of the logarithmic derivative of
`s ↦ ξ(1/(1-s))`. This is the equivalence of X.-J. Li (1997); it is **not** a proof of RH.

The second, `li_coefficients_eq_zero_sum`, verifies that the analytic Taylor coefficients in the
first theorem are Li's arithmetic coefficients: the symmetrized sum over the nontrivial zeros,
counted with multiplicity. The pairing records the classical symmetric summation convention;
the corresponding unpaired family is not absolutely summable. The theorem is a conjunction: the
symmetrized, multiplicity-weighted family is `Summable` (so the `∑'` denotes the genuine symmetric
sum and not Lean's default value for a non-summable family), and the Taylor coefficient equals half
that sum.

## The files

| File | Trust | Role |
|---|---|---|
| `Challenge.lean` | trusted | Defines the statement vocabulary directly from Mathlib and gives the two statements of record with deliberate `sorry` proofs. Imports only Mathlib. This is what a reader audits. |
| `ChallengeDeps.lean` | untrusted | Solution-side mirror of the Challenge definitions, character-for-character with `Lc/LiCriterion/Basic.lean`, in namespace `LiChallenge`. Imports only Mathlib. |
| `Solution.lean` | untrusted | The same two statements, proved by delegating to `LiCriterion.li_criterion_rh_iff` and `LiCriterion.taylorCoeff_eq_li_symmetrized`. Imports the LiCriterion library. |
| `../comparator.json` | — | Module names, `theorem_names`, permitted axioms (`propext`, `Quot.sound`, `Classical.choice`), `enable_nanoda`. |
| `../formalization.yaml` | — | Provenance / sources / automation / review / limitations / known gaps. |
| `PrintAxioms.lean` | — | Axiom audit without the Comparator binary; reads `comparator.json` and fails on a forbidden axiom. |
| `GeneratePrintAxioms.lean` | — | Dev tool: regenerates a static `#print axioms` transcript from `comparator.json`. |

The delegation in `Solution.lean` typechecks because the `LiChallenge.*` definitions are
definitionally equal to the library's `LiCriterion.*` definitions (identical bodies, different
namespace). The comparator re-checks statement equality, the axiom allowlist, and replays the
proof through both the Lean and NanoDa kernels.

## Submission gate — cleared

`LiCriterion.li_criterion_rh_iff` (in `Lc/LiCriterion/XiOrderBridge.lean`) is assembled from the
proved biconditional `biconditional_rh_li_of_hadamard_order_one` by supplying two order facts
about ξ:

- `LiCriterion.xi_hasFiniteOrder : Hadamard.hasFiniteOrder riemannXi`
- `LiCriterion.xi_order_le_one   : Hadamard.order riemannXi ≤ 1`

Both are **proved**, in `Lc/LiCriterion/XiGrowth.lean`, so the first compared theorem is
unconditional:

```
'li_criterion' depends on axioms: [propext, Classical.choice, Quot.sound]
```

Not via `ξ = ½ s (s-1) π^{-s/2} Γ(s/2) ζ(s)`: that route owes a polynomial bound for `ζ` in the
critical strip, which is not in Mathlib. Instead `XiGrowth.lean` uses the Mellin representation
that Mathlib already builds `completedRiemannZeta₀` from, together with the exponential decay of
the theta kernel and its functional equation, giving `‖ξ(s)‖ ≤ exp (O (‖s‖ log ‖s‖))` for every
`s` with no case split on the strip and no Stirling expansion.

## Checking the axioms without the Comparator binary

```
lake build Comparator && lake env lean comparator/PrintAxioms.lean
```

`PrintAxioms.lean` prints the conventional `#print axioms` transcript and then runs
`#audit_axioms`, which reads `comparator.json` itself and *fails the run* if any compared
declaration is missing or uses an axiom outside `permitted_axioms`. `GeneratePrintAxioms.lean`
regenerates a static transcript from the same config, for repos that prefer one checked in.

See [`../SUBMISSION_CHECKLIST.md`](../SUBMISSION_CHECKLIST.md) for the full submission procedure.

## Packaging note

For local development the three modules live here alongside the LiCriterion sources. For the
actual comparator run they form their own package whose dependencies are (a) Mathlib at the
project's pinned revision and (b) the LiCriterion repository at a pinned commit; the comparator
builds `Challenge` and `Solution` and checks them against `comparator.json`. That Lake wiring is set
up at submission time and is deliberately not committed into the main library build.
