terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region     = "eu-north-1"
  access_key = "AKIA6GBMEVMW7M3YT6I7"
  secret_key = "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"
}
# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"  # Specify your availability zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"  # Specify your availability zone

  tags = {
    Name = "private-subnet"
  }
}

# # Create a route table for the public subnet
# resource "aws_route_table" "public_route_table" {
#   vpc_id = aws_vpc.my_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.my_igw.id
#   }

#   tags = {
#     Name = "public-route-table"
#   }
# }

# # Associate the public subnet with the public route table
# resource "aws_route_table_association" "public_subnet_association" {
#   subnet_id      = aws_subnet.public_subnet.id
#   route_table_id = aws_route_table.public_route_table.id
# }
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Use locals for concise subnet association
locals {
  public_subnets = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id] # Assuming you want both subnets to have internet access; adjust as needed
}

# Create a route table association for each subnet
resource "aws_route_table_association" "subnet_public" {
  count          = length(local.public_subnets)
  subnet_id      = local.public_subnets[count.index]
  route_table_id = aws_route_table.public.id
}

# Update the ECS Service with depends_on for route table associations
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = local.public_subnets
    security_groups = [aws_security_group.my_security_group2.id]
    assign_public_ip = false # Consider setting this to true if your instances need to directly access the internet and are not in a private subnet with NAT
  }

  depends_on = [
    aws_route_table_association.subnet_public,
  ]
}


# Create a security group for the EC2 instance
resource "aws_security_group" "my_security_group2" {
  name        = "my-security-group2"
  description = "Allow inbound SSH, HTTP, and custom application traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic on port 3000 for the application
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Don't forget to define egress rules, typically allowing all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
        Effect = "Allow",
        Sid    = "",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs_instance_profile"
  role = aws_iam_role.ecs_task_execution_role.name
}
# Launch a basic EC2 instance in the public subnet
resource "aws_instance" "my_ec2_instance" {
  ami                     = "ami-0014ce3e52359afbd"  # Specify your preferred AMI ID
  instance_type           = "t3.micro"
  key_name                = "testingpair"    # Specify your key pair name
  subnet_id               = aws_subnet.public_subnet.id
  vpc_security_group_ids  = [aws_security_group.my_security_group2.id]
  user_data     = <<-EOF
                    #!/bin/bash
                    echo ECS_CLUSTER=${aws_ecs_cluster.my_cluster.name} >> /etc/ecs/ecs.config
                  EOF
  iam_instance_profile    =  aws_iam_instance_profile.ecs_instance_profile.name
  tags = {
    Name = "my-ec2-instance"
  }

  associate_public_ip_address = true
}


# Create an ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-application"
  network_mode             = "awsvpc" # Common for EC2 launch type
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "my-web-app"
      image     = "975050156845.dkr.ecr.eu-north-1.amazonaws.com/hello-repository:latest" # Specify your container image
      cpu        = 256
      memory     = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# resource "aws_ecs_service" "my_service" {
#   name            = "my-service"
#   cluster         = aws_ecs_cluster.my_cluster.id
#   task_definition = aws_ecs_task_definition.my_task_definition.arn
#   desired_count   = 1
#   launch_type     = "EC2"

#   network_configuration {
#     subnets         = [aws_subnet.public_subnet.id]
#     security_groups = [aws_security_group.my_security_group2.id]
#     assign_public_ip = false
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
#   ]
# }