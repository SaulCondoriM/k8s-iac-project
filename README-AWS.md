# 🚀 Kubernetes Autoscaling en AWS EKS

## 📋 Descripción

Este proyecto implementa **autoescalado completo** (Pods y Nodos) en **AWS EKS** usando Kubernetes, con infraestructura como código mediante Ansible.

### ✨ Características Principales

- ✅ **HPA (Horizontal Pod Autoscaler)**: Escala pods de 2 a 10 réplicas
- ✅ **Cluster Autoscaler**: Escala nodos EC2 de 2 a 5 instancias
- ✅ **Políticas Avanzadas**: Configuración detallada de comportamiento de scaling
- ✅ **Monitoreo**: Prometheus + Grafana con dashboards preconfigurados
- ✅ **Load Testing**: Locust distribuido para pruebas de carga
- ✅ **Automatización Completa**: Ansible + eksctl
- ✅ **Optimizado para Free Tier**: Minimiza costos en cuentas nuevas

---

## 🏗️ Arquitectura

```
                                ┌─────────────────────┐
                                │   AWS Cloud         │
                                └─────────────────────┘
                                          │
                    ┌────────────────────┴────────────────────┐
                    │         VPC (10.0.0.0/16)               │
                    │                                          │
                    │  ┌────────────────────────────────────┐ │
                    │  │    EKS Cluster                     │ │
                    │  │                                    │ │
                    │  │  ┌──────────────────────────────┐ │ │
                    │  │  │  Control Plane (Managed)     │ │ │
                    │  │  └──────────────────────────────┘ │ │
                    │  │                                    │ │
                    │  │  ┌──────────────────────────────┐ │ │
                    │  │  │  Worker Nodes (EC2)          │ │ │
                    │  │  │  ┌────────────────────────┐  │ │ │
                    │  │  │  │ Cluster Autoscaler     │  │ │ │
                    │  │  │  │ (Escala Nodos)         │  │ │ │
                    │  │  │  └────────────────────────┘  │ │ │
                    │  │  │                               │ │ │
                    │  │  │  Min: 2 nodes (t3.medium)    │ │ │
                    │  │  │  Max: 5 nodes                │ │ │
                    │  │  └──────────────────────────────┘ │ │
                    │  │                                    │ │
                    │  │  ┌──────────────────────────────┐ │ │
                    │  │  │  Application Pods            │ │ │
                    │  │  │  ┌────────────────────────┐  │ │ │
                    │  │  │  │ HPA                    │  │ │ │
                    │  │  │  │ (Escala Pods)          │  │ │ │
                    │  │  │  └────────────────────────┘  │ │ │
                    │  │  │                               │ │ │
                    │  │  │  Min: 2 pods                 │ │ │
                    │  │  │  Max: 10 pods                │ │ │
                    │  │  │  Triggers: CPU 50%, Mem 70%  │ │ │
                    │  │  └──────────────────────────────┘ │ │
                    │  │                                    │ │
                    │  │  ┌──────────────────────────────┐ │ │
                    │  │  │  Monitoring Stack            │ │ │
                    │  │  │  • Prometheus                │ │ │
                    │  │  │  • Grafana                   │ │ │
                    │  │  │  • Metrics Server            │ │ │
                    │  │  └──────────────────────────────┘ │ │
                    │  └────────────────────────────────────┘ │
                    │                                          │
                    │  ┌────────────────────────────────────┐ │
                    │  │    Elastic Load Balancers          │ │
                    │  │  • Application                     │ │
                    │  │  • Locust UI                       │ │
                    │  │  • Grafana                         │ │
                    │  └────────────────────────────────────┘ │
                    └──────────────────────────────────────────┘
```

---

## 📦 Componentes

### Cluster Autoscaler

**Políticas de Scaling de Nodos**:

```yaml
Scale Up:
  - Trigger: Pods en estado Pending (sin recursos)
  - Acción: Crear nueva instancia EC2 t3.medium
  - Tiempo: ~3-5 minutos
  - Máximo: 5 nodos

Scale Down:
  - Trigger: Utilización < 50% por 10 minutos
  - Delay: 10 minutos después de scale up
  - Acción: Terminar instancia EC2
  - Protección: No elimina nodos con pods del sistema
```

