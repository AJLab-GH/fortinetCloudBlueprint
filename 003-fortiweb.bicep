/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  This Template File should NOT be MODIFIED - Please make all modifications via "MAIN.BICEP"                                     //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          PARAMETERS                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

param adminUsername string
@secure()
param adminPassword string
param deploymentPrefix string
param fortiWebImageSKU string
param fortiWebImageVersion string
param fortiWebHaGroupId int
param fortiWebAAdditionalCustomData string
param fortiWebBAdditionalCustomData string
param instanceType string
param availabilityOptions string
param acceleratedNetworking bool
param publicIPNewOrExistingOrNone string
param publicIPName string
param publicIPResourceGroup string
param publicIPType string
param vnetNewOrExisting string
param vnetName string
param vnetResourceGroup string
param subnet4StartAddress string
param subnet5Name string 
param subnet5Prefix string
param subnet5StartAddress string
param subnet6Name string
param subnet6Prefix string
param subnet6StartAddress string
param fwbserialConsole string
@secure()
param location string
param fortinetTags object
param vnetAddressPrefix string
param subnet7StartAddress string

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          VARIABLES                                                              //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var imagePublisher = 'fortinet'
var imageOffer = 'fortinet_fortiweb-vm_v5'
var var_availabilitySetName = '${deploymentPrefix}-FWB-AvailabilitySet'
var availabilitySetId = {
  id: availabilitySetName.id
}
var var_vnetName = ((vnetName == '') ? '${deploymentPrefix}-VNET' : vnetName)
var subnet5Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet5Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet5Name))
var subnet6Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet6Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet6Name))
var fwbGlobalDataBody = 'config system settings\n set enable-file-upload enable\n end\nconfig system admin\nedit admin\nset password Q1w2e34567890--\nend\n'
var fwbACustomDataBodyHA = 'config system ha\n set override enable\n set mode active-active-high-volume\n set group-id ${fortiWebHaGroupId}\n set group-name ${toLower(deploymentPrefix)}\n set priority 1\n set tunnel-local ${sn2IPfwbA}\n set tunnel-peer ${sn2IPfwbB}\n set monitor port1 port2\nend\n\n'
var fwbACustomDataBody = '${fwbGlobalDataBody}${fwbACustomDataBodyHA}${fwbACustomDataPreconfig}${fortiWebAAdditionalCustomData}\n'
var fwbACustomDataCombined = { 
  'cloud-initd' : 'enable'
  'usr-cli': fwbACustomDataBody
  }
var fwbACustomDataPreconfig = '${fwbCustomDataVIP}${fwbStaticRoute}${fwbServerPool}${configFortiGateIntegrationA}${letsEncrypt}${wvsProfile}${bulkPoCConfig}'
var fwbCustomDataVIP = '\nconfig system vip\n edit "WKLD_VIP"\n set vip ${reference(publicIPId).ipAddress}/32\n set interface port1\n next\n end\n'
var fwbStaticRoute = '\nconfig router static\n edit 1\n set dst ${vnetAddressPrefix}\n set gateway ${sn2GatewayIP}\n set device port2\n next\n end\n'
var fwbServerPool = '\nconfig server-policy server-pool\n edit "WKLD_POOL"\n config pserver-list\n edit 1\n set ip ${subnet7StartAddress}\n next\n end\n next\n end\n'
var configFortiGateIntegrationA = '\nconfig system fortigate-integration\nset address ${subnet4StartAddress}\nset port 443\nset protocol HTTPS\nset username ${adminUsername}\nset password ${adminPassword}\nset flag enable\nend\n'
var letsEncrypt = '\nconfig system certificate letsencrypt\nedit "WKLD_LE_CERTIFICATE"\nset domain ${deploymentPrefix}.${location}.cloudapp.azure.com\nset validation-method TLS-ALPN\nnext\nend\n'
var wvsProfile = '\nconfig wvs profile\nedit "WKLDSCANPROFILE"\nset scan-target https://${sn1IPfwbA}\nset scan-template "OWASP Top 10"\nset custom-header0 "Cookie: security=low; PHPSESSID=XXXXXXXXXXXXXXXXXXXX"\nset form-based-authentication enable\nset form-based-username pablo\nset form-based-password letmein\nset form-based-auth-url https://${sn1IPfwbA}/login.php\nset username-field username\nset password-field password\nset session-check-url https://10.0.5.5/index.php\nset session-check-string Welcome\nset data-format %u=%U&%p=%P\nnext\nend\n'
var bulkPoCConfig = loadTextContent('005-fortiwebCustomData.txt')

