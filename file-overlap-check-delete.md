# ============================================
# 1) RECURSIVE REFERENCE CHECK
#    Checks if ANY file in Folder B references
#    the relative paths OR filenames of files
#    that exist in Folder A.
# ============================================

$A="C:\path-to\original\folder"
$B="C:\path-to\new\folder-to-be-deleted-from"

Get-ChildItem -Path $A -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($A.Length).TrimStart('\')
    $name = $_.Name
    Select-String -Path (Get-ChildItem $B -Recurse -File).FullName `
        -Pattern $rel,$name -SimpleMatch -ErrorAction SilentlyContinue |
        Select-Object Path,Line,Pattern
}

# ============================================
# 2) DRY RUN
#    Shows what WOULD be deleted from Folder B
#    based on matching relative paths in A.
# ============================================

$A="C:\path-to\original\folder"
$B="C:\path-to\new\folder-to-be-deleted-from"

Get-ChildItem -Path $A -Recurse | ForEach-Object {
    $r = $_.FullName.Substring($A.Length)
    $t = Join-Path $B $r
    if (Test-Path $t) {
        Write-Output $t
    }
}

# ============================================
# 3) LIVE DELETE
#    Removes from Folder B anything that exists
#    in Folder A (matching relative paths).
# ============================================

$A="C:\path-to\original\folder"
$B="C:\path-to\new\folder-to-be-deleted-from"

Get-ChildItem -Path $A -Recurse | ForEach-Object {
    $r = $_.FullName.Substring($A.Length)
    $t = Join-Path $B $r
    if (Test-Path $t) {
        Remove-Item $t -Force -Recurse
    }
}