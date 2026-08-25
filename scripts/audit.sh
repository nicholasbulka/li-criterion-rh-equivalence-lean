#!/bin/sh
# Trust audit for the Li-criterion submission.  See SUBMISSION_CHECKLIST.md Part 4.
#
#   1. no forbidden tokens in the proof sources or in Solution.lean
#   2. Challenge.lean holds exactly its one deliberate hole
#   3. the compared theorem depends on the three standard axioms only
cd "$(dirname "$0")/.." || exit 1
rc=0

echo "=== 1. forbidden tokens ==="
hits=$(grep -rnE '\bsorry\b|^ *axiom |native_decide|\bunsafe \b|\bpartial def\b|Float' \
         Lc/ Hadamard/ FunctionsOfOneComplexVariable/ comparator/Solution.lean \
         comparator/ChallengeDeps.lean --include=*.lean \
       | grep -vE ':[0-9]+: *--' | grep -vE '`sorry`|`native_decide`')
if [ -n "$hits" ]; then echo "$hits"; rc=1; else echo "none"; fi

echo
echo "=== 2. Challenge.lean: deliberate holes only ==="
holes=$(grep -cE '^ *sorry$' comparator/Challenge.lean)
echo "deliberate holes: $holes (expected 2, one per compared theorem)"
[ "$holes" = "2" ] || { echo "!! unexpected hole count"; rc=1; }

echo
echo "=== 3. axioms of the compared theorem ==="
out=$(lake env lean comparator/PrintAxioms.lean 2>&1)
echo "$out"
echo "$out" | grep -qE "sorryAx|ofReduceBool|ofReduceNat|FAIL" && { echo "!! forbidden axiom"; rc=1; }

echo
echo "=== audit finished (rc=$rc) ==="
exit $rc