### HPA (Horizontal Pod Autoscaler)

**Políticas de Scaling de Pods**:

```yaml
Métricas:
  - CPU: 50% utilización promedio
  - Memory: 70% utilización promedio

Scale Up:
  - Duplica pods cada 15 segundos
  - Máximo 4 pods por ciclo
  - Sin delay (respuesta inmediata)

Scale Down:
  - Reduce 50% cada 15 segundos
  - Stabilization window: 5 minutos
  - Comportamiento conservador
```

---

## 🛠️ Prerequisitos

### Software Requerido

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Ansible
pip install ansible
```

### Cuenta AWS

- ✅ Cuenta AWS activa
- ✅ Credenciales configuradas (`aws configure`)
- ✅ Permisos para crear:
  - EKS clusters
  - EC2 instances
  - VPCs, subnets, security groups
  - IAM roles y políticas
  - Load Balancers
  - EBS volumes

### Verificar Configuración

```bash
# Verificar AWS CLI
aws sts get-caller-identity

# Verificar región
aws configure get region
# Debe retornar: us-east-1
```

---

## 🚀 Instalación Rápida

### Opción 1: Script Interactivo (Recomendado)

```bash
# Hacer el script ejecutable
chmod +x aws-eks-manager.sh

# Ejecutar el menú interactivo
./aws-eks-manager.sh

# Selecciona opción 1: Desplegar Cluster EKS Completo
```

**Tiempo estimado**: 20-25 minutos

### Opción 2: Comandos Manuales

```bash
# 1. Crear cluster EKS
cd ansible-aws
eksctl create cluster -f cluster-config.yaml

# 2. Configurar kubectl
aws eks update-kubeconfig --name k8s-autoscaling-cluster --region us-east-1

# 3. Agregar repo Helm de Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 4. Desplegar componentes
ansible-playbook deploy-eks-autoscaling.yml

# 5. Verificar despliegue
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get hpa
```

---

## 📊 Uso

### Ver Estado del Cluster

```bash
# Opción 1: Script
./aws-eks-manager.sh status

# Opción 2: Manual
kubectl get nodes
kubectl get hpa
kubectl get pods -l app=do-sample-app
kubectl get deployment cluster-autoscaler -n kube-system
```

### Monitorear en Tiempo Real

```bash
# HPA
./aws-eks-manager.sh monitor-hpa
# O: kubectl get hpa -w

# Pods
./aws-eks-manager.sh monitor-pods
# O: kubectl get pods -l app=do-sample-app -w

# Nodos
./aws-eks-manager.sh monitor-nodes
# O: kubectl get nodes -w

# Logs del Cluster Autoscaler
./aws-eks-manager.sh logs
# O: kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

### Ejecutar Prueba de Carga

```bash
# 1. Obtener URL de Locust
./aws-eks-manager.sh load-test

# 2. Abrir en navegador: http://<LOCUST-URL>:8089

# 3. Configurar prueba:
#    - Usuarios: 100
#    - Spawn rate: 10/s
#    - Host: http://do-sample-app-service:8080

# 4. Click "Start swarming"

# 5. En otra terminal, monitorear:
./aws-eks-manager.sh monitor-hpa
./aws-eks-manager.sh monitor-nodes
```

### Acceder a Grafana

```bash
# Obtener URL y contraseña
kubectl get svc prometheus-grafana -n monitoring
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d

# Abrir en navegador: http://<GRAFANA-URL>
# Usuario: admin
# Contraseña: <output del comando anterior>
```

---

## 🎯 Escenarios de Prueba

### Escenario 1: Scale Up de Pods (Sin Scale Up de Nodos)

**Objetivo**: Ver HPA escalando pods dentro de los nodos existentes.

```bash
# 1. Estado inicial
kubectl get nodes
kubectl get pods -l app=do-sample-app
# Debería ver: 2 nodos, 2 pods

# 2. Generar carga moderada en Locust
#    Usuarios: 50, Spawn rate: 5/s

# 3. Observar en 2-3 minutos
kubectl get hpa -w
# Debería ver: 2 → 4 → 6 pods
# Nodos se mantienen en 2
```

### Escenario 2: Scale Up de Nodos (Pods Pending)

