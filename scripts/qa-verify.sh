#!/usr/bin/env bash
# qa-verify.sh - Post-deployment QA verification for the Breadcrumb project.
# Run after `vercel --prod` completes to verify production output is correct.
# Exit 0 = all checks passed, non-zero = one or more checks failed.

set -euo pipefail

BASE_URL="${BASE_URL:-https://breadcrumb-challenge.vercel.app/stage-2}"
if [[ "$BASE_URL" == *"/stage-"* ]]; then
  ORIGIN_URL="${BASE_URL%%/stage-*}"
elif [[ "$BASE_URL" == *"/index.html" ]]; then
  ORIGIN_URL="${BASE_URL%/index.html}"
else
  ORIGIN_URL="${BASE_URL%/}"
fi
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

if echo "$HTML" | grep -qF "stage-shell-stage-3"; then
  pass "Stage 3 spacing class found"
else
  fail "Stage 3 spacing class NOT found"
fi

if echo "$HTML" | grep -qF "stage-shell-stage-5" && echo "$HTML" | grep -qF "stage-shell-spaced-hints"; then
  pass "Stage 5 spacing class found"
else
  fail "Stage 5 spacing class NOT found"
fi

if echo "$HTML" | grep -qF "stage-shell-stage-6" && echo "$HTML" | grep -qF "stage-shell-spaced-hints"; then
  pass "Stage 6 spacing class found"
else
  fail "Stage 6 spacing class NOT found"
fi

if echo "$HTML" | grep -qF "stage-shell-stage-7" && echo "$HTML" | grep -qF "stage-shell-spaced-hints"; then
  pass "Stage 7 spacing class found"
else
  fail "Stage 7 spacing class NOT found"
fi

EXPECTED_STAGE5_HASH="b698d86c67a2cff80405bd47af322216c552fd3a52f9c58a70f7b3a3313895b1"
if echo "$HTML" | grep -qF "$EXPECTED_STAGE5_HASH"; then
  pass "Stage 5 answer hash matches expected value for 7000"
else
  fail "Stage 5 answer hash for 7000 NOT found"
  echo "       Expected: ${EXPECTED_STAGE5_HASH}"
fi

EXPECTED_STAGE6_HASH="2669177e036faf971d71a01d43e24021aedb25513df4bfd3a6916d78599f8bd4"
OLD_STAGE6_HASH="75e74817bfd082c9c1ff399396217f2d718ab5b688c7e8a0feb116a19b970515"
if echo "$HTML" | grep -qF "$EXPECTED_STAGE6_HASH"; then
  pass "Stage 6 answer hash matches expected value for 8635"
else
  fail "Stage 6 answer hash for 8635 NOT found"
  echo "       Expected: ${EXPECTED_STAGE6_HASH}"
fi

if echo "$HTML" | grep -qF "$OLD_STAGE6_HASH"; then
  fail "Old Stage 6 SOBRES hash still present"
else
  pass "Old Stage 6 SOBRES hash removed"
fi

if echo "$HTML" | grep -qF "https://search.sunbiz.org/Inquiry/CorporationSearch/ByName" && echo "$HTML" | grep -qF "OPEN STATE REGISTRY"; then
  pass "Stage 6 Sunbiz registry link data found"
else
  fail "Stage 6 Sunbiz registry link data NOT found"
fi

if echo "$HTML" | grep -qF "stage6-registry-matrix.png" && echo "$HTML" | grep -qF "N08000008635"; then
  pass "Stage 6 registry asset and document number found"
else
  fail "Stage 6 registry asset or document number NOT found"
fi

if echo "$HTML" | grep -qF "[INTEL ALERT - REGISTRY VECTOR]" && echo "$HTML" | grep -qF "[INTEL ALERT - DOCUMENT TRAILER]"; then
  pass "Stage 6 timed hint data found"
else
  fail "Stage 6 timed hint data NOT found"
fi

EXPECTED_STAGE7_HASH="2a898bc98aaf6c96f2054bb1eadc9848eb77633039e9e9ffd833184ce553fe9b"
OLD_STAGE7_HASH="b5f6dbae04bd764b0c2f3cb796e404ffdf77fb4cac171d72ec7fa6a2077da252"
if echo "$HTML" | grep -qF "$EXPECTED_STAGE7_HASH"; then
  pass "Stage 7 answer hash matches expected value for UUID"
else
  fail "Stage 7 answer hash for UUID NOT found"
  echo "       Expected: ${EXPECTED_STAGE7_HASH}"
fi

if echo "$HTML" | grep -qF "$OLD_STAGE7_HASH"; then
  fail "Old Stage 7 connectivity hash still present"
else
  pass "Old Stage 7 connectivity hash removed"
fi

if echo "$HTML" | grep -qF "https://www.iana.org/assignments/urn-namespaces/urn-namespaces.xhtml" && echo "$HTML" | grep -qF "OPEN PROTOCOL REGISTRY"; then
  pass "Stage 7 IANA registry link data found"
else
  fail "Stage 7 IANA registry link data NOT found"
fi

if echo "$HTML" | grep -qF "stage7-protocol-frame.png" && echo "$HTML" | grep -qF "Technical Protocol Standards"; then
  pass "Stage 7 protocol asset and title found"
else
  fail "Stage 7 protocol asset or title NOT found"
fi

if echo "$HTML" | grep -qF "[INTEL ALERT - PROTOCOL REGISTRY]" && echo "$HTML" | grep -qF "[INTEL ALERT - NAMESPACE ACRONYM]"; then
  pass "Stage 7 timed hint data found"
else
  fail "Stage 7 timed hint data NOT found"
fi

if echo "$HTML" | grep -qF ".stage-shell-stage-3 .timeline-graphic" && echo "$HTML" | grep -qF "1360px"; then
  pass "Stage 3 enlarged image styling found"
else
  fail "Stage 3 enlarged image styling NOT found"
fi

if echo "$HTML" | grep -qF "National archives query vector"; then
  fail "Stage 3 asset meta label still present"
else
  pass "Stage 3 asset meta label removed"
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

# Check 7: Stage 6 and 7 assets are served
echo "[7/7] Verifying Stage 6 and 7 assets are served"
STAGE6_ASSET_URL="${ORIGIN_URL}/assets/stage6-registry-matrix.png"
if curl -sS -f -I --max-time 30 "$STAGE6_ASSET_URL" >/dev/null; then
  pass "Stage 6 registry asset served: ${STAGE6_ASSET_URL}"
else
  fail "Stage 6 registry asset NOT served: ${STAGE6_ASSET_URL}"
fi

STAGE7_ASSET_URL="${ORIGIN_URL}/assets/stage7-protocol-frame.png"
if curl -sS -f -I --max-time 30 "$STAGE7_ASSET_URL" >/dev/null; then
  pass "Stage 7 protocol asset served: ${STAGE7_ASSET_URL}"
else
  fail "Stage 7 protocol asset NOT served: ${STAGE7_ASSET_URL}"
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
