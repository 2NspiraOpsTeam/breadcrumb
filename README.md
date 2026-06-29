# Needles in Haystacks

Static OSINT challenge game designed for zero-cost hosting on Vercel.

## Stack

- Plain HTML, CSS, and JavaScript
- No build step
- No server runtime
- No database

## Local preview

From this folder:

```bash
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Zero-cost GitHub + Vercel path

1. Create a GitHub repo for this folder, for example `2NspiraOpsTeam/needles-in-haystacks`.
2. Push `main`.
3. In Vercel, import the GitHub repo.
4. Leave framework preset as `Other`.
5. Set the root directory to the repo root.
6. Keep build command empty.
7. Keep output directory empty.
8. Deploy on the Hobby plan.

Because this app is static, there are no paid dependencies, no env vars, and no function execution costs in the normal flow.

## Notes

- Progress is stored only in local browser storage.
- `vercel.json` keeps URLs clean and avoids build/runtime assumptions.