**Objetivo**: Ver Cluster Autoscaler creando nuevos nodos EC2.

```bash
# 1. Estado inicial
kubectl get nodes
# Debería ver: 2 nodos

# 2. Generar carga alta en Locust
#    Usuarios: 200, Spawn rate: 20/s

# 3. Observar HPA escalando pods
kubectl get hpa -w
# 2 → 4 → 6 → 8 → 10 pods

# 4. Algunos pods quedarán en Pending
kubectl get pods -l app=do-sample-app
# Verás pods en estado: Pending

# 5. Cluster Autoscaler detectará esto
kubectl logs -f deployment/cluster-autoscaler -n kube-system
# Verás logs: "Scale-up: creating new node..."

# 6. En 3-5 minutos, nuevo nodo aparece
kubectl get nodes -w
# 2 → 3 nodos (nueva instancia EC2)

# 7. Pods Pending se programan en el nuevo nodo
kubectl get pods -l app=do-sample-app -o wide
```

### Escenario 3: Scale Down Completo

**Objetivo**: Ver scale down de pods y luego de nodos.

```bash
# 1. Después de tener carga alta (3+ nodos, 8+ pods)

# 2. Detener carga en Locust
#    Click "Stop"

# 3. HPA empieza scale down después de 5 minutos
kubectl get hpa -w
# 10 → 8 → 6 → 4 → 3 → 2 pods

# 4. Cluster Autoscaler espera 10 minutos de baja utilización
kubectl logs -f deployment/cluster-autoscaler -n kube-system
# Verás: "node X is underutilized"

# 5. Después de 10 minutos, elimina nodos extra
kubectl get nodes -w
# 3 → 2 nodos

# 6. Pods se re-programan en nodos restantes
kubectl get pods -l app=do-sample-app -o wide
```

---

## 📈 Métricas y Observabilidad

### Dashboards de Grafana

1. **Kubernetes / Compute Resources / Cluster**
   - CPU y Memory del cluster completo
   - Utilización por nodo

2. **Kubernetes / Compute Resources / Namespace (Pods)**
   - CPU y Memory por pod
   - Request rate

3. **Cluster Autoscaler**
   - Eventos de scaling
   - Nodos agregados/removidos
   - Pods pending

### Comandos Útiles

```bash
# Métricas en tiempo real
kubectl top nodes
kubectl top pods -l app=do-sample-app

# Eventos del cluster (ver scaling)
kubectl get events --sort-by='.lastTimestamp' | grep -E 'ScalingReplicaSet|TriggeredScaleUp'

# Describir HPA (ver targets y eventos)
kubectl describe hpa do-sample-app-hpa

# Estado del Auto Scaling Group (nodos)
aws autoscaling describe-auto-scaling-groups --region us-east-1 | jq '.AutoScalingGroups[] | select(.AutoScalingGroupName | contains("eks"))'

# Activity history del ASG
aws autoscaling describe-scaling-activities --auto-scaling-group-name <ASG-NAME> --max-records 10
```

---

## 💰 Costos Estimados

### Free Tier (Primeros 12 meses)

| Componente | Cantidad | Costo/mes | Free Tier | Real |
|------------|----------|-----------|-----------|------|
| EKS Control Plane | 1 | $73.00 | $73.00 | $0.00* |
| EC2 t3.medium | 2-5 | $30.37 c/u | 750h gratis | ~$15-30 |
| EBS gp3 | ~60GB | $0.08/GB | - | ~$5 |
| Load Balancers | 3 | $16.20 c/u | - | ~$49 |
| **Total estimado** | | | | **$70-85/mes** |

\* *EKS Free Tier válido 12 meses desde creación de cuenta*

### Sin Free Tier

- **Costo mensual**: ~$150-200
- **Costo por hora**: ~$0.20-0.27

### Recomendaciones para Minimizar Costos

```bash
# 1. Destruir cluster cuando no lo uses
./aws-eks-manager.sh destroy

# 2. Usar instancias Spot (70% descuento)
# Editar ansible-aws/cluster-config.yaml:
# managedNodeGroups[0].spot: true

# 3. Reducir LoadBalancers
# Cambiar servicios a NodePort en manifests-aws/*.yaml

# 4. Usar t3.small en lugar de t3.medium
# Editar ansible-aws/cluster-config.yaml:
# managedNodeGroups[0].instanceType: t3.small
```

