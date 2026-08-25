/-
Copyright (c) 2026 Nicholas Bulka. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
SPDX-License-Identifier: Apache-2.0
Authors: Nicholas Bulka
-/
/-
comparator/PrintAxioms.lean — the axiom audit, runnable WITHOUT the Comparator binary:

    lake build Comparator && lake env lean comparator/PrintAxioms.lean

It does two things:

* the conventional `#print axioms` transcript, which a human reads;
* `#audit_axioms`, which reads `comparator.json` itself and *fails* (non-zero exit) if any
  compared declaration is missing or depends on an axiom outside `permitted_axioms` --
  in particular `sorryAx` (from `sorry`) or `Lean.ofReduceBool` (from `native_decide`).

The second is the one worth wiring into CI: `#print axioms` only prints, so a regression
scrolls past in a green build.  Comparator itself remains the stronger check, because it also
verifies that these statements coincide with the trusted ones in `Challenge.lean`.

IMPORTANT: import `Solution` only, never `Challenge` as well.  Both modules declare the same
root-level names, and importing both makes the *sorried* Challenge version win -- the audit
then correctly reports `sorryAx` for a theorem that is in fact proved.
-/
import Solution
import Lean

/-! ## The conventional transcript -/

open Lean Elab Command

#print axioms li_criterion

/-! ## The mechanical audit -/

namespace PalomarAudit

/-- The subset of `comparator.json` this audit needs. -/
structure Config where
  theoremNames : Array String
  permittedAxioms : Array String
  deriving Repr

/-- Read and validate the Comparator configuration. -/
def readConfig (path : System.FilePath) : IO Config := do
  unless ← path.pathExists do
    throw <| IO.userError s!"comparator config not found: {path} (paths are relative to the \
      directory `lake env lean` is run from, normally the project root)"
  let j ← IO.ofExcept (Json.parse (← IO.FS.readFile path))
  let field (k : String) : IO (Array String) :=
    match j.getObjValAs? (Array String) k with
    | .ok a => pure a
    | .error e => throw <| IO.userError s!"{path}: field '{k}': {e}"
  return { theoremNames := ← field "theorem_names",
           permittedAxioms := ← field "permitted_axioms" }

/-- Audit one declaration against the permitted set; log, and report success. -/
def auditOne (permitted : Array Name) (n : Name) : CommandElabM Bool := do
  if ((← getEnv).find? n).isNone then
    logError m!"missing declaration: {n}"
    return false
  let axs := (← collectAxioms n).qsort Name.lt
  let bad := axs.filter fun a => !permitted.contains a
  if bad.isEmpty then
    logInfo m!"ok   '{n}' depends on axioms: {axs.toList}"
    return true
  else
    logError m!"FAIL '{n}' uses forbidden axioms: {bad.toList}"
    return false

/-- Run the audit over a list of names, failing the elaboration if any check fails. -/
def auditAll (permitted : Array Name) (targets : Array Name) : CommandElabM Unit := do
  let mut ok := true
  for n in targets do
    unless ← auditOne permitted n do ok := false
  unless ok do throwError "axiom audit FAILED"
  logInfo m!"axiom audit passed ({targets.size} declaration(s))"

end PalomarAudit

open PalomarAudit in
/-- `#audit_axioms "comparator.json"` — check every declaration named in the Comparator
configuration against its own `permitted_axioms` list.  There is no second list to keep in
sync: the config is the single source of truth. -/
elab "#audit_axioms" cfg:str : command => do
  let config ← readConfig cfg.getString
  let permitted := config.permittedAxioms.map (·.toName)
  logInfo m!"auditing {config.theoremNames.size} declaration(s) named in {cfg.getString}; \
    permitted: {permitted.toList}"
  auditAll permitted (config.theoremNames.map (·.toName))

open PalomarAudit in
/-- `#audit_module "Solution" "comparator.json"` — audit *every* theorem declared in a module,
with no list at all.  Catches a theorem that was added to `Solution.lean` but never added to
`comparator.json`. -/
elab "#audit_module" mod:str cfg:str : command => do
  let permitted := (← readConfig cfg.getString).permittedAxioms.map (·.toName)
  let env ← getEnv
  let modName := mod.getString.toName
  let some idx := env.getModuleIdx? modName
    | throwError "module not found (is it imported?): {modName}"
  let mut targets : Array Name := #[]
  for (n, i) in env.const2ModIdx.toList do
    if i == idx && !n.isInternal && !isPrivateName n then
      if let some (.thmInfo _) := env.find? n then
        targets := targets.push n
  logInfo m!"auditing every theorem declared in {modName}"
  auditAll permitted (targets.qsort Name.lt)

#audit_axioms "comparator.json"
#audit_module "Solution" "comparator.json"
