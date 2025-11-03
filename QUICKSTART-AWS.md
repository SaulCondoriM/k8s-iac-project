# 🚀 Guía Rápida: AWS EKS Autoscaling

## Paso 1: Instalar Dependencias

```bash
# Instalar eksctl (necesita sudo)
./install-eksctl.sh

# Verificar otras dependencias
aws --version      # AWS CLI
kubectl version    # kubectl
helm version       # Helm
ansible --version  # Ansible
```

Si falta alguna, ver sección "Prerequisitos" en `README-AWS.md`

---

## Paso 2: Verificar Credenciales AWS

```bash
# Ver tu identidad AWS
aws sts get-caller-identity

# Verificar región (debe ser us-east-1)
aws configure get region
```

---

## Paso 3: Desplegar Cluster EKS

### Opción A: Script Interactivo (Recomendado)

```bash
./aws-eks-manager.sh

# En el menú, selecciona:
# 1) Desplegar Cluster EKS Completo
```

### Opción B: Comandos Directos

```bash
./aws-eks-manager.sh deploy
```

**Tiempo**: 20-25 minutos

---

## Paso 4: Verificar Despliegue

```bash
# Ver estado completo
./aws-eks-manager.sh status

# O manualmente:
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get hpa
```

---

## Paso 5: Ejecutar Prueba de Carga

```bash
# 1. Obtener URL de Locust
./aws-eks-manager.sh load-test

# 2. Abrir navegador en la URL mostrada
# 3. Configurar:
#    - Number of users: 100
#    - Spawn rate: 10
#    - Host: http://do-sample-app-service:8080

# 4. Click "Start swarming"

# 5. En otra terminal, monitorear:
./aws-eks-manager.sh monitor-hpa    # Ver escalado de pods
./aws-eks-manager.sh monitor-nodes  # Ver escalado de nodos
```

---

## Paso 6: Observar Autoscaling

### Escalado de Pods (HPA)

```bash
# Terminal 1: Ver HPA en tiempo real
kubectl get hpa -w

# Terminal 2: Ver pods
kubectl get pods -l app=do-sample-app -w

# Terminal 3: Ver métricas
watch kubectl top pods -l app=do-sample-app
```

**Esperado**: 2 → 4 → 6 → 8 → 10 pods en 2-5 minutos

### Escalado de Nodos (Cluster Autoscaler)

```bash
# Terminal 1: Ver nodos
kubectl get nodes -w

# Terminal 2: Ver logs del autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# Terminal 3: Ver pods pending
watch 'kubectl get pods -l app=do-sample-app | grep Pending'
```

**Esperado**: 
- Pods en Pending cuando HPA escala más allá de la capacidad
- Nuevo nodo EC2 creado en 3-5 minutos
- Pods Pending se programan en el nuevo nodo

---

## Paso 7: Acceder a Grafana

```bash
# Obtener URL y contraseña
kubectl get svc prometheus-grafana -n monitoring

# Obtener contraseña
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d
echo

# Abrir navegador: http://<LOADBALANCER-URL>
# Usuario: admin
# Contraseña: <la del comando anterior>
```

**Dashboards recomendados**:
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)

---

## Paso 8: Limpiar Recursos

### Limpiar componentes pero mantener cluster:

```bash
./aws-eks-manager.sh cleanup
```

### Destruir completamente el cluster:

```bash
./aws-eks-manager.sh destroy
```

⚠️ **Esto eliminará TODO y es irreversible**

---

## 📊 Resultados Esperados

### Escalado Exitoso de Pods

```
Tiempo    | Carga    | Pods | CPU   | Estado
----------|----------|------|-------|------------------
T+0       | Ninguna  | 2    | ~5%   | Inicial
T+1min    | Media    | 4    | ~60%  | Escalando
T+2min    | Alta     | 6    | ~55%  | Escalando
T+3min    | Alta     | 8    | ~50%  | Cerca del target
T+5min    | Alta     | 10   | ~50%  | Estable (max)
```

