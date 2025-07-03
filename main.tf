module "vpc" {
  source = "./modules/infra/vpc"

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
  project_name        = var.project_name
  cluster_name        = var.cluster_name
  common_tags         = var.common_tags
}

module "eks" {
  source = "./modules/infra/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block
  subnet_ids         = module.vpc.public_subnet_ids
  common_tags        = var.common_tags

  # Node Group Configuration
  node_group_desired_size   = var.node_group_desired_size
  node_group_max_size       = var.node_group_max_size
  node_group_min_size       = var.node_group_min_size
  node_group_instance_types = var.node_group_instance_types
}

module "karpenter" {
  source                    = "./modules/services/karpenter"
  cluster_name              = module.eks.cluster_name
  cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn
  depends_on                = [module.eks]

}

module "nvidia_gpu_operator" {
  source     = "./modules/services/nvidia_gpu_operator"
  depends_on = [module.eks]
}

module "ray" {
  source     = "./modules/services/kuberay"
  depends_on = [module.eks]
}