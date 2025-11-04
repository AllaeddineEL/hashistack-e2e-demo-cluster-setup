resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 3072
}

resource "local_file" "private_key_ssh_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "/root/.ssh/id_rsa"
  file_permission = "400"
}
