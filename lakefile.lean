import Lake
open Lake DSL

/-!
Palomar submission project: Li's criterion for the Riemann Hypothesis.

Trimmed to the transitive import closure of `comparator/Solution.lean`.  The only dependency is
Mathlib, pinned in `lake-manifest.json`.
-/

/-- Mathlib-style linters enforced across the project. -/
abbrev liCriterionLinters : Array LeanOption := #[
  ⟨`linter.mathlibStandardSet, true⟩,
  ⟨`linter.style.header, true⟩,
  ⟨`linter.checkInitImports, true⟩,
  ⟨`linter.allScriptsDocumented, true⟩,
  ⟨`linter.pythonStyle, true⟩,
  ⟨`linter.style.longFile, .ofNat 1500⟩
]

package LiCriterion where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩,
    ⟨`maxSynthPendingDepth, .ofNat 3⟩
  ] ++ liCriterionLinters.map fun s ↦ { s with name := `weak ++ s.name }

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @
  "de5ce8a9a66a4aa68a9bdbb35b63a06d34d9ca11"

/-- The Li-criterion development. -/
lean_lib Lc

/-- The genus-1 Hadamard factorization machinery. -/
lean_lib Hadamard

/-- Shared complex-analysis utilities. -/
lean_lib FunctionsOfOneComplexVariable

/-- The Comparator bundle: the statement of record, and its proof. -/
@[default_target]
lean_lib Comparator where
  srcDir := "comparator"
  roots := #[`ChallengeDeps, `Challenge, `Solution]
