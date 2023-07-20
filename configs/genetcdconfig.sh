#!/bin/bash
allinitialclustercontrollers=()
for instance in master-1 master-2 master-3; do
    hostname="${instance}.kubelab"
    ip=$(nslookup "$instance.kubelab" | grep "Address: " | awk '{print $2}')
    allinitialclustercontrollers+=("$instance=https://$ip:2380")
done
initialclusterstring=$(echo "${allinitialclustercontrollers[*]}" | tr ' ' ',')

function generateetcdconfigforinstance() {
    machine="$1"
    hostname="$machine.kubelab"
    internalip=$(nslookup "$hostname" | grep "Address: " | awk '{print $2}')
    # echo "$machine ($hostname) ($internalip) => $initialclusterstring"

    cat >"kubeconfigs/$machine-etcd.service" <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${machine} \\
  --cert-file=/etc/etcd/kubernetes.crt \\
  --key-file=/etc/etcd/kubernetes.key \\
  --peer-cert-file=/etc/etcd/kubernetes.crt \\
  --peer-key-file=/etc/etcd/kubernetes.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${internalip}:2380 \\
  --listen-peer-urls https://${internalip}:2380 \\
  --listen-client-urls https://0.0.0.0:2379 \\
  --advertise-client-urls https://${internalip}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster $initialclusterstring \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

}
#   --listen-client-urls https://${internalip}:2379,https://127.0.0.1:2379 \\


for instance in master-1 master-2 master-3; do
    generateetcdconfigforinstance "$instance"
done

echo "Done generating ETCD services"