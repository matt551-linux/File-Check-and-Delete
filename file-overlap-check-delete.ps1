[CmdletBinding()]
param(
    [string]$FolderA,
    [string]$FolderB,
    [switch]$ReferenceCheck,
    [switch]$Delete,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $resolved = Resolve-Path -LiteralPath $Path
    return [System.IO.Path]::GetFullPath($resolved.Path)
}

function Prompt-ForDirectory {
    param([Parameter(Mandatory = $true)][string]$Label)

    while ($true) {
        $inputPath = Read-Host "$Label"

        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            Write-Host 'Please provide a directory path.'
            continue
        }

        try {
            $normalizedPath = Resolve-NormalizedPath -Path $inputPath
        }
        catch {
            Write-Host "Path could not be resolved: $inputPath"
            continue
        }

        if (-not (Test-Path -LiteralPath $normalizedPath -PathType Container)) {
            Write-Host "Path is not a directory: $normalizedPath"
            continue
        }

        return $normalizedPath
    }
}

function Prompt-ForYesNo {
    param(
        [Parameter(Mandatory = $true)][string]$Question,
        [bool]$DefaultNo = $true
    )

    while ($true) {
        $suffix = if ($DefaultNo) { '[y/N]' } else { '[Y/n]' }
        $response = (Read-Host "$Question $suffix").Trim()

        if ([string]::IsNullOrWhiteSpace($response)) {
            return (-not $DefaultNo)
        }

        switch -Regex ($response.ToLowerInvariant()) {
            '^(y|yes)$' { return $true }
            '^(n|no)$' { return $false }
            default { Write-Host 'Please answer y/yes or n/no.' }
        }
    }
}

function Get-RelativeMatches {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot
    )

    $matches = @()

    Get-ChildItem -LiteralPath $SourceRoot -Recurse -File | ForEach-Object {
        $sourcePath = $_.FullName
        $relativePath = [System.IO.Path]::GetRelativePath($SourceRoot, $sourcePath)
        $targetPath = Join-Path -Path $TargetRoot -ChildPath $relativePath

        if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
            $matches += [PSCustomObject]@{
                RelativePath = $relativePath
                SourcePath   = $sourcePath
                TargetPath   = $targetPath
            }
        }
    }

    return $matches
}

if (-not $NonInteractive) {
    Write-Host '=== File Overlap Check + Optional Delete ==='

    if ([string]::IsNullOrWhiteSpace($FolderA)) {
        $FolderA = Prompt-ForDirectory -Label 'Enter FolderA (reference/source)'
    }

    if ([string]::IsNullOrWhiteSpace($FolderB)) {
        $FolderB = Prompt-ForDirectory -Label 'Enter FolderB (checked/deletion target)'
    }

    if (-not $PSBoundParameters.ContainsKey('ReferenceCheck')) {
        $ReferenceCheck = Prompt-ForYesNo -Question 'Run recursive reference check in FolderB?'
    }

    if (-not $PSBoundParameters.ContainsKey('Delete')) {
        $Delete = Prompt-ForYesNo -Question 'Delete matched files from FolderB?' -DefaultNo $true
    }
}

$folderAPath = Resolve-NormalizedPath -Path $FolderA
$folderBPath = Resolve-NormalizedPath -Path $FolderB

if (-not (Test-Path -LiteralPath $folderAPath -PathType Container)) {
    throw "FolderA does not exist or is not a directory: $folderAPath"
}

if (-not (Test-Path -LiteralPath $folderBPath -PathType Container)) {
    throw "FolderB does not exist or is not a directory: $folderBPath"
}

$relativeMatches = Get-RelativeMatches -SourceRoot $folderAPath -TargetRoot $folderBPath

Write-Host "\nFound $($relativeMatches.Count) matching file(s) in FolderB based on FolderA relative paths."

if ($relativeMatches.Count -eq 0) {
    return
}

$relativeMatches | Select-Object RelativePath, TargetPath | Format-Table -AutoSize

if ($ReferenceCheck) {
    $filesInB = Get-ChildItem -LiteralPath $folderBPath -Recurse -File

    Write-Host "\nReference check results (files in FolderB containing matched relative paths or file names):"

    foreach ($match in $relativeMatches) {
        $patterns = @($match.RelativePath, [System.IO.Path]::GetFileName($match.RelativePath))

        Select-String -Path $filesInB.FullName -Pattern $patterns -SimpleMatch -ErrorAction SilentlyContinue |
            Select-Object Path, Line, Pattern
    }
}

if (-not $Delete) {
    Write-Host "\nDry run complete. No files were deleted."
    return
}

$confirmation = Read-Host "\nDelete ALL listed matches from FolderB? Type YES to continue"
if ($confirmation -cne 'YES') {
    Write-Host 'Deletion cancelled.'
    return
}

foreach ($match in $relativeMatches) {
    Remove-Item -LiteralPath $match.TargetPath -Force
}

Write-Host "Deleted $($relativeMatches.Count) file(s) from FolderB."
