Kind = "tcp-route"
Name = "product-db-route"

// Rules define how requests will be routed

Services = [
  {
    Name = "product-api-db"
  }
]

Parents = [
  {
    Kind        = "api-gateway"
    Name        = "api-gateway"
    SectionName = "hashicups-db-tcp-route"
  }
]