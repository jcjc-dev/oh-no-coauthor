# oh-no-coauthor installer (PowerShell)
# Installs git hooks that strip AI-generated Co-authored-by trailers.

param(
    [switch]$Global,
    [switch]$Local,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$HookDirName = ".oh-no-coauthor"
$GlobalHookDir = Join-Path $HOME "$HookDirName/hooks"
$BackupSuffix = ".pre-oh-no-coauthor"
$ConfigFile = Join-Path $HOME "$HookDirName/config"

# --- Hook contents ---
# The hooks themselves are bash scripts (git runs them through its bundled sh)

$AwkPattern = @'
/^[[:space:]]*Co-authored-by[[:space:]]*:/ {
    line = tolower($0)
    if (line ~ /copilot/ ||
        line ~ /claude/ ||
        line ~ /codex/ ||
        line ~ /openai/ ||
        line ~ /anthropic/ ||
        line ~ /codeium/ ||
        line ~ /tabnine/ ||
        line ~ /cursor[[:space:]]*</ ||
        line ~ /ai[- ]?assistant/ ||
        line ~ /github[[:space:]]*</ ||
        line ~ /\+copilot@users\.noreply\.github\.com/ ||
        line ~ /copilot@github\.com/ ||
        line ~ /@anthropic\.com/ ||
        line ~ /@openai\.com/) {
        blocked++
        next
    }
}
{ print }
'@

$PrepareCommitMsgHook = @"
#!/usr/bin/env bash
# oh-no-coauthor: prepare-commit-msg hook
# Strips AI Co-authored-by trailers before the editor opens.

COMMIT_MSG_FILE="`$1"

# --- begin ai pattern filter ---
tmpfile=`$(mktemp)
awk '
$AwkPattern
END { if (blocked > 0) print "[oh-no-coauthor] stripped " blocked " AI co-author trailer(s)" > "/dev/stderr" }
' "`$COMMIT_MSG_FILE" > "`$tmpfile" && mv "`$tmpfile" "`$COMMIT_MSG_FILE"
# --- end ai pattern filter ---

# Chain to previous hook if it exists
if [ -f "`$0.pre-oh-no-coauthor" ]; then
    exec "`$0.pre-oh-no-coauthor" "`$@"
fi
"@

$CommitMsgHook = @"
#!/usr/bin/env bash
# oh-no-coauthor: commit-msg hook
# Final safety net -- catches any AI Co-authored-by trailers that survived.

COMMIT_MSG_FILE="`$1"

# --- begin ai pattern filter ---
tmpfile=`$(mktemp)
awk '
$AwkPattern
END { if (blocked > 0) print "[oh-no-coauthor] commit-msg hook caught " blocked " AI co-author trailer(s)" > "/dev/stderr" }
' "`$COMMIT_MSG_FILE" > "`$tmpfile" && mv "`$tmpfile" "`$COMMIT_MSG_FILE"
# --- end ai pattern filter ---

# Chain to previous hook if it exists
if [ -f "`$0.pre-oh-no-coauthor" ]; then
    exec "`$0.pre-oh-no-coauthor" "`$@"
fi
"@

function Show-Usage {
    Write-Host "Usage: install.ps1 [-Global] [-Local]"
    Write-Host ""
    Write-Host "  -Global   Install hooks globally for all repos (default)"
    Write-Host "  -Local    Install hooks in the current repo only"
    Write-Host ""
    Write-Host "Global install sets core.hooksPath to $GlobalHookDir"
    Write-Host "Local install copies hooks into .git/hooks/ of the current repo"
}

function Install-Hook {
    param(
        [string]$TargetDir,
        [string]$HookName,
        [string]$HookContent
    )

    # Resolve to absolute path so .NET methods work with Push-Location
    $absDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetDir)
    $hookPath = Join-Path $absDir $HookName

    # Back up existing hook if it's not ours
    if (Test-Path $hookPath) {
        $content = Get-Content $hookPath -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -notmatch "oh-no-coauthor") {
            $backupPath = "$hookPath$BackupSuffix"
            Write-Host "  Backing up existing $HookName -> $HookName$BackupSuffix"
            Move-Item $hookPath $backupPath -Force
        }
    }

    # Write hook with Unix line endings (LF)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $normalizedContent = $HookContent -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($hookPath, $normalizedContent, $utf8NoBom)

    Write-Host "  Installed $HookName"
}

function Install-Global {
    Write-Host "Installing oh-no-coauthor hooks globally..."
    Write-Host ""

    New-Item -ItemType Directory -Force -Path $GlobalHookDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path $ConfigFile) | Out-Null

    # Save previous hooksPath if set
    $prevHooksPath = git config --global core.hooksPath 2>$null
    if ($prevHooksPath -and $prevHooksPath -ne $GlobalHookDir) {
        Write-Host "  Saving previous core.hooksPath: $prevHooksPath"
        "previous_hooks_path=$prevHooksPath" | Out-File -FilePath $ConfigFile -Encoding ascii

        # Copy existing hooks from the old path
        if (Test-Path $prevHooksPath) {
            Get-ChildItem $prevHooksPath -File | ForEach-Object {
                Copy-Item $_.FullName $GlobalHookDir
            }
        }
    }

    Install-Hook -TargetDir $GlobalHookDir -HookName "prepare-commit-msg" -HookContent $PrepareCommitMsgHook
    Install-Hook -TargetDir $GlobalHookDir -HookName "commit-msg" -HookContent $CommitMsgHook

    git config --global core.hooksPath $GlobalHookDir
    Write-Host ""
    Write-Host "Done. core.hooksPath set to $GlobalHookDir"
    Write-Host "AI co-author trailers will be stripped from all repos."
    Write-Host ""
    Write-Host "To undo: run uninstall.ps1 or:"
    Write-Host "  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/uninstall.ps1' -OutFile uninstall.ps1; .\uninstall.ps1"
}

function Install-Local {
    Write-Host "Installing oh-no-coauthor hooks in this repo..."
    Write-Host ""

    if (-not (Test-Path ".git")) {
        Write-Error "Not in a git repository. Run this from the root of a git repo."
        exit 1
    }

    $hookDir = ".git/hooks"
    New-Item -ItemType Directory -Force -Path $hookDir | Out-Null

    Install-Hook -TargetDir $hookDir -HookName "prepare-commit-msg" -HookContent $PrepareCommitMsgHook
    Install-Hook -TargetDir $hookDir -HookName "commit-msg" -HookContent $CommitMsgHook

    Write-Host ""
    Write-Host "Done. Hooks installed in .git/hooks/"
    Write-Host "AI co-author trailers will be stripped in this repo."
}

# --- Main ---

if ($Help) {
    Show-Usage
    exit 0
}

if ($Local) {
    Install-Local
} else {
    Install-Global
}