---

## 🧹 Limpieza

### Limpiar Componentes (Mantener Cluster)

```bash
# Opción 1: Script
./aws-eks-manager.sh cleanup

# Opción 2: Ansible
cd ansible-aws
ansible-playbook cleanup-eks.yml
```

Esto elimina:
- ✅ Aplicación y HPA
- ✅ Locust
- ✅ Cluster Autoscaler
- ✅ Prometheus y Grafana
- ✅ Metrics Server

Mantiene:
- ❌ Cluster EKS
- ❌ Nodos EC2
- ❌ VPC y networking

### Destruir Cluster Completo

```bash
# Opción 1: Script (solicita confirmación)
./aws-eks-manager.sh destroy

# Opción 2: Manual
eksctl delete cluster --name k8s-autoscaling-cluster --region us-east-1
```

**⚠️ ADVERTENCIA**: Esto elimina TODO de forma permanente.

**Tiempo estimado**: 10-15 minutos

---

## 🔧 Configuración Avanzada

### Modificar Políticas del Cluster Autoscaler

Editar `manifests-aws/cluster-autoscaler.yaml`:

```yaml
# Líneas 70-80 del deployment
- --scale-down-delay-after-add=10m      # Espera después de agregar nodo
- --scale-down-unneeded-time=10m        # Tiempo de baja utilización
- --scale-down-utilization-threshold=0.5 # 50% de utilización
- --max-node-provision-time=15m         # Timeout para crear nodo
```

### Modificar Límites del Node Group

Editar `ansible-aws/cluster-config.yaml`:

```yaml
managedNodeGroups:
  - name: worker-nodes
    desiredCapacity: 2
    minSize: 1          # Cambiar mínimo
    maxSize: 10         # Cambiar máximo
    instanceType: t3.large  # Cambiar tipo
```

Aplicar cambios:

```bash
eksctl scale nodegroup --cluster=k8s-autoscaling-cluster --name=worker-nodes --nodes-min=1 --nodes-max=10
```

### Usar Instancias Spot

Editar `ansible-aws/cluster-config.yaml`:

```yaml
managedNodeGroups:
  - name: worker-nodes
    # ... configuración existente ...
    spot: true
    instancesDistribution:
      maxPrice: 0.05  # Precio máximo por hora
      instanceTypes:
        - t3.medium
        - t3a.medium
        - t2.medium
      onDemandBaseCapacity: 0
      onDemandPercentageAboveBaseCapacity: 0
      spotInstancePools: 3
```

---

## 🐛 Troubleshooting

### Pods en Pending después de mucho tiempo

```bash
# Ver eventos del pod
kubectl describe pod <pod-name>

# Posibles causas:
# 1. Límite de nodos alcanzado (maxSize en cluster-config.yaml)
# 2. Cuota de EC2 excedida
# 3. Problemas con IAM roles del Cluster Autoscaler

# Verificar logs del Cluster Autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system | grep -i error
```

### Cluster Autoscaler no crea nodos

```bash
# 1. Verificar que el deployment esté corriendo
kubectl get deployment cluster-autoscaler -n kube-system

# 2. Ver logs detallados
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# 3. Verificar IAM role
kubectl describe sa cluster-autoscaler -n kube-system
# Debe tener annotation: eks.amazonaws.com/role-arn

# 4. Verificar tags del ASG
aws autoscaling describe-auto-scaling-groups --region us-east-1 | \
  jq '.AutoScalingGroups[] | select(.AutoScalingGroupName | contains("eks")) | .Tags'
# Debe tener: k8s.io/cluster-autoscaler/enabled: true
```

### HPA muestra `<unknown>` en targets

```bash
# Verificar Metrics Server
kubectl get deployment metrics-server -n kube-system
kubectl logs -n kube-system deployment/metrics-server

# Esperar 1-2 minutos después del despliegue
kubectl top nodes
kubectl top pods

# Si aún falla, reinstalar
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### LoadBalancers en estado Pending

```bash
# Ver eventos del servicio
kubectl describe svc <service-name>

