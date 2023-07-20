#! /bin/bash
KUBERNETES_PUBLIC_ADDRESS="kubernetes.kubelab"
function generateworkerconfigs() {
    local machine="$1"
    mkdir -p kubeconfigs

    kubectl config set-cluster kubernetes-the-hard-way \
        --certificate-authority="../ca/certs/ca.crt" \
        --embed-certs=true \
        --server="https://${KUBERNETES_PUBLIC_ADDRESS}:6443" \
        --kubeconfig="kubeconfigs/${machine}.kubeconfig"

    kubectl config set-credentials "system:node:${machine}" \
        --client-certificate="../ca/certs/${machine}.crt" \
        --client-key="../ca/certs/${machine}.key" \
        --embed-certs=true \
        --kubeconfig="kubeconfigs/${machine}.kubeconfig"

    kubectl config set-context default \
        --cluster=kubernetes-the-hard-way \
        --user="system:node:${machine}" \
        --kubeconfig="kubeconfigs/${machine}.kubeconfig"

    kubectl config use-context default --kubeconfig="kubeconfigs/${machine}.kubeconfig"
}
function kubeproxyconfig() {
    kubectl config set-cluster kubernetes-the-hard-way \
        --certificate-authority="../ca/certs/ca.crt" \
        --embed-certs=true \
        --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
        --kubeconfig="kubeconfigs/kube-proxy.kubeconfig"

    kubectl config set-credentials system:kube-proxy \
        --client-certificate="../ca/certs/kube-proxy.crt" \
        --client-key="../ca/certs/kube-proxy.key" \
        --embed-certs=true \
        --kubeconfig="kubeconfigs/kube-proxy.kubeconfig"

    kubectl config set-context default \
        --cluster=kubernetes-the-hard-way \
        --user=system:kube-proxy \
        --kubeconfig="kubeconfigs/kube-proxy.kubeconfig"

    kubectl config use-context default --kubeconfig="kubeconfigs/kube-proxy.kubeconfig"
}
function generatecontrollermanagerconfig() {
    kubectl config set-cluster kubernetes-the-hard-way \
        --certificate-authority="../ca/certs/ca.crt" \
        --embed-certs=true \
        --server=https://127.0.0.1:6443 \
        --kubeconfig="kubeconfigs/kube-controller-manager.kubeconfig"

    kubectl config set-credentials system:kube-controller-manager \
        --client-certificate="../ca/certs/kube-controller-manager.crt" \
        --client-key="../ca/certs/kube-controller-manager.key" \
        --embed-certs=true \
        --kubeconfig="kubeconfigs/kube-controller-manager.kubeconfig"

    kubectl config set-context default \
        --cluster=kubernetes-the-hard-way \
        --user=system:kube-controller-manager \
        --kubeconfig="kubeconfigs/kube-controller-manager.kubeconfig"

    kubectl config use-context default --kubeconfig="kubeconfigs/kube-controller-manager.kubeconfig"
}
function generateschedulerconfig() {
    kubectl config set-cluster kubernetes-the-hard-way \
        --certificate-authority="../ca/certs/ca.crt" \
        --embed-certs=true \
        --server=https://127.0.0.1:6443 \
        --kubeconfig="kubeconfigs/kube-scheduler.kubeconfig"

    kubectl config set-credentials system:kube-scheduler \
        --client-certificate="../ca/certs/kube-scheduler.crt" \
        --client-key="../ca/certs/kube-scheduler.key" \
        --embed-certs=true \
        --kubeconfig="kubeconfigs/kube-scheduler.kubeconfig"

    kubectl config set-context default \
        --cluster=kubernetes-the-hard-way \
        --user=system:kube-scheduler \
        --kubeconfig="kubeconfigs/kube-scheduler.kubeconfig"

    kubectl config use-context default --kubeconfig="kubeconfigs/kube-scheduler.kubeconfig"
}
function generateadminconfig() {
    kubectl config set-cluster kubernetes-the-hard-way \
        --certificate-authority="../ca/certs/ca.crt" \
        --embed-certs=true \
        --server=https://kubernetes.kubelab \
        --kubeconfig="kubeconfigs/admin.kubeconfig"

    kubectl config set-credentials admin \
        --client-certificate="../ca/certs/admin.crt" \
        --client-key="../ca/certs/admin.key" \
        --embed-certs=true \
        --kubeconfig="kubeconfigs/admin.kubeconfig"

    kubectl config set-context default \
        --cluster=kubernetes-the-hard-way \
        --user=admin \
        --kubeconfig="kubeconfigs/admin.kubeconfig"

    kubectl config use-context default --kubeconfig="kubeconfigs/admin.kubeconfig"
}
for instance in worker-1 worker-2 worker-3 worker-4 worker-5 worker-6; do
    generateworkerconfigs "${instance}"
done
kubeproxyconfig
generatecontrollermanagerconfig
generateschedulerconfig
generateadminconfig
echo "Done generating kube-proxy kube-controller-manager kube-scheduler kube-admin configurations"