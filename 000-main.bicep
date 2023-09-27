/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//  This is the MAIN deployment file. Any changes or modification of parameters should ONLY be performed in this file              //
//                                                                                                                                 //
//                                                                                                                                 //
//  Deployment Commands:                                                                                                           //
//  az group create --location <location> --name <resourceGroupName>                                                               //
//  az deployment group create --name <deploymentName> --resource-group <resourceGroupName> --template-file main.bicep             //
//  az deployment group show  -g <resourceGroupName>   -n <deploymentName>  --query properties.outputs                             //
//                                                                                                                                 //
//  Navigation:                                                                                                                    //
//  to jump to Network Portion "CTRL + F" for 123                                                                                  //
//  to jump to FortiGate Portion "CTRL + F" for 456                                                                                //
//  to jump to FortiWeb Portion "CTRL + F" for 789                                                                                 //
//  to jump to WKLD Portion "CTRL + F" for 101112                                                                                  //
//  to jump to Modules Portion "CTRL + F" for 131415                                                                               //
//  to jump to Outputs Portion "CTRL + F" for 161718                                                                               //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters impact which Modules are Deployed                                                                     //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description ('Do you want to deploy a FortiWeb as a part of this Template (Y/N)')
@allowed([
  'yes'
  'no'
])
param deployFortiWeb string = 'yes'

@description ('Do you want to deploy a WKLD Instance as a part of this Template (Y/N)')
@allowed([
  'yes'
  'no'
])
param deployWKLD string = 'yes'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//  The Following Parameters will be asked in the form of a prompt when running main.bicep via AZ CLI (az deployment group create) //
//                                                                                                                                 //
//                                                                                                                                 //
//   NOTES:                                                                                                                        // 
//   1). The Deployment Prefix will be used throughout the deployment                                                              //
//   2). The same Username and Password will be applied to the FortiGate(s), FortiWeb(s) and WKLD appliance                        //
//       and can be changed post-deployment                                                                                        //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Username for the FortiGate VM')
param adminUsername string

@description('Password for the FortiGate VM')
@secure()
param adminPassword string

@description('Naming prefix for all deployed resources.')
param deploymentPrefix string

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values used globally                                                             //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

param location string = resourceGroup().location

