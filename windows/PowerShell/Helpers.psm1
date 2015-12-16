Function Resolve-EnvironmentVariable {

	[cmdletbinding()]
	Param(
		[Parameter(
			Position=0,
			Mandatory=$True,
			ValueFromPipeline=$True
		)]
		#[(ValidateNotNullOrEmpty())]
		[String]$EnvVar
	)
	Begin{
		$ValidInput = $False
		$ValidOutput = $False
		$EnvVar = $EnvVar.trim()
		if($EnvVar -match "%\S+%"){
			$ValidInput = $True
		}
	}
	Process {
		if($ValidInput){
			$OutPut = [Environment]::ExpandEnvironmentVariables($EnvVar)
			if($OutPut -cne $EnvVar){
				$ValidOutput = $True
			}
		}
	}
	End{
		if($ValidOutput){
			$OutPut
		} else{
			"!!Use valid input next time!!`n`n(If input is of the form: '%<something>%'`nIt could be that the .NET function finds no corresponding variable...)"
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