Kind = "http-route"
Name = "nginx-route"

// Rules define how requests will be routed
Rules = [
  {
    Matches = [
      {
        Path = {
          Match = "prefix"
          Value = "/"
        }
      }
    ]
    Services = [
      {
        Name = "nginx"
      }
    ]
  }
]

Parents = [
  {
    Kind        = "api-gateway"
    Name        = "api-gateway"
    SectionName = "hashicups-http-route"
  }
]