MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    apiServerEndpoint: ${cluster_endpoint}
    certificateAuthority: ${cluster_ca_certificate}
    cidr: 172.20.0.0/16
    name: ${cluster_name}
  kubelet:
    flags:
    - "--node-labels=ray-type=head"

--//--