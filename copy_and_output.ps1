# Get the directory of the script file
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$OutputFile = "$ScriptDirectory\Merged_Output.txt"  # Output file in the same directory
$FileExtension = "*.gml"   # Change this to your target file extension

# Define the priority order of folders
$PriorityFoldersList = @("coordination_manager", "progression_manager", "subscription_manager", "draw_manager", "collision_manager", "player", "enemy", "boss", "weapon", "projectile", "explosion", "shield", "obstacle", "barrier", "powerup", "orbital", "parallax", "animation", "wave", "time_zone", "ui")  # Change as needed

Write-Output "Priority List: $($PriorityFoldersList)"
# Ensure the output file is empty before writing
Set-Content -Path $OutputFile -Value ""

# Get all subdirectories
$AllFolders = Get-ChildItem -Path $ScriptDirectory -Directory -Recurse

# Extract folder names for easier comparison
$AllFolderNames = $AllFolders | ForEach-Object { $_.Name }

# Sort folders by the priority list, placing unknown folders last
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
# Append remaining folders that weren't in the priority list
$RemainingFolders = $AllFolders | Where-Object { $_.Name -notin $PriorityFoldersList }
$OrderedFolders += $RemainingFolders

# Debugging: Print folder order before processing
Write-Output "Processing Order:"
$OrderedFolders | ForEach-Object { Write-Output $_.FullName }

# Process files within each folder
foreach ($Folder in $OrderedFolders) {
    Write-Output "Processing folder: $($Folder.FullName)"

    # Get all matching files within the folder
    $Files = Get-ChildItem -Path $Folder.FullName -Filter $FileExtension -File

    # Append each file’s content to the output file
    foreach ($File in $Files) {
        Write-Output "Appending: $($File.Name)"
        Get-Content -Path $File.FullName | Add-Content -Path $OutputFile
    }
}

Write-Output "Merging completed! Check: $OutputFile"
