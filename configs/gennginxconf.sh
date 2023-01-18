#!/bin/bash
function generatenginxconfiguration() {
    machine="$1"

    cat >"kubeconfigs/${machine}-nginx.conf" <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.crt;
  }
}
EOF

}

for instance in master-1 master-2 master-3; do
    generatecontrollermanagerservice "$instance"
done

echo "Done generating kube controller manager service"
