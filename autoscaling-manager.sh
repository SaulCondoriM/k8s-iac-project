#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}K8s Autoscaling Demo - Manager${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

show_menu() {
    echo -e "${GREEN}1)${NC} Deploy complete autoscaling infrastructure"
    echo -e "${GREEN}2)${NC} Run load test with monitoring"
    echo -e "${GREEN}3)${NC} Show current status (HPA, Pods, Services)"
    echo -e "${GREEN}4)${NC} Access Grafana (port-forward)"
    echo -e "${GREEN}5)${NC} Access Locust UI info"
    echo -e "${GREEN}6)${NC} Monitor HPA in real-time"
    echo -e "${GREEN}7)${NC} Monitor Pods in real-time"
    echo -e "${GREEN}8)${NC} Get Grafana password"
    echo -e "${GREEN}9)${NC} Show all access URLs"
    echo -e "${GREEN}10)${NC} Cleanup all resources"
    echo -e "${RED}0)${NC} Exit"
    echo ""
}

deploy_infrastructure() {
    echo -e "${YELLOW}Deploying autoscaling infrastructure...${NC}"
    cd ansible && ansible-playbook deploy-autoscaling.yml
}

run_load_test() {
    echo -e "${YELLOW}Starting load test...${NC}"
    cd ansible && ansible-playbook run-load-test.yml
}

show_status() {
    echo -e "${BLUE}=== Current Status ===${NC}"
    echo ""
    echo -e "${GREEN}HPA Status:${NC}"
    kubectl get hpa
    echo ""
    echo -e "${GREEN}Application Pods:${NC}"
    kubectl get pods -l app=do-sample-app
    echo ""
    echo -e "${GREEN}Monitoring Pods:${NC}"
    kubectl get pods -n monitoring | grep -E "NAME|grafana|prometheus-prometheus"
    echo ""
    echo -e "${GREEN}Locust Pods:${NC}"
    kubectl get pods -l app=locust-master
    kubectl get pods -l app=locust-worker
    echo ""
    echo -e "${GREEN}Services:${NC}"
    kubectl get svc | grep -E "NAME|do-sample-app|locust"
}

access_grafana() {
    echo -e "${YELLOW}Starting port-forward to Grafana...${NC}"
    echo -e "${GREEN}Access Grafana at: ${NC}http://localhost:3000"
    echo -e "${GREEN}Username: ${NC}admin"
    PASSWORD=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d)
    echo -e "${GREEN}Password: ${NC}${PASSWORD}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop port-forward${NC}"
    kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
}

show_locust_info() {
    echo -e "${BLUE}=== Locust Access Information ===${NC}"
    echo ""
    LOCUST_IP=$(kubectl get svc locust-master-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$LOCUST_IP" ]; then
        echo -e "${YELLOW}Waiting for Load Balancer IP...${NC}"
        kubectl get svc locust-master-service
    else
        echo -e "${GREEN}Locust Web UI: ${NC}http://${LOCUST_IP}:8089"
        echo -e "${GREEN}Target Host: ${NC}http://do-sample-app-service:8080"
    fi
    echo ""
    echo -e "${YELLOW}Alternative: Use port-forward${NC}"
    echo -e "kubectl port-forward svc/locust-master-service 8089:8089"
    echo -e "Then access: http://localhost:8089"
}

monitor_hpa() {
    echo -e "${YELLOW}Monitoring HPA (Press Ctrl+C to stop)...${NC}"
    kubectl get hpa do-sample-app-hpa -w
}

monitor_pods() {
    echo -e "${YELLOW}Monitoring Pods (Press Ctrl+C to stop)...${NC}"
    kubectl get pods -l app=do-sample-app -w
}

get_grafana_password() {
    PASSWORD=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d)
    echo -e "${GREEN}Grafana Admin Password: ${NC}${PASSWORD}"
}

show_all_urls() {
    echo -e "${BLUE}=== All Access URLs ===${NC}"
    echo ""
    
    # Application
    APP_IP=$(kubectl get svc do-sample-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -z "$APP_IP" ]; then
        APP_IP="45.55.116.144"
    fi
    echo -e "${GREEN}Application: ${NC}http://${APP_IP}"
    
    # Locust
    LOCUST_IP=$(kubectl get svc locust-master-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ ! -z "$LOCUST_IP" ]; then
        echo -e "${GREEN}Locust UI: ${NC}http://${LOCUST_IP}:8089"
    else
        echo -e "${YELLOW}Locust: ${NC}Pending external IP..."
    fi
    
    # Grafana
    PASSWORD=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d 2>/dev/null)
    echo -e "${GREEN}Grafana: ${NC}http://localhost:3000 (requires port-forward)"
    echo -e "  ${GREEN}User: ${NC}admin"
    echo -e "  ${GREEN}Pass: ${NC}${PASSWORD}"
    echo -e "  ${GREEN}Command: ${NC}kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    
    echo ""
    echo -e "${BLUE}=== Quick Status ===${NC}"
    kubectl get hpa 2>/dev/null | head -2
}

cleanup() {
    echo -e "${RED}WARNING: This will remove all autoscaling infrastructure${NC}"
    echo -e "${YELLOW}The main application will remain active${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        echo -e "${YELLOW}Cleaning up...${NC}"
        cd ansible && ansible-playbook cleanup.yml
    else
        echo -e "${GREEN}Cleanup cancelled${NC}"
    fi
}

# Main loop
while true; do
    show_menu
    read -p "Select an option: " choice
    echo ""
    
    case $choice in
        1) deploy_infrastructure ;;
        2) run_load_test ;;
        3) show_status ;;
        4) access_grafana ;;
        5) show_locust_info ;;
        6) monitor_hpa ;;
        7) monitor_pods ;;
        8) get_grafana_password ;;
        9) show_all_urls ;;
        10) cleanup ;;
        0) 
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done
