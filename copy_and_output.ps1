$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$OutputFile = "$ScriptDirectory\Merged_Output.txt"  # Output file in the same directory
$FileExtension = "*.gml"   # Change this to your target file extension

$PriorityFoldersList = @("scripts")

Set-Content -Path $OutputFile -Value ""

$AllFolders = Get-ChildItem -Path $ScriptDirectory -Directory -Recurse

$AllFolderNames = $AllFolders | ForEach-Object { $_.Name }

$OrderedFolders = @()
foreach ($FolderName in $PriorityFoldersList) {
    $Match = $AllFolders | Where-Object { $_.Name -match [regex]::Escape($FolderName) }
    if ($Match) { 
        Write-Output "Matched Folder: $($Match.FullName)"
        $OrderedFolders += $Match 
    } else {
        Write-Output "No Match for: $FolderName"
    }
}
Write-Output "Ordered Folders: $($OrderedFolders)"
$RemainingFolders = $AllFolders | Where-Object { $_.Name -notin $PriorityFoldersList }
$OrderedFolders += $RemainingFolders

Write-Output "Processing Order:"
$OrderedFolders | ForEach-Object { Write-Output $_.FullName }

foreach ($Folder in $OrderedFolders) {
    Write-Output "Processing folder: $($Folder.FullName)"

    $Files = Get-ChildItem -Path $Folder.FullName -Filter $FileExtension -File

    foreach ($File in $Files) {
        Write-Output "Appending: $($File.Name)"
        Get-Content -Path $File.FullName | Add-Content -Path $OutputFile
    }
}

Write-Output "Merging completed! Check: $OutputFile"
