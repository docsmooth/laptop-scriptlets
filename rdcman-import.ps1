Param(
     [Parameter(mandatory=$true)][string]$Path,
     [switch]$displayName,
     [string]$groupName,
     [string]$output,
     [switch]$help
)
if ( $groupName -eq "" -or $groupName -is $null ) {
    $rdcmanName = "PowerBroker Servers"
}
if ($output -eq "" -or $output -is $null ) {
    $output = "PasswordSafe-Servers.rdg"
}

if ($help) {
    Write-Host "
Import RDP files from PBPS DirectConnect into 
RDCMan XML format.

Modified from Stuart Leeks: https://gist.github.com/stuartleeks/8436568

Run as:
.\rdcman-import.ps1 -Path <path-to-RDP files>

Options:
    -Path <directory>
        Directory where the RDP files exist
    -groupName Text
        name of RDCMan Group to create
    -output <FileName>
        output file name to create (in PWD)
    -displayName
        If true (or passed), include the username
        In the RDCMan displayed server name:
        domain\user@server
        If not true (or not set), then:
        server
"
}

$outputFileName = Get-Location | Join-Path -ChildPath $output

$ServerText = "full address:s:"
$UsernameText = "username:s:"
$PathArray = @()
$File = ""
$String = ""
$FinalString = ""

$xml = [xml]'<?xml version="1.0" encoding="utf-8"?>
<RDCMan schemaVersion="1">
    <version>2.2</version>
    <file>
        <properties>
            <name>blog</name>
            <expanded>True</expanded>
            <comment />
            <logonCredentials inherit="FromParent" />
            <connectionSettings inherit="FromParent" />
            <gatewaySettings inherit="FromParent" />
            <remoteDesktop inherit="FromParent" />
            <localResources inherit="FromParent" />
            <securitySettings inherit="FromParent" />
            <displaySettings inherit="FromParent" />
        </properties>
        <group>
            <properties>
                <name>a group</name>
                <expanded>False</expanded>
                <comment />
                <logonCredentials inherit="FromParent" />
                <connectionSettings inherit="FromParent" />
                <gatewaySettings inherit="FromParent" />
                <remoteDesktop inherit="FromParent" />
                <localResources inherit="FromParent" />
                <securitySettings inherit="FromParent" />
                <displaySettings inherit="FromParent" />
            </properties>
            <server>
                <name>myservername</name>
                <displayName>my display name</displayName>
                <comment />
                <logonCredentials inherit="None" >
                    <profileName scope="Local">Custom</profileName>
                    <userName>dummy</userName>
                    <password />
                    <domain>dummy</domain>
                </logonCredentials>
                <connectionSettings inherit="None">
                    <connectToConsole>False</connectToConsole>
                    <startProgram />
                    <workingDir />
                    <port>12345</port>
                </connectionSettings>
                <gatewaySettings inherit="FromParent" />
                <remoteDesktop inherit="FromParent" />
                <localResources inherit="FromParent" />
                <securitySettings inherit="FromParent" />
                <displaySettings inherit="FromParent" />
            </server>
        </group>
    </file>
</RDCMan>'

$fileElement =$xml.RDCMan.file
$groupTemplateElement =$xml.RDCMan.file.group
$fileElement.properties.name = $rdcmanName
$gotVmWithRdpEndpoint = $false
$groupElement = $groupTemplateElement.Clone()
$groupElement.properties.name = $rdcmanName
    
$serverTemplateElement = $groupElement.server

Get-ChildItem $Path -Filter “*.rdp” |
    Where-Object { $_.Attributes -ne “Directory”} |
    ForEach-Object {
        If (Get-Content $_.FullName | Select-String -Pattern $ServerText) {
            $File = $PathArray += $_.FullName
            $ServerString = Get-Content $File | Where-Object { $_.Contains($ServerText) }
            $UserString = Get-Content $File | Where-Object { $_.Contains($UsernameText) }
            $ServerList = $ServerString.split(":")
            $UserLine = $UserString.split(":")[-1]
            $UserList = $UserLine.split("+")
            $serverElement = $serverTemplateElement.Clone()
            $serverElement.name = $ServerList[-2]
            $serverElement.displayName = $UserList[-1]
            $serverElement.connectionSettings.port = $ServerList[-1]
            $serverElement.logonCredentials.userName = "\" + $UserLine
            $serverElement.logonCredentials.domain = ""
            if ($displayName -eq $true) {
                $serverElement.displayName = $UserList[-2] + "@" + $UserList[-1]
            } else {
                $serverElement.displayName = $UserList[-1]
            }
            $groupElement.AppendChild($serverElement) | out-null
            $gotVmWithRdpEndpoint = $true

    }
}

    if($gotVmWithRdpEndpoint){
        $groupElement.RemoveChild($serverTemplateElement) | out-null
        ($fileElement.AppendChild($groupElement)) | out-null
    }

$fileElement.RemoveChild($groupTemplateElement) | out-null


$xml.Save($outputFileName)
