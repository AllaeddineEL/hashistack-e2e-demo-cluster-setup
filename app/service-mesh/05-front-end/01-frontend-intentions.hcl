Kind = "service-intentions"
Name = "frontend"
Sources = [
  {
    Name   = "api-gateway"
    Action = "allow"
  },
  {
    Name   = "nginx"
    Action = "allow"
  }
]