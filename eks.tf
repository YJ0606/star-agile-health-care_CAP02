module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    amc-cluster-wg = {
      min_size     = 1
      max_size     = 2
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  tags = local.tags
}
# Data source to fetch security group ID
data "aws_security_group" "node_group" {
  filter {
    name   = "tag:aws:eks:cluster-name"
    values = [var.name]
  }

  filter {
    name   = "tag:kubernetes.io/cluster/${var.name}"
    values = ["owned"]
  }
}

# Security Group Rule to allow all traffic
resource "aws_security_group_rule" "allow_all_traffic" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  security_group_id = data.aws_security_group.node_group.id

  cidr_blocks = ["0.0.0.0/0"]
}
