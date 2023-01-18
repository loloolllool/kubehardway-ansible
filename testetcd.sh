#!/bin/bash
ETCDCTL_API=3
etcdctl member list \
    --endpoints=https://master-3.kubelab:2379 \
    --cacert="ca/certs/ca.crt" \
    --cert="ca/certs/kubernetes.crt" \
    --key="ca/certs/kubernetes.key"
