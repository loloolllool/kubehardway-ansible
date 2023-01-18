#!/bin/bash
function generatekubescheduleryaml() {
  machine="$1"

  cat >"kubeconfigs/${machine}-kube-scheduler.yaml" <<EOF
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
}
function generatekubeschedulerservice() {
  machine="$1"

  cat >"kubeconfigs/${machine}-kube-scheduler.service" <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

}

for instance in master-1 master-2 master-3; do
  generatekubescheduleryaml "$instance"
  generatekubeschedulerservice "$instance"
done

echo "Done generating kube scheduler service"
