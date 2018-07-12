################################################
# filename: sophosuninstaller01.ps1
# Version 2.0
# Written by: Hubert Tan
# Written on: 3/23/2018
# Updated: 7/5/2018
################################################
# 		------->READ THIS SECTION <--------
# Must change Script execution policy from Restricted to unrestricted: run the below command
#
# Set-ExecutionPolicy -Scope Process unrestricted
#################################################

#Variables
$u="$env:USERNAME"
$checkrights=net localgroup Sophosadministrator | where {$_-match $u}
$sophosedpath="C:\Windows\System32\drivers\SophosED.sys"
$sophosservices = @('ALsvc','Health','McsClient','McsAgent')


#Registry Paths
$sophosMCSA = 'HKLM:\SYSTEM\CurrentControlSet\Services\Sophos MCS Agent'
$sophosEPD = 'HKLM:\SYSTEM\CurrentControlSet\Services\Sophos Endpoint Defense\TamperProtection\Config'
$sophostamperprot = 'HKLM:\SOFTWARE\WOW6432Node\Sophos\SAVService\TamperProtection'

#Function to modify Sophos registry
function disabletamper {
	param($registryPath,$dword,$rvalue)

	$originalvalue = (Get-ItemProperty -Path $registryPath).$dword
		
		IF((Get-ItemProperty -Path $registryPath).$dword -eq $rvalue) {
			write-host "$registryPath $dword registry property value is $rvalue -- No change needed"
			write-host ""
		} else {
			write-host "Changing $registryPath registry property value from $originalvalue to $rvalue"
			Set-ItemProperty -Path $registryPath -Name $dword -Value $rvalue
			write-host ""
	}
}

#'ALsvc','Health','McsClient','McsAgent'
function removesophos {
    param(
    [Parameter(Position=0,mandatory=$true)]
    [string]$services)

    
    if ($services -match "Health")
    {
        Write-Host =======================================================================
        Write-Host ====================== kill Sophos services [$services] ==================
        Write-Host ===============================[ Done ]===============================

        
        do{$i = (!(Test-Path "$env:userprofile\AppData\Local\Temp\Sophos Health Uninstall*"))

            Start-Sleep -Milliseconds 1000
            "Please wait $date"

        } until ($i -eq $False)
        		Write-Host "Stopping $services"
            Get-Process $services | Stop-Process -force
        
    } 
    	elseif ($services -match "McsClient")
    {
        Write-Host =======================================================================
        Write-Host ====================== kill Sophos services [$services] ================
        Write-Host ===============================[ Done ]================================


        do{$i = (!(Test-Path "$env:userprofile\AppData\Local\Temp\Sophos Management Communications System Uninstall*"))

            Start-Sleep -Milliseconds 1000
            "Please wait $date"

        } until ($i -eq $False)
        		Write-Host "Stopping $services"
            Get-Process $services | Stop-Process -force
    }
    	elseif ($services -match "ALsvc") 
    {
        Write-Host ========================================================================
        Write-Host ====================== kill Sophos services [$services] ================
        Write-Host ===============================[ Done ]=================================
				Write-Host "Stopping $services"
				Get-Process $services | Stop-Process -force
				Start-Sleep -s 5
        		write-host "Running uninstaller"
				Start-Process 'C:\Program Files\Sophos\Sophos Endpoint Agent\uninstallcli.exe'-Verb runAs

    }
   	else
    {
        Write-Host ========================================================================
        Write-Host ====================== kill Sophos services [$services] ================
        Write-Host ===============================[ Done ]=================================
				Write-Host "Stopping $services"
				Get-Process $services | Stop-Process -force
    }
}



If ( ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	do {
		do {
			write-host "================================================================"
			write-host "1 - Grant SophosAdministrator Access and rename SophosEd.sys"
			write-host "2 - Disable network adapters then reboots"
			write-host "3 - Modify Sophos Registry values - disable Tamper Protection"
			write-host "4 - Stop all sophos services, Uninstall Sophos, and renables network adapters."
			write-host ""
			write-host "X - Exit"
			write-host "================================================================"
			write-host -nonewline "Type your choice and press Enter: "
			
			$choice = read-host
			
			write-host ""
			
			$ok = $choice -match '^[1234x]+$'
			
			if ( -not $ok) { write-host "Invalid selection" }
		} until ( $ok )

		clear-host 
		switch -Regex ( $choice ) {
			"1"
			{
				write-host "You entered '1'"
				
				if ($checkrights -eq $u) {
					net localgroup Sophosadministrator
					write-host "$u already has SophosAdministrator"
					pause
				} else {
					net localgroup Sophosadministrator /add $u
					Write-Host "Adding $u to SophosAdministrator Group"
					pause
				}

				#Renaming the SophosED.sys to SophosED.sys.Bak
				write-host ""
				write-host ""
				write-host ""
				write-host "Renaming SophosEd"

				if ((Test-Path $sophosedpath) -and (!(Test-Path $sophosedpath+".bak"))) {
					Rename-Item -Force -Path $sophosedpath -NewName "SophosED.sys.bak"
					Write-Host "Renaming sophosED.sys to sophosed.sys.bak!!"
				} else {
					write-host "SophosED.sys not found"
				}

				ls C:\Windows\System32\drivers\SophosED*
			}

			"2"
			{
				write-host "You entered '2'"
				write-host ""
				write-host "Disable network adapters"
				write-host "============================="
				write-host ""
				#Turning off all netadapters
				$domainuser = whoami
				write-host "temporarily disabling network adapters"
				Disable-NetAdapter *
				write-host "Rebooting your machine to complete the uninstallation"
				Restart-Computer -confirm -credential $domainuser                

			}
			
			"3"
			{
				write-host "You entered '3'"
				write-host ""
				write-host "Modifying Sophos Registry"
				write-host "============================="
				write-host ""
				#disabletamper function
				disabletamper $sophosMCSA Start 4
				disabletamper $sophosEPD SAVEnabled 0
				disabletamper $sophosEPD SEDEnabled 0
				disabletamper $sophostamperprot Enabled 0                                              

			}

			"4"
			{
				write-host "You entered '4'"
				write-host ""
				write-host "Modifying Sophos Registry"
				write-host "============================="
				write-host ""
				write-host "uninstall sophos"
				ii $env:userprofile\AppData\Local\Temp\



<#				ALsvc = Sophos AutoUpdate Service
				Health = Sophos Health Service
				McsAgent = Sophos MCS Agent Services
				McsClient = Sophos MCS Client Services 
#>
				#Function
				removesophos ALsvc
				removesophos Health
				removesophos McsClient
				removesophos McsAgent



				#Re-enable net adapters
				pause
				Enable-NetAdapter *
				write-host "Please reboot to finalize the uninstallation"
			}
		}
		# X stops script
	} until ( $choice -match "X" )

} # Did you run powershell as admin?
ELSE{"Please Run PowerShell as Administrator"}