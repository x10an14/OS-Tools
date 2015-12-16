## Below is outdated (from 2012)*
#$JavaScriptFile = "https://raw.github.com/golovko/Fixed-Header-Table/master/jquery.fixedheadertable.js"

## *Hence, doesn't work with these cmdlets at the moment.
# For future reference, here's the current version of that file: https://github.com/markmalek/Fixed-Header-Table


function Get-ApplicationRegNameAndVersion{
<#
.SYNOPSIS
Queries the registries of the inputted machines at a specific registry location.
Returns a Hashtable which key(s) is/are the ComputerName(s) inputted, and their corresponding Values are new hashtables, whose Keys are
the DisplayNames of the application the registry key represents.

.DESCRIPTION
Looks for and finds application names and version numbers in the registry on the given ComputerName(s) at the following registry location,
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall".

This function has a string-array consisting of the strings "DisplayVersion" and "UninstallString". This array will be expanded with whatever
input is given to the parameter SearchString, of which a wildcard search will be performed on all the elements of said string-array.
If a matching field is found on a said registryKey, then the Hashtable of that ComputerName's Application will have a property added named
whatever the Registry Key fields name which matched the wilcard search, with the corresponding field value added as this hashtables Value.

The whole function will in the end return a Hashtable which key(s) is/are the ComputerName(s) inputted, and their corresponding Values are new hashtables, whose Keys are
the DisplayNames of the application the registry key represents.

Every remote computer is contacted sequentially, not in parallel.
You can choose to add -Verbose after if you're interested in seeing what the script is doing/stuck on,
gets error from.

.PARAMETER ComputerName
A mandatory parameter which can be piped or retrieved directly, this parameter should be a single ComputerName or an array of ComputerName(s).
You may also provide IP addresses.

You can for instance instantiate a variable like so and use it:
$servers = Get-Content C:\User\%user%\Desktop\TxtFileWithAServerNameOnEachLine.txt

.PARAMETER searchString
An optional parameter which can be piped or retrieved directly, this parameter is in effect an array of strings
that a wildcard search will be performed with in the set registry path the method iterates over.

Examples of wildcard additions could be:

?ce?n, *ocean*, oc*n.
The above three will always return any matches with for example "ocean".
(The wildcard search is case-insensitive).

.PARAMETER AsHTML
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
Have a list of computernames/IP's somewhere, say in a variable $servers, and then run:
$output = Get-EnvironmentVariables -ComputerName $servers

Then $output will contain the output Hashtable the function returns with all the successfully found registry values.

.EXAMPLE
If you find out that you want to search for additional RegistryKey fields (since there is a list hardcoded into this script),
you can add -searchString which should be an array of strings that a wildcard search will be performed on at the
registry locations iterated over.

Get-ApplicationRegNameAndVersion -ComputerName $servers -searchString $searchInput

Then for any element of $searchInput, say "*oce?n*", will match any RegistryKey field with "oce" + random character + "n" wherever
in its name.

.EXAMPLE
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-EnvironmentVariables -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.NOTES
To run this function you need admin access on each remote computer you run the function towards.
Has been confirmed to work in Non-Admin-Elevated mode.
Needs the service Remote Registry running on each machine queried.
#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param(
	[Parameter(
	Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[String[]]$ComputerName,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='A string or array of strings which you want wildcard-search performed on while querying the registry')]
	[ValidateNotNullOrEmpty()]
	[String[]]$searchString,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$AsHTML,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$LastWeeksInstallDates
	)
	begin{
		Write-Verbose "In Begin-block"
		[String[]]$strings = [String]"DisplayVersion",[String]"UninstallString", [String]"InstallDate"
		$RegistryEntries = @{}
		if($searchString){
			foreach($str in $searchString){
				$strings += $str
			}
		}
		$appnames = @()
		$Computers = @()
	}
	process{
		foreach($server in $ComputerName){
			Write-Verbose "Connecting to server: $server"
			$serverKeys = @()
			$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $server)
			$regKey = $regKey.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
			if($regKey){
				Write-Verbose "Connection successfully achieved!"
				foreach($subKey in $regKey.GetSubKeyNames()){
					$serverKeys += $regkey.OpenSubKey($subKey)
				}
				trap {
					throw{
						Write-Error "`"Your user credentials do not have permissions to run this script against $server!!!`"`n
					`t`t`t`t`t`t`t`t`"Any errors on line 139, 143 relates to this fact.`""
					}
				}
				foreach($key in $serverKeys){
					if($key.GetValueNames() -contains "DisplayName"){#This means that the key represent an application (which we're then interested in)
						$cust = @{}
						$keyaddr = [String]$key
						$cust.add("RegistryAddress",$keyaddr)
						foreach($str in $strings){
							foreach($val in $key.GetValueNames()){
								$newstr = [String]$key.GetValue($val)
								if (($val -like $str) -and ($newstr.Length -gt 0)){#So, first we see if it matches the searchterms were looking for, then we make sure it's not empty
									$cust.add($val,$newstr)
								}
							}
						}
						$app = [String]$key.GetValue("DisplayName")
						if(!($appnames -contains $app)){ #If it's not present, add it
							Write-Debug "Added $app to `$appnames!!!"
							$appnames += $app
						}
						if($RegistryEntries.$server){#If server already exists in the top-level hashtable
							if($RegistryEntries.$server.$app){#if Application already exists as key in sub-level hashtable
								$bleh = $RegistryEntries.$server.$app
								if($bleh.DisplayVersion -ne $cust.DisplayVersion -and $cust.DisplayVersion){#Check to see if there's a discrepancy in displayversions
									if($bleh.DisplayVersion){#check to see if the sub-hash actually does have a DisplayVersion parameter
										[String]$str2 = $app + ": " + [String]$cust.DisplayVersion #A different version number, AKA two different versions of same application
										$bleh.add($str2, $cust.DisplayVersion)
									} else{ #There exists no DisplayVersion initially in the sub-hash
										$bleh.Add("DisplayVersion",$cust.DisplayVersion)
									}
								}
								if($bleh.UninstallString -ne $cust.UninstallString -and $bleh.UninstallString -notlike "*/?{*}*" -and $cust.UninstallString -like "*/?{*}*" ){
									#if the Uninstallstrings don't match and the new uninstall string is preferable, then-->
									$RegistryEntries.$server.$app.UninstallString = $cust.UninstallString
								}
							} else{ #The server key exists, but not application key
								$RegistryEntries.$server.add($app, $cust)
							}
						} else{
							$RegistryEntries.add($server,@{$app = $cust})
						}
					}
				}
				$serverKeys = @()
				Write-Verbose "Connection to $server successfully completed..."
			} else{
				Write-Error "`"Could not connect to remote computer $server!`"`n
				`t`t`t`t`t`t`t`t`"Any errors on line 136 relates to this fact.`""
			}
		}
		if($AsHTML -or $LastWeeksInstallDates){
			$Computers = $RegistryEntries.keys | Sort-Object
			$appnames = $appnames | Sort-Object
			Write-Verbose "Generating HTML Report..."
			$th = "
			<TR><TH>Application&nbsp;Name</TH>" #Create Top header
			foreach ($pc in $Computers) {
				$th += "<TH>$pc</TH>" #Another header for each pc
			}
			$th += "</TR>" #Header finished
			if($AsHTML){
				Write-Debug "Number of entries in `$appnames = $($appnames.count)"
				$rows = ""
				foreach($app in $appnames){
					$rows += "
				<TR><TH>$app</TH>"
					foreach($pc in $Computers){
						$currentApp = $RegistryEntries.$pc.$app
						if($currentApp){#Does the machine in question have this?
							if($currentApp.DisplayVersion){#Does it then have display version?
								$status = $currentApp.DisplayVersion
							} else{
								$status = "Version-nr.&nbsp;N/A"
							}
						} else{
							$status = "Application&nbsp;N/A"
						}
						if($status -eq "Application&nbsp;N/A"){
							$color = "`"FAAFBE`"" #Pink
						} elseif($status -eq "Version-nr.&nbsp;N/A"){
							$color = "`"FFFFFF`"" #White
						} else{
							$color = "`"F7FF45`"" #Yellow
						}
						$cell = "<TD bgcolor = $color><center>$status</center></TD>"
						$rows += $cell #Intersection cell for each pc's application
					}
					$rows += "</TR>`n"
				}
				Write-Verbose "Finishing HTML report..."
			} elseif($LastWeeksInstallDates){
				$rows = ""
				foreach($app in $appnames){
					$incldd = @{} #A hashtable which will only have entries of pc's with install dates of said application within last week.
					foreach($pc in $Computers){
						$currentApp = $RegistryEntries.$pc.$app
						if($currentApp.InstallDate){#Does the machine in question have this and a InstallDate field?
							[String]$status = $currentApp.InstallDate
							$status -match "(\d{4})(\d{2})(\d{2})" | Out-Null
							$date = Get-Date -Day $matches[3] -Month $matches[2] -Year $matches[1] #The install date
							$curDate = Get-Date #Current date
							#if($app -eq "Visual Studio 2010 Prerequisites - English"){
							#	Write-Verbose "TEST TEST TEST"
							#}
							$recentEnough = $False
							for($i = 0; $i -lt 8; $i++){
								if($curDate.day -eq $date.addDays($i).day -and
									$curDate.month -eq $date.addDays($i).month -and
									$curDate.year -eq $date.addDays($i).year){ #Does the date + $i days equal current date?
									#Write-Verbose $curDate
									#Write-Verbose "$($date.addDays($i))`n`n"
									$recentEnough = $True
									break;
								}
							}
							if($recentEnough){
								$status = $matches[3] + "." + $matches[2] + "." + $matches[1]
								$cell = "<TD bgcolor = `"F7FF45`"><center>$status</center></TD>"
								$incldd.add($pc, $cell)
							}
							$recentEnough = $False
							Remove-Variable matches
						}
					}
					if($incldd.Count -gt 0){ #If this is true, that means some pc had said application with an install date younger than a week.
					$rows += "
				<TR><TH>$app</TH>"
						foreach($pc in $Computers){
							if($incldd.$pc){
								$rows += $incldd.$pc
							} else{
								$currentApp = $RegistryEntries.$pc.$app
								if($currentApp){
									if($currentApp.InstallDate){ #Does the machine in question have this and a InstallDate field?
										$status = "InstallDate&nbsp;too&nbsp;old."
										$color = "`"FFFFFF`""

									} else{
										$status = "Application&nbsp;InstallDate&nbsp;N/A"
										$color= "`"FAAFBE`""
									}
								} else{
									$status = "Application&nbsp;N/A"
									$color= "`"FAAFBE`""
								}
								$cell = "<TD bgcolor = $color><center>$status</center></TD>"
								$rows += $cell
							}
						}
						$rows += "</TR>`n"
					}
					Remove-Variable incldd
				}
			}
		$html = "<html>
	<head>
		<Title>Application&nbspReport</Title>
		<script src=`"https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js`"></script>
		<script src=`"" + $JavaScriptFile + "`"></script>
		<script language=`"javascript`" type=`"text/javascript`">
			`$(document).ready(function() {
				`$('#myTable01').fixedHeaderTable({ footer: true, cloneHeadToFoot: true, altClass: 'odd', autoShow: false });
				`$('#myTable01').fixedHeaderTable('show', 1000);
				`$('#myTable02').fixedHeaderTable({ footer: true, altClass: 'odd' });
				`$('#myTable05').fixedHeaderTable({ altClass: 'odd', footer: false, fixedColumns: 1 });
				`$('#myTable03').fixedHeaderTable({ altClass: 'odd', footer: true, fixedColumns: 1 });
				`$('#myTable04').fixedHeaderTable({ altClass: 'odd', footer: true, cloneHeadToFoot: true, fixedColumns: 3 });
			});
			`$(window).bind('resize',function(){
				window.location.href = window.location.href;
			});
		</script>
		<style>
			.fht-table,
			.fht-table thead,
			.fht-table tfoot,
			.fht-table tbody,
			.fht-table tr,
			.fht-table th,
			.fht-table td {
				/* position */
				margin: 0;
				/* size */
				padding: 0;
				/* text */
				font-size: 100%;
				font: inherit;
				vertical-align: top;
			}
			.fht-table {
				/* appearance */
				border-collapse: collapse;
				border-spacing: 0;
			}
			.fht-table-wrapper,
			.fht-table-wrapper .fht-thead,
			.fht-table-wrapper .fht-tfoot,
			.fht-table-wrapper .fht-fixed-column .fht-tbody,
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: hidden;
				/* position */
				position: relative;
			}
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: auto;
			}
			.fht-table-wrapper .fht-table .fht-cell {
				/* appearance */
				overflow: hidden;
				/* size */
				height: 1px;
			}
			.fht-table-wrapper .fht-fixed-column,
			.fht-table-wrapper .fht-fixed-body {
				/* position */
				top: 0;
				left: 0;
				position: absolute;
			}
			.fht-table-wrapper .fht-fixed-column {
					/* position */
					z-index: 1;
			}
			body { background-color:#FFFFCC;
			font-family:Courier New;
			font-size:11pt; }
			td.path {vertical-align:text-top;
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table td,
			.fht-table th {
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table th { color:black;
			background-color:lightblue; }
		</style>
	</head>
	<body>
		<div class=`"container_12 divider`">
			<div class=`"grid_4 height400`">
				<table class=`"fancyTable`" id=`"myTable05`" cellpadding=`"0`" cellspacing=`"0`" border = `"1`">
					<thead>
						$th
					</thead>
					<tbody>
						$rows
					</tbody>
				</table>
			</div>
		</div>
	</body>
</html>"
		}
	}
	end{
		if($AsHTML){ #Switch parameter
			Write-Verbose "Returning HTML pivot-table..."
			,$html
		} elseif($LastWeeksInstallDates){
			Write-Verbose "Returning HTML table..."
			,$html
		} else{
			Write-Verbose "Returning Hashtable..."
			,$RegistryEntries
		}
	}
}

function Get-EnvironmentVariables {
<#
.SYNOPSIS
Looks for and finds Environmental Variables in the registry on the given computers at the following registry locations:
1."HKEY_CURRENT_USER\ENVIRONMENT"
2."HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

.DESCRIPTION
The Get-Environment function uses .Net's [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"HiveEnum", "Server-Name")
to access the two following registry directories:
1."HKEY_CURRENT_USER\ENVIRONMENT"
2."HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

At each directory, the function iterates over all the keys, and only looks at those keys whose ValueName match one of the following:
"CodeContractsInstallDir","NUMBER_OF_PROCESSORS","OS","PATH","PROCESSOR_IDENTIFIER",PROCESSOR_LEVEL","SLBSLS_LICENSE_FILE","TEMP","TMP","VS100COMNTOOLS"

(You can search for more with wildcards by using the -searchString parameter).

Any registry Key's matching will have their values added to a nested hashtable where the primary key(s) is/are the inputted ComputerName(s),
and the sub-keys are the keys found on said computer, with their corresponding values being the corresponding registry values.

Every remote computer is contacted sequentially, not in parallel.
You can choose to add -Verbose after if you're interested in seeing what the script is doing/stuck on,
gets error from.

.PARAMETER ComputerName
A mandatory parameter which can be piped or retrieved directly, this parameter should be a single ComputerName or an array of ComputerName(s).
You may also provide IP addresses.

You can for instance instantiate a variable like so and use it:
$servers = Get-Content C:\User\%user%\Desktop\TxtFileWithAServerNameOnEachLine.txt


.PARAMETER searchString
An optional parameter which can be piped or retrieved directly, this parameter is in effect an array of strings
that a wildcard search will be performed with in the set registry path the method iterates over.

Examples of wildcard additions could be:

?ce?n, *ocean*, oc*n.
The above three will always return any matches with for example "ocean".
(The wildcard search is case-insensitive).

.PARAMETER all
If set, it will retrieve all registrykey-entries at the set environment locations in the registry.

.PARAMETER AsHTML
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
Have a list of computernames/IP's somewhere, say in a variable $servers, and then run:

$test = Get-EnvironmentVariables -ComputerName $servers

Then $test will contain the output Hashtable the function returns with all the successfully found registry values.

.EXAMPLE
If you find out that you want to search for additional RegistryKeys (since there is a list hardcoded into this script),
you can add -searchString which should be an array of strings that a wildcard search will be performed on at the
registry locations iterated over.

$test = Get-EnvironmentVariables -ComputerName $servers -searchString $searchInput

$test will now contain  all the entries which match the hardcoded entries, as well as the -searchString entries.

.EXAMPLE
If you want to have all registrykeys at the given Registry paths returned, the command will look like the following:

$output = Get-EnvironmentVariables -ComputerName $servers -all

$output will now contain all the Registry Keys at said Registry locations. (Rendering the parameter
-searchString irrelevant).

.EXAMPLE
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-EnvironmentVariables -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.NOTES
To run this function you need admin access on each remote computer you run the function towards.
Has been confirmed to work in Non-Admin-Elevated mode.
The Remote Registry service has to be enabled on each machine queried.
#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param(
	[Parameter(
	Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[String[]]$ComputerName,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='A string or array of strings which you want wildcard-search performed on while querying the registry')]
	[ValidateNotNullOrEmpty()]
	[String[]]$searchString,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='If set, it will list all Environmental registry keys and their respective values')]
	[switch]$all,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$AsHTML
	)
	Begin{
		Write-Verbose "In Begin block..."
		$KeyPaths = [System.String]"Environment",[System.String]"SYSTEM\CurrentControlSet\Control\Session Manager\Environment" #User and System Variables(s)
		$Hives =[Microsoft.Win32.RegistryHive]::CurrentUser,[Microsoft.Win32.RegistryHive]::LocalMachine #Hive enum for HKEY_CURRENT_USER and HKEY_Local_Machine
		$ValueNames = [System.String]"CodeContractsInstallDir",[System.String]"NUMBER_OF_PROCESSORS",[System.String]"OS"`
			,[System.String]"PATH",[System.String]"PROCESSOR_IDENTIFIER",[System.String]"PROCESSOR_LEVEL",`
			,[System.String]"TEMP",[System.String]"TMP"#ValueNames we're interested in
		$returnHash = @{}
		Write-Verbose "Internal variables created, adding searchString..."
		$ValueNamesLength = $ValueNames.Count
		Write-Verbose "Potentially adding search strings..."
		if ($searchString){
			foreach($str in $searchString){
				$ValueNames += $str
			}
		}
		$newLength = $ValueNames.Count
		$ComputerName = $ComputerName | Sort-Object
		$fieldNames = @()
	}
	Process{
		foreach($server in $ComputerName){
			Write-Verbose "Connecting to server: $server"
			$key = @{}
			for($i=0;$i -lt 2;$i++){
				$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hives[$i], $server)
				$regKey = $regKey.OpenSubKey($KeyPaths[$i])
				if($regKey){
					Write-Verbose "Connection established.`nAdding Environment keys."
					$cust = @{}
					$addr = [String]$regKey
					$cust.Add("RegistryAddress",$addr)
					foreach($valName in $regKey.GetValueNames()){
						if($all){#If we're interested in all the registrykeyNames and -Values
							Write-Verbose "I'm taking all!!!"
							$string = [String]$regKey.GetValue($valName)
							$cust.Add($valName,$string)
						} else{
							#Write-Verbose "Looking for matches..."
							if($valueNames -contains $valName){ #Else we've gotta match them, however we also have a wildcard search to perform
								#Write-Verbose "Match found!"
								$string = [String]$regKey.GetValue($valName)
								$cust.Add($valName,$string)
							} else{
								for($j = $ValueNamesLength; $j -lt $newLength;$j++){ #Wildcard search, loop will never iterate if there are no wildcards added
									if($ValName -like $ValueNames[$j]){
										#Write-Verbose "Match found!"
										$string = [String]$regKey.GetValue($valName)
										$cust.Add($valName,$string)
									}
								}
							}
						}
					}
					$cust.Keys |
					foreach{
						if($fieldNames -notcontains $_){
							Write-Verbose "Adding $_ to `$fieldNames..."
							$fieldNames += $_
						}
					}
					$str = [String]$Hives[$i]
					$key.add($str,@{})
					$cust.keys | Sort-Object |
					foreach{
						$key.$str += @{$_ = $cust.$_}
					}
					Write-Verbose "`$key: `n$key`n"
				} else{
					Write-Verbose "`"$server could not be reached or accessed!!!`"
				`t`t`t`t`t`t`t`t`"Any errors on line 576 or 577 relate to this fact.`""
				}
			}
			if($key.Keys -contains "LocalMachine" -or $key.Keys -contains "CurrentUser"){
				Write-Verbose "Adding `$key to hashtable..."
				$returnHash.add($server, $key)
			}
		}
		if($AsHTML){
			$ComputerName = $ReturnHash.keys | Sort-Object
			$fieldNames = $fieldNames | Sort-Object
			Write-Verbose "Generating HTML Report..."
			$th = "
			<TR><TH>Environment Fields</TH>" #Create Top header
			foreach ($pc in $ComputerName) {
				$th += "<TH>$pc</TH>" #Another header for each pc
			}
			$th += "</TR>" #Header finished
			$rows = ""
			foreach($hive in $Hives){
				$hiveName = [String]$hive
				Write-Verbose $hive
				foreach($field in $fieldNames){
					$temp = "$hiveName&#58;
$field"
					Write-Verbose $temp
					$rows += "
			<TR><TH>$temp</TH>"
					foreach($pc in $ComputerName){
						$currentField = $ReturnHash.$pc.$hiveName.$field
						if($currentField){#Does the machine in question have this?
							if($field -eq "Path"){
								$strlst = $currentField.split(";") | Sort-Object
								[String]$str = "<ul>"
								foreach($it in $strlst){
									$str += "<li>$it</li>"
								}
								$cell = "<TD class = `"path`" bgcolor = `"44FF44`">$str</TD>"
							} else{
								$str = [String]$currentField
								$cell = "<TD bgcolor = `"44FF44`"><center>$str</center></TD>"
							}
						} else{
							$cell ="<TD bgcolor = `"FAAFBE`"><center>N/A</center></TD>"
						}
						$rows += $cell #Intersection cell for each pc's application
					}
					$rows += "</TR>`n"
				}
			}
			Write-Verbose "Finishing HTML report..."
			$html = "<html>
	<head>
		<Title>Environment&nbspVariables</Title>
		<script src=`"https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js`"></script>
		<script src=`"" + $JavaScriptFile + "`"></script>
		<script language=`"javascript`" type=`"text/javascript`">
			`$(document).ready(function() {
				`$('#myTable01').fixedHeaderTable({ footer: true, cloneHeadToFoot: true, altClass: 'odd', autoShow: false });
				`$('#myTable01').fixedHeaderTable('show', 1000);
				`$('#myTable02').fixedHeaderTable({ footer: true, altClass: 'odd' });
				`$('#myTable05').fixedHeaderTable({ altClass: 'odd', footer: false, fixedColumns: 1 });
				`$('#myTable03').fixedHeaderTable({ altClass: 'odd', footer: true, fixedColumns: 1 });
				`$('#myTable04').fixedHeaderTable({ altClass: 'odd', footer: true, cloneHeadToFoot: true, fixedColumns: 3 });
			});
			`$(window).bind('resize',function(){
				window.location.href = window.location.href;
			});
		</script>
		<style>
			.fht-table,
			.fht-table thead,
			.fht-table tfoot,
			.fht-table tbody,
			.fht-table tr,
			.fht-table th,
			.fht-table td {
				/* position */
				margin: 0;
				/* size */
				padding: 0;
				/* text */
				font-size: 100%;
				font: inherit;
				vertical-align: top;
			}
			.fht-table {
				/* appearance */
				border-collapse: collapse;
				border-spacing: 0;
			}
			.fht-table-wrapper,
			.fht-table-wrapper .fht-thead,
			.fht-table-wrapper .fht-tfoot,
			.fht-table-wrapper .fht-fixed-column .fht-tbody,
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: hidden;
				/* position */
				position: relative;
			}
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: auto;
			}
			.fht-table-wrapper .fht-table .fht-cell {
				/* appearance */
				overflow: hidden;
				/* size */
				height: 1px;
			}
			.fht-table-wrapper .fht-fixed-column,
			.fht-table-wrapper .fht-fixed-body {
				/* position */
				top: 0;
				left: 0;
				position: absolute;
			}
			.fht-table-wrapper .fht-fixed-column {
					/* position */
					z-index: 1;
			}
			body { background-color:#FFFFCC;
			font-family:Courier New;
			font-size:11pt; }
			td.path {vertical-align:text-top;
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table td,
			.fht-table th {
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table th { color:black;
			background-color:lightblue; }
		</style>
	</head>
	<body>
		<div class=`"container_12 divider`">
			<div class=`"grid_4 height400`">
				<table class=`"fancyTable`" id=`"myTable05`" cellpadding=`"0`" cellspacing=`"0`" border = `"1`">
					<thead>
						$th
					</thead>
					<tbody>
						$rows
					</tbody>
				</table>
			</div>
		</div>
	</body>
</html>"
		}
	}
	End{
		if($AsHTML){
			Write-Verbose "Returning HTML pivot-table..."
			,$html
		} else{
			Write-Verbose "Returning `$returnHash..."
			return ,$returnHash
		}
	}
}

