#!/bin/bash

# Simple GKE cluster health monitor
# Continuously monitors cluster status and key components

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}=== GKE Cluster Status - $(date) ===${NC}"

    # Nodes overview with resource usage
    echo -e "${BLUE}Nodes:${NC}"
    kubectl get nodes --no-headers | while read line; do
        name=$(echo $line | awk '{print $1}')
        status=$(echo $line | awk '{print $2}')

        # Get pod count for this node
        pod_count=$(kubectl get pods --all-namespaces --field-selector spec.nodeName="$name" --no-headers 2>/dev/null | wc -l)

        # Get resource usage (if metrics available)
        resource_info=""
        if kubectl top node "$name" &>/dev/null; then
            cpu_usage=$(kubectl top node "$name" --no-headers 2>/dev/null | awk '{print $3}')
            mem_usage=$(kubectl top node "$name" --no-headers 2>/dev/null | awk '{print $5}')
            resource_info=" - CPU: ${cpu_usage} Mem: ${mem_usage}"
        fi

        if [[ $status == "Ready" ]]; then
            echo -e "  ${GREEN}✅ $name${NC} (${pod_count} pods)${resource_info}"
        else
            echo -e "  ${RED}❌ $name ($status)${NC} (${pod_count} pods)${resource_info}"
        fi
    done

    # Node pool distribution
    local regular=$(kubectl get nodes -l node-pool=regular --no-headers 2>/dev/null | wc -l)
    local spot=$(kubectl get nodes -l node-pool=spot --no-headers 2>/dev/null | wc -l)
    echo -e "  Regular: $regular, Spot: $spot"

    # Key workloads
    echo -e "${BLUE}Key Services:${NC}"

    # NGINX Ingress
    if kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --no-headers 2>/dev/null | grep -q "Running"; then
        echo -e "  ${GREEN}✅ NGINX Ingress${NC}"
    else
        echo -e "  ${RED}❌ NGINX Ingress${NC}"
    fi

    # Cloudflare Tunnel
    if kubectl get pods -n cloudflare --no-headers 2>/dev/null | grep -q "Running"; then
        echo -e "  ${GREEN}✅ Cloudflare Tunnel${NC}"
    else
        echo -e "  ${RED}❌ Cloudflare Tunnel${NC}"
    fi

    # Recent events (last 5)
    echo -e "${BLUE}Recent Events:${NC}"
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' --field-selector type!=Normal

    echo ""
}

# Main loop - runs continuously
echo "Starting GKE cluster monitor (Ctrl+C to stop)..."
echo ""

while true; do
    print_status
    sleep 30
done
