# File overlap check + optional delete (cross-platform PowerShell CLI)

This tool compares files recursively by **relative path**:

- `FolderA` = reference/source folder.
- `FolderB` = folder checked for overlaps (and optionally deleted from).

If a file exists in both folders at the same relative path, it is a match.

## Script

`file-overlap-check-delete.ps1`

## Requirements

- Windows: PowerShell 5.1+ or PowerShell 7+
- macOS / Linux: PowerShell 7+ (`pwsh`)

> PowerShell 5.1 compatibility is included for relative-path handling (no dependency on `[System.IO.Path]::GetRelativePath` being available).

## Interactive CLI mode (default)

Run the script with no arguments and it will prompt for:

1. `FolderA`
2. `FolderB`
3. Whether to run reference check
4. Whether to delete matches
5. Final `YES` confirmation before deletion

```powershell
./file-overlap-check-delete.ps1
```

You can paste paths with or without quotes at prompts.

## Optional non-interactive usage

You can still run it with explicit arguments:

```powershell
./file-overlap-check-delete.ps1 -FolderA "./starter/static/uploads" -FolderB "./joseph-or/static/uploads"
./file-overlap-check-delete.ps1 -FolderA "./starter/static/uploads" -FolderB "./joseph-or/static/uploads" -ReferenceCheck
./file-overlap-check-delete.ps1 -FolderA "./starter/static/uploads" -FolderB "./joseph-or/static/uploads" -Delete
```

To skip prompt questions entirely (for automation), add `-NonInteractive` with explicit folder paths.