function Get-EventLogs{
<#
.SYNOPSIS
This function queries computers for their Event Logs, and returns them either as a nested hashtable with ComputerName(s) as
top-level Key(s), and the Key's respective Value(s) is/are new hashtables where the Key(s) are the names of the Logs queried,
and the Values are the Log-Objects.

.DESCRIPTION
This function queries computers for their Event Logs, and returns them either as a nested hashtable with ComputerName(s) as
top-level Key(s), and the Key's respective Value(s) is/are new hashtables where the Key(s) are the names of the Logs queried,
and the Values are the Log-Objects.

You can also add the -AsHTML Switch-Parameter, which will make the function return a String with formatted HTML tables displaying
the logs alphabetically sorted on the computers queried (again alphabetically sorted).

When the logs are queried, only the EventID, Index, EntryType, Source, MachineName, TimeWritten, InstanceID, Message -fields
in the queried objects are kept. If you for some reason want another field which should come with Get-EventLog, then this
function will not be of use.

Every remote computer is contacted sequentially, not in parallel.
You can choose to add -Verbose after if you're interested in seeing what the script is doing/stuck on,
gets error from.

.PARAMETER ComputerName
A mandatory parametere which can be piped or retrieved directly, this parameter should be a single ComputerName or an array of ComputerName(s).
You may also provide IP addresses. Mandatory parameter.

.PARAMETER Newest
A parameter that accepts Int's, which will be the X number of Newest Error entries that will be retrieved in each EventLog query.
Set to default 10. Not mandatory.

.PARAMETER Log
A Enum parameter accepting strings matching (case insensitive) any of the following Strings:
'Application','Security','Setup','System'.

Set by default to Application and System. Not mandatory.

.PARAMETER AsHTML
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
Have a list of computernames/IP's somewhere, say in an $servers, and then run:
$output = Get-RecentEventLogs -computerName $servers

$output will then hold the nested hashtables with the results of the function.

.EXAMPLE
If you want to get the output of this function as a HTML-table, you could do the following:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.NOTES
To run this function you need admin access on each remote computer you run the function towards.
Has been confirmed to work in Non-Admin-Elevated mode.
#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param(
	[Parameter(Mandatory=$True,
	Position = 0,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[String[]]$ComputerName,

	[Parameter(Mandatory=$False,
	Position = 1,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='The number of Error eventlog entries you want to extract from said Event Logs.')]
	[ValidateNotNullOrEmpty()]
	[Int]$Newest=10,

	[Parameter(Mandatory=$False,
	Position = 2,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[ValidateSet('Application','Security','Setup','System')]
	[String[]]$Log=('Application','System'),

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$AsHTML
	)
	begin{
		Write-Verbose "In Begin block..."
		$returnHash = @{}
	}
	process{
		foreach($server in $computerName){
			Write-Verbose "Querying $server..."
			foreach($entry in $Log){
				$temp = Get-EventLog -LogName $entry -ComputerName $server -Newest $Newest -EntryType Error |
				Select EventID, Index, EntryType, Source, MachineName, TimeWritten, InstanceID, Message
				if($temp){ #Null check. (I.e. if there has been a connection and the computer allows the query).
					if($returnHash.$server){
						$returnHash.$server.add($entry,$temp)
					} else{
						$returnHash.Add($server, @{$entry = $temp})
					}
				} else{
					Write-Error "Unable to connect to $server."
				}
			}
				Write-Verbose "--Query complete for $server--"
		}
		if($AsHTML){
			Write-Verbose "Generating HTML Report..."
			$Computers = $returnHash.Keys | Sort-Object
			$Log = $Log | Sort-Object
			[String]$tables = ""
			foreach($pc in $Computers){
				foreach($entry in $Log){
					$tables += "<b>--- $entry Log ---</b>"
					$tables += $returnHash.$pc.$entry | ConvertTo-Html -Fragment
					$tables += "<br/><br/>"
				}
			}
			$html = "<html>
	<head>
		<style>
			body { background-color:#FFFFCC;
			font-family:Courier New;
			font-size:11pt; }
			td.path {vertical-align:text-top;
			border:1px solid #000033;
			border-collapse:collapse; }
			td, th { border:1px solid #000033;
			border-collapse:collapse;
			background-color:PaleGoldenrod }
			th { color:white;
			background-color:#000033; }
			table, tr, td, th { padding: 0px; margin: 0px }
			table { margin-left:10px; }
		</style>
		<Title>EventLogs Report</Title>
	</head>
	<body>
		$tables
	</body>
</html>"
		}
		$html -replace '<table>','<table border = `"1`">'
		while($html -contains '<table>'){
			Write-Verbose "Adding borders to table!!!"
		}
	}
	end{
		if($AsHTML){
			Write-Verbose "Returning HTML string..."
			,$html
		} else{
			Write-Verbose "Returning Hashtable..."
			return ,$returnHash
		}
	}
}

function Get-HDDInfo{
<#
.SYNOPSIS
Returns a hashtable with Key(s) being the inputted ComputerName(s), and the corresponding values
being new Hashtables where the Keys are DeviceID (i.e. C:, D:, etc.), with the information for each disk contained in a String added
as that Keys Value.

.DESCRIPTION
The Get-HDDInfo -ComputerName $servers returns a Hashtable with the inputted ComputerName(s) as Key(s), and their respective
Values being new Hashtables where the Keys are DeviceID (i.e. C:, D:, etc.), with the information for each disk contained in a String
added as that Keys Value.

Every computer is contacted sequentially, not in parallel.
You can choose to add -Verbose after if you're interested in seeing what the script is doing/stuck on,
gets error from.

.PARAMETER ComputerName
A mandatory parametere which can be piped or retrieved directly, this parameter should be a single ComputerName or an array of ComputerName(s).
You may also provide IP addresses.

.PARAMETER AsHTML
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
Have a list of computernames/IP's somewhere, say in an $servers, and then run:

Get-HDDInfo -ComputerName $servers

.EXAMPLE
If you want to get the output of this function as a HTML-table, you could do the following:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.NOTES
To run this function you need admin access on each remote computer you run the function towards.
Has been confirmed to work in Non-Admin-Elevated mode.
#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param(
	[Parameter(Mandatory=$True,
	Position = 0,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[String[]]$ComputerName,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$AsHTML
	)
	begin{
		Write-Verbose "In Begin block..."
		$returnHash = @{}
		$diskNames = @()
	}
	process{
		foreach ($server in $ComputerName){
			Write-Verbose "Querying server $server..."
			$currentServer = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -computer $server | Select DeviceID, Size, FreeSpace
			if($currentServer){
				Write-Verbose "Connection established to server."
				$disks = @{}
				foreach($disk in $currentServer){
					[double]$size = [Math]::Round($disk.size/1073741824)
					[double]$freespace = [Math]::Round($disk.freespace/1073741824)
					[string]$deviceID = $disk.deviceid
					if($size){ #Skipping all disks not equal to or larger than one GiB in size (during testing only found one, suspected to be licesence dongle)
						$obj = @{}
						[double]$percentageFree = [Math]::Round(($freespace/$size)*100.0)
						[String]$percentageFree += " %"
						[String]$freespace += " GiB"
						[String]$size += " GiB"
						$obj.Add("Size",$size)
						$obj.Add("FreeSpace",$freespace)
						$obj.Add("PercentFree",$percentageFree)
						$disks.add($deviceID, $obj)
						if(!($diskNames -contains $deviceID)){
							$diskNames += $deviceID
						}
					}
				}
				$returnHash.add($server,$disks)
				Write-Verbose "Array of server disks added to hashtable"
			} else{
				Write-Verbose "$server was not reached. Errors on line 1051 relate to this fact."
			}
			Write-Verbose "Closing connection to $server..."
		}
		if($AsHTML){
			$Computers = $returnHash.keys | Sort-Object
			Write-Verbose "Generating HTML Report..."
			$th = "
			<TR><TH>DeviceID</TH>" #Create Top header
			foreach ($pc in $Computers) {
				$th += "<TH>$pc</TH>" #Another header for each pc
			}
			$th += "</TR>" #Header finished
			$rows = ""
			foreach($disk in $diskNames){
				$rows += "
			<TR><TH>$disk</TH>"
				foreach($pc in $Computers){
					$currentDisk = $returnHash.$pc.$disk
					if($currentDisk){#Does the machine in question have this?
						$status = "Freespace&#58; $($currentDisk.freespace)<br/>Free&#58; $($currentDisk.percentfree)<br/>Size&#58; $($currentDisk.Size)"
						$cell = "<TD bgcolor = `"44FF44`"><center>$status</center></TD>"
					} else{
						$status = "Disk N/A"
						$cell = "<TD bgcolor = `"red`"><center>$status</center></TD>"
					}
					$rows += $cell #Intersection cell for each pc's application
				}
				$rows += "</TR>`n"
			}
			Write-Verbose "Finishing HTML report..."
			$html = "<html>
	<head>
		<Title>HDD&nbspProperties</Title>
		<script src=`"https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js`"></script>
		<script src=`"" + $JavaScriptFile + "`"></script>
		<script language=`"javascript`" type=`"text/javascript`">
			`$(document).ready(function() {
				`$('#myTable01').fixedHeaderTable({ footer: true, cloneHeadToFoot: true, altClass: 'odd', autoShow: false });
				`$('#myTable01').fixedHeaderTable('show', 1000);
				`$('#myTable02').fixedHeaderTable({ footer: true, altClass: 'odd' });
				`$('#myTable05').fixedHeaderTable({ altClass: 'odd', footer: false, fixedColumns: 1 });
				`$('#myTable03').fixedHeaderTable({ altClass: 'odd', footer: true, fixedColumns: 1 });
				`$('#myTable04').fixedHeaderTable({ altClass: 'odd', footer: true, cloneHeadToFoot: true, fixedColumns: 3 });
			});
			`$(window).bind('resize',function(){
				window.location.href = window.location.href;
			});
		</script>
		<style>
			.fht-table,
			.fht-table thead,
			.fht-table tfoot,
			.fht-table tbody,
			.fht-table tr,
			.fht-table th,
			.fht-table td {
				/* position */
				margin: 0;
				/* size */
				padding: 0;
				/* text */
				font-size: 100%;
				font: inherit;
				vertical-align: top;
			}
			.fht-table {
				/* appearance */
				border-collapse: collapse;
				border-spacing: 0;
			}
			.fht-table-wrapper,
			.fht-table-wrapper .fht-thead,
			.fht-table-wrapper .fht-tfoot,
			.fht-table-wrapper .fht-fixed-column .fht-tbody,
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: hidden;
				/* position */
				position: relative;
			}
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: auto;
			}
			.fht-table-wrapper .fht-table .fht-cell {
				/* appearance */
				overflow: hidden;
				/* size */
				height: 1px;
			}
			.fht-table-wrapper .fht-fixed-column,
			.fht-table-wrapper .fht-fixed-body {
				/* position */
				top: 0;
				left: 0;
				position: absolute;
			}
			.fht-table-wrapper .fht-fixed-column {
					/* position */
					z-index: 1;
			}
			body { background-color:#FFFFCC;
			font-family:Courier New;
			font-size:11pt; }
			td.path {vertical-align:text-top;
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table td,
			.fht-table th {
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table th { color:black;
			background-color:lightblue; }
		</style>
	</head>
	<body>
		<div class=`"container_12 divider`">
			<div class=`"grid_4 height400`">
				<table class=`"fancyTable`" id=`"myTable05`" cellpadding=`"0`" cellspacing=`"0`" border = `"1`">
					<thead>
						$th
					</thead>
					<tbody>
						$rows
					</tbody>
				</table>
			</div>
		</div>
	</body>
</html>"
		}
	}
	end{
		if($AsHTML){
			Write-Verbose "Returning HTML pivot-table..."
			,$html
		} else{
			Write-Verbose "Returning `$returnHash"
			return $returnHash
		}
	}
}

function Get-HWInfo{
<#
.SYNOPSIS
Returns a Hashtable with Computername(s) for Key(s), with Hashtables where system hardware properties are Keys (this includes DeviceID's),
and a string describing their values as Value.

.DESCRIPTION
The Get-HWInfo -computerName $servers queries each server in sequence, returning a Hashtable with the the
number of threads for each computer queried.

This function was created with the intention of using the -AsHTML switch, so you'd get a String of the infomation formatted into
HTML format.

Every remote computer is contacted sequentially, not in parallel.
You can choose to add -Verbose after if you're interested in seeing what the script is doing/stuck on,
gets error from.

.PARAMETER ComputerName
A mandatory parameter which can be piped or retrieved directly, this parameter should be a single ComputerName or an array of ComputerName(s).
You may also provide IP addresses.

You can for instance instantiate a variable like so and use it:
$servers = Get-Content C:\User\%user%\Desktop\TxtFileWithAServerNameOnEachLine.txt

And then:
Get-HWInfo -computerName $servers

.PARAMETER AsHTML
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
Have a list of computernames/IP's somewhere, say in an $stringArray, and then run:

$output = Get-HWInfo -computerName $stringArray

Output will now hold a Hashtable with ComputerName(s) for key(s), and HW properties for Keys in the subhashes.

.EXAMPLE
If you want to get the output of this function as a HTML-table, you could do the following:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.NOTES
To run this function you need admin access on each remote computer you run the function towards.
Has been confirmed to work in Non-Admin-Elevated mode.
#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param(
	[Parameter(Mandatory=$True,
	Position = 0,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[string[]]$ComputerName,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$AsHTML
	)
	begin{
		Write-Verbose "In Begin block..."
		$returnHash = @{}
		$propertyNames = "Uptime","LastBootTime","RAM","CPUThreads"
	}
	process{
		foreach($server in $ComputerName){
			Write-Verbose "Querying server $server..."
			$serverDisks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $server |
			Select DeviceID, Size, FreeSpace
			foreach($disk in $serverDisks | Sort-Object -Property DeviceID){
				#Write-Verbose "Current DeviceID evaluated: $($disk.DeviceID)"
				$str = [String]$disk.DeviceID
				if($propertyNames -notcontains $str){
					#Write-Verbose "$($disk.DeviceID) added..."
					$propertyNames += $str
				}
			}
			$hw = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $server |
			Select NumberOfLogicalProcessors, TotalPhysicalMemory
			$sw = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $server
			if($serverDisks -and $hw -and $sw){
				Write-Verbose "Connection to $server established..."
				$upt = (Get-Date) - [System.Management.ManagementDateTimeConverter]::ToDateTime($sw.LastBootUpTime)
				[String]$str = "$([System.Math]::Round($hw.TotalPhysicalMemory/1Gb)) GiB RAM"
				$returnHash.add($server, @{"RAM" = $str})
				[String]$str = "$($hw.NumberOfLogicalProcessors) CPU Threads"
				$returnHash.$server.add("CPUThreads",$str)
				$str = [String]$sw.ConvertToDateTime($sw.LastBootUpTime)
				$returnHash.$server.add("LastBootTime",$str)
				$str = "Uptime for: " +
				$upt.Days +	" days <br/>" +
				$upt.Hours + " hours " +
				$upt.Minutes + " minutes </br>" +
				$upt.Seconds + " seconds."
				$returnHash.$server.add("Uptime",$str)
				foreach($disk in $serverDisks){
					if([Math]::Round($disk.size/1073741824) -gt 0){
						$str = "Freespace: " + [Math]::Round($disk.freespace/1073741824,2) + "G" +
						"<br/>Free: " + [Math]::Round($disk.freespace/$disk.size,2)*100 + "%" +
						"<br/>Sz: " + [Math]::Round($disk.size/1073741824,2) + "G"
						$returnHash.$server.add($disk.DeviceID, $str)
					} elseif([Math]::Round($disk.size/1048576) -gt 0){
						$str = "Freespace: " + [Math]::Round($disk.freespace/1048576,2)+ "M" +
						"<br/>Free: " + [Math]::Round($disk.freespace/$disk.size,2)*100 + "%" +
						"<br/>Sz: " + [Math]::Round($disk.size/1048576,2) + "M"
						$returnHash.$server.add($disk.DeviceID, $str)
					}
				}
			} else{
				Write-Error "`"Unable to connect to $server...`"
				 `"Any errors on lines 1298, 1308 and 1310 relates to this fact...`""
			}
		}
		if($AsHTML){
			$Computers = $returnHash.keys | Sort-Object
			#Write-Host $propertyNames
			Write-Verbose "Generating HTML Report..."
			$th = "						<TR>
							<TH>HW&nbspProperty</TH>" #Create Top header
			foreach ($pc in $Computers) {
				$th += "
							<TH>$pc</TH>" #Another header for each pc
			}
			$th += "
						</TR>" #Header finished
			$rows = ""
			foreach($prop in $propertyNames){
				$rows += "						<TR>
							<TH>$prop</TH>"
				foreach($pc in $Computers){
					$currentProp = $returnHash.$pc.$prop
					if($currentProp){
						$cell = "<TD bgcolor = `"44FF44`"><center>$currentProp</center></TD>"
					} else{
						$cell = "<TD bgcolor = `"FAAFBE`"><center>N/A</center></TD>"
					}
					$rows += "
							" + $cell + "`n"
				}
				$rows += "
						</TR>`n"
			}
			Write-Verbose "Finishing HTML report..."
			$html = "<html>
	<head>
		<Title>HW&nbspProperties</Title>
		<script src=`"https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js`"></script>
		<script src=`"" + $JavaScriptFile + "`"></script>
		<script language=`"javascript`" type=`"text/javascript`">
			`$(document).ready(function() {
				`$('#myTable01').fixedHeaderTable({ footer: true, cloneHeadToFoot: true, altClass: 'odd', autoShow: false });
				`$('#myTable01').fixedHeaderTable('show', 1000);
				`$('#myTable02').fixedHeaderTable({ footer: true, altClass: 'odd' });
				`$('#myTable05').fixedHeaderTable({ altClass: 'odd', footer: false, fixedColumns: 1 });
				`$('#myTable03').fixedHeaderTable({ altClass: 'odd', footer: true, fixedColumns: 1 });
				`$('#myTable04').fixedHeaderTable({ altClass: 'odd', footer: true, cloneHeadToFoot: true, fixedColumns: 3 });
			});
			`$(window).bind('resize',function(){
				window.location.href = window.location.href;
			});
		</script>
		<style>
			.fht-table,
			.fht-table thead,
			.fht-table tfoot,
			.fht-table tbody,
			.fht-table tr,
			.fht-table th,
			.fht-table td {
				/* position */
				margin: 0;
				/* size */
				padding: 0;
				/* text */
				font-size: 100%;
				font: inherit;
				vertical-align: top;
			}
			.fht-table {
				/* appearance */
				border-collapse: collapse;
				border-spacing: 0;
			}
			.fht-table-wrapper,
			.fht-table-wrapper .fht-thead,
			.fht-table-wrapper .fht-tfoot,
			.fht-table-wrapper .fht-fixed-column .fht-tbody,
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: hidden;
				/* position */
				position: relative;
			}
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: auto;
			}
			.fht-table-wrapper .fht-table .fht-cell {
				/* appearance */
				overflow: hidden;
				/* size */
				height: 1px;
			}
			.fht-table-wrapper .fht-fixed-column,
			.fht-table-wrapper .fht-fixed-body {
				/* position */
				top: 0;
				left: 0;
				position: absolute;
			}
			.fht-table-wrapper .fht-fixed-column {
					/* position */
					z-index: 1;
			}
			body { background-color:#FFFFCC;
			font-family:Courier New;
			font-size:11pt; }
			td.path {vertical-align:text-top;
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table td,
			.fht-table th {
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table th { color:black;
			background-color:lightblue; }
		</style>
	</head>
	<body>
		<div class=`"container_12 divider`">
			<div class=`"grid_4 height400`">
				<table class=`"fancyTable`" id=`"myTable05`" cellpadding=`"0`" cellspacing=`"0`" border = `"1`">
					<thead>
						$th
					</thead>
					<tbody>
						$rows
					</tbody>
				</table>
			</div>
		</div>
	</body>
</html>"
		}
	}
	end{
		if($AsHTML){
			Write-Verbose "Returning HTML pivot-table..."
			,$html
		} else{
			Write-Verbose "Returning `$returnHash"
			return ,$returnHash
		}
	}
}

function Get-NumberOfThreads{
<#
.SYNOPSIS
Returns a Hashtable with ComputerName(s) for Key(s), and number of Processing threads for corresponding Value.

.DESCRIPTION
The Get-NumberOfThreads -ComputerName $servers queries each server in sequence, returning a Hashtable with the the
number of threads for each computer queried.

Every remote computer is contacted sequentially, not in parallel.
You can choose to add -Verbose after if you're interested in seeing what the script is doing/stuck on,
gets error from.

.PARAMETER ComputerName
A single computer name or an array of computer names. You may also provide IP addresses.
You can for instance instantiate a variable like so and use it:
$servers = Get-Content C:\User\%user%\Desktop\TxtFileWithAServerNameOnEachLine.txt

And then:
$output = Get-NumberOfThreads -ComputerName $servers

.PARAMETER ComputerName
A mandatory parametere which can be piped or retrieved directly, this parameter should be a single ComputerName or an array of ComputerName(s).
You may also provide IP addresses.

.PARAMETER AsHTML
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
Have a list of computernames/IP's somewhere, say in an $servers, and then run:

$output = Get-NumberOfThreads -computerName $servers

$output will now contain the Hashtable with computernames for keys, and number of processing
threads for values.

.EXAMPLE
If you want to get the output of this function as a HTML-table, you could do the following:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.NOTES
To run this function you need admin access on each remote computer you run the function towards.
Has been confirmed to work in Non-Admin-Elevated mode.
#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param(
	[Parameter(Mandatory=$True,
	Position = 0,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[string[]]$ComputerName,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$AsHTML
	)
	begin{
		Write-Verbose "In Begin block, making Hash..."
		$returnHash = @{}
	}
	process{
		foreach($server in $computerName){
			Write-Verbose "Querying machine $server."
			$wmi = Get-WmiObject Win32_ComputerSystem -computer $server
			$str = [String]$wmi.Name
			$nr = [Int32]$wmi.NumberOfLogicalProcessors
			if ($str -and $nr -gt 0){ #If everything is in order (it should if communication with the server was achieved and all permissions were in order)
				$returnHash.add($str, $nr)
				Write-Verbose "Machine should now be added.`n"
			}
		}
		if($AsHTML){
			$Computers = $returnHash.keys | Sort-Object
			Write-Verbose "Generating HTML Report..."
			$th = "<TR><TH>HW&nbsp;Property</TH>" #Create Top header
			foreach ($pc in $Computers) {
				$th += "<TH>$pc</TH>" #Another header for each pc
			}
			$th += "</TR>" #Header finished
			$rows = "<TR><TH>Number&nbsp;of&nbsp;Processors</TH>"
			foreach($pc in $Computers){
				$currentProcessor = $returnHash.$pc
				$status = "$currentProcessor"
				$cell = "<TD bgcolor = `"44FF44`"><center>$status</center></TD>"
				$rows += $cell #Intersection cell for each pc's application
			}
			$rows += "</TR>`n"
			Write-Verbose "Finishing HTML report..."
			$html = "<html>
	<head>
		<Title>Number&nbspOf&nbspThreads</Title>
		<script src=`"https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js`"></script>
		<script src=`"" + $JavaScriptFile + "`"></script>
		<script language=`"javascript`" type=`"text/javascript`">
			`$(document).ready(function() {
				`$('#myTable01').fixedHeaderTable({ footer: true, cloneHeadToFoot: true, altClass: 'odd', autoShow: false });
				`$('#myTable01').fixedHeaderTable('show', 1000);
				`$('#myTable02').fixedHeaderTable({ footer: true, altClass: 'odd' });
				`$('#myTable05').fixedHeaderTable({ altClass: 'odd', footer: false, fixedColumns: 1 });
				`$('#myTable03').fixedHeaderTable({ altClass: 'odd', footer: true, fixedColumns: 1 });
				`$('#myTable04').fixedHeaderTable({ altClass: 'odd', footer: true, cloneHeadToFoot: true, fixedColumns: 3 });
			});
			`$(window).bind('resize',function(){
				window.location.href = window.location.href;
			});
		</script>
		<style>
			.fht-table,
			.fht-table thead,
			.fht-table tfoot,
			.fht-table tbody,
			.fht-table tr,
			.fht-table th,
			.fht-table td {
				/* position */
				margin: 0;
				/* size */
				padding: 0;
				/* text */
				font-size: 100%;
				font: inherit;
				vertical-align: top;
			}
			.fht-table {
				/* appearance */
				border-collapse: collapse;
				border-spacing: 0;
			}
			.fht-table-wrapper,
			.fht-table-wrapper .fht-thead,
			.fht-table-wrapper .fht-tfoot,
			.fht-table-wrapper .fht-fixed-column .fht-tbody,
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: hidden;
				/* position */
				position: relative;
			}
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: auto;
			}
			.fht-table-wrapper .fht-table .fht-cell {
				/* appearance */
				overflow: hidden;
				/* size */
				height: 1px;
			}
			.fht-table-wrapper .fht-fixed-column,
			.fht-table-wrapper .fht-fixed-body {
				/* position */
				top: 0;
				left: 0;
				position: absolute;
			}
			.fht-table-wrapper .fht-fixed-column {
					/* position */
					z-index: 1;
			}
			body { background-color:#FFFFCC;
			font-family:Courier New;
			font-size:11pt; }
			td.path {vertical-align:text-top;
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table td,
			.fht-table th {
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table th { color:black;
			background-color:lightblue; }
		</style>
	</head>
	<body>
		<div class=`"container_12 divider`">
			<div class=`"grid_4 height400`">
				<table class=`"fancyTable`" id=`"myTable05`" cellpadding=`"0`" cellspacing=`"0`" border = `"1`">
					<thead>
						$th
					</thead>
					<tbody>
						$rows
					</tbody>
				</table>
			</div>
		</div>
	</body>
</html>"
		}
	}
	end{
		if($AsHTML){
			Write-Verbose "Returning HTML pivot-table..."
			,$html
		} else{
			Write-Verbose "Returning `$returnHash"
			return ,$returnHash
		}
	}
}

function Get-TotalPhysicalMemory{
<#
.SYNOPSIS
Returns a hashtable with the inputted ComputerName(s) for key(s), and a string giving the amount of total physical memory
as value.

.DESCRIPTION
The Get-TotalPhysicalMemory -ComputerName $servers queries each server in sequence, returning a hashtable where the keys
are the inputted computer names/IP addresses, and the corresponding values are a string with "XX GiB RAM"

Every remote computer is contacted sequentially, not in parallel.
You can choose to add -Verbose after if you're interested in seeing what the script is doing/stuck on,
gets error from.

.PARAMETER ComputerName
A single computer name or an array of computer names. You may also provide IP addresses.
You can for instance instantiate a variable like so and use it:
$servers = Get-Content C:\User\%user%\Desktop\TxtFileWithAServerNameOnEachLine.txt

And then:
Get-TotalPhysicalMemory -ComputerName $servers

.PARAMETER ComputerName
A mandatory parametere which can be piped or retrieved directly, this parameter should be a single ComputerName or an array of ComputerName(s).
You may also provide IP addresses.

.PARAMETER AsHTML
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
If you want to get the output of this function as a HTML-table, you could do the following:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
Have a list of computer names/IP's somewhere, say in an $stringArray, and then run:

Get-TotalPhysicalMemory -ComputerName $stringArray

This will return a hashtable:

Name 						Value
-----						-----
<servername1> 				XX GiB RAM
<servername2>				YY GiB RAM
...

.NOTES
To run this function you need admin access on each remote computer you run the function towards.
Has been confirmed to work in Non-Admin-Elevated mode.
#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param(
	[Parameter(Mandatory=$True,
	Position = 0,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[string[]]$ComputerName,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$AsHTML
	)
	begin{
		Write-Verbose "In Begin block..."
		$returnHash = @{}
	}
	process{
		foreach ($server in $ComputerName){
			Write-Verbose "Querying server $server."
			$mem = Get-WmiObject win32_computersystem -ComputerName $server
			if($mem){
				Write-Verbose "Server connection established."
				[String]$string = [System.Math]::Round($mem.totalphysicalmemory / 1Gb)
				$string += " GiB RAM"
				$returnHash.add($server, $string)
				Write-Verbose "Added serverdata to Hashtable."
			}
		}
		if($AsHTML){
			$Computers = $returnHash.keys | Sort-Object
			Write-Verbose "Generating HTML Report..."
			$th = "<TR><TH>HW&nbsp;Property</TH>" #Create Topleft header
			foreach ($pc in $Computers) {
				$th += "<TH>$pc</TH>" #Another header for each pc
			}
			$th += "</TR>" #Header finished
			$rows = "<TR><TH>Amount&nbsp;of&nbsp;RAM</TH>"
			foreach($pc in $Computers){
				$currentRAM = $returnHash.$pc
				$status = "$currentRAM"
				$cell = "<TD bgcolor = `"44FF44`"><center>$status</center></TD>"
				$rows += $cell #Intersection cell for each pc's RAM info
			}
			$rows += "</TR>`n"
			Write-Verbose "Finishing HTML report..."
			$html = "<html>
	<head>
		<Title>Total&nbspPhysical&nbspMemory</Title>
		<script src=`"https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js`"></script>
		<script src=`"" + $JavaScriptFile + "`"></script>
		<script language=`"javascript`" type=`"text/javascript`">
			`$(document).ready(function() {
				`$('#myTable01').fixedHeaderTable({ footer: true, cloneHeadToFoot: true, altClass: 'odd', autoShow: false });
				`$('#myTable01').fixedHeaderTable('show', 1000);
				`$('#myTable02').fixedHeaderTable({ footer: true, altClass: 'odd' });
				`$('#myTable05').fixedHeaderTable({ altClass: 'odd', footer: false, fixedColumns: 1 });
				`$('#myTable03').fixedHeaderTable({ altClass: 'odd', footer: true, fixedColumns: 1 });
				`$('#myTable04').fixedHeaderTable({ altClass: 'odd', footer: true, cloneHeadToFoot: true, fixedColumns: 3 });
			});
			`$(window).bind('resize',function(){
				window.location.href = window.location.href;
			});
		</script>
		<style>
			.fht-table,
			.fht-table thead,
			.fht-table tfoot,
			.fht-table tbody,
			.fht-table tr,
			.fht-table th,
			.fht-table td {
				/* position */
				margin: 0;
				/* size */
				padding: 0;
				/* text */
				font-size: 100%;
				font: inherit;
				vertical-align: top;
			}
			.fht-table {
				/* appearance */
				border-collapse: collapse;
				border-spacing: 0;
			}
			.fht-table-wrapper,
			.fht-table-wrapper .fht-thead,
			.fht-table-wrapper .fht-tfoot,
			.fht-table-wrapper .fht-fixed-column .fht-tbody,
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: hidden;
				/* position */
				position: relative;
			}
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: auto;
			}
			.fht-table-wrapper .fht-table .fht-cell {
				/* appearance */
				overflow: hidden;
				/* size */
				height: 1px;
			}
			.fht-table-wrapper .fht-fixed-column,
			.fht-table-wrapper .fht-fixed-body {
				/* position */
				top: 0;
				left: 0;
				position: absolute;
			}
			.fht-table-wrapper .fht-fixed-column {
					/* position */
					z-index: 1;
			}
			body { background-color:#FFFFCC;
			font-family:Courier New;
			font-size:11pt; }
			td.path {vertical-align:text-top;
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table td,
			.fht-table th {
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table th { color:black;
			background-color:lightblue; }
		</style>
	</head>
	<body>
		<div class=`"container_12 divider`">
			<div class=`"grid_4 height400`">
				<table class=`"fancyTable`" id=`"myTable05`" cellpadding=`"0`" cellspacing=`"0`" border = `"1`">
					<thead>
						$th
					</thead>
					<tbody>
						$rows
					</tbody>
				</table>
			</div>
		</div>
	</body>
</html>"
		}
	}
	end{
		if($AsHTML){
			Write-Verbose "Returning HTML pivot-table..."
			,$html
		} else{
			Write-Verbose "Returning `$returnHash..."
			return ,$returnHash
		}
	}
}

function Get-Uptime{
<#
.SYNOPSIS
Returns a hashtable which for said ComputerName has a sub-hashtable with the time of last boot, and
the amount of time since then.

.DESCRIPTION
The Get-Uptime -ComputerName $computer(s) queries each computer/server in sequence, returning a hashtable with computer names
as keys, and a sub-hashtable with the keys .Uptime and .LastBootTime returning the respective values for
said computer name.

Every remote computer is contacted sequentially, not in parallel.
You can choose to add -Verbose after if you're interested in seeing what the script is doing/stuck on,
gets error from.

.PARAMETER ComputerName
A single computer name or an array of computer names. You may also provide IP addresses.
You can for instance instantiate a variable like so and use it:
$servers = Get-Content C:\User\%user%\Desktop\TxtFileWithAServerNameOnEachLine.txt

And then:
Get-Uptime -ComputerName $servers

.PARAMETER AsHTML
A switch to get the output as a String formatted into HTML-code.
An example on the use of -AsHTML would be:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
If you want to get the output of this function as a HTML-table, you could do the following:

(1) $html = Get-HWInfo -ComputerName -$servers -AsHTML
(2) $html > ReportName.htm
(3) ii $html

(1) Sets the output of the function call to the variable $html
(2) Sets the contents of $html to a new file, "ReportName.htm" at the current location.
(3) Opens ReportName.htm with the default webbrowser on your system.

.EXAMPLE
Have a list of computer names/IP's somewhere, say in an $stringArray, and then run:

Get-Uptime -ComputerName $stringArray

And you will be outputted a hashtable with the results.

.NOTES
To run this function you need admin access on each remote computer you run the function towards.
Has been confirmed to work in Non-Admin-Elevated mode.
#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param(
	[Parameter(Mandatory=$True,
	Position = 0,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='The computer name/IP you want to run the script towards.')]
	[ValidateNotNullOrEmpty()]
	[string[]]$ComputerName,

	[Parameter(
	Mandatory=$False,
	ValueFromPipeline=$False,
	ValueFromPipelineByPropertyName=$False,
	HelpMessage='A switch statement if you want to output a HTML report.')]
	[ValidateNotNullOrEmpty()]
	[Switch]$AsHTML
	)
		begin{
		Write-Verbose "In Begin block..."
		$returnHash = @{}
		$propertyNames = "Uptime","LastBootTime"
	}
	process{
		foreach($server in $ComputerName){
			Write-Verbose "Querying server $server..."
			$sw = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $server
			if($sw){
				Write-Verbose "Connection to $server established..."
				$upt = (Get-Date) - [System.Management.ManagementDateTimeConverter]::ToDateTime($sw.LastBootUpTime)
				$str = [String]$sw.ConvertToDateTime($sw.LastBootUpTime)
				$returnHash.$server.add("LastBootTime",$str)
				$str = "Uptime for: " +
				$upt.Days +	" days <br/>" +
				$upt.Hours + " hours " +
				$upt.Minutes + " minutes </br>" +
				$upt.Seconds + " seconds."
				$returnHash.$server.add("Uptime",$str)
			} else{
				Write-Error "`"Unable to connect to $server...`"
				 `"Any errors on line 2061 relates to this fact...`""
			}
		}
		if($AsHTML){
			$Computers = $returnHash.keys | Sort-Object
			#Write-Host $propertyNames
			Write-Verbose "Generating HTML Report..."
			$th = "
			<TR>
				<TH>HW&nbspProperty</TH>" #Create Top header
			foreach ($pc in $Computers) {
				$th += "
				<TH>$pc</TH>" #Another header for each pc
			}
			$th += "
			</TR>" #Header finished
			$rows = ""
			foreach($prop in $propertyNames){
				$rows += "
			<TR>
				<TH>$prop</TH>"
				foreach($pc in $Computers){
					$currentProp = $returnHash.$pc.$prop
					if($currentProp){
						$cell = "<TD bgcolor = `"44FF44`"><center>$currentProp</center></TD>"
					} else{
						$cell = "<TD bgcolor = `"red`"><center>N/A</center></TD>"
					}
					$rows += $cell
				}
				$rows += "
			</TR>`n"
			}
			Write-Verbose "Finishing HTML report..."
			$html = "<html>
	<head>
		<Title>Number&nbspOf&nbspThreads</Title>
		<script src=`"https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js`"></script>
		<script src=`"" + $JavaScriptFile + "`"></script>
		<script language=`"javascript`" type=`"text/javascript`">
			`$(document).ready(function() {
				`$('#myTable01').fixedHeaderTable({ footer: true, cloneHeadToFoot: true, altClass: 'odd', autoShow: false });
				`$('#myTable01').fixedHeaderTable('show', 1000);
				`$('#myTable02').fixedHeaderTable({ footer: true, altClass: 'odd' });
				`$('#myTable05').fixedHeaderTable({ altClass: 'odd', footer: false, fixedColumns: 1 });
				`$('#myTable03').fixedHeaderTable({ altClass: 'odd', footer: true, fixedColumns: 1 });
				`$('#myTable04').fixedHeaderTable({ altClass: 'odd', footer: true, cloneHeadToFoot: true, fixedColumns: 3 });
			});
			`$(window).bind('resize',function(){
				window.location.href = window.location.href;
			});
		</script>
		<style>
			.fht-table,
			.fht-table thead,
			.fht-table tfoot,
			.fht-table tbody,
			.fht-table tr,
			.fht-table th,
			.fht-table td {
				/* position */
				margin: 0;
				/* size */
				padding: 0;
				/* text */
				font-size: 100%;
				font: inherit;
				vertical-align: top;
			}
			.fht-table {
				/* appearance */
				border-collapse: collapse;
				border-spacing: 0;
			}
			.fht-table-wrapper,
			.fht-table-wrapper .fht-thead,
			.fht-table-wrapper .fht-tfoot,
			.fht-table-wrapper .fht-fixed-column .fht-tbody,
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: hidden;
				/* position */
				position: relative;
			}
			.fht-table-wrapper .fht-fixed-body .fht-tbody,
			.fht-table-wrapper .fht-tbody {
				/* appearance */
				overflow: auto;
			}
			.fht-table-wrapper .fht-table .fht-cell {
				/* appearance */
				overflow: hidden;
				/* size */
				height: 1px;
			}
			.fht-table-wrapper .fht-fixed-column,
			.fht-table-wrapper .fht-fixed-body {
				/* position */
				top: 0;
				left: 0;
				position: absolute;
			}
			.fht-table-wrapper .fht-fixed-column {
					/* position */
					z-index: 1;
			}
			body { background-color:#FFFFCC;
			font-family:Courier New;
			font-size:11pt; }
			td.path {vertical-align:text-top;
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table td,
			.fht-table th {
			border:1px solid #000033;
			border-collapse:collapse; }
			.fht-table th { color:black;
			background-color:lightblue; }
		</style>
	</head>
	<body>
		<div class=`"container_12 divider`">
			<div class=`"grid_4 height400`">
				<table class=`"fancyTable`" id=`"myTable05`" cellpadding=`"0`" cellspacing=`"0`" border = `"1`">
					<thead>
						$th
					</thead>
					<tbody>
						$rows
					</tbody>
				</table>
			</div>
		</div>
	</body>
</html>"
		}
	}
	end{
		if($AsHTML){
			Write-Verbose "Returning HTML pivot-table..."
			,$html
		} else{
			Write-Verbose "Returning `$returnHash"
			return ,$returnHash
		}
	}
}
