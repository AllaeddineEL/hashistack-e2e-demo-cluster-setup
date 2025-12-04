$CONSUL_VERSION = "1.22.1+ent"
$NOMAD_VERSION = "1.11.0+ent"

$CONSUL_PATH = "C:\consul"
$CONSUL_CONFIG_PATH = "C:\consul\config"
$CONSUL_CERTS_PATH = "C:\consul\certs"


$NOMAD_PATH = "C:\nomad"
$NOMAD_CONFIG_PATH = "C:\nomad\config"
$NOMAD_CERTS_PATH = "C:\nomad\certs"
$NOMAD_PLUGINS_PATH = "C:\nomad\plugins"

# Configure firewall rules
Start-Process -FilePath C:\Windows\System32\netsh.exe -ArgumentList "advfirewall set publicprofile state off"

mkdir $CONSUL_PATH
mkdir $CONSUL_CONFIG_PATH
mkdir $CONSUL_CERTS_PATH

mkdir $NOMAD_PATH
mkdir $NOMAD_CONFIG_PATH
mkdir $NOMAD_CERTS_PATH
mkdir $NOMAD_PLUGINS_PATH



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