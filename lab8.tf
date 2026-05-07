RG="az104-rg8"
LOCATION="eastus"
USERNAME="localadmin"
PASSWORD="AzurePass123!"

az group create \
  --name $RG \
  --location $LOCATION

az vm create \
  --resource-group $RG \
  --name az104-vm1 \
  --image Win2025Datacenter \
  --size Standard_D2s_v3 \
  --admin-username $USERNAME \
  --admin-password $PASSWORD \
  --zone 1 \
  --public-ip-sku Standard \
  --nsg-rule NONE

az vm create \
  --resource-group $RG \
  --name az104-vm2 \
  --image Win2025Datacenter \
  --size Standard_D2s_v3 \
  --admin-username $USERNAME \
  --admin-password $PASSWORD \
  --zone 2 \
  --public-ip-sku Standard \
  --nsg-rule NONE

az vm resize \
  --resource-group $RG \
  --name az104-vm1 \
  --size Standard_D2ds_v4

az disk create \
  --resource-group $RG \
  --name vm1-disk1 \
  --size-gb 32 \
  --sku Standard_LRS

az vm disk attach \
  --resource-group $RG \
  --vm-name az104-vm1 \
  --name vm1-disk1

az vm disk detach \
  --resource-group $RG \
  --vm-name az104-vm1 \
  --name vm1-disk1

az disk update \
  --resource-group $RG \
  --name vm1-disk1 \
  --sku StandardSSD_LRS

az vm disk attach \
  --resource-group $RG \
  --vm-name az104-vm1 \
  --name vm1-disk1

az network vnet create \
  --resource-group $RG \
  --name vmss-vnet \
  --address-prefix 10.82.0.0/20 \
  --subnet-name subnet0 \
  --subnet-prefix 10.82.0.0/24

az network nsg create \
  --resource-group $RG \
  --name vmss1-nsg

az network nsg rule create \
  --resource-group $RG \
  --nsg-name vmss1-nsg \
  --name allow-http \
  --priority 1010 \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --source-address-prefix "*" \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 80

az vmss create \
  --resource-group $RG \
  --name vmss1 \
  --image Win2025Datacenter \
  --admin-username $USERNAME \
  --admin-password $PASSWORD \
  --instance-count 2 \
  --vm-sku Standard_D2s_v3 \
  --zones 1 2 3 \
  --vnet-name vmss-vnet \
  --subnet subnet0 \
  --nsg vmss1-nsg \
  --lb vmss-lb \
  --orchestration-mode Uniform \
  --upgrade-policy-mode automatic

VMSS_ID=$(az vmss show \
  --resource-group $RG \
  --name vmss1 \
  --query id \
  --output tsv)

az monitor autoscale create \
  --resource-group $RG \
  --resource $VMSS_ID \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name vmss-autoscale \
  --min-count 2 \
  --max-count 10 \
  --count 2

az monitor autoscale rule create \
  --resource-group $RG \
  --autoscale-name vmss-autoscale \
  --condition "Percentage CPU > 70 avg 10m" \
  --scale out 50%

az monitor autoscale rule create \
  --resource-group $RG \
  --autoscale-name vmss-autoscale \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 50%

az vmss list-instances \
  --resource-group $RG \
  --name vmss1 \
  --output table