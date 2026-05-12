<#
  - GOAL: easily deploy a VM using a template and a cloud init file
  - PREREQUISITES:
      - follow the directory structure 
      - create a VM in hyper-v  and install an OS on it. Make any required changes and then remove any device-specific information
      - detach the vhdx and store it in the $Template path 
      - adjust VLAN or make adjustments to script if not applicable
      - prepare a CloudInit configuration --- userdata and metadata 
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory =$false)] 
    [string]$cloudInitFileName
)


$Template  = "V:\Templates\Ubuntu-Template.vhdx"
$VMFolder  = "V:\Virtual Machines\$VMName"
$VHDXPath  = "$VMFolder\$VMName.vhdx"
$vmVLAN    = 4

$cloudInitDir  = "C:\ISOs\CloudInit" 


# --- Validate paths ---
if (-not (Test-Path $cloudInitDir)) { throw "ERROR: Cloud-init directory not found: $cloudInitDir" }
if (-not (Test-Path $Template))     { throw "ERROR: Template VHDX not found: $Template" }

# --- Prompt for cloud-init ISO if not provided
if (-not $cloudInitFileName) {
    Write-Host "`nAvailable cloud-init ISOs in $cloudInitDir :" -ForegroundColor Cyan
    Get-ChildItem -Path $cloudInitDir -Filter "*.iso" | ForEach-Object {
        Write-Host "  - $($_.Name)"
    }
    $cloudInitFileName = Read-Host "`nEnter cloud-init ISO filename"
    if (-not $cloudInitFileName) { throw "ERROR: cloud-init filename is required." }
}

$cloudInitFile = "$cloudInitDir\$cloudInitFileName"

# -- will catch error 
if (-not (Test-Path $CloudInitFile)) { throw "ERROR: Cloud-init File not found: $CloudInitFile" }

# Create VM folder and copy template disk
New-Item -ItemType Directory -Path $VMFolder
Copy-Item $Template $VHDXPath

# Create the VM
New-VM -Name $VMName `
       -Generation 2 `
       -MemoryStartupBytes 2GB `
       -VHDPath $VHDXPath `
       -SwitchName "Broadcom NetXtreme 5720 Dual Port Gigabit PCIe Adapter #2 - Virtual Switch"


# Disable Secure Boot
Set-VMFirmware -VMName $VMName `
               -SecureBootTemplate MicrosoftUEFICertificateAuthority

# Set CPUs
Set-VMProcessor -VMName $VMName -Count 2

# Set the Right VLAN
Set-VMNetworkAdapterVlan -VMName $VMName -Access -VlanId $vmVLAN

# Set the Cloud Init
Add-VMDvdDrive -VMName $VMName -Path "$cloudInitFile"