param fortinetTags object = {
  publisher: 'Fortinet'
  template: 'Canadian Fortinet Architecture Blueprint'
  provider: '6EB3B02F-50E5-4A3E-8CB8-2E12925831AP'
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values will be pushed down to the Network Template                               //
//                                                                                                                                 //
//                                                                                                                          123    //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Identify whether to use a new or existing vnet')
@allowed([
  'new'
  'existing'
])
param vnetNewOrExisting string = 'new'

@description('Name of the Azure virtual network, required if utilizing and existing VNET. If no name is provided the default name will be the Resource Group Name as the Prefix and \'-VNET\' as the suffix')
param vnetName string = ''

@description('Resource Group containing the existing virtual network, leave blank if a new VNET is being utilized')
param vnetResourceGroup string = ''

@description('Virtual Network Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet 1 Name')
param subnet1Name string = 'FGExternal'

@description('Subnet 1 Prefix')
param subnet1Prefix string = '10.0.1.0/24'

@description('Subnet 1 start address, 2 consecutive private IPs are required')
param subnet1StartAddress string = '10.0.1.5'

@description('Subnet 2 Name')
param subnet2Name string = 'FGInternal'

@description('Subnet 2 Prefix')
param subnet2Prefix string = '10.0.2.0/24'

@description('Subnet 2 start address, 3 consecutive private IPs are required')
param subnet2StartAddress string = '10.0.2.4'

@description('Subnet 3 Name')
param subnet3Name string = 'FGHA'

@description('Subnet 3 Prefix')
param subnet3Prefix string = '10.0.3.0/24'

@description('Subnet 3 start address, 2 consecutive private IPs are required')
param subnet3StartAddress string = '10.0.3.5'

@description('Subnet 4 Name')
param subnet4Name string = 'FGMgmt'

@description('Subnet 4 Prefix')
param subnet4Prefix string = '10.0.4.0/24'

@description('Subnet 4 start address, 2 consecutive private IPs are required')
param subnet4StartAddress string = '10.0.4.5'

@description('Subnet 5 Name')
param subnet5Name string = 'FWBExternal'

@description('Subnet 5 Prefix')
param subnet5Prefix string = '10.0.5.0/24'

@description('Subnet 5 start address, 3 consecutive private IPs are required')
param subnet5StartAddress string = '10.0.5.5'

@description('Subnet 6 Name')
param subnet6Name string = 'FWBInternal'

@description('Subnet 6 Prefix')
param subnet6Prefix string = '10.0.6.0/24'

@description('Subnet 6 start address, 2 consecutive private IPs are required')
param subnet6StartAddress string = '10.0.6.4'

@description('Subnet 7 Name')
param subnet7Name string = 'DMZProtectedA'

@description('Subnet 7 Prefix')
param subnet7Prefix string = '10.0.10.0/24'   

@description('Subnet 7 start address, 1 consecutive private IPs are required')
param subnet7StartAddress string = '10.0.10.7'

@description('Define the IP address range of your on-premise x.x.x.x/x')
param onPremRange string = '172.16.0.0/16'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values will be pushed down to the FortiGate Template                             //
//                                                                                                                                 //
//                                                                                                                          456    //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Identifies whether to to use PAYG (on demand licensing) or BYOL license model (where license is purchased separately)')
@allowed([
  'fortinet_fg-vm'
  'fortinet_fg-vm_payg_2022'
])
param fortiGateImageSKU string = 'fortinet_fg-vm_payg_2022'

@description('Select the image version')
@allowed([
'7.0.12'
'7.2.5'
'7.4.0'
'latest'
])
param fortiGateImageVersion string = 'latest'

@description('The ARM template provides a basic configuration. Additional configuration can be added here.')
param fortiGateAdditionalCustomData string = ''

@description('Virtual Machine size selection - must be F4 or other instance that supports 4 NICs')
@allowed([
  'Standard_F2s'
  'Standard_F4s'
  'Standard_F8s'
  'Standard_F16s'
  'Standard_F2'
  'Standard_F4'
  'Standard_F8'
  'Standard_F16'
  'Standard_F2s_v2'
  'Standard_F4s_v2'
  'Standard_F8s_v2'
  'Standard_F16s_v2'
  'Standard_F32s_v2'
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D2_v4'
  'Standard_D4_v4'
  'Standard_D8_v4'
  'Standard_D16_v4'
  'Standard_D32_v4'
  'Standard_D2s_v4'
  'Standard_D4s_v4'
  'Standard_D8s_v4'
  'Standard_D16s_v4'
  'Standard_D32s_v4'
  'Standard_D2a_v4'
  'Standard_D4a_v4'
  'Standard_D8a_v4'
  'Standard_D16a_v4'
  'Standard_D32a_v4'
  'Standard_D2as_v4'
  'Standard_D4as_v4'
  'Standard_D8as_v4'
  'Standard_D16as_v4'
  'Standard_D32as_v4'
  'Standard_D2_v5'
  'Standard_D4_v5'
  'Standard_D8_v5'
  'Standard_D16_v5'
  'Standard_D32_v5'
  'Standard_D2s_v5'
  'Standard_D4s_v5'
  'Standard_D8s_v5'
  'Standard_D16s_v5'
  'Standard_D32s_v5'
  'Standard_D2as_v5'
  'Standard_D4as_v5'
  'Standard_D8as_v5'
  'Standard_D16as_v5'
  'Standard_D32as_v5'
  'Standard_D2ads_v5'
  'Standard_D4ads_v5'
  'Standard_D8ads_v5'
  'Standard_D16ads_v5'
  'Standard_D32ads_v5'
])
param instanceType string = 'Standard_F4s'

@description('Deploy FortiGate VMs in an Availability Set or Availability Zones. If Availability Zones deployment is selected but the location does not support Availability Zones an Availability Set will be deployed. If Availability Zones deployment is selected and Availability Zones are available in the location, FortiGate A will be placed in Zone 1, FortiGate B will be placed in Zone 2')
@allowed([
  'Availability Set'
  'Availability Zones'
])
param availabilityOptions string = 'Availability Set'

@description('Accelerated Networking enables direct connection between the VM and network card. Only available on 2 CPU F/Fs and 4 CPU D/Dsv2, D/Dsv3, E/Esv3, Fsv2, Lsv2, Ms/Mms and Ms/Mmsv2')
@allowed([
  false
  true
])
param acceleratedNetworking bool = true

@description('Public IP for the Load Balancer for inbound and outbound data of the FortiGate VMs')
@allowed([
  'new'
  'existing'
])
param publicIP1NewOrExisting string = 'new'

@description('Name of Public IP address, if no name is provided the default name will be the Resource Group Name as the Prefix and \'-FGT-PIP\' as the suffix')
param publicIP1Name string = ''

@description('Public IP Resource Group, this value is required if an existing Public IP is selected')
param publicIP1ResourceGroup string = ''

@description('Public IP for management of the FortiGate A. This deployment uses a Standard SKU Azure Load Balancer and requires a Standard SKU public IP. Microsoft Azure offers a migration path from a basic to standard SKU public IP. The management IP\'s for both FortiGate can be set to none. If no alternative internet access is provided, the SDN Connector functionality for dynamic objects will not work.')
@allowed([
  'new'
  'existing'
  'none'
])
param publicIP2NewOrExisting string = 'new'

@description('Name of Public IP address, if no name is provided the default name will be the Resource Group Name as the Prefix and \'-FGT-A-MGMT-PIP\' as the suffix')
param publicIP2Name string = ''

@description('Public IP Resource Group, this value is required if an existing Public IP is selected')
param publicIP2ResourceGroup string = ''

@description('Public IP for management of the FortiGate B. This deployment uses a Standard SKU Azure Load Balancer and requires a Standard SKU public IP. Microsoft Azure offers a migration path from a basic to standard SKU public IP. The management IP\'s for both FortiGate can be set to none. If no alternative internet access is provided, the SDN Connector functionality for both HA failover and dynamic objects will not work.')
@allowed([
  'new'
  'existing'
  'none'
])
param publicIP3NewOrExisting string = 'new'

@description('Name of Public IP address, if no name is provided the default name will be the Resource Group Name as the Prefix and \'-FGT-B-MGMT-PIP\' as the suffix')
param publicIP3Name string = ''

@description('Public IP Resource Group, this value is required if an existing Public IP is selected')
param publicIP3ResourceGroup string = ''

@description('Enable Serial Console on the FortiGates')
@allowed([
  'yes'
  'no'
])
param fgtserialConsole string = 'yes'

@description('Connect to FortiManager')
@allowed([
  'yes'
  'no'
])
param fortiManager string = 'no'

@description('FortiManager IP or DNS name to connect to on port TCP/541')
param fortiManagerIP string = ''

@description('FortiManager serial number to add the deployed FortiGate into the FortiManager')
param fortiManagerSerial string = ''

@description('Primary FortiGate BYOL license content')
param fortiGateLicenseBYOLA string = ''

@description('Secondary FortiGate BYOL license content')
param fortiGateLicenseBYOLB string = ''

@description('Primary FortiGate BYOL Flex-VM license token')
param fortiGateLicenseFlexVMA string = ''

@description('Secondary FortiGate BYOL Flex-VM license token')
param fortiGateLicenseFlexVMB string = ''

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values will be pushed down to the FortiWeb Template                              //
//                                                                                                                                 //
//                                                                                                                          789    //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Identifies whether to to use PAYG (on demand licensing) or BYOL license model (where license is purchased separately)')
@allowed([
  'fortinet_fw-vm'
  'fortinet_fw-vm_payg_v2'
])
param fortiWebImageSKU string = 'fortinet_fw-vm_payg_v2'

@description('FortiWeb versions available in the Azure Marketplace. Additional version can be downloaded via https://support.fortinet.com/')
@allowed([
  '7.0.0'
  '7.0.3'
  '7.0.5'
  '7.2.0'
  'latest'
])
param fortiWebImageVersion string = 'latest'

@description('Type a group id that identifies of HA cluster. Mininum is 0, Maximum is 63.')
@minValue(0)
@maxValue(63)
param fortiWebHaGroupId int = 1

@description('The ARM template provides a basic configuration. Additional configuration can be added here.')
param fortiWebAAdditionalCustomData string = ''

@description('The ARM template provides a basic configuration. Additional configuration can be added here.')
param fortiWebBAdditionalCustomData string = ''

@description('Public IP for the Load Balancer for inbound and outbound data of the FortiWeb VMs')
@allowed([
  'new'
  'existing'
  'none'
])
param publicIPNewOrExistingOrNone string = 'new'

@description('Name of Public IP address element.')
param publicIPName string = 'FWBAPClusterPublicIP'

@description('Resource group to which the Public IP belongs.')
param publicIPResourceGroup string = ''

@description('Type of public IP address')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPType string = 'Static'

@description('Enable Serial Console on the FortiWeb')
@allowed([
  'yes'
  'no'
])
param fwbserialConsole string = 'yes'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values will be pushed down to the WKLD Template                                  //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Enable Serial Console on the WKLD')
@allowed([
  'yes'
  'no'
])
param wkldserialConsole string = 'yes'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Modules are Responsible for the Deployment the Network, FortiGate and FortiWeb Bicep Files.                      //
//  These values should NOT be modified.                                                                                           //
//                                                                                                                                 //
//                                                                                                                       131415    //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module networkTemplate '001-network.bicep' = {
  name: 'networkDeployment'
  params: {
    deploymentPrefix: deploymentPrefix
    fortinetTags: fortinetTags   
    location: location
    subnet1Name: subnet1Name
    subnet1Prefix: subnet1Prefix
    subnet2Name: subnet2Name
    subnet2Prefix: subnet2Prefix
    subnet2StartAddress: subnet2StartAddress
    subnet3Name: subnet3Name
    subnet3Prefix: subnet3Prefix
    subnet4Name: subnet4Name
    subnet4Prefix: subnet4Prefix
    subnet5Name: subnet5Name 
    subnet5Prefix: subnet5Prefix
    subnet6Name: subnet6Name
    subnet6Prefix: subnet6Prefix
    subnet7Name: subnet7Name
    subnet7Prefix: subnet7Prefix
    vnetAddressPrefix: vnetAddressPrefix
    vnetName: vnetName
    vnetNewOrExisting: vnetNewOrExisting
    onPremRange: onPremRange
      }
}

