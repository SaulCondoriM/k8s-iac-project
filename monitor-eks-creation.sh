#!/bin/bash

echo "🔍 Monitoreando creación del cluster EKS..."
echo ""

while true; do
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║     📊 ESTADO DE CREACIÓN DE CLUSTER EKS         ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    echo "⏰ $(date '+%H:%M:%S')"
    echo ""
    
    # Últimas 10 líneas del log
    echo "📝 Progreso actual:"
    tail -n 10 /tmp/eks-creation-v2.log 2>/dev/null | grep -E "\[ℹ\]|\[✔\]|\[✖\]" | tail -5
    echo ""
    
    # Intentar ver el cluster
    echo "🎯 Estado del cluster:"
    eksctl get cluster --name k8s-autoscaling-cluster --region us-east-1 2>/dev/null || echo "   ⏳ Aún en creación..."
    echo ""
    
    # Intentar ver nodos
    echo "🖥️  Nodos:"
    kubectl get nodes 2>/dev/null || echo "   ⏳ Esperando nodos..."
    echo ""
    
    echo "Actualización cada 30 segundos... (Ctrl+C para salir)"
    sleep 30
done
