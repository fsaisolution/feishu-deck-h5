# Internal fork workflow

This repository should be treated as a light fork, not a rewrite.

## Remote layout

Use `upstream` for the original project and `origin` for the internal fork:

```bash
git remote rename origin upstream
git remote add origin <our-internal-fork-url>
git fetch upstream
```

Keep day-to-day work on feature branches:

```bash
git switch -c codex/<topic>
```

Periodically pull upstream into the internal fork:

```bash
git fetch upstream
git switch main
git merge --ff-only upstream/main
```

If the internal fork has local commits on `main`, use a normal merge commit
instead of rewriting history.

## What should go upstream

Prefer upstream pull requests for changes that benefit everyone:

- validator correctness
- DeckJSON schema/rendering fixes
- sample deck fixes
- install and packaging reliability
- CI coverage
- documentation that matches shipped behavior

## What should stay internal

Keep internal-only changes in the fork:

- private customer materials and thumbnails
- internal Feishu auth or deployment settings
- org-specific ingestion policies
- internal asset licensing notes
- customer delivery templates and review gates

## First hardening branch

The first internal branch should focus on production readiness only:

- make visual validation actually run in CI
- make the bundled sample pass strict visual validation
- document Python and optional validation dependencies
- support HTTPS clone by default
- keep public README links accurate from the repo root
