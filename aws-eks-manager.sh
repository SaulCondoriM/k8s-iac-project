#!/bin/bash

# AWS EKS Autoscaling Management Script
# Este script gestiona el cluster EKS con autoscaling de pods y nodos

set -e

CLUSTER_NAME="k8s-autoscaling-cluster"
REGION="us-east-1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible-aws"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_message() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

print_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

# Verificar dependencias
check_dependencies() {
    print_message "Verificando dependencias..."
    
    local missing_deps=()
    
    if ! command -v aws &> /dev/null; then
        missing_deps+=("aws-cli")
    fi
    
    if ! command -v eksctl &> /dev/null; then
        missing_deps+=("eksctl")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_deps+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_deps+=("helm")
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        missing_deps+=("ansible")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Faltan las siguientes dependencias: ${missing_deps[*]}"
        echo ""
        echo "Instala las dependencias faltantes:"
        echo "  - AWS CLI: https://aws.amazon.com/cli/"
        echo "  - eksctl: curl --silent --location \"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_\$(uname -s)_amd64.tar.gz\" | tar xz -C /tmp && sudo mv /tmp/eksctl /usr/local/bin"
        echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "  - helm: https://helm.sh/docs/intro/install/"
        echo "  - ansible: pip install ansible"
        exit 1
    fi
    
    print_info "✓ Todas las dependencias están instaladas"
}

# Verificar credenciales de AWS
check_aws_credentials() {
    print_message "Verificando credenciales de AWS..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "No se pudieron verificar las credenciales de AWS"
        echo "Ejecuta: aws configure"
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local user=$(aws sts get-caller-identity --query Arn --output text)
    
    print_info "✓ Autenticado como: $user"
    print_info "✓ Account ID: $account_id"
}

# Crear cluster EKS
create_cluster() {
    print_message "Creando cluster EKS: ${CLUSTER_NAME}..."
    
    if eksctl get cluster --name ${CLUSTER_NAME} --region ${REGION} &> /dev/null; then
        print_warning "El cluster ${CLUSTER_NAME} ya existe"
        read -p "¿Deseas continuar sin recrearlo? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_info "Creando cluster (esto puede tardar 15-20 minutos)..."
        eksctl create cluster -f ${ANSIBLE_DIR}/cluster-config.yaml
        
        if [ $? -eq 0 ]; then
            print_info "✓ Cluster creado exitosamente"
        else
            print_error "Error al crear el cluster"
            exit 1
        fi
    fi
    
    # Configurar kubectl context
    print_info "Configurando kubectl context..."
    aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION}
    
    # Verificar conectividad
    if kubectl cluster-info &> /dev/null; then
        print_info "✓ kubectl configurado correctamente"
    else
        print_error "No se pudo conectar al cluster"
        exit 1
    fi
}

# Desplegar componentes con Ansible
deploy_components() {
    print_message "Desplegando componentes de autoscaling con Ansible..."
    
    cd ${ANSIBLE_DIR}
    
    # Agregar repo de Bitnami para PostgreSQL
    print_info "Agregando repositorio Helm de Bitnami..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    # Ejecutar playbook
    ansible-playbook deploy-eks-autoscaling.yml
    
    if [ $? -eq 0 ]; then
        print_info "✓ Componentes desplegados exitosamente"
    else
        print_error "Error al desplegar componentes"
        exit 1
    fi
    
    cd - > /dev/null
}