module fortiGateTemplate '002-fortigate.bicep' = {
  name: 'fortigateDeployment'
  params: {
    subnet7StartAddress: subnet7StartAddress
    acceleratedNetworking: acceleratedNetworking
    adminPassword: adminPassword
    adminUsername: adminUsername
    availabilityOptions: availabilityOptions
    deploymentPrefix: deploymentPrefix
    fortiGateAdditionalCustomData: fortiGateAdditionalCustomData
    fortiGateImageSKU: fortiGateImageSKU
    fortiGateImageVersion: fortiGateImageVersion
    fortiGateLicenseBYOLA: fortiGateLicenseBYOLA
    fortiGateLicenseBYOLB: fortiGateLicenseBYOLB
    fortiGateLicenseFlexVMA: fortiGateLicenseFlexVMA
    fortiGateLicenseFlexVMB: fortiGateLicenseFlexVMB
    fortiManager: fortiManager
    fortiManagerIP: fortiManagerIP
    fortiManagerSerial: fortiManagerSerial
    fortinetTags: fortinetTags
    instanceType: instanceType
    location: location
    publicIP1Name: publicIP1Name
    publicIP1NewOrExisting: publicIP1NewOrExisting
    publicIP1ResourceGroup: publicIP1ResourceGroup
    publicIP2Name: publicIP2Name
    publicIP2NewOrExisting: publicIP2NewOrExisting
    publicIP2ResourceGroup: publicIP2ResourceGroup
    publicIP3Name: publicIP3Name
    publicIP3NewOrExisting: publicIP3NewOrExisting
    publicIP3ResourceGroup: publicIP3ResourceGroup
    fgtserialConsole: fgtserialConsole
    subnet1Name: subnet1Name
    subnet1Prefix: subnet1Prefix
    subnet1StartAddress: subnet1StartAddress
    subnet2Name: subnet2Name
    subnet2Prefix: subnet2Prefix
    subnet2StartAddress: subnet2StartAddress
    subnet3Name: subnet3Name
    subnet3Prefix: subnet3Prefix
    subnet3StartAddress: subnet3StartAddress
    subnet4Name: subnet4Name
    subnet4Prefix: subnet4Prefix
    subnet4StartAddress: subnet4StartAddress
    vnetAddressPrefix: vnetAddressPrefix
    vnetName: vnetName
    vnetNewOrExisting: vnetNewOrExisting
    vnetResourceGroup: vnetResourceGroup
}
  dependsOn: [
    networkTemplate
  ]
}

