# To request data encoding using  the payments role
path "transform/encode/payments" {
   capabilities = [ "update" ]
}

# To request data decoding using the payments role
path "transform/decode/payments" {
   capabilities = [ "update" ]
}
