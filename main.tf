terraform {
  cloud {
    organization = "imperva-datasec"
    
    workspaces {
      tags = ["github_example"]
    }
  }
}
