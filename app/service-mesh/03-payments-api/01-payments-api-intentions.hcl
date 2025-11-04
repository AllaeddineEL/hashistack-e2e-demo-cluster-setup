Kind = "service-intentions"
Name = "payments-api"
Sources = [
  {
    Name   = "public-api"
    Action = "allow"
  },
  {
    Name   = "product-api"
    Action = "allow"
  }
]