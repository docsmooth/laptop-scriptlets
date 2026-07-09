# =========================
# Bulk-fix apostrophes in Outlook/Exchange contacts
# Version 2:
# - Scans all contact folders in your own mailbox
# - Removes leading apostrophe from FirstName
# - Removes trailing apostrophe from LastName
# - Normalizes FileAs to "Last, First"
# - Logs Changed / Unchanged / Skipped / Error
# =========================

# ---- Settings ----
$WhatIfMode = $false   # Set to $true for preview only (no changes saved)
$LogPath = "$env:USERPROFILE\Desktop\contact-cleanup-log.csv"

# Outlook constants
$olFolderContacts = 10
$olContactItem    = 2
$olContactClass   = 40   # Outlook.OlObjectClass.olContact
$olDistListClass  = 69   # Distribution list / contact group

# ---- Start Outlook COM ----
$outlook = New-Object -ComObject Outlook.Application
$namespace = $outlook.GetNamespace("MAPI")

# Use the store that contains your default Contacts folder = your own mailbox
$defaultContactsFolder = $namespace.GetDefaultFolder($olFolderContacts)
$store = $defaultContactsFolder.Store
$rootFolder = $store.GetRootFolder()

Write-Host "Scanning mailbox store:" $store.DisplayName
Write-Host "Root folder:" $rootFolder.Name
Write-Host "WhatIfMode:" $WhatIfMode
Write-Host ""

