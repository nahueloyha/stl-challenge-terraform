terraform {
  backend "remote" {
    organization = "nahueloyha"

    workspaces {
      name = "stl-challenge-terraform-${var.environment}"
    }
  }

  required_version = ">= 0.14.0"
}
