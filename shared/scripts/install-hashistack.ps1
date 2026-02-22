$CONSUL_VERSION = "1.22.2+ent"
$NOMAD_VERSION = "1.11.1+ent"
$COREDNS_VERSION = "1.14.1"
$winSWVersion = "v2.12.0"
$IIS_PLUGIN_VERSION = "v0.19.0"


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

rm consul.zip

# Download Nomad    
cd $NOMAD_PATH

$Url = "https://releases.hashicorp.com/nomad/$NOMAD_VERSION/nomad_${NOMAD_VERSION}_windows_amd64.zip"

Invoke-WebRequest -Uri $Url -OutFile "nomad.zip" -UseBasicParsing

Expand-Archive -Path nomad.zip -DestinationPath .

rm nomad.zip

# Download IIS Plugin
cd $NOMAD_PLUGINS_PATH

$IISPluginUrl = "https://github.com/sevensolutions/nomad-iis/releases/download/$IIS_PLUGIN_VERSION/nomad_iis_mgmt_api.zip"

Invoke-WebRequest -Uri $IISPluginUrl -OutFile "nomad_iis_mgmt_api.zip" -UseBasicParsing

Expand-Archive -Path nomad_iis_mgmt_api.zip -DestinationPath .

rm nomad_iis_mgmt_api.zip

# Install Windows IIS

$features = @(
    "IIS-WebServerRole",
    "IIS-WebServer",
    "IIS-CommonHttpFeatures",
    "IIS-HttpErrors",
    "IIS-HttpRedirect",
    "IIS-ApplicationDevelopment",
    "NetFx4Extended-ASPNET45",
    "IIS-NetFxExtensibility45",
    "IIS-HealthAndDiagnostics",
    "IIS-HttpLogging",
    "IIS-LoggingLibraries",
    "IIS-RequestMonitor",
    "IIS-HttpTracing",
    "IIS-Security",
    "IIS-RequestFiltering",
    "IIS-Performance",
    "IIS-WebServerManagementTools",
    "IIS-IIS6ManagementCompatibility",
    "IIS-Metabase",
    "IIS-ManagementConsole",
    "IIS-BasicAuthentication",
    "IIS-WindowsAuthentication",
    "IIS-StaticContent",
    "IIS-DefaultDocument",
    "IIS-WebSockets",
    "IIS-ApplicationInit",
    "IIS-ISAPIExtensions",
    "IIS-ISAPIFilter",
    "IIS-HttpCompressionStatic",
    "IIS-ASP",
    "IIS-ServerSideIncludes",
    "IIS-ASPNET45"
)

Enable-WindowsOptionalFeature -Online -FeatureName $features

# Enable feature delegation for Anonymous Authentication in the host configuration of IIS
Set-WebConfiguration //System.WebServer/Security/Authentication/anonymousAuthentication -metadata overrideMode -value Allow

# Nomad client will dynamically allocate ports on your machine in the range 20000-32000. Therefore we need to open these ports on the Windows Firewall by running
New-NetFirewallRule -DisplayName "Allow Nomad Dynamic Ports 20000-32000" -Action Allow -Direction Inbound -Protocol TCP -LocalPort 20000-32000

# Download CoreDNS    
cd $COREDNS_PATH


$Url = "https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_windows_amd64.tgz"

Invoke-WebRequest -Uri $Url -OutFile "coredns.tgz" -UseBasicParsing

# Extract the tgz file

tar -xzf coredns.tgz

rm coredns.tgz

# Download and install winsw (Windows Service Wrapper) to run CoreDNS as Windows services

$WinSWUrl = "https://github.com/winsw/winsw/releases/download/$winSWVersion/WinSW-x64.exe"

Invoke-WebRequest -Uri $WinSWUrl -OutFile "$COREDNS_PATH\WinCoreDNS.exe" -UseBasicParsing


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

$COREDNS_PATH\WinCoreDNS.exe install

# Create Firewall Rules

# Consul
New-NetFirewallRule -Name 'Consul-Client-In-HTTP' -DisplayName 'Consul Client (http)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 8500
New-NetFirewallRule -Name 'Consul-Client-In-GRPS' -DisplayName 'Consul Client (grpc)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 8502
New-NetFirewallRule -Name 'Consul-Client-In-DNS' -DisplayName 'Consul Client (dns)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 8600

# Nomad
New-NetFirewallRule -Name 'Nomad-Client-In-HTTP' -DisplayName 'Nomad Client (http)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 4646
New-NetFirewallRule -Name 'Nomad-Client-In-RPC' -DisplayName 'Nomad Client (rpc)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 4647
New-NetFirewallRule -Name 'Nomad-Client-In-SERF' -DisplayName 'Nomad Client (serf)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 4648