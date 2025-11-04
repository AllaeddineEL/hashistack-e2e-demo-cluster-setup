Kind = "service-intentions"
Name = "product-api-db"
Sources = [
  {
    Name   = "product-api"
    Action = "allow"
  },
  {
    Name   = "api-gateway"
    Action = "allow"
  }
  ,
  {
    Name   = "payments-api"
    Action = "allow"
  }
]