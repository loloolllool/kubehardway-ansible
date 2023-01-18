#!/bin/bash
function generateworkerconfigs() {
    local machine="$1"
    cat >"kubeconfigs/$machine-kubelet-config.yaml" <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.crt"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "172.16.0.0/16"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${machine}.crt"
tlsPrivateKeyFile: "/var/lib/kubelet/${machine}.key"
EOF
}

for instance in worker-1 worker-2 worker-3 worker-4 worker-5 worker-6; do
    generateworkerconfigs "${instance}"
done
