mock_provider "aws" {}

run "full_vpc_deployment" {
  command = apply

  variables {
    vpc_name             = "integration-vpc"
    vpc_cidr             = "10.10.0.0/16"
    availability_zones   = ["us-west-1a", "us-west-1b"]
    public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
    private_subnet_cidrs = ["10.10.101.0/24", "10.10.102.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true

    tags = {
      Environment = "integration"
      Project     = "terraform-vpc-test"
    }
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "VPC ID output should not be null."
  }

  assert {
    condition     = output.vpc_cidr_block == "10.10.0.0/16"
    error_message = "VPC CIDR output is incorrect."
  }

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "Expected 2 public subnet IDs."
  }

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "Expected 2 private subnet IDs."
  }

  assert {
    condition     = output.internet_gateway_id != null
    error_message = "Internet Gateway output should not be null."
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 1
    error_message = "Expected 1 NAT Gateway ID."
  }
}

run "network_connectivity_routes" {
  command = apply

  variables {
    vpc_name             = "route-test-vpc"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-west-1a", "us-west-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.101.0/24", "10.20.102.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true
  }

  assert {
    condition = one([
      for route in aws_route_table.public.route : route
      if route.cidr_block == "0.0.0.0/0"
    ]).gateway_id == aws_internet_gateway.this.id

    error_message = "Public route table should route 0.0.0.0/0 to the Internet Gateway."
  }

  assert {
    condition = one([
      for route in aws_route_table.private[0].route : route
      if route.cidr_block == "0.0.0.0/0"
    ]).nat_gateway_id == aws_nat_gateway.this[0].id

    error_message = "Private route table should route 0.0.0.0/0 to the NAT Gateway."
  }

  assert {
    condition     = length(aws_route_table_association.public) == 2
    error_message = "Expected 2 public route table associations."
  }

  assert {
    condition     = length(aws_route_table_association.private) == 2
    error_message = "Expected 2 private route table associations."
  }
}