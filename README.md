# Terraform EKS AI Cluster

A comprehensive Terraform infrastructure for deploying an Amazon EKS cluster optimized for AI/ML workloads with Karpenter for node autoscaling, NVIDIA GPU Operator for GPU support, and KubeRay for distributed computing.

## 🏗️ Architecture Overview

This project creates an EKS cluster with the following components:

- **VPC Infrastructure**: Custom VPC with public subnets across multiple availability zones
- **EKS Cluster**: Kubernetes cluster with managed node groups and launch templates
- **Data Management**: S3 buckets, EFS file system, and DataSync for data orchestration
- **Karpenter**: Just-in-time node provisioning and autoscaling with dynamic GPU node pools
- **NVIDIA GPU Operator**: Automated GPU driver and container runtime management
- **KubeRay**: Distributed computing framework for Ray workloads
- **OIDC Provider**: Secure service account authentication
- **AWS Auth ConfigMap**: IAM role mapping for EKS node authentication

## 📁 Project Structure

```
terraform_eks_ai_cluster/
├── backend.tf                 # S3 backend configuration
├── main.tf                    # Main module orchestration
├── providers.tf               # Provider configurations
├── variables.tf               # Variable definitions
├── envs/
│   └── main/
│       ├── backend.conf       # Backend configuration
│       └── main.tfvars        # Environment-specific variables
└── modules/
    ├── infra/
    │   ├── vpc/              # VPC and networking resources
    │   ├── eks/              # EKS cluster and node groups
    │   └── data/             # Data management (S3, EFS, DataSync)
    └── services/
        ├── aws-auth/            # AWS IAM role mapping for EKS authentication
        ├── karpenter/           # Karpenter autoscaling with GPU node pools
        ├── nvidia_gpu_operator/ # NVIDIA GPU support
        └── kuberay/             # KubeRay distributed computing
```

## 🚀 Features

### Core Infrastructure
- **Multi-AZ VPC**: High availability with public subnets across availability zones
- **EKS Cluster**: Managed Kubernetes cluster with version 1.32
    - **Launch Templates**: Custom AMI and configuration for EKS nodes
    - **Security Groups**: Properly configured network security for cluster communication

> **⚠️ Important Notice**: This configuration uses public subnets for the EKS cluster, which is suitable for development and testing environments but **not recommended for production workloads**. For production environments, consider using private subnets with NAT gateways and the required VPC endpoints for AWS services (EKS, ECR, S3, etc.) to enhance security.

### Dynamic GPU Cluster Management
The `gpu_clusters` variable enables dynamic creation of both Karpenter node pools and corresponding Ray clusters:

```hcl
gpu_clusters = [
  {
    instance_type     = "g4dn.xlarge"
    replicas          = 2
    gpus_per_replica  = 1
  },
  {
    instance_type     = "p4de.24xlarge"
    replicas          = 1
    gpus_per_replica  = 8
  }
]
```

**How it works:**
1. **Karpenter Node Pools**: For each GPU configuration, a Karpenter NodePool is created with:
   - **Instance Type Label**: `instance_type: ${INSTANCE_TYPE}` for node selection
   - **Ray Worker Label**: `ray_type: worker` for Ray cluster targeting
   - **GPU Requirements**: Configured for the specific instance type
   - **Capacity Types**: Support for both on-demand and spot instances

2. **Ray Clusters**: Corresponding RayCluster resources are created with:
   - **Worker Replicas**: Controlled by the `replicas` parameter in `gpu_clusters`
   - **GPU Allocation**: `gpus_per_replica` determines GPU resources per worker
   - **Node Selection**: Uses `ray_type: worker` and `instance_type: ${INSTANCE_TYPE}` labels
   - **Persistent Storage**: EFS-backed persistent volumes for data persistence

3. **Automatic Scaling**: 
   - **Karpenter**: Provisions nodes based on Ray cluster requirements
   - **Ray Workers**: Scale according to the `replicas` parameter
   - **Cost Optimization**: Automatic node consolidation and spot instance usage

### Autoscaling with Karpenter
- **Just-in-time Provisioning**: Nodes are created only when needed
- **CPU Node Pool**: On-demand m5.large instances for general workloads
- **Dynamic GPU Node Pools**: Automatically created based on `gpu_clusters` variable
- **Spot Instance Support**: Cost optimization for GPU workloads
- **Consolidation**: Automatic node consolidation for cost efficiency

### AI/ML Optimizations
- **NVIDIA GPU Operator**: Automated GPU driver installation and management
- **Large EBS Volumes**: 400GB GP3 volumes for data storage
- **KubeRay Integration**: Ready for distributed Ray workloads with persistent storage
- **Multi-GPU Support**: Configurable GPU allocation per worker node