var fwbACustomData = base64(string(fwbACustomDataCombined))
var fwbBCustomDataBodyHA = 'config system ha\n set override enable\n set mode active-active-high-volume\n set group-id ${fortiWebHaGroupId}\n set group-name ${toLower(deploymentPrefix)}\n set priority 2\n set tunnel-local ${sn2IPfwbB}\n set tunnel-peer ${sn2IPfwbA}\n set monitor port1 port2\nend\n'
var fwbBCustomDataBody = '${fwbGlobalDataBody}${fwbBCustomDataBodyHA}${fwbBCustomDataPreconfig}${fortiWebBAdditionalCustomData}'
var fwbBCustomDataPreconfig = '${fwbCustomDataVIP}${fwbStaticRoute}${fwbServerPool}${configFortiGateIntegrationB}${letsEncrypt}${bulkPoCConfig}\n'
var fwbbCustomDataCombined = { 
  'cloud-initd': 'enable'
  'usr-cli': fwbBCustomDataBody
}
var fwbBCustomData = base64(string(fwbbCustomDataCombined))
var configFortiGateIntegrationB = '\nconfig system fortigate-integration\nset address ${subnet4StartAddress}\nset port 443\nset protocol HTTPS\nset username ${adminUsername}\nset password ${adminPassword}\nset flag enable\nend\n'
var var_fwbAVmName = '${deploymentPrefix}-FWB-A'
var var_fwbBVmName = '${deploymentPrefix}-FWB-B'
var var_fwbANic1Name = '${var_fwbAVmName}-Nic1'
var fwbANic1Id = fwbANic1Name.id
var var_fwbANic2Name = '${var_fwbAVmName}-Nic2'
var fwbANic2Id = fwbANic2Name.id
var var_fwbBNic1Name = '${var_fwbBVmName}-Nic1'
var fwbBNic1Id = fwbBNic1Name.id
var var_fwbBNic2Name = '${var_fwbBVmName}-Nic2'
var fwbBNic2Id = fwbBNic2Name.id
var var_serialConsoleStorageAccountName = 'fwbsc${uniqueString(resourceGroup().id)}'
var serialConsoleStorageAccountType = 'Standard_LRS'
var serialConsoleEnabled = ((fwbserialConsole == 'yes') ? true : false)
var var_publicIPName = ((publicIPName == '') ? '${deploymentPrefix}-FWB-PIP' : publicIPName)
var publicIPId = ((publicIPNewOrExistingOrNone == 'new') ? publicIPName_resource.id : resourceId(publicIPResourceGroup, 'Microsoft.Network/publicIPAddresses', var_publicIPName))
var publicIPAddressId = {
  id: publicIPId
}
var ilbProperties = {
  properties: {
    privateIPAddress: sn1IPlb
    privateIPAllocationMethod: 'Static'
    subnet: subnet5Id
  }
}
var elbProperties = {
  properties: {
    publicIPAddress: publicIPAddressId
  }
}
var var_NSGName = '${deploymentPrefix}-${uniqueString(resourceGroup().id)}-NSG'
var NSGId = NSGName.id
var sn1IPArray = split(subnet5Prefix, '.')
var sn1IPArray2 = string(int(sn1IPArray[2]))
var sn1IPArray1 = string(int(sn1IPArray[1]))
var sn1IPArray0 = string(int(sn1IPArray[0]))
var sn1IPStartAddress = split(subnet5StartAddress, '.')
var sn1IPfwbA = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${int(sn1IPStartAddress[3])}'
var sn1IPfwbB = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${(int(sn1IPStartAddress[3]) + 1)}'
var sn1IPlb = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${(int(sn1IPStartAddress[3]) - 1)}'
var sn2IPArray = split(subnet6Prefix, '.')
var sn2IPArray2 = string(int(sn2IPArray[2]))
var sn2IPArray1 = string(int(sn2IPArray[1]))
var sn2IPArray0 = string(int(sn2IPArray[0]))
var sn2IPStartAddress = split(subnet6StartAddress, '.')
var sn2GatewayIP = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${sn2IPArray3}'
var sn2IPArray3 = string((int(sn2IPArray2nd[0]) + 1))
var sn2IPArray2nd = split(sn2IPArray2ndString, '/')
var sn2IPArray2ndString = string(sn2IPArray[3])
var sn2IPfwbA = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${(int(sn2IPStartAddress[3]) + 1)}'
var sn2IPfwbB = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${(int(sn2IPStartAddress[3]) + 2)}'
var externalLBName_NatRule_FWBAdminPerm_fwbA = '${var_fwbAVmName}FWBAdminPerm'
var externalLBId_NatRule_FWBAdminPerm_fwbA = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', var_externalLBName, externalLBName_NatRule_FWBAdminPerm_fwbA)
var externalLBName_NatRule_SSH_fwbA = '${var_fwbAVmName}SSH'
var externalLBId_NatRule_SSH_fwbA = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', var_externalLBName, externalLBName_NatRule_SSH_fwbA)
var externalLBName_NatRule_FWBAdminPerm_fwbB = '${var_fwbBVmName}FWBAdminPerm'
var externalLBId_NatRule_FWBAdminPerm_fwbB = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', var_externalLBName, externalLBName_NatRule_FWBAdminPerm_fwbB)
var externalLBName_NatRule_SSH_fwbB = '${var_fwbBVmName}SSH'
var externalLBId_NatRule_SSH_fwbB = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', var_externalLBName, externalLBName_NatRule_SSH_fwbB)
var var_externalLBName = '${deploymentPrefix}-FWB-ELB'
var externalLBFEName = '${deploymentPrefix}-LB-${subnet5Name}-FrontEnd'
var externalLBFEId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations/', var_externalLBName, externalLBFEName)
var externalLBBEName = '${deploymentPrefix}-LB-${subnet5Name}-BackEnd'
var externalLBBEId = resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', var_externalLBName, externalLBBEName)
var externalLBProbeName = 'heatlhProbeHttp'
var externalLBProbeId = resourceId('Microsoft.Network/loadBalancers/probes/', var_externalLBName, externalLBProbeName)
var externalLBProbe2Name = 'heatlhProbeHttps'
var externalLBProbe2Id = resourceId('Microsoft.Network/loadBalancers/probes/', var_externalLBName, externalLBProbe2Name)
var useAZ = ((!empty(pickZones('Microsoft.Compute', 'virtualMachines', location))) && (availabilityOptions == 'Availability Zones'))
var var_internalLBName = '${deploymentPrefix}-FWB-ILB'
var internalLBFEName = '${deploymentPrefix}-ILB-${subnet5Name}-FrontEnd'
var internalLBFEId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', var_internalLBName, internalLBFEName)
var internalLBBEName = '${deploymentPrefix}-ILB-${subnet5Name}-BackEnd'
var internalLBBEId = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', var_internalLBName, internalLBBEName)
var internalLBProbeName = 'lbprobe'
var internalLBProbeId = resourceId('Microsoft.Network/loadBalancers/probes', var_internalLBName, internalLBProbeName)
var zone1 = [
  '1'
]
var zone2 = [
  '2'
]

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          RESOURCES                                                              //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource serialConsoleStorageAccountName 'Microsoft.Storage/storageAccounts@2021-02-01' = if (fwbserialConsole == 'yes') {
  name: var_serialConsoleStorageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: serialConsoleStorageAccountType
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2021-07-01' = if (!useAZ) {
  name: var_availabilitySetName
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource NSGName 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_NSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSHInbound'
        properties: {
          description: 'Allow SSH In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          description: 'Allow 80 In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPSInbound'
        properties: {
          description: 'Allow 443 In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowDevRegInbound'
        properties: {
          description: 'Allow 514 in for device registration'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '514'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowMgmtHTTPInbound'
        properties: {
          description: 'Allow 8080 In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowMgmtHTTPSInbound'
        properties: {
          description: 'Allow 8443 In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 150
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAllOutbound'
        properties: {
          description: 'Allow all out'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 105
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource publicIPName_resource 'Microsoft.Network/publicIPAddresses@2022-05-01' = if (publicIPNewOrExistingOrNone == 'new') {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_publicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: publicIPType
    dnsSettings: {
      domainNameLabel: toLower(deploymentPrefix)
    }
  }
}

resource externalLBName 'Microsoft.Network/loadBalancers@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_externalLBName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: externalLBFEName
        properties: ((publicIPNewOrExistingOrNone == 'none') ? ilbProperties.properties : elbProperties.properties)
      }
    ]
    backendAddressPools: [
      {
        name: externalLBBEName
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          backendAddressPool: {
            id: externalLBBEId
          }
          probe: {
            id: externalLBProbeId
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
        }
        name: 'PublicLBRule-FE1-http'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          backendAddressPool: {
            id: externalLBBEId
          }
          probe: {
            id: externalLBProbe2Id
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
        }
        name: 'PublicLBRule-FE1-https'
      }
    ]
    inboundNatRules: [
      {
        name: externalLBName_NatRule_SSH_fwbA
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          protocol: 'Tcp'
          frontendPort: 50030
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: externalLBName_NatRule_FWBAdminPerm_fwbA
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          protocol: 'Tcp'
          frontendPort: 40030
          backendPort: 8443
          enableFloatingIP: false
        }
      }
      {
        name: externalLBName_NatRule_SSH_fwbB
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          protocol: 'Tcp'
          frontendPort: 50031
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: externalLBName_NatRule_FWBAdminPerm_fwbB
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          protocol: 'Tcp'
          frontendPort: 40031
          backendPort: 8443
          enableFloatingIP: false
        }
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 8080
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: externalLBProbeName
      }
      {
        properties: {
          protocol: 'Tcp'
          port: 8443
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: externalLBProbe2Name
      }
    ]
  }
}

