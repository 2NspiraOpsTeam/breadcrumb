# Breadcrumb Operational Runbook

## Purpose

Breadcrumb is a static OSINT challenge hosted on Vercel from the `2NspiraOpsTeam/breadcrumb` GitHub repository. It has no build step, server runtime, database, or required environment variables.

## Normal Recovery Path

1. Inspect the repo state.

```bash
git status --short --branch
git log --oneline -8
```

2. Verify the static app locally.

```bash
bash -n scripts/qa-verify.sh
python3 -m http.server 4173
```

Open `http://localhost:4173/stage-1` and confirm the page boots, the stage input focuses, and no JavaScript error appears in the browser console.

3. Deploy through GitHub/Vercel.

```bash
git push origin main
```

Vercel is connected to the GitHub repository. A push to `main` should trigger the production deployment for `https://breadcrumb-challenge.vercel.app/`.

4. Verify production after Vercel finishes.

```bash
bash scripts/qa-verify.sh
curl -I -L https://breadcrumb-challenge.vercel.app/stage-2
```

Expected result: HTTP 200 and all QA checks pass.

## Routing Expectations

- `/` loads the landing page.
- `/stage-1` through `/stage-10` route to `index.html`.
- `/complete` routes to `index.html`.
- `/assets/*` serves static assets directly.

These rules are controlled by `vercel.json`. Do not add a build command or output directory unless the app is converted away from plain static HTML.

## Known Failure Modes

- If every route returns 404, inspect `vercel.json` and Vercel project root settings first.
- If the page loads but the challenge does not render, inspect `index.html` for JavaScript syntax errors around `renderEvidenceAsset()`, `renderStage()`, and external-link rendering.
- If `scripts/qa-verify.sh` exits early, check for `set -e` interactions with arithmetic increments.
- If production still shows old content after a push, wait for the Vercel deployment to finish and rerun the QA script. The app sends no-store headers for HTML, but Vercel can briefly serve the previous deployment during rollout.

## Ownership Notes

- Keep recovery changes small and reversible.
- Do not commit local test files such as `button-test.html` unless they are intentionally part of the app.
- Keep assets under `assets/` and reference them with absolute paths like `/assets/example.png`.
