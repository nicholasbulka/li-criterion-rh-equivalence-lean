# Li's criterion for the Riemann Hypothesis, in Lean 4

A `sorry`-free formalization of **Li's criterion**: the Riemann Hypothesis holds if and only if
every Li–Keiper coefficient of the completed ξ function is nonnegative.

```lean
theorem li_criterion :
    RiemannHypothesis ↔ (∀ n : ℕ, 0 ≤ (taylorCoeff riemannXi n).re)
```

`RiemannHypothesis` is Mathlib's. `riemannXi` is the entire completed ξ, built from Mathlib's
`completedRiemannZeta₀`, and `taylorCoeff riemannXi n` is the zero-indexed analytic coefficient
corresponding to Li's classical `λ_{n+1}` — the `n`-th Taylor coefficient at `0` of the
logarithmic derivative of `s ↦ ξ(1/(1-s))`. This is the criterion of X.-J. Li (1997).

**It is an equivalence, not a proof of RH.** Nothing here asserts that the coefficients are
nonnegative.

The statement is **unconditional**: no Hadamard-factorization hypothesis, no summability
hypothesis, no growth assumption on ξ.

A second compared theorem verifies the normalization: the analytically defined Taylor
coefficient is Li's coefficient in its symmetrically summed arithmetic form over the nontrivial
zeros. This rules out a formally consistent but incorrectly normalized coefficient sequence.

```
'li_criterion' depends on axioms: [propext, Classical.choice, Quot.sound]
```

## Layout

| | |
|---|---|
| `comparator/Challenge.lean` | *trusted.* Mathlib-only definitions and the two statements of record, with deliberate `sorry` proofs. This is what a reader audits |
| `comparator/ChallengeDeps.lean` | solution-side mirror of the Challenge definitions, from Mathlib alone |
| `comparator/Solution.lean` | the same two statements, proved by delegation to the library |
| `comparator/PrintAxioms.lean` | axiom audit that **fails** on a forbidden axiom (see `SUBMISSION_CHECKLIST.md` Part 4) |
| `comparator.json`, `formalization.yaml` | Comparator configuration and Palomar metadata |
| `Lc/` | the Li-criterion development (15 modules, including `Lc.lean`) |
| `Hadamard/` | genus-1 Hadamard factorization with multiplicities (18 modules) |
| `FunctionsOfOneComplexVariable/` | Borel–Carathéodory and supporting complex analysis (3 modules) |

41 Lean modules including the five comparator modules, ~23,100 lines, one direct dependency
(Mathlib, pinned in `lake-manifest.json`).

## Building

```
lake exe cache get
lake build
bash scripts/audit.sh
```

## The two halves

**Positivity ⟹ RH** is unconditional and self-contained (`Lc/LiCriterion/ReverseDirection.lean`):
nonnegative Taylor coefficients of the logarithmic derivative force `φ = ξ ∘ (z ↦ 1/(1-z))` to be
zero-free on the unit disk, by a Pringsheim-type argument, and the functional equation then pins
every nontrivial zero to the critical line.

**RH ⟹ positivity** needs the genus-1 Hadamard factorization of ξ with multiplicities and the
summability of `∑ 1/|ρ|²`. Both are proved here, from `order ξ ≤ 1`
(`Lc/LiCriterion/XiOrderBridge.lean`).

## The growth bound

`order ξ ≤ 1` is proved in `Lc/LiCriterion/XiGrowth.lean` **without any bound on ζ**. The
classical route through `ξ = ½ s (s-1) π^{-s/2} Γ(s/2) ζ(s)` owes a polynomial bound for ζ in the
critical strip, which is not in Mathlib. Instead, Mathlib already *defines* the completed zeta as
a Mellin transform, and that is available by `rfl`:

```lean
lemma completedRiemannZeta₀_eq_mellin (s : ℂ) :
    completedRiemannZeta₀ s = (mellin PR.f_modif (s / 2)) / 2 := rfl
```

`f_modif` is the modified theta kernel of `HurwitzZeta.hurwitzEvenFEPair 0`: `Θ(x) - 1` on
`(1, ∞)` and `Θ(x) - x^{-1/2}` on `(0, 1)`. The kernel decays exponentially at `∞`
(`isBigO_atTop_evenKernel_sub`) and its functional equation transports that decay to `0`, so
bounding the Mellin integral against the two exponentials gives

    ‖ξ(s)‖ ≤ exp (O (‖s‖ log ‖s‖))

for **every** `s` — no case split on the critical strip, no reflection argument, no Stirling
expansion. What replaces Stirling is one elementary lemma, which is just `log t ≤ t - 1`:

```lean
lemma rpow_mul_exp_neg_le {u A p : ℝ} (hu : 0 < u) (hA : 0 ≤ A) (hp : 0 < p) :
    u ^ A * rexp (-(p * u)) ≤ rexp (A * Real.log (A / p))
```

Integrability of the Mellin integrand comes free from Mathlib's functional-equation-pair
machinery (`PR.toStrongFEPair.hasMellin`), so no convergence side conditions are proved by hand.

## Provenance

Classically known result. Li's criterion is due to Xian-Jin Li, and the related coefficient
construction builds on Jerry B. Keiper's work. Professor M. Ram Murty's lecture
[Lectures on Probability Theory — Li Criterion](https://www.youtube.com/watch?v=M0lgrrskxMw)
was also helpful as an explanation of the mathematics. See `formalization.yaml` for full sources,
authorship, automation, review status and limitations. The Lean development was written by Claude
(Anthropic) in Claude Code under the direction and review of the maintainer.

`SUBMISSION_CHECKLIST.md` documents the Palomar submission procedure this repository targets.

## Licence

Apache-2.0; see `LICENSE`.