module fortiWebTemplate '003-fortiweb.bicep' = if (deployFortiWeb == 'yes') {
  name: 'fortiwebDeployment'
  params: {
    subnet4StartAddress: subnet4StartAddress
    subnet7StartAddress: subnet7StartAddress
    vnetAddressPrefix: vnetAddressPrefix
    acceleratedNetworking: acceleratedNetworking
    adminPassword: adminPassword
    adminUsername: adminUsername
    availabilityOptions: availabilityOptions
    deploymentPrefix: deploymentPrefix
    fortinetTags: fortinetTags
    fortiWebAAdditionalCustomData:fortiWebAAdditionalCustomData
    fortiWebBAdditionalCustomData:fortiWebBAdditionalCustomData
    fortiWebHaGroupId: fortiWebHaGroupId
    fortiWebImageSKU: fortiWebImageSKU
    fortiWebImageVersion: fortiWebImageVersion
    fwbserialConsole: fwbserialConsole
    instanceType: instanceType
    location: location
    publicIPName: publicIPName
    publicIPNewOrExistingOrNone: publicIPNewOrExistingOrNone
    publicIPResourceGroup: publicIPResourceGroup
    publicIPType: publicIPType
    subnet5Name: subnet5Name
    subnet5Prefix: subnet5Prefix
    subnet5StartAddress: subnet5StartAddress
    subnet6Name: subnet6Name
    subnet6Prefix:subnet6Prefix 
    subnet6StartAddress: subnet6StartAddress
    vnetName:vnetName 
    vnetNewOrExisting: vnetNewOrExisting
    vnetResourceGroup: vnetResourceGroup
     }
  dependsOn: [
    networkTemplate
  ]
}

