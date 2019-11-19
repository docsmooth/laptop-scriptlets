Param(
        [Parameter(Mandatory=$true)][string]$etlfile,
        [Parameter(Mandatory=$true)][string]$capfile,
        [switch]$help
    ); #end param

# Generate the netsh trace ETL file with:
# netsh trace start persistent=(yes|no) capture=yes tracefile=c:\trace.etl
# netsh trace stop
#
# This tool requires Microsoft Message Analyzer:
# https://docs.microsoft.com/en-us/openspecs/blog/ms-winintbloglp/dd98b93c-0a75-4eb0-b92e-e760c502394f

$etlExists = [System.IO.File]::Exists($etlfile);
if ( $etlExists -eq $false)
{
  Write-Host "Could not find $etlfile!!"
  exit 9
}
$s = New-PefTraceSession -Path $capfile -SaveOnStop
$s | Add-PefMessageProvider -Provider $etlfile
$s | Start-PefTraceSession
