#!/bin/bash
RED='\033[0;31m'
NC='\033[0m' 
cd "$(dirname "$0")"
rm -f certs
function myecho() {
    echo -e "${RED}$1${NC}"
}
function generateca() {
    myecho "Generate ca cert"

    cfssl gencert -initca ca-csr.json | cfssljson -bare ca
    mkdir -p certs
    mv ca.pem certs/ca.crt
    mv ca-key.pem certs/ca.key
    rm ca.csr
}
function generatecontrollermanagercert() {
    myecho "Generate kube-controller cert"

    cfssl gencert -ca=certs/ca.crt -ca-key=certs/ca.key -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
    mkdir -p certs
    mv kube-controller-manager.pem certs/kube-controller-manager.crt
    mv kube-controller-manager-key.pem certs/kube-controller-manager.key
    rm kube-controller-manager.csr
}
function generatekubeproxycert() {
    myecho "Generate kube-proxy cert"

    cfssl gencert -ca=certs/ca.crt -ca-key=certs/ca.key -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
    mkdir -p certs
    mv kube-proxy.pem certs/kube-proxy.crt
    mv kube-proxy-key.pem certs/kube-proxy.key
    rm kube-proxy.csr
}
function generatekubeschedulercert() {
    myecho "Generate kube-scheduler cert"

    cfssl gencert -ca=certs/ca.crt -ca-key=certs/ca.key -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler
    mkdir -p certs
    mv kube-scheduler.pem certs/kube-scheduler.crt
    mv kube-scheduler-key.pem certs/kube-scheduler.key
    rm kube-scheduler.csr
}
function generateworkercert() {
    instance="$1"
    myecho "Generate worker cert $instance"
    csrfile=${instance}-csr.json
    ## Works fine, but found more elegant way
    # jq --arg replacement $instance '.CN |= gsub("\\$\\{instance\\}"; $replacement)' worker-template.json >worker/$instance-output.json
    jq --arg replacement "system:node:$instance" \
        '.CN = $replacement' \
        ./worker-template-csr.json >certs/"$csrfile"

    EXTERNAL_IP=$(nslookup "$instance.kubelab" | grep "Address: " | awk '{print $2}')
    # echo "$EXTERNAL_IP"
    cfssl gencert \
        -ca=certs/ca.crt \
        -ca-key=certs/ca.key \
        -config=ca-config.json \
        -hostname="$instance,$instance.kubelab,$EXTERNAL_IP" \
        -profile=kubernetes \
        "certs/${instance}-csr.json" | cfssljson -bare "${instance}"
    mkdir -p certs
    mv "${instance}".pem certs/"${instance}.crt"
    mv "${instance}"-key.pem certs/"${instance}.key"
    rm -f "${instance}".csr
    rm -f "certs/${instance}-csr.json"

}
function generateallworkercerts() {
    # rm worker/*
    for instance in worker-1 worker-2 worker-3 worker-4 worker-5 worker-6; do
        generateworkercert "${instance}"
    done
}
# function generateapicert() {
#     local instance="$1"

#     local KUBERNETES_PUBLIC_ADDRESS=$(nslookup "$instance.kubelab" | grep "Address: " | awk '{print $2}')
#     local KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

#     # echo "$EXTERNAL_IP"
#     cfssl gencert \
#         -ca=certs/ca.crt \
#         -ca-key=certs/ca.key \
#         -config=ca-config.json \
#         -hostname="10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES},${instance}.kubelab" \
#         -profile=kubernetes \
#         "kube-apiserver-csr.json" | cfssljson -bare "apiserver-${instance}"
#     mkdir -p certs
#     mv "apiserver-${instance}.pem" "certs/apiserver-${instance}.crt"
#     mv "apiserver-${instance}-key.pem" "certs/apiserver-${instance}.key"
#     rm -f "apiserver-${instance}.csr"
# }
function generatefullapicert() {
    myecho "Generate kube-api certs"
    local loadbalancerhostname=kubernetes.kubelab
    local KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

    local machines=(master-1 master-2 master-3 lb-1 lb-2)
    local ip_addresses=()
    local hostnames=()
    # Display the list of modified machines
    for instance in "${machines[@]}"; do
        hostnames+=("$instance.kubelab")
        ip_addresses+=($(nslookup "$instance.kubelab" | grep "Address: " | awk '{print $2}'))
    done
    # echo ${ip_addresses[*]}
    hostnamesstring=$(echo "${hostnames[*]}" | tr ' ' ',')
    ip_addressesstring=$(echo "${ip_addresses[*]}" | tr ' ' ',')
    # ip_addressesstring=($(echo "${ipaddresses[*]}" | tr ' ' ','))
    # echo "10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${ip_addressesstring},127.0.0.1,${KUBERNETES_HOSTNAMES},${hostnamesstring}"

    cfssl gencert \
        -ca=certs/ca.crt \
        -ca-key=certs/ca.key \
        -config=ca-config.json \
        -hostname="10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${ip_addressesstring},127.0.0.1,${loadbalancerhostname},${KUBERNETES_HOSTNAMES},${hostnamesstring}" \
        -profile=kubernetes \
        "kubernetes-csr.json" | cfssljson -bare "kubernetes"
    mkdir -p certs
    mv "kubernetes.pem" "certs/kubernetes.crt"
    mv "kubernetes-key.pem" "certs/kubernetes.key"
    rm -f "kubernetes.csr"
    # echo "$hostnamesstring,$ip_addressesstring"
    # echo "${ip_addresses[@]}"
}

# function generateallapicerts() {
#     # rm worker/*
#     for instance in master-1 master-2 master-3; do
#         generateapicert "${instance}"
#     done
# }
function generateserviceaccountcert() {
    myecho "Generate Service Account Certs"
    cfssl gencert -ca=certs/ca.crt -ca-key=certs/ca.key -config=ca-config.json -profile=kubernetes service-account-csr.json | cfssljson -bare service-account
    mkdir -p certs
    mv service-account.pem certs/service-account.crt
    mv service-account-key.pem certs/service-account.key
    rm service-account.csr
}
function generateadmincert() {
    myecho "Generate admin certs"
    cfssl gencert -ca=certs/ca.crt -ca-key=certs/ca.key -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
    mkdir -p certs
    mv admin.pem certs/admin.crt
    mv admin-key.pem certs/admin.key
    rm admin.csr
}
rm -rf certs
generateca
generatecontrollermanagercert
generatekubeproxycert
generatekubeschedulercert
generateallworkercerts
generatefullapicert
generateadmincert
generateserviceaccountcert
