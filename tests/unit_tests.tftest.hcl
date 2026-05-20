mock_provider "aws" {}

run "vpc_minimal_configuration" {
  command = plan

  variables {
    vpc_name             = "test-vpc"
    vpc_cidr             = "10.0.0.0/16"
    availability_zones   = ["us-west-1a"]
    public_subnet_cidrs  = ["10.0.1.0/24"]
    private_subnet_cidrs = ["10.0.101.0/24"]

    enable_nat_gateway   = true
    single_nat_gateway   = true
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
      Environment = "test"
      Project     = "terraform-vpc"
    }
  }

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block is incorrect."
  }

  assert {
    condition     = aws_vpc.this.enable_dns_hostnames == true
    error_message = "DNS hostnames should be enabled."
  }

  assert {
    condition     = aws_vpc.this.enable_dns_support == true
    error_message = "DNS support should be enabled."
  }

  assert {
    condition     = length(aws_subnet.public) == 1
    error_message = "Expected 1 public subnet."
  }

  assert {
    condition     = length(aws_subnet.private) == 1
    error_message = "Expected 1 private subnet."
  }
}

run "multi_az_deployment" {
  command = plan

  variables {
    vpc_name             = "multi-az-vpc"
    vpc_cidr             = "10.1.0.0/16"
    availability_zones   = ["us-west-1a", "us-west-1b"]
    public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
    private_subnet_cidrs = ["10.1.101.0/24", "10.1.102.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Expected 2 public subnets."
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Expected 2 private subnets."
  }

  assert {
    condition     = aws_subnet.public[0].availability_zone == "us-west-1a"
    error_message = "First public subnet should be in us-west-1a."
  }

  assert {
    condition     = aws_subnet.public[1].availability_zone == "us-west-1b"
    error_message = "Second public subnet should be in us-west-1b."
  }
}

run "single_nat_gateway_enabled" {
  command = plan

  variables {
    vpc_name             = "single-nat-vpc"
    vpc_cidr             = "10.2.0.0/16"
    availability_zones   = ["us-west-1a", "us-west-1b"]
    public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
    private_subnet_cidrs = ["10.2.101.0/24", "10.2.102.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Expected only 1 NAT Gateway."
  }
}

run "multiple_nat_gateways_enabled" {
  command = plan

  variables {
    vpc_name             = "multi-nat-vpc"
    vpc_cidr             = "10.3.0.0/16"
    availability_zones   = ["us-west-1a", "us-west-1b"]
    public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24"]
    private_subnet_cidrs = ["10.3.101.0/24", "10.3.102.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "Expected NAT Gateways to match number of public subnets."
  }
}

run "nat_gateway_disabled" {
  command = plan

  variables {
    vpc_name             = "no-nat-vpc"
    vpc_cidr             = "10.4.0.0/16"
    availability_zones   = ["us-west-1a"]
    public_subnet_cidrs  = ["10.4.1.0/24"]
    private_subnet_cidrs = ["10.4.101.0/24"]

    enable_nat_gateway = false
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0
    error_message = "Expected no NAT Gateways."
  }
}

run "tagging_validation" {
  command = plan

  variables {
    vpc_name             = "tag-test-vpc"
    vpc_cidr             = "10.5.0.0/16"
    availability_zones   = ["us-west-1a"]
    public_subnet_cidrs  = ["10.5.1.0/24"]
    private_subnet_cidrs = ["10.5.101.0/24"]

    tags = {
      Environment = "dev"
      Owner       = "Jeremy"
      Project     = "vpc-module"
    }
  }

  assert {
    condition     = aws_vpc.this.tags["Environment"] == "dev"
    error_message = "Environment tag was not applied to VPC."
  }

  assert {
    condition     = aws_subnet.public[0].tags["Owner"] == "Jeremy"
    error_message = "Owner tag was not applied to public subnet."
  }

  assert {
    condition     = aws_subnet.private[0].tags["Project"] == "vpc-module"
    error_message = "Project tag was not applied to private subnet."
  }
}