### Security & Compliance
- **OIDC Provider**: Secure service account authentication
- **IAM Roles**: Least privilege access for all components
- **AWS Auth ConfigMap**: Maps IAM roles to Kubernetes RBAC for node authentication
- **Encrypted Storage**: EBS and EFS volumes with encryption enabled
- **Network Security**: Proper security group configurations
- **S3 Security**: Public access blocked, server-side encryption

## 📋 Prerequisites

- Terraform >= 0.13
- AWS CLI configured with appropriate permissions
- kubectl for cluster interaction
- Helm for package management

### Required AWS Permissions
- EKS cluster creation and management
- VPC and networking resources
- IAM role and policy management
- EC2 instance and launch template management
- S3 bucket access for Terraform state
- EFS file system creation and management
- DataSync task creation and execution

## 🔧 Configuration

### Environment Variables

The main configuration is in `envs/main/main.tfvars`:

```hcl
# VPC Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]

# EKS Configuration
cluster_name = "eks-ai-cluster"
kubernetes_version = "1.32"

# Node Group Configuration
node_group_desired_size = 2
node_group_max_size = 4
node_group_min_size = 0
node_group_instance_types = ["m5.large"]

# GPU Cluster Configuration
gpu_clusters = [
  {
    instance_type     = "g4dn.xlarge"
    replicas          = 2
    gpus_per_replica  = 1
  },
  {
    instance_type     = "p4de.24xlarge"
    replicas          = 3
    gpus_per_replica  = 8
  }
]
```

### Backend Configuration

The project uses S3 backend for state management. Configure your common backend parameters in `backend.tf`:

```hcl
key = "state/genai_gateway/terraform.tfstate"
region = "us-east-1"
```

and `./envs/main/backend.conf` for the environment specific bucket.

```hcl
bucket = "<YOUR_S3_BUCKET_NAME>"
```

## 🚀 Deployment

### 1. Initialize Terraform

```bash
terraform init -upgrade --backend-config envs/main/backend.conf
```

### 2. Plan the Deployment

```bash
terraform plan -var-file=envs/main/main.tfvars
```

### 3. Apply the Infrastructure

```bash
terraform apply -var-file=envs/main/main.tfvars
```

### 4. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-ai-cluster
```

## 📊 Node Pools

### CPU Node Pool
- **Instance Type**: m5.large
- **Capacity Type**: On-demand
- **Architecture**: AMD64
- **Storage**: 400GB GP3 EBS
- **Purpose**: General workloads, Ray head nodes

### Dynamic GPU Node Pools
- **Instance Types**: Configurable via `gpu_clusters` variable
- **Capacity Type**: On-demand and Spot
- **GPUs**: Configurable via `gpus_per_replica` parameter
- **Storage**: 400GB GP3 EBS
- **Purpose**: AI/ML workloads, GPU-intensive tasks
- **Auto-scaling**: Based on Ray cluster requirements

## 🔍 Monitoring and Management

### Karpenter Metrics
Monitor Karpenter's autoscaling behavior:
```bash
kubectl get nodepools
kubectl get ec2nodeclasses
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

### GPU Operator Status
Check GPU operator installation:
```bash
kubectl get pods -n gpu-operator
kubectl get nodes -l nvidia.com/gpu.present=true
```

### KubeRay Status
Monitor KubeRay operator and clusters:
```bash
kubectl get pods -n kuberay-operator
```

## 🧹 Cleanup

To destroy the infrastructure:

```bash
terraform destroy -var-file=envs/main/main.tfvars
```

**⚠️ Warning**: This will delete all resources including the EKS cluster, VPC, S3 buckets, EFS file system, and all associated resources.

## 🔧 Troubleshooting

### Common Issues

1. **Karpenter Pods Crashing**: Check OIDC provider configuration and IAM roles
2. **GPU Nodes Not Joining**: Verify GPU AMI and NVIDIA GPU operator installation
3. **Node Autoscaling Issues**: Check Karpenter logs and IAM permissions
4. **Ray Cluster Issues**: Verify node selectors and GPU resource allocation
5. **DataSync Failures**: Check IAM permissions and network connectivity

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check Karpenter status
kubectl get nodepools
kubectl get ec2nodeclasses

# Check GPU operator
kubectl get pods -n gpu-operator
nvidia-smi # On GPU nodes

# Check KubeRay
kubectl get pods -n kuberay-operator
kubectl get rayclusters
kubectl describe raycluster <cluster-name>

# Check data infrastructure
kubectl get pv
kubectl get pvc
```

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review AWS EKS and Karpenter documentation

## 🔗 References

- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Karpenter Documentation](https://karpenter.sh/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/amazon-eks.html)
- [KubeRay Documentation](https://docs.ray.io/en/latest/cluster/kubernetes/index.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) 