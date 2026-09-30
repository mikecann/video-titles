# Agent guidance for video-titles

This is a standalone Bun and TypeScript CLI for chatting about YouTube video titles.
It runs in a visible terminal on Windows and macOS. Keep the command name `video-titles`.

## Development

- Use test-first development for non-trivial changes. Extract a clean test seam if needed.
- Rerun relevant tests when behaviour, configuration, persistence or startup changes.
- Before committing, run `bun install --frozen-lockfile`, `bun test` and `bunx tsc --noEmit`.
- Check shell syntax with `bash -n install.sh video-titles`.
- Parse every `.ps1` with `System.Management.Automation.Language.Parser.ParseFile` and run `pwsh -NoProfile -File tests/install-lib.Tests.ps1`.
- Smoke-test the actual CLI and check exit codes. Paid OpenRouter requests need a configured key; automated tests use mocked responses.
- Keep `.env` beside `index.ts` and out of Git. List required variables in `.env.example`. Launch Bun with `--no-env-file` so a video's folder does not supply configuration.

## Installation

- Source stays in this clone. `C:\dev\tools` gets only generated launchers, never source files.
- Keep `.bat` files ASCII. Windows clones must use an ASCII path so the generated launcher can represent it.
- Large `.exe` and `.dll` files belong outside this repo, never commit them.
- `deps.ps1` must be self-contained, safe to rerun and give clear output. Detect missing system tools with `Get-Command`, give setup instructions and report failures.
- `install.ps1` runs `deps.ps1`; `-SkipDeps` skips dependency installation.
- Editing the existing tool does not require reinstalling, because launchers point at the live clone. Rerun the installer after moving the clone.
- Preserve the shared `Mike's Tools` submenu and every other tool's verb. `uninstall.ps1` removes only `VideoTitles` and this tool's generated launchers and icon.
- The macOS installer links `video-titles` into `~/.local/bin` by default. It checks Bun and Python 3, then installs dependencies.

## Transcription

`lib/run-transcribe.ts` is local to this repo. It calls the optional [transcribe](https://github.com/mikecann/transcribe) command on PATH, preferring `C:\dev\tools\transcribe.bat` on Windows.
Keep the argument quoting tests, especially video filenames containing spaces. Do not add sibling-checkout imports.

## Writing

Keep documentation plain, friendly and first person when expressing Mike's opinion. No em dashes or en dashes. Do not introduce unrelated UI or stack conventions.
