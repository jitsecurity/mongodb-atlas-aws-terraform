provider "aws" {
  region = "us-east-1"
}

provider "mongodbatlas" {
  private_key = var.mongo_atlas_private_key
  public_key  = var.mongo_atlas_public_key
  region      = "us-east-1"
}

# Setup auth for mongo management rest API
provider "shell" {
  sensitive_environment = {
    AUTH = jsonencode({
      username = var.mongo_atlas_public_key
      apiKey   = var.mongo_atlas_private_key
    })
  }
}