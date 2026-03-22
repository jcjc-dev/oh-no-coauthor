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

## Verification

If you don't want to pipe curl to bash from a moving branch (fair enough),
pin to a specific release tag instead:

```bash
curl -fsSL https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/v1.0.0/install.sh | bash
```

Or download it first and check the hash before running:

```bash
curl -fsSL https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/v1.0.0/install.sh -o install.sh
shasum -a 256 install.sh
# compare against the SHA256SUMS file in the release
bash install.sh
```

Checksums for each release are in the
[GitHub Releases](https://github.com/jcjc-dev/oh-no-coauthor/releases) page.

## Notes

Global install uses `core.hooksPath` pointing to `~/.oh-no-coauthor/hooks/`.
If you already had that set to something else, the installer saves your old
value and the uninstaller puts it back. Existing hooks get backed up with a
`.pre-oh-no-coauthor` suffix and are chained — nothing is lost.

Only AI tool names and emails are matched. Human co-authors are never touched.

To update, just run the install command again.

New AI tool adding trailers? Open an issue or PR.

## License

[MIT](LICENSE)

