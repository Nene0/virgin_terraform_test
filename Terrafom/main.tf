# Configure the AWS Provider ro allow Terraform to communicate with my AWS account
provider "aws" {
  version = "~> 4.0"
  region  = "eu-west-2"
  access_key = "my-access-key"    #replace with your access and secret key. make use to hard code to avoiavoiding viewing it in plane text
  secret_key = "my-secret-key"
}



resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "eks_subnet_london" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.eks_vpc.id
  availability_zone = "eu-west-2a"
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name = "my-private-cluster"
  subnets = [aws_subnet.eks_subnet_london.id]
  vpc_id = aws_vpc.eks_vpc.id
  manage_aws_auth = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  tags_map_additional = {
    KubernetesCluster = "my-private-cluster"
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


  
   
