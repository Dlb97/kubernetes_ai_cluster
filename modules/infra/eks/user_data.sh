#!/bin/bash
set -o xtrace

# Install required packages
yum install -y amazon-efs-utils

# Configure kubelet
/etc/eks/bootstrap.sh ${cluster_name} \
  --kubelet-extra-args '--node-labels=ray_type=head' \
  --apiserver-endpoint ${cluster_endpoint} \
  --b64-cluster-ca ${cluster_ca_certificate}

# Configure kubelet to use IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/

# Restart kubelet to apply changes
systemctl restart kubelet 