# Mostrar estado del cluster
show_status() {
    print_message "Estado del Cluster EKS"
    echo ""
    
    # Nodos
    echo -e "${BLUE}=== NODOS (EC2 Instances) ===${NC}"
    kubectl get nodes -o wide
    echo ""
    
    # HPA
    echo -e "${BLUE}=== HORIZONTAL POD AUTOSCALER ===${NC}"
    kubectl get hpa
    echo ""
    
    # Pods de la aplicación
    echo -e "${BLUE}=== PODS DE LA APLICACIÓN ===${NC}"
    kubectl get pods -l app=do-sample-app -o wide
    echo ""
    
    # Cluster Autoscaler
    echo -e "${BLUE}=== CLUSTER AUTOSCALER ===${NC}"
    kubectl get deployment cluster-autoscaler -n kube-system
    echo ""
    
    # LoadBalancers
    echo -e "${BLUE}=== LOADBALANCERS ===${NC}"
    kubectl get svc -A -o wide | grep LoadBalancer
    echo ""
    
    # URLs de acceso
    print_message "URLs de Acceso"
    echo ""
    
    APP_URL=$(kubectl get svc do-sample-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    LOCUST_URL=$(kubectl get svc locust-master-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    GRAFANA_URL=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    GRAFANA_PASS=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 -d || echo "N/A")
    
    echo "📊 Aplicación:    http://${APP_URL}"
    echo "🔥 Locust:        http://${LOCUST_URL}:8089"
    echo "📈 Grafana:       http://${GRAFANA_URL}"
    echo "   Usuario:       admin"
    echo "   Contraseña:    ${GRAFANA_PASS}"
    echo ""
}

# Monitorear HPA en tiempo real
monitor_hpa() {
    print_message "Monitoreando HPA (Ctrl+C para salir)..."
    echo ""
    kubectl get hpa -w
}

# Monitorear Pods en tiempo real
monitor_pods() {
    print_message "Monitoreando Pods (Ctrl+C para salir)..."
    echo ""
    kubectl get pods -l app=do-sample-app -w
}

# Monitorear Nodos en tiempo real
monitor_nodes() {
    print_message "Monitoreando Nodos (Ctrl+C para salir)..."
    echo ""
    kubectl get nodes -w
}

# Ver logs del Cluster Autoscaler
show_autoscaler_logs() {
    print_message "Logs del Cluster Autoscaler (Ctrl+C para salir)..."
    echo ""
    kubectl logs -f deployment/cluster-autoscaler -n kube-system
}

# Ejecutar test de carga
run_load_test() {
    print_message "Configuración de Prueba de Carga"
    echo ""
    
    LOCUST_URL=$(kubectl get svc locust-master-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -z "$LOCUST_URL" ] || [ "$LOCUST_URL" == "Pending..." ]; then
        print_error "El servicio de Locust aún no está disponible"
        echo "Espera unos minutos y vuelve a intentar"
        exit 1
    fi
    
    echo "🔥 Accede a Locust en: http://${LOCUST_URL}:8089"
    echo ""
    echo "Configuraciones recomendadas:"
    echo "  • Test Ligero:   50 usuarios,  spawn rate 5/s"
    echo "  • Test Medio:    100 usuarios, spawn rate 10/s"
    echo "  • Test Pesado:   200 usuarios, spawn rate 20/s"
    echo ""
    echo "Monitorea en otra terminal con:"
    echo "  ./aws-eks-manager.sh monitor-hpa"
    echo "  ./aws-eks-manager.sh monitor-nodes"
    echo ""
}

# Limpiar componentes pero mantener cluster
cleanup_components() {
    print_warning "Esto eliminará todos los componentes de autoscaling pero mantendrá el cluster EKS"
    read -p "¿Continuar? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd ${ANSIBLE_DIR}
        ansible-playbook cleanup-eks.yml
        cd - > /dev/null
        print_info "✓ Limpieza completada"
    fi
}

# Destruir completamente el cluster
destroy_cluster() {
    print_error "⚠️  ADVERTENCIA: Esto eliminará COMPLETAMENTE el cluster EKS"
    print_error "     Todos los datos se perderán de forma PERMANENTE"
    echo ""
    read -p "Escribe 'DELETE' para confirmar: " confirm
    
    if [ "$confirm" == "DELETE" ]; then
        print_message "Eliminando cluster ${CLUSTER_NAME}..."
        eksctl delete cluster --name ${CLUSTER_NAME} --region ${REGION}
        
        if [ $? -eq 0 ]; then
            print_info "✓ Cluster eliminado exitosamente"
        else
            print_error "Error al eliminar el cluster"
            exit 1
        fi
    else
        print_info "Operación cancelada"
    fi
}

# Menú principal
show_menu() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     AWS EKS Autoscaling Manager                      ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  1)  🚀 Desplegar Cluster EKS Completo"
    echo "  2)  📊 Mostrar Estado del Cluster"
    echo "  3)  👀 Monitorear HPA (tiempo real)"
    echo "  4)  👀 Monitorear Pods (tiempo real)"
    echo "  5)  👀 Monitorear Nodos (tiempo real)"
    echo "  6)  📜 Ver Logs del Cluster Autoscaler"
    echo "  7)  🔥 Ejecutar Prueba de Carga"
    echo "  8)  🧹 Limpiar Componentes (mantener cluster)"
    echo "  9)  💣 Destruir Cluster Completo"
    echo "  0)  ❌ Salir"
    echo ""
}

# Main
main() {
    while true; do
        show_menu
        read -p "Selecciona una opción: " choice
        
        case $choice in
            1)
                check_dependencies
                check_aws_credentials
                create_cluster
                deploy_components
                show_status
                ;;
            2)
                show_status
                ;;
            3)
                monitor_hpa
                ;;
            4)
                monitor_pods
                ;;
            5)
                monitor_nodes
                ;;
            6)
                show_autoscaler_logs
                ;;
            7)
                run_load_test
                ;;
            8)
                cleanup_components
                ;;
            9)
                destroy_cluster
                ;;
            0)
                print_info "¡Hasta luego!"
                exit 0
                ;;
            *)
                print_error "Opción inválida"
                ;;
        esac
        
        echo ""
        read -p "Presiona Enter para continuar..."
    done
}

# Si se pasa un comando como argumento
if [ $# -gt 0 ]; then
    case $1 in
        deploy)
            check_dependencies
            check_aws_credentials
            create_cluster
            deploy_components
            show_status
            ;;
        status)
            show_status
            ;;
        monitor-hpa)
            monitor_hpa
            ;;
        monitor-pods)
            monitor_pods
            ;;
        monitor-nodes)
            monitor_nodes
            ;;
        logs)
            show_autoscaler_logs
            ;;
        load-test)
            run_load_test
            ;;
        cleanup)
            cleanup_components
            ;;
        destroy)
            destroy_cluster
            ;;
        *)
            echo "Uso: $0 {deploy|status|monitor-hpa|monitor-pods|monitor-nodes|logs|load-test|cleanup|destroy}"
            exit 1
            ;;
    esac
else
    main
fi
