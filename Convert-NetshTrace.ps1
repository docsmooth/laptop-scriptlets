Param(
        [Parameter(Mandatory=$true)][string]$etlfile,
        [Parameter(Mandatory=$true)][string]$capfile,
        [switch]$help
    ); #end param

$etlExists = [System.IO.File]::Exists($etlfile);
if ( $etlExists -eq $false)
{
  Write-Host "Could not find $etlfile!!"
  exit 9
}
$s = New-PefTraceSession -Path $capfile -SaveOnStop
$s | Add-PefMessageProvider -Provider $etlfile
$s | Start-PefTraceSession