locals {
    name             = "${var.namespace}-${var.environment}"
    
    tags = {
      Owner       = var.namespace
      Environment = var.environment
    }
  }