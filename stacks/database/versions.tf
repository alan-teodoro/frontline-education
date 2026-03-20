terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 7.0.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }

    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = ">= 2.12.0, < 3.0.0"
    }
  }
}