# Verificar AWS Load Balancer Controller
kubectl get deployment -n kube-system

# Si falta el controller, instalarlo:
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json
```

---

## 📚 Referencias

### Documentación Oficial

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Cluster Autoscaler on AWS](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)
- [HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [eksctl Documentation](https://eksctl.io/)

### Arquitectura del Proyecto

```
k8s-on-digital-ocean-main/
├── ansible-aws/                    # Configuración Ansible para AWS
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── cluster-config.yaml         # Configuración del cluster EKS
│   ├── deploy-eks-autoscaling.yml  # Playbook de despliegue
│   └── cleanup-eks.yml             # Playbook de limpieza
│
├── manifests-aws/                  # Manifests de Kubernetes para AWS
│   ├── application.yaml            # Deployment + LoadBalancer
│   ├── hpa.yaml                    # HPA configuration
│   ├── locust.yaml                 # Load testing
│   ├── cluster-autoscaler.yaml     # Cluster Autoscaler
│   ├── storage-class.yaml          # EBS GP3 storage
│   ├── postgres-pv.yaml            # PostgreSQL volume
│   └── postgres-connection.yaml    # Database secret
│
├── aws-eks-manager.sh              # Script de gestión interactivo
└── README-AWS.md                   # Este archivo
```

---

## 🎓 Aprendizajes Clave

### Diferencias vs DigitalOcean

| Aspecto | AWS EKS | DigitalOcean K8s |
|---------|---------|------------------|
| **Cluster Autoscaler** | ✅ Completo | ❌ Básico |
| **Políticas de Scaling** | ✅ Avanzadas | ❌ Min/Max simple |
| **Tipos de Instancia** | ✅ 400+ opciones | ❌ Limitado |
| **Spot Instances** | ✅ Sí (70% descuento) | ❌ No |
| **Complejidad** | 🔴 Alta | 🟢 Baja |
| **Costo** | 🔴 Mayor | 🟢 Menor |
| **Free Tier** | ✅ 12 meses | ❌ No |

### Conceptos Demostrados

1. **Autoscaling de Dos Niveles**:
   - HPA escala pods horizontalmente
   - Cluster Autoscaler escala nodos (infraestructura)

2. **Políticas Avanzadas**:
   - Delays configurables
   - Thresholds personalizados
   - Comportamiento de scale up/down diferenciado

3. **IAM Roles for Service Accounts (IRSA)**:
   - Autenticación segura entre K8s y AWS
   - No credentials hardcodeadas

4. **Infrastructure as Code**:
   - Cluster definido en YAML (eksctl)
   - Despliegue automatizado (Ansible)
   - Reproducible y versionable

---

## 🤝 Contribuciones

Este proyecto es parte de una demostración de autoscaling en Kubernetes. Originalmente configurado para DigitalOcean, ahora adaptado para AWS EKS con capacidades avanzadas de autoscaling.

### Próximas Mejoras

- [ ] Integración con AWS CloudWatch Alarms
- [ ] Autoscaling basado en métricas custom (RPS, latencia)
- [ ] Multi-region deployment
- [ ] GitOps con ArgoCD
- [ ] Service Mesh con Istio
- [ ] Karpenter como alternativa al Cluster Autoscaler

---

## 📞 Soporte

### Comandos de Diagnóstico

```bash
# Información completa del cluster
./aws-eks-manager.sh status

# Logs de todos los componentes
kubectl logs -n kube-system deployment/cluster-autoscaler
kubectl logs deployment/do-sample-app
kubectl logs -n monitoring deployment/prometheus-operator

# Exportar configuración para análisis
kubectl get all --all-namespaces -o yaml > cluster-state.yaml
kubectl describe nodes > nodes-info.txt
kubectl get events --sort-by='.lastTimestamp' > events.txt
```

### Recursos de Ayuda

- 📖 [EKS Workshop](https://www.eksworkshop.com/)
- 💬 [AWS EKS Forum](https://repost.aws/tags/TABhLMKzZLSZyb8w2S_wFsLQ/amazon-elastic-kubernetes-service)
- 🐛 [Cluster Autoscaler FAQ](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md)

---

**Creado con ❤️ para demostrar Kubernetes Autoscaling en AWS EKS**
