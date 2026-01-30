$CONSUL_VERSION = "1.22.2+ent"
$NOMAD_VERSION = "1.11.1+ent"
$COREDNS_VERSION = "v1.14.1"

$CONSUL_PATH = "C:\consul"
$CONSUL_CONFIG_PATH = "C:\consul\config"
$CONSUL_DATA_PATH = "C:\consul\data"
$CONSUL_CERTS_PATH = "C:\consul\certs"


$NOMAD_PATH = "C:\nomad"
$NOMAD_CONFIG_PATH = "C:\nomad\config"
$NOMAD_DATA_PATH = "C:\nomad\data"
$NOMAD_CERTS_PATH = "C:\nomad\certs"
$NOMAD_PLUGINS_PATH = "C:\nomad\plugins"

$COREDNS_PATH = "C:\coredns"

# Configure firewall rules
Start-Process -FilePath C:\Windows\System32\netsh.exe -ArgumentList "advfirewall set publicprofile state off"

mkdir $CONSUL_PATH
mkdir $CONSUL_CONFIG_PATH
mkdir $CONSUL_DATA_PATH
mkdir $CONSUL_CERTS_PATH

mkdir $NOMAD_PATH
mkdir $NOMAD_CONFIG_PATH
mkdir $NOMAD_DATA_PATH
mkdir $NOMAD_CERTS_PATH
mkdir $NOMAD_PLUGINS_PATH

mkdir $COREDNS_PATH



# Download Consul    
cd $CONSUL_PATH

$Url = "https://releases.hashicorp.com/consul/$CONSUL_VERSION/consul_${CONSUL_VERSION}_windows_amd64.zip"

Invoke-WebRequest -Uri $Url -OutFile "consul.zip" -UseBasicParsing

Expand-Archive -Path consul.zip -DestinationPath .

# Download Nomad    
cd $NOMAD_PATH

$Url = "https://releases.hashicorp.com/nomad/$NOMAD_VERSION/nomad_${NOMAD_VERSION}_windows_amd64.zip"

Invoke-WebRequest -Uri $Url -OutFile "nomad.zip" -UseBasicParsing

Expand-Archive -Path nomad.zip -DestinationPath .


# Download CoreDNS    
cd $COREDNS_PATH


$Url = "https://github.com/coredns/coredns/releases/download/${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_windows_amd64.tgz"

Invoke-WebRequest -Uri $Url -OutFile "coredns.tgz" -UseBasicParsing

# Extract the tgz file

tar -xzf coredns.tgz

rm coredns.tgz

# Create Windows service 

New-Service `
  -Name "consul" `
  -BinaryPathName "$CONSUL_PATH\consul.exe agent -config-dir=$CONSUL_CONFIG_PATH" `
  -DisplayName "HashiCorp Consul Agent" `
  -StartupType Automatic

New-Service `
-Name "nomad" `
-BinaryPathName "$NOMAD_PATH\nomad.exe agent -config=$NOMAD_CONFIG_PATH" `
-DisplayName "HashiCorp Nomad Agent" `
-StartupType Automatic

New-Service `
-Name "coredns" `
-BinaryPathName "$COREDNS_PATH\coredns.exe -conf=$COREDNS_PATH\Corefile" `
-DisplayName "CoreDNS Agent" `
-StartupType Automatic

# Create Firewall Rules

# Consul
New-NetFirewallRule -Name 'Consul-Client-In-HTTP' -DisplayName 'Consul Client (http)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 8500
New-NetFirewallRule -Name 'Consul-Client-In-GRPS' -DisplayName 'Consul Client (grpc)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 8502
New-NetFirewallRule -Name 'Consul-Client-In-DNS' -DisplayName 'Consul Client (dns)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 8600

# Nomad
New-NetFirewallRule -Name 'Nomad-Client-In-HTTP' -DisplayName 'Nomad Client (http)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 4646
New-NetFirewallRule -Name 'Nomad-Client-In-RPC' -DisplayName 'Nomad Client (rpc)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 4647
New-NetFirewallRule -Name 'Nomad-Client-In-SERF' -DisplayName 'Nomad Client (serf)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 4648