# ---- Helpers ----
function Get-FolderPath {
    param($Folder)

    $parts = New-Object System.Collections.Generic.List[string]
    $current = $Folder
    while ($null -ne $current) {
        [void]$parts.Add($current.Name)
        try { $current = $current.Parent } catch { break }
    }
    $parts.Reverse()
    return ($parts -join "\")
}

function Get-ContactFoldersRecursive {
    param($Folder)

    $results = New-Object System.Collections.Generic.List[object]

    try {
        if ($Folder.DefaultItemType -eq $olContactItem) {
            [void]$results.Add($Folder)
        }
    } catch {}

    foreach ($subFolder in $Folder.Folders) {
        $subResults = Get-ContactFoldersRecursive -Folder $subFolder
        foreach ($r in $subResults) {
            [void]$results.Add($r)
        }
    }

    return $results
}

function Build-FileAs {
    param(
        [string]$FirstName,
        [string]$LastName
    )

    $FirstName = ($FirstName ?? "").Trim()
    $LastName  = ($LastName  ?? "").Trim()

    if ($LastName -and $FirstName) {
        return "$LastName, $FirstName"
    }
    elseif ($LastName) {
        return $LastName
    }
    elseif ($FirstName) {
        return $FirstName
    }
    else {
        return ""
    }
}

# ---- Discover all contact folders in your mailbox ----
$contactFolders = Get-ContactFoldersRecursive -Folder $rootFolder

Write-Host "Found $($contactFolders.Count) contact folder(s):"
foreach ($f in $contactFolders) {
    Write-Host " - $(Get-FolderPath $f)"
}
Write-Host ""

# ---- Process contacts ----
$log = New-Object System.Collections.Generic.List[object]

foreach ($folder in $contactFolders) {
    $folderPath = Get-FolderPath $folder
    Write-Host "Processing folder: $folderPath"

    # Snapshot items first to avoid collection weirdness while saving
    $items = @()
    foreach ($item in $folder.Items) {
        $items += $item
    }

    foreach ($item in $items) {
        try {
            # Skip non-contact items
            if ($item.Class -eq $olDistListClass) {
                [void]$log.Add([pscustomobject]@{
                    FolderPath        = $folderPath
                    EntryID           = $item.EntryID
                    ItemType          = "DistributionList"
                    FullNameBefore    = $item.DLName
                    FirstNameBefore   = $null
                    LastNameBefore    = $null
                    FileAsBefore      = $null
                    FullNameAfter     = $item.DLName
                    FirstNameAfter    = $null
                    LastNameAfter     = $null
                    FileAsAfter       = $null
                    Action            = "Skipped"
                    Reason            = "Distribution list / contact group"
                })
                continue
            }

            if ($item.Class -ne $olContactClass) {
                [void]$log.Add([pscustomobject]@{
                    FolderPath        = $folderPath
                    EntryID           = $item.EntryID
                    ItemType          = "Other"
                    FullNameBefore    = $null
                    FirstNameBefore   = $null
                    LastNameBefore    = $null
                    FileAsBefore      = $null
                    FullNameAfter     = $null
                    FirstNameAfter    = $null
                    LastNameAfter     = $null
                    FileAsAfter       = $null
                    Action            = "Skipped"
                    Reason            = "Not a contact item"
                })
                continue
            }

            $firstBefore  = [string]$item.FirstName
            $lastBefore   = [string]$item.LastName
            $fullBefore   = [string]$item.FullName
            $fileAsBefore = [string]$item.FileAs

            # Only remove:
            # - leading apostrophe from FirstName
            # - trailing apostrophe from LastName
            $firstAfter = $firstBefore -replace "^'", ""
            $lastAfter  = $lastBefore  -replace "'$", ""

            # Keep FullName as natural display order
            $fullAfter = (($firstAfter + " " + $lastAfter).Trim())

            # Normalize FileAs to "Last, First"
            $fileAsAfter = Build-FileAs -FirstName $firstAfter -LastName $lastAfter

            $changed =
                ($firstAfter -ne $firstBefore) -or
                ($lastAfter  -ne $lastBefore)  -or
                ($fileAsAfter -ne $fileAsBefore)

            if ($changed) {
                if (-not $WhatIfMode) {
                    $item.FirstName = $firstAfter
                    $item.LastName  = $lastAfter
                    $item.FullName  = $fullAfter
                    $item.FileAs    = $fileAsAfter
                    $item.Save()
                }

                [void]$log.Add([pscustomobject]@{
                    FolderPath        = $folderPath
                    EntryID           = $item.EntryID
                    ItemType          = "Contact"
                    FullNameBefore    = $fullBefore
                    FirstNameBefore   = $firstBefore
                    LastNameBefore    = $lastBefore
                    FileAsBefore      = $fileAsBefore
                    FullNameAfter     = $fullAfter
                    FirstNameAfter    = $firstAfter
                    LastNameAfter     = $lastAfter
                    FileAsAfter       = $fileAsAfter
                    Action            = $(if ($WhatIfMode) { "WouldChange" } else { "Changed" })
                    Reason            = "Normalized names and/or FileAs"
                })
            }
            else {
                [void]$log.Add([pscustomobject]@{
                    FolderPath        = $folderPath
                    EntryID           = $item.EntryID
                    ItemType          = "Contact"
                    FullNameBefore    = $fullBefore
                    FirstNameBefore   = $firstBefore
                    LastNameBefore    = $lastBefore
                    FileAsBefore      = $fileAsBefore
                    FullNameAfter     = $fullBefore
                    FirstNameAfter    = $firstBefore
                    LastNameAfter     = $lastBefore
                    FileAsAfter       = $fileAsBefore
                    Action            = "Unchanged"
                    Reason            = "No matching apostrophe pattern and FileAs already normalized"
                })
            }
        }
        catch {
            [void]$log.Add([pscustomobject]@{
                FolderPath        = $folderPath
                EntryID           = $null
                ItemType          = "Unknown"
                FullNameBefore    = $null
                FirstNameBefore   = $null
                LastNameBefore    = $null
                FileAsBefore      = $null
                FullNameAfter     = $null
                FirstNameAfter    = $null
                LastNameAfter     = $null
                FileAsAfter       = $null
                Action            = "Error"
                Reason            = $_.Exception.Message
            })
        }
    }

    Write-Host "Finished folder: $folderPath"
    Write-Host ""
}

# ---- Export log ----
$log | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8

# ---- Summary ----
$summary = $log | Group-Object Action | Sort-Object Name
Write-Host "Summary:"
foreach ($row in $summary) {
    Write-Host (" - {0}: {1}" -f $row.Name, $row.Count)
}

Write-Host ""
Write-Host "Log written to: $LogPath"