### Escalado Exitoso de Nodos

```
Tiempo    | Nodos | Estado de Pods      | Acción
----------|-------|---------------------|----------------------
T+0       | 2     | 2 running           | Inicial
T+2min    | 2     | 6 running           | HPA escaló, caben
T+3min    | 2     | 8 running, 2 pending| Sin recursos
T+4min    | 2     | Logs: "scale-up"    | CA detecta necesidad
T+7min    | 3     | 10 running          | Nuevo nodo creado ✅
```

---

## 🐛 Problemas Comunes

### Error: "cluster not found"

```bash
# Verificar que el cluster existe
eksctl get cluster --region us-east-1

# Si no existe, créalo primero
cd ansible-aws
eksctl create cluster -f cluster-config.yaml
```

### Error: "unauthorized" al acceder al cluster

```bash
# Reconfigurar kubectl
aws eks update-kubeconfig --name k8s-autoscaling-cluster --region us-east-1
```

### Pods en "Pending" mucho tiempo

```bash
# Ver por qué está pending
kubectl describe pod <pod-name>

# Verificar logs del Cluster Autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

### LoadBalancer en "Pending"

```bash
# Ver eventos del servicio
kubectl describe svc <service-name>

# Esperar 2-3 minutos (es normal que tarde)
```

---

## 💰 Estimación de Costos

### Durante las Pruebas (1-2 horas)

- **Con Free Tier**: $0-2 USD
- **Sin Free Tier**: $0.50-1 USD

### Si lo dejas corriendo 24h

- **Con Free Tier**: ~$3-5 USD/día
- **Sin Free Tier**: ~$5-8 USD/día

⚠️ **IMPORTANTE**: Destruye el cluster cuando no lo uses para evitar cargos.

```bash
./aws-eks-manager.sh destroy
```

---

## 📚 Archivos Importantes

| Archivo | Descripción |
|---------|-------------|
| `aws-eks-manager.sh` | Script principal de gestión |
| `README-AWS.md` | Documentación completa |
| `ansible-aws/cluster-config.yaml` | Configuración del cluster |
| `ansible-aws/deploy-eks-autoscaling.yml` | Playbook de despliegue |
| `manifests-aws/cluster-autoscaler.yaml` | Políticas de autoscaling de nodos |
| `manifests-aws/hpa.yaml` | Políticas de autoscaling de pods |

---

## ✅ Checklist de Verificación

Antes de empezar:
- [ ] AWS CLI instalado y configurado
- [ ] eksctl instalado
- [ ] kubectl instalado
- [ ] Helm instalado
- [ ] Ansible instalado
- [ ] Credenciales AWS verificadas (`aws sts get-caller-identity`)
- [ ] Región configurada en us-east-1

Después del despliegue:
- [ ] Cluster EKS creado (`kubectl get nodes`)
- [ ] Pods corriendo (`kubectl get pods -A`)
- [ ] HPA configurado (`kubectl get hpa`)
- [ ] Cluster Autoscaler corriendo (`kubectl get deployment -n kube-system cluster-autoscaler`)
- [ ] LoadBalancers asignados (`kubectl get svc -A | grep LoadBalancer`)

Durante las pruebas:
- [ ] HPA escala pods correctamente
- [ ] Cluster Autoscaler crea nuevos nodos cuando es necesario
- [ ] Scale down funciona después de quitar carga
- [ ] Grafana muestra métricas correctamente

---

## 🎯 Próximos Pasos

1. **Explorar Grafana**: Ver dashboards de Kubernetes
2. **Experimentar con carga**: Probar diferentes configuraciones en Locust
3. **Modificar políticas**: Cambiar thresholds en HPA y Cluster Autoscaler
4. **Ver costos**: Revisar AWS Cost Explorer
5. **Limpiar**: Destruir recursos cuando termines

---

**¿Problemas?** Revisa `README-AWS.md` sección "Troubleshooting"

**¿Dudas sobre costos?** Revisa `README-AWS.md` sección "Costos Estimados"
