# Create Outlook COM object
$Outlook = New-Object -ComObject Outlook.Application
$Namespace = $Outlook.GetNamespace("MAPI")

# Default Contacts folder (10 = olFolderContacts)
$ContactsFolder = $Namespace.GetDefaultFolder(10)

$updated = 0

foreach ($Contact in $ContactsFolder.Items) {
    if ($Contact -is [__ComObject]) {

        $first = $Contact.FirstName
        $last  = $Contact.LastName

        $newFirst = $first
        $newLast  = $last

        # Remove leading apostrophe from FirstName
        if ($first -and $first.StartsWith("'")) {
            $newFirst = $first.TrimStart("'")
        }

        # Remove trailing apostrophe from LastName
        if ($last -and $last.EndsWith("'")) {
            $newLast = $last.TrimEnd("'")
        }

        # Only update if something changed
        if ($newFirst -ne $first -or $newLast -ne $last) {
            $Contact.FirstName = $newFirst
            $Contact.LastName  = $newLast

            # Rebuild FullName properly
            $Contact.FullName = ($newFirst + " " + $newLast).Trim()

            $Contact.Save()
            $updated++
        }
    }
}

Write-Host "Updated $updated contacts."