module wkldTemplate '004-wkld.bicep' = if (deployWKLD == 'yes') {
  name: 'wkldDeployment'
  params: {
    adminPassword: adminPassword
    adminUsername:  adminUsername
    deploymentPrefix: deploymentPrefix 
    location: location
    subnet7Name: subnet7Name
    subnet7Prefix: subnet7Prefix
    subnet7StartAddress: subnet7StartAddress
    vnetName: vnetName
    vnetNewOrExisting: vnetNewOrExisting
    vnetResourceGroup: vnetResourceGroup
    wkldserialConsole: wkldserialConsole
  }
  dependsOn: [
    fortiGateTemplate
  ]
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//                      The following portion of the template is responsible for Output generation                                 //
//                      To Output these Values please Run:                                                                         //
//                                                                                                                                 //
//                      az deployment group show  -g <resourceGroupName>   -n <deploymentName>  --query properties.outputs         //
//                                                                                                                                 //
//                                                                                                                       161718    //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output wkldSSH string = '${fortiGateTemplate.outputs.fortiGatePublicIP}:22'
output wkldHTTP string = 'http://${fortiWebTemplate.outputs.fortiWebPublicIP}:80'
output fortiGateAManagementConsole string = 'https://${fortiGateTemplate.outputs.fortiGateAManagementPublicIP}:443'
output fortiGateBManagementConsole string = 'https://${fortiGateTemplate.outputs.fortiGateBManagementPublicIP}:443'
output fortiWebAManagementConsole string = 'https://${fortiWebTemplate.outputs.fortiWebPublicIP}:40030'
output fortiWebBManagementConsole string = 'https://${fortiWebTemplate.outputs.fortiWebPublicIP}:40031'

