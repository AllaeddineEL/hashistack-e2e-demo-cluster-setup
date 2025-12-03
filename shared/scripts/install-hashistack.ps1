SET CONSUL_VERSION=1.22.1+ent
SET NOMAD_VERSION=1.11.0+ent

SET CONSUL_PATH=C:\consul
SET CONSUL_CONFIG_PATH=C:\consul\config
SET CONSUL_CERTS_PATH=C:\consul\certs


SET NOMAD_PATH=C:\nomad
SET NOMAD_CONFIG_PATH=C:\nomad\config
SET NOMAD_CERTS_PATH=C:\nomad\certs
SET NOMAD_PLUGINS_PATH=C:\nomad\plugins

# Configure firewall rules
netsh advfirewall set publicprofile state off

# Install chocolatey and others
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command " [System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
choco install wget -y --force
choco install unzip -y --force


# # Install Docker
# Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" -o install-docker-ce.ps1
# .\install-docker-ce.ps1

mkdir %CONSUL_PATH%
mkdir %CONSUL_CONFIG_PATH%
mkdir %CONSUL_CERTS_PATH%

mkdir %NOMAD_PATH%
mkdir %NOMAD_CONFIG_PATH%
mkdir %NOMAD_CERTS_PATH%
mkdir %NOMAD_PLUGINS_PATH%



# Download Consul    
cd %CONSUL_PATH%


wget https://releases.hashicorp.com/consul/%CONSUL_VERSION%/consul_%CONSUL_VERSION%_windows_amd64.zip --no-check-certificate -O consul.zip -o consul.zip.log
unzip consul.zip -d .

# Download Nomad    
cd %NOMAD_PATH%
wget https://releases.hashicorp.com/nomad/%NOMAD_VERSION%/nomad_%NOMAD_VERSION%_windows_amd64.zip --no-check-certificate -O nomad.zip -o nomad.zip.log
unzip nomad.zip -d .