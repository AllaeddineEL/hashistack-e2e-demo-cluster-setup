# Exit on error


$ErrorActionPreference = "Stop"

Write-Host "Start Logging"

Start-Transcript -Append C:\Windows\Temp\UserData.txt


# -------------------------------------------------------------------------------
# Paths (Windows versions)
# -------------------------------------------------------------------------------

$CONSUL_PATH = "C:\consul"
$CONSUL_CONFIG_PATH = "C:\consul\config"
$CONSUL_DATA_PATH = "C:\consul\data"
$CONSUL_CERTS_PATH = "C:\consul\certs"


$NOMAD_PATH = "C:\nomad"
$NOMAD_CONFIG_PATH = "C:\nomad\config"
$NOMAD_DATA_PATH = "C:\nomad\data"
$NOMAD_CERTS_PATH = "C:\nomad\certs"
$NOMAD_PLUGINS_PATH = "C:\nomad\plugins"



Write-Host "Decoding certificates..."

[IO.File]::WriteAllBytes("C:\Windows\Temp\agent-ca.pem",    [Convert]::FromBase64String("${ca_certificate}"))

[IO.File]::WriteAllBytes("C:\Windows\Temp\agent.pem",       [Convert]::FromBase64String("${agent_certificate}"))

[IO.File]::WriteAllBytes("C:\Windows\Temp\agent-key.pem",   [Convert]::FromBase64String("${agent_key}"))



Copy-Item "C:\Windows\Temp\agent-ca.pem"  "$CONSUL_CERTS_PATH\consul-agent-ca.pem"
Copy-Item "C:\Windows\Temp\agent-ca.pem"  "$NOMAD_CERTS_PATH\nomad-agent-ca.pem"
Copy-Item "C:\Windows\Temp\agent.pem"     "$NOMAD_CERTS_PATH\nomad-agent.pem"
Copy-Item "C:\Windows\Temp\agent-key.pem" "$NOMAD_CERTS_PATH\nomad-agent-key.pem"

# -------------------------------------------------------------------------------
# IP address detection by cloud metadata
# -------------------------------------------------------------------------------

$cloud = "${cloud_env}"
$IP_ADDRESS = ""

switch ($cloud) {
    "aws" {
        Write-Host "CLOUD_ENV: aws"

        $token = Invoke-WebRequest `
            -Uri "http://169.254.169.254/latest/api/token" `
            -Method PUT `
            -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" } `
            -UseBasicParsing

        $IP_ADDRESS = Invoke-WebRequest `
            -Uri "http://169.254.169.254/latest/meta-data/local-ipv4" `
            -Headers @{ "X-aws-ec2-metadata-token" = $token.Content } `
            -UseBasicParsing | Select-Object -ExpandProperty Content
    }
    "gce" {
        Write-Host "CLOUD_ENV: gce"

        $IP_ADDRESS =  Invoke-RestMethod  `
            -Uri "http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip" `
            -Headers @{ "Metadata-Flavor" = "Google" } `
            -UseBasicParsing 
    }
    "azure" {
        Write-Host "CLOUD_ENV: azure"

        $resp = Invoke-WebRequest `
            -Uri "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0?api-version=2021-12-13" `
            -Headers @{ "Metadata" = "true" } `
            -UseBasicParsing

        $IP_ADDRESS = (ConvertFrom-Json $resp.Content).privateIpAddress
    }
    default {
        Write-Host "CLOUD_ENV: not set"
    }
}

Write-Host "The local IP: $IP_ADDRESS"
# -------------------------------------------------------------------------------
# Variables for rendering *.hcl config files
# -------------------------------------------------------------------------------

$CONSUL_DATACENTER   = "${datacenter}"
$CONSUL_DOMAIN       = "${domain}"
$CONSUL_NODE_NAME    = "${consul_node_name}"
$CONSUL_BIND_ADDR    = "$IP_ADDRESS"
$CONSUL_RETRY_JOIN   = "${retry_join}"
$CONSUL_ENCRYPTION_KEY = "${consul_encryption_key}"
$CONSUL_AGENT_TOKEN  = "${consul_agent_token}"
$CONSUL_DEFAULT_TOKEN = "${consul_default_token}"

$NOMAD_DATACENTER    = "${datacenter}"
$NOMAD_DOMAIN        = "${domain}"
$NOMAD_NODE_NAME     = "${nomad_node_name}"
$NOMAD_AGENT_META    = "${nomad_agent_meta}"
$NOMAD_AGENT_TOKEN   = "${nomad_agent_token}"

# ------------------------------------------------------------}-------------------
# Expand templates like sed -i
# PowerShell replaces tokens in files
# -------------------------------------------------------------------------------

function Replace-Token {
    param (
        [string]$Path,
        [string]$Token,
        [string]$Value
    )

    (Get-Content $Path) -replace $Token, $Value | Set-Content $Path -Encoding UTF8
}

# -------------------------------------------------------------------------------
# Render Consul config
# -------------------------------------------------------------------------------

#Copy-Item "$CONFIG_DIR\agent-config-consul_client.hcl" "$CONSUL_CONFIG_DIR\consul.hcl" -Force

Replace-Token "$CONSUL_CONFIG_PATH\consul.hcl" "_CONSUL_DATACENTER"    $CONSUL_DATACENTER
Replace-Token "$CONSUL_CONFIG_PATH\consul.hcl" "_CONSUL_DOMAIN"        $CONSUL_DOMAIN
Replace-Token "$CONSUL_CONFIG_PATH\consul.hcl" "_CONSUL_NODE_NAME"     $CONSUL_NODE_NAME
Replace-Token "$CONSUL_CONFIG_PATH\consul.hcl" "_CONSUL_BIND_ADDR"     $CONSUL_BIND_ADDR
Replace-Token "$CONSUL_CONFIG_PATH\consul.hcl" "_CONSUL_RETRY_JOIN"    $CONSUL_RETRY_JOIN
Replace-Token "$CONSUL_CONFIG_PATH\consul.hcl" "_CONSUL_ENCRYPTION_KEY" $CONSUL_ENCRYPTION_KEY
Replace-Token "$CONSUL_CONFIG_PATH\consul.hcl" "_CONSUL_AGENT_TOKEN"   $CONSUL_AGENT_TOKEN
Replace-Token "$CONSUL_CONFIG_PATH\consul.hcl" "_CONSUL_DEFAULT_TOKEN" $CONSUL_DEFAULT_TOKEN

# -------------------------------------------------------------------------------
# Render Nomad config
# -------------------------------------------------------------------------------

#Copy-Item "$CONFIG_DIR\agent-config-nomad_client.hcl" "$NOMAD_CONFIG_DIR\nomad.hcl" -Force

Replace-Token "$NOMAD_CONFIG_PATH\nomad.hcl" "_NOMAD_DATACENTER"  $NOMAD_DATACENTER
Replace-Token "$NOMAD_CONFIG_PATH\nomad.hcl" "_NOMAD_DOMAIN"      $NOMAD_DOMAIN
Replace-Token "$NOMAD_CONFIG_PATH\nomad.hcl" "_NOMAD_NODE_NAME"   $NOMAD_NODE_NAME
Replace-Token "$NOMAD_CONFIG_PATH\nomad.hcl" "_NOMAD_AGENT_META"  $NOMAD_AGENT_META
Replace-Token "$NOMAD_CONFIG_PATH\nomad.hcl" "_CONSUL_AGENT_TOKEN" $NOMAD_AGENT_TOKEN

(Get-Content $CONSUL_CONFIG_PATH\consul.hcl) | Out-File $CONSUL_CONFIG_PATH\consul.hcl -Encoding ascii 
(Get-Content $NOMAD_CONFIG_PATH\nomad.hcl) | Out-File $NOMAD_CONFIG_PATH\nomad.hcl -Encoding ascii 

Start-Service consul
Start-Service nomad

Add-DnsServerConditionalForwarderZone `
  -Name "$CONSUL_DOMAIN" `
  -MasterServers 127.0.0.1 `
  -PassThru

Set-ItemProperty `
  -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DNS\Parameters\Forwarders" `
  -Name "Port" `
  -Value 8600

Restart-Service DNS  