resource internalLBName 'Microsoft.Network/loadBalancers@2020-04-01' = {
  name: var_internalLBName
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: internalLBFEName
        properties: {
          privateIPAddress: sn1IPlb
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet5Id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: internalLBBEName
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: internalLBFEId
          }
          backendAddressPool: {
            id: internalLBBEId
          }
          probe: {
            id: internalLBProbeId
          }
          protocol: 'All'
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
        }
        name: 'lbruleFEall'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
  dependsOn: [
  ]
}

resource fwbANic1Name 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbANic1Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn1IPfwbA
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet5Id
          }
          loadBalancerBackendAddressPools: [
            {
              id: externalLBBEId
            }
            {
              id: internalLBBEId
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: externalLBId_NatRule_SSH_fwbA
            }
            {
              id: externalLBId_NatRule_FWBAdminPerm_fwbA
            }
          ]
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: NSGId
    }
  }
  dependsOn: [
    externalLBName
    internalLBName
  ]
}

resource fwbBNic1Name 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbBNic1Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn1IPfwbB
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet5Id
          }
          loadBalancerBackendAddressPools: [
            {
              id: externalLBBEId
            }
            {
              id: internalLBBEId
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: externalLBId_NatRule_SSH_fwbB
            }
            {
              id: externalLBId_NatRule_FWBAdminPerm_fwbB
            }
          ]
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: NSGId
    }
  }
  dependsOn: [
    externalLBName
    internalLBName
  ]
}

resource fwbANic2Name 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbANic2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: sn2IPfwbA
          subnet: {
            id: subnet6Id
          }
        }
      }
    ]
    enableIPForwarding: false
    enableAcceleratedNetworking: acceleratedNetworking
  }
}

resource fwbBNic2Name 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbBNic2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: sn2IPfwbB
          subnet: {
            id: subnet6Id
          }
        }
      }
    ]
    enableIPForwarding: false
    enableAcceleratedNetworking: acceleratedNetworking
  }
}

resource fwbAVmName 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbAVmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  zones: (useAZ ? zone1 : null)
  plan: {
    name: fortiWebImageSKU
    publisher: imagePublisher
    product: imageOffer
  }
  properties: {
    hardwareProfile: {
      vmSize: instanceType
    }
    availabilitySet: ((!useAZ) ? availabilitySetId : null)
    osProfile: {
      computerName: var_fwbAVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: fwbACustomData
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: fortiWebImageSKU
        version: fortiWebImageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 30
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: fwbANic1Id
        }
        {
          properties: {
            primary: false
          }
          id: fwbANic2Id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: serialConsoleEnabled
        storageUri: ((fwbserialConsole == 'yes') ? reference(var_serialConsoleStorageAccountName, '2021-08-01').primaryEndpoints.blob : null)
      }
    }
  }
}

resource fwbBVmName 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: var_fwbBVmName
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  zones: (useAZ ? zone2 : null)
  plan: {
    name: fortiWebImageSKU
    publisher: imagePublisher
    product: imageOffer
  }
  properties: {
    hardwareProfile: {
      vmSize: instanceType
    }
    availabilitySet: ((!useAZ) ? availabilitySetId : null)
    osProfile: {
      computerName: var_fwbBVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: fwbBCustomData
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: fortiWebImageSKU
        version: fortiWebImageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 30
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: fwbBNic1Id
        }
        {
          properties: {
            primary: false
          }
          id: fwbBNic2Id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: serialConsoleEnabled
        storageUri: ((fwbserialConsole == 'yes') ? reference(var_serialConsoleStorageAccountName, '2021-08-01').primaryEndpoints.blob : null)
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          OUTPUTS                                                                //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output fortiWebPublicIP string = ((publicIPNewOrExistingOrNone == 'new') ? reference(publicIPId).dnsSettings.fqdn : '')
output fwbACustomData string = fwbACustomData
output fwbBCustomData string = fwbBCustomData
output fwbACustomDataPreconfig string = fwbACustomDataPreconfig




