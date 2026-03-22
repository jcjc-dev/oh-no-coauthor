# oh-no-coauthor

Git hooks that quietly strip those `Co-authored-by` trailers that AI tools keep
sneaking into your commits.

You wrote the code. You fixed the bug. You don't need a line in your commit
saying some AI helped. If you wanted credit shared, you'd share it yourself.

## What it does

Two git hooks working together:

- **prepare-commit-msg** — runs before your editor opens. Strips AI co-author
  lines so you never even see them.
- **commit-msg** — runs after you save. Catches anything that slipped through
  the first pass.

Both hooks only touch lines that match known AI tools. Your human co-authors
are left completely alone.

## What it catches

Anything in a `Co-authored-by:` line that looks like it came from:

- GitHub Copilot
- Claude / Anthropic
- OpenAI / Codex
- Codeium
- Tabnine
- Cursor
- Generic "AI Assistant" patterns

The matching is case-insensitive and checks both the name and email parts. If a
new AI tool starts doing this, open an issue and I'll add it.

## Install

### Mac / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/install.sh | bash
```

That's it. This installs the hooks globally — every repo on your machine gets
them.

If you only want it in one repo, `cd` into that repo and run:

```bash
curl -fsSL https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/install.sh | bash -s -- --local
```

### Windows (Git Bash)

Same as above — open Git Bash and run:

```bash
curl -fsSL https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/install.ps1" -OutFile install.ps1
.\install.ps1
Remove-Item install.ps1
```

For a single repo only, use `-Local`:

```powershell
.\install.ps1 -Local
```

## Uninstall

Removing it is just as easy.

### Mac / Linux / Git Bash

```bash
curl -fsSL https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/uninstall.sh | bash
```

For a local install:

```bash
curl -fsSL https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/uninstall.sh | bash -s -- --local
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/uninstall.ps1" -OutFile uninstall.ps1
.\uninstall.ps1
Remove-Item uninstall.ps1
```

## How it works (the boring details)

**Global install** creates `~/.oh-no-coauthor/hooks/` and points git at it via
`core.hooksPath`. If you already had `core.hooksPath` set to something, the
installer saves your old value and copies your existing hooks over.

**Local install** drops the hooks into `.git/hooks/` directly. If you had
existing hooks there, they get renamed with a `.pre-oh-no-coauthor` suffix and
the new hooks chain into them — so nothing is lost.

The actual filtering is done with `awk` (not `sed`) because `awk` behaves the
same on macOS, Linux, and Git Bash on Windows. No platform-specific hacks.

## Existing hooks

If you already have a `prepare-commit-msg` or `commit-msg` hook, the installer
backs it up and the new hooks call into the old ones after doing their thing.
Uninstalling restores your originals.

## Updating

Just run the install command again. It'll overwrite the hooks with the latest
version.

## FAQ

**Will this break anything?**
No. It only removes specific lines from commit messages. It doesn't change your
code, your staged files, or anything else.

**Does it block human co-authors?**
No. It only matches known AI tool names and email patterns. A `Co-authored-by`
line with a real person's name and email goes through untouched.

**What if a new AI tool starts adding these?**
Open an issue or a PR. The pattern list lives in the install scripts and is easy
to extend.

**I use `core.hooksPath` for something else already.**
The global installer handles this — it saves your old path, copies your hooks
over, and the uninstaller restores everything.

## License

MIT — do whatever you want with it.
