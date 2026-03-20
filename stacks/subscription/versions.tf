terraform {
  required_version = ">= 1.6.0"

  required_providers {
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = ">= 2.12.0, < 3.0.0"
    }
  }
}
