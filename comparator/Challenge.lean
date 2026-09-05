/-
Copyright (c) 2026 Nicholas Bulka. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
SPDX-License-Identifier: Apache-2.0
Authors: Nicholas Bulka
-/
import Mathlib

/-!
Challenge.lean — the TRUSTED comparator challenge module: WHAT IS CLAIMED.

Two theorem statements, each with proof `sorry`. The first is Li's criterion for the Riemann zeta
function: Mathlib's `RiemannHypothesis` holds if and only if every Li–Keiper coefficient of ξ has
nonnegative real part. The second identifies those analytically defined Taylor coefficients with
Li's symmetrically summed arithmetic formula over the nontrivial zeros, and establishes that the
symmetrized family is summable so the `∑'` is the genuine sum. Every notion they use is
either Mathlib's (`RiemannHypothesis`, `analyticOrderNatAt`) or defined directly below from
Mathlib alone (`riemannXi`, `taylorCoeff`, `NontrivialZero`).

`Solution.lean` (untrusted) proves exactly these statements by delegating to the LiCriterion
library. The comparator checks statement equality, that only the axioms `propext`,
`Classical.choice`, `Quot.sound` are used, and replays the proofs through the kernel. See
`README.md` here.

The two `sorry`s below are deliberate (this is the challenge side); expect two "declaration uses
'sorry'" warnings when building this module.

## What the statement says

Writing `λ_{n+1} := taylorCoeff riemannXi n` for the `n`-th Taylor coefficient at `0` of the
logarithmic derivative of `s ↦ ξ(1/(1-s))`, the claim is

  RiemannHypothesis  ↔  ∀ n, 0 ≤ (λ_{n+1}).re.

The coefficients `λ_{n+1}` are real, so taking the real part expresses Li's positivity condition.
This is the criterion of X.-J. Li, "The positivity of a sequence of numbers and the Riemann
hypothesis" (J. Number Theory 65 (1997), 325–333), in the normalization related to Jerry B.
Keiper's coefficients and used in this development.
-/

noncomputable section

open Complex

namespace LiChallenge

/-- The Riemann ξ function in entire form: `ξ(s) = ½ · s · (s-1) · Λ₀(s) + ½`, where
`Λ₀ = completedRiemannZeta₀` is Mathlib's entire completed zeta. -/
def riemannXi (s : ℂ) : ℂ :=
  (1 / 2 : ℂ) * s * (s - 1) * completedRiemannZeta₀ s + (1 / 2 : ℂ)

/-- The Cayley-type change of variable `z ↦ 1/(1-z)`. -/
def phi (f : ℂ → ℂ) (z : ℂ) : ℂ := f (1 / (1 - z))

/-- The logarithmic derivative `f' / f`. -/
def logDeriv (φ : ℂ → ℂ) (z : ℂ) : ℂ := deriv φ z / φ z

/-- The zero-indexed analytic coefficient corresponding, for `f = riemannXi`, to Li's classical
`λ_{n+1}`: the `n`-th Taylor coefficient at `0` of the logarithmic derivative after the Cayley
change of variable. -/
def taylorCoeff (f : ℂ → ℂ) (n : ℕ) : ℂ :=
  (deriv^[n] (logDeriv (phi f))) 0 / n.factorial

/-- The nontrivial zeros of `ζ`: the zeros in the open critical strip `0 < re s < 1`. -/
def NontrivialZero : Type := {ρ : ℂ // riemannZeta ρ = 0 ∧ 0 < ρ.re ∧ ρ.re < 1}

end LiChallenge

open LiChallenge

/-- **Li's criterion for the Riemann Hypothesis.**  The Riemann Hypothesis (Mathlib's
`RiemannHypothesis`) holds if and only if every Li–Keiper coefficient of the completed ξ has
nonnegative real part. -/
theorem li_criterion :
    RiemannHypothesis ↔ (∀ n : ℕ, 0 ≤ (taylorCoeff riemannXi n).re) := by
  sorry

/-- **Fidelity: the coefficients are Li's.**  The `n`-th Taylor coefficient above is Li's
`λ_{n+1}` in the arithmetic form of Li (1997) and Bombieri-Lagarias: the sum over the nontrivial
zeros, counted with multiplicity, of `1 - (1 - 1/ρ)^{n+1}`, taken in the symmetric sense that
pairs `ρ` with `1 - ρ`.

The symmetrisation is not a weakening: the unpaired sum is not absolutely convergent, so a bare
`∑'` over the zeros would be false rather than stronger.

The statement is a conjunction.  Its first half says the symmetrized, multiplicity-weighted
family is `Summable`, so that the `∑'` in the second half denotes the genuine symmetric sum over
the zeros and not Lean's default value `0` for a non-summable family. -/
theorem li_coefficients_eq_zero_sum (n : ℕ) :
    Summable (fun ρ : NontrivialZero =>
        (analyticOrderNatAt riemannXi ρ.val : ℂ) *
          ((1 - (1 - 1 / ρ.val) ^ (-((n : ℤ) + 1)))
            + (1 - (1 - 1 / ρ.val) ^ ((n : ℤ) + 1)))) ∧
    taylorCoeff riemannXi n
      = (2⁻¹ : ℂ) * ∑' ρ : NontrivialZero,
          (analyticOrderNatAt riemannXi ρ.val : ℂ) *
            ((1 - (1 - 1 / ρ.val) ^ (-((n : ℤ) + 1)))
              + (1 - (1 - 1 / ρ.val) ^ ((n : ℤ) + 1))) := by
  sorry
