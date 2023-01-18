#!/bin/bash
allinitialclustercontrollers=()
for instance in master-1 master-2 master-3; do
    hostname="${instance}.kubelab"
    ip=$(nslookup "$instance.kubelab" | grep "Address: " | awk '{print $2}')
    allinitialclustercontrollers+=("https://$ip:2379")
done
etcdserverurlsstring=$(echo "${allinitialclustercontrollers[*]}" | tr ' ' ',')
function generateapiserverservice() {
    machine="$1"
    hostname="$machine.kubelab"
    internalip=$(nslookup "$hostname" | grep "Address: " | awk '{print $2}')
    # echo "$machine ($hostname) ($internalip) => $initialclusterstring"

    cat >"kubeconfigs/${machine}-kube-apiserver.service" <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${internalip} \\
  --allow-privileged=true \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.crt \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.crt \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.crt \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes.key \\
  --etcd-servers=${etcdserverurlsstring} \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.crt \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.crt \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes.key \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.crt \\
  --service-account-signing-key-file=/var/lib/kubernetes/service-account.key \\
  --service-account-issuer=https://${internalip}:6443 \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.crt \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes.key \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

}

for instance in master-1 master-2 master-3; do
    generateapiserverservice "$instance"
done

echo "Done generating kube api service service"
