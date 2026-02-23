#!/bin/bash

vault_addr="http://vault.service.dc1.global:8200/"

domain="dc1.global"


set -euo pipefail

vault auth enable approle


cat <<-EOF | vault policy write vault-iis-agent -
# Issue new certs
path "pki_int/issue/win-iis" {
    capabilities = ["list", "read", "create", "update", "delete"]
}

# Revoke certs
path "pki_int/revoke" {
    capabilities = [ "list", "read", "update", "delete"]
}
EOF


vault write auth/approle/role/iis-role \
    secret_id_ttl=10m \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=40 \
    policies="default","vault-iis-agent"

# certificates
echo "populating certificates"

vault secrets enable -path=pki pki
vault secrets enable -path=pki_int pki

vault write -field=certificate pki/root/generate/internal \
    issuer_name="root-issuer" \
    common_name="$domain" \
    ttl="8760h"

vault write pki/config/urls \
    issuing_certificates="${vault_addr}/v1/pki/ca" \
    crl_distribution_points="${vault_addr}/v1/pki/crl"

vault write pki/roles/root-role \
    allow_any_name=true \
    no_store=false

CSR=$(vault write -field=csr pki_int/intermediate/generate/internal \
    issuer_name="intermediate-issuer" \
    common_name="$domain Intermediate Authority" \
    ttl="4380h")

CERT=$(vault write -field=certificate pki/root/sign-intermediate \
    csr="$CSR" \
    format=pem_bundle \
    ttl="4380h")

vault write pki_int/intermediate/set-signed certificate="$CERT"

vault write pki_int/config/urls \
    issuing_certificates="${vault_addr}/v1/pki_int/ca" \
    crl_distribution_points="${vault_addr}/v1/pki_int/crl"

vault write pki_int/roles/win-iis allowed_domains="$domain" allow_subdomains=true max_ttl="720h"


# issue a leaf certificate from intermediate CA
# SERIAL=$(vault write -field=serial_number \
#     pki_int/issue/win-iis \
#     common_name="$sub_domain.$domain" \
#     ttl="24h")

echo "done!"