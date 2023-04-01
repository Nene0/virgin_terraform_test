# Configure the AWS Provider ro allow Terraform to communicate with my AWS account
provider "aws" {
  version = "~> 4.0"
  region  = "eu-west-2"
  access_key = "AKIAUVWYTCGUY5LSQKM2"  #replace with your access and secret key. make use to hard code to avoiavoiding viewing it in plane text
  secret_key = "BT4mryfP+aPbJVOZuGI8Dvy5iDgYy2jrGpl7BsCp"
}



resource "aws_vpc" "vm_eks_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private_eks_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.vm_eks_vpc.id
  availability_zone = "eu-west-2a"
}

resource "aws_subnet" "public_eks_subnet" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.vm_eks_vpc.id
  availability_zone = "eu-west-2a"
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name = "vm-test-cluster"
  subnets = [aws_subnet.private_eks_subnet.id]
  vpc_id = aws_vpc.vm_eks_vpc.id
  manage_aws_auth = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  tags_map_additional = {
    KubernetesCluster = "vm-test-cluster"
  }

  node_groups_launch_template = [
    {
      name = "my-node-group"
      instance_type = "t3.medium"
      capacity_type = "SPOT"
      asg_desired_capacity = 0
      asg_max_size = 10
      asg_min_size = 0
      additional_security_group_ids = []
      kubelet_extra_args = "--node-labels=spot=true"
      labels = {
        nodegroupname = "my-node-group"
      }
    },
    {
      name = "my-on-demand-node-group"
      instance_type = "t3.medium"
      asg_desired_capacity = 3
      asg_max_size = 3
      asg_min_size = 3
      additional_security_group_ids = []
      kubelet_extra_args = "--node-labels=spot=false"
      labels = {
        nodegroupname = "my-on-demand-node-group"
      }
    }

     launch_template_spec {
       instance_market_options {
         market_type = "spot"
         spot_options {
           max_price = "0.05"
           spot_instance_type = "one-time"
    }
  }
}


  ]

  kubelet_extra_args = "--node-labels=foo=bar"

  write_kubeconfig = true
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
  tags_all = {
    Terraform = "true"
    Environment = "dev"
  }
}


resource "aws_eip" "vm_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "vm_nat_gateway" {
  allocation_id = aws_eip.vm_nat_eip.id
  subnet_id = aws_subnet.public_eks_subnet.id
}

resource "aws_route_table" "vm_private_rt" {
  vpc_id = aws_vpc.vm_eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vm_nat_gateway.id
  }
}

resource "aws_route_table_association" "vm_private_rt_association" {
  subnet_id = aws_subnet.public_eks_subnet.id
  route_table_id = aws_route_table.vm_private_rt
}

  
   
