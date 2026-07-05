#!/usr/bin/env bash
# qa-verify.sh - Post-deployment QA verification for the Breadcrumb project.
# Run after `vercel --prod` completes to verify production output is correct.
# Exit 0 = all checks passed, non-zero = one or more checks failed.

set -euo pipefail

BASE_URL="${BASE_URL:-https://breadcrumb-challenge.vercel.app/stage-2}"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "==========================================="
echo " Breadcrumb Post-Deployment QA Verification"
echo "==========================================="
echo ""

# Fetch production HTML once
echo "[1/6] Fetching production URL: ${BASE_URL}"
HTML=$(curl -sS -f --max-time 30 "${BASE_URL}") || {
  fail "Could not fetch ${BASE_URL} (HTTP error or timeout)"
  echo ""
  echo "Results: ${PASS} passed, ${FAIL} failed"
  exit 1
}

if [ -z "$HTML" ]; then
  fail "Production URL returned empty response"
  echo ""
  echo "Results: ${PASS} passed, ${FAIL} failed"
  exit 1
fi
pass "Successfully fetched production HTML ($(wc -c <<< "$HTML") bytes)"
echo ""

# Check 2: Stage 2 hash value
echo "[2/6] Verifying stage-2 hash (SHA-256 of '1997')"
EXPECTED_HASH="0985b889a1fe4f4e1fb925061ac6fb2247f10875f5fcbe63eec2ab55ed68970e"

if echo "$HTML" | grep -qF "$EXPECTED_HASH"; then
  pass "Stage-2 hash matches expected value: ${EXPECTED_HASH}"
else
  FOUND=$(echo "$HTML" | grep -oE '[a-f0-9]{64}' | head -5 || true)
  fail "Stage-2 hash not found in production HTML"
  echo "       Expected: ${EXPECTED_HASH}"
  echo "       Found hex strings in page: ${FOUND:-<none>}"
fi
echo ""

# Check 3: recovery hint data exists for stages 2, 3, and 4
echo "[3/6] Verifying recovery hint data presence"

if echo "$HTML" | grep -q "attemptHints"; then
  pass "Stage 2 attempt-based hint data found"
else
  fail "Stage 2 attempt-based hint data NOT found"
fi

if echo "$HTML" | grep -q "timedHints"; then
  pass "Timed hint data found for later stages"
else
  fail "Timed hint data NOT found for later stages"
fi

if echo "$HTML" | grep -qF "attempts: 10" && echo "$HTML" | grep -qF "[INTEL ALERT - FEDERAL VECTOR]"; then
  pass "Stage 3 10-attempt clue data found"
else
  fail "Stage 3 10-attempt clue data NOT found"
fi

if echo "$HTML" | grep -qF "delayMs: 120000" && echo "$HTML" | grep -qF "[INTEL ALERT - FEDERAL VECTOR]"; then
  pass "Stage 3 2-minute clue data found"
else
  fail "Stage 3 2-minute clue data NOT found"
fi

if echo "$HTML" | grep -q "getExternalLinkAttrs"; then
  pass "External-link rendering helper found"
else
  fail "External-link rendering helper NOT found"
fi
echo ""

# Check 4: Stage 2 Wayback button is present and points to the right URL
echo "[4/6] Verifying Stage 2 Wayback button"
EXPECTED_WAYBACK_URL="https://web.archive.org/web/*/granma.cu"

if echo "$HTML" | grep -qF "$EXPECTED_WAYBACK_URL"; then
  pass "Stage 2 Wayback URL matches expected value"
else
  fail "Stage 2 Wayback URL NOT found"
  echo "       Expected: ${EXPECTED_WAYBACK_URL}"
fi

if echo "$HTML" | grep -qF "Open Wayback Timeline"; then
  pass "Stage 2 Wayback button label found"
else
  fail "Stage 2 Wayback button label NOT found"
fi

if echo "$HTML" | grep -qF 'externalLinkPlacement: "asset-bottom"'; then
  pass "Stage 2 Wayback button placement is below the timeline asset"
else
  fail "Stage 2 Wayback button placement is NOT set below the timeline asset"
fi
echo ""

# Check 5: "Wayback timeline matrix" text removed
echo "[5/6] Verifying 'Wayback timeline matrix' text is removed"
if echo "$HTML" | grep -qF "Wayback timeline matrix"; then
  fail "'Wayback timeline matrix' text still present in production HTML"
  echo "       Expected: text removed"
  echo "       Found: text still exists in the page"
else
  pass "'Wayback timeline matrix' text successfully removed"
fi
echo ""

# Check 6: "Wayback Machine // secure external tab" text removed
echo "[6/6] Verifying 'Wayback Machine // secure external tab' text is removed"
if echo "$HTML" | grep -qF "Wayback Machine // secure external tab"; then
  fail "'Wayback Machine // secure external tab' text still present in production HTML"
  echo "       Expected: text removed"
  echo "       Found: text still exists in the page"
else
  pass "'Wayback Machine // secure external tab' text successfully removed"
fi
echo ""

# Summary
echo "==========================================="
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "==========================================="

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "QA verification FAILED. Review the failures above."
  echo "   Common causes:"
  echo "   - Vercel deployment is still building (wait a moment and retry)"
  echo "   - Git integration pushed stale content"
  echo "   - Build output differs from local staging"
  exit 1
fi

echo ""
echo "All QA checks passed. Production looks good."
exit 0
