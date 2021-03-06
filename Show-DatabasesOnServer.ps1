<#PSScriptInfo

.VERSION 1.0

.GUID 48bf0316-66c3-4253-9154-6fc5b28e482a

.AUTHOR Rob Sewell

.DESCRIPTION Returns Database Name and Size in MB for databases on a SQL server
      
.COMPANYNAME 

.COPYRIGHT 

.TAGS SQL, Database, Databases, Size

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>
<#
    .Synopsis
    Returns the databases on a SQL Server and their size
    .DESCRIPTION
    Returns Database Name and Size in MB for databases on a SQL server
    .EXAMPLE
    Show-DatabasesOnServer

    This will return the user database names and sizes on the local machine default instance
    .EXAMPLE
    Show-DatabasesOnServer -Servers SERVER1

    This will return the database names and sizes on SERVER1
    .EXAMPLE
    Show-DatabasesOnServer -Servers SERVER1 -IncludeSystemDatabases

    This will return all of the database names and sizes on SERVER1 including system databases
    .EXAMPLE
    Show-DatabasesOnServer -Servers 'SERVER1','SERVER2\INSTANCE'

    This will return the user database names and sizes on SERVER1 and SERVER2\INSTANCE
    .EXAMPLE
    $Servers = 'SERVER1','SERVER2','SERVER3'
    Show-DatabasesOnServer -Servers $servers|out-file c:\temp\dbsize.txt

    This will get the user database names and sizes on SERVER1, SERVER2 and SERVER3 and export to a text file c:\temp\dbsize.txt
    .NOTES
    AUTHOR : Rob Sewell http://sqldbawithabeard.com
    Initial Release 22/07/2013
    Updated with switch for system databases added assembly loading and error handling 20/12/2015
    Some tidying up and ping check 01/06/2016
    
#>

Function Show-DatabasesOnServer 

{
[CmdletBinding()]
param (
    # Server Name or array of Server Names - Defaults to $ENV:COMPUTERNAME
    [Parameter(Mandatory = $false, 
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true, 
    Position = 0)]
    $Servers = $Env:COMPUTERNAME,
    # Switch to include System Databases
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSystemDatabases
    )
    [void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
    foreach($Server in $Servers)
    {
    if($Server.Contains('\'))
    {
    $ServerName = $Server.Split('\')[0]
    $Instance = $Server.Split('\')[1]
    }
    else
    {
    $Servername = $Server
    } 

    ## Check for connectivity
      if((Test-Connection $ServerName -count 1 -Quiet) -eq $false){
       Write-Error "Could not connect to $ServerName - Server did not respond to ping"
       $_.Exception
       continue
        }
    
    $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $Server

    if($IncludeSystemDatabases)
    {
        try
           {
            $Return = $srv.databases| Select Name, Size
           }
        catch
            {
            Write-Error "Failed to get database information from $Server"
            $_.Exception
            continue
            }
    }
    else
    {
           try
           {
            $Return = $srv.databases.Where{$_.IsSystemObject -eq $false}| Select Name, Size
           }
        catch
            {
            Write-Error "Failed to get database information from $Server"
            $_.Exception
            continue
            }
    }
    Write-Output "`n The Databases on $Server and their Size in MB `n"
    $Return
    }
}