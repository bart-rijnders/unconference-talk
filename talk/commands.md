## Introduce the azure shell
az version
az --help

## Create resource group to hold our infrastructure
az group create --name unconference --location northeurope

## Create virtual network
az network vnet create -n unconference-vnet -g unconference --address-prefixes 192.168.0.0/16

## Create subnet
az network vnet subnet create -n unconference-site-subnet -g unconference --vnet-name unconference-vnet --address-prefixes 192.168.0.0/24

## Create a private VM on the network
az vm create --name birthday-host -g unconference --image debian --vnet-name unconference-vnet --subnet unconference-site-subnet --ssh-key-values ~/.ssh/ah_rsa_unconference.pub --authentication-type ssh --public-ip-address ""

## Create a public IP manually
az network public-ip create -n public-ip -g unconference

## Prepare our firewall for public access
az network nsg list -g unconference
az network nsg rule list -g unconference --nsg-name birthday-hostNSG
curl https://ipinfo.io/ip
az network nsg rule update -g unconference --nsg-name birthday-hostNSG -n default-allow-ssh  --source-address-prefixes 
az network nsg rule create -g unconference --nsg-name birthday-hostNSG -n allow-80 --priority 1010 --destination-port-ranges 80

## Assign public ip to our VMs network interface
az network nic ip-config update \
  --name ipconfigbirthday-host \
  --nic-name birthday-hostVMNic \
  --resource-group unconference \
  --public-ip-address public-ip

## Set up our VM
az network public-ip list -g unconference
ssh moro@
sudo su
sudo apt-get install nginx git -y
cd /var/www/html/
rm -Rf * && git clone https://github.com/bart-rijnders/birthday-wishes.git .

## Deploy a classic videogame as a container
az container create -g unconference --name wolfenstein3d --image srenkens/wolfenstein3d --dns-name-label unconference-wolfenstein --ports 80
az container show -g unconference --name wolfenstein3d --query "{FQDN:ipAddress.fqdn,ProvisioningState:provisioningState}"

## Create a Kubernetes cluster with Azure Kubernetes Services
cd ~/git/github/bart-rijnders/unconference-talk/terraform
terraform init

## Put the subscription id in here yourself
terraform import azurerm_resource_group.default /subscriptions/id/resourceGroups/unconference
terraform import azurerm_virtual_network.vnet /subscriptions/id/resourceGroups/unconference/providers/Microsoft.Network/virtualNetworks/unconference-vnet

terraform apply
watch az aks list -g unconference

## Get our Kubernetes cluster connection
az aks get-credentials --name unconference-k8s -g unconference
kubectx unconference-k8s

## Deploy our website unto Kubernetes
cd ~/git/github/bart-rijnders/unconference-talk/k8s
kubectl apply -f birthday-site.yaml
kubectl get pods

## Scale up!
az vmss list -g MC_unconference_unconference-k8s_northeurope
az vmss scale --new-capacity 10 -g MC_unconference_unconference-k8s_northeurope -n aks-default-15864464-vmss
kubectl get nodes

## Install a minecraft server using the helm package manager
kubectl create namespace minecraft
helm install minecraft itzg/minecraft --namespace minecraft -f minecraft.values.yaml
kubectl get svc --namespace minecraft -w minecraft-minecraft

## Scale down!
az vmss scale --new-capacity 2 -g MC_unconference_unconference-k8s_northeurope -n aks-default-15864464-vmss
