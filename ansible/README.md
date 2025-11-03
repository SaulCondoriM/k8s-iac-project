# Kubernetes Autoscaling Demo with Ansible

Este proyecto demuestra el autoscaling horizontal (HPA) de una aplicación en Kubernetes usando Ansible para automatización, Locust para pruebas de carga, y Prometheus + Grafana para monitoreo.

## Componentes

### Aplicación
- **Frontend**: HTML/CSS/JavaScript
- **Backend**: Go (Golang)
- **Base de datos**: PostgreSQL
- **Despliegue**: Kubernetes en DigitalOcean

### Infraestructura de Autoscaling
- **HPA (Horizontal Pod Autoscaler)**: Escala de 2 a 10 pods basado en CPU (50%) y memoria (70%)
- **Metrics Server**: Proporciona métricas de recursos
- **Prometheus**: Recolección de métricas
- **Grafana**: Visualización de métricas
- **Locust**: Generación de carga para pruebas

## Requisitos Previos

- Cluster de Kubernetes en DigitalOcean
- kubectl configurado
- Helm 3 instalado
- Ansible instalado
- Aplicación ya desplegada

## Estructura del Proyecto

```
.
├── ansible/
│   ├── ansible.cfg                 # Configuración de Ansible
│   ├── inventory.ini               # Inventario
│   ├── deploy-autoscaling.yml      # Playbook de despliegue completo
│   ├── run-load-test.yml           # Playbook para pruebas de carga
│   └── cleanup.yml                 # Playbook de limpieza
├── manifests/
│   ├── application.yaml            # Deployment de la app con resources
│   ├── hpa.yaml                    # Configuración del HPA
│   └── locust.yaml                 # Deployment de Locust
└── load-testing/
    ├── locustfile.py               # Script de pruebas de Locust
    └── Dockerfile                  # Imagen de Locust personalizada
```

## Instalación de Ansible

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible -y

# macOS
brew install ansible

# Verificar instalación
ansible --version
```

## Uso

### 1. Desplegar toda la infraestructura de autoscaling

```bash
cd ansible
ansible-playbook deploy-autoscaling.yml
```

Este playbook:
- ✅ Instala Metrics Server
- ✅ Instala Prometheus + Grafana
- ✅ Configura HPA
- ✅ Despliega Locust
- ✅ Muestra credenciales y URLs de acceso

### 2. Ejecutar pruebas de carga y monitorear autoscaling

```bash
ansible-playbook run-load-test.yml
```

Este playbook:
- 📊 Muestra el estado inicial de pods y HPA
- 🚀 Inicia Locust y obtiene su IP externa
- 📈 Monitorea el autoscaling en tiempo real
- 📝 Guarda logs de monitoreo
- 📊 Muestra comparación de estado inicial vs final

**Opciones de prueba de carga:**

**Opción 1 - Manual (Recomendada):**
1. Abrir la URL de Locust mostrada en el output
2. Configurar usuarios y spawn rate
3. Iniciar la prueba desde la UI
4. Observar dashboards en tiempo real

**Opción 2 - Automática:**
- El playbook ejecutará una prueba headless de 10 minutos
- 100 usuarios con spawn rate de 10/seg

### 3. Acceder a Grafana

```bash
# Obtener contraseña (mostrada en el playbook)
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d

# Port-forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Acceder a http://localhost:3000
# Usuario: admin
# Password: (obtenida del comando anterior)
```

**Dashboards recomendados en Grafana:**
- **Kubernetes / Compute Resources / Pod**: Métricas por pod
- **Kubernetes / Compute Resources / Namespace (Pods)**: Vista general
- **Node Exporter / Nodes**: Métricas de nodos

### 4. Acceder a Locust

```bash
# Obtener IP externa
kubectl get svc locust-master-service

# O usar port-forward
kubectl port-forward svc/locust-master-service 8089:8089

# Acceder a http://<EXTERNAL-IP>:8089 o http://localhost:8089
```

### 5. Monitorear HPA en tiempo real

```bash
# Ver estado actual
kubectl get hpa

# Monitorear cambios continuamente
kubectl get hpa -w

# Ver eventos de scaling
kubectl describe hpa do-sample-app-hpa

# Ver pods escalando
kubectl get pods -l app=do-sample-app -w
```

### 6. Limpiar recursos

```bash
ansible-playbook cleanup.yml
```

Este playbook elimina:
- Locust
- HPA
- Prometheus + Grafana
- Metrics Server
- Namespace de monitoring

**Nota**: La aplicación principal permanece activa.

## Configuración del HPA

El HPA está configurado en `manifests/hpa.yaml`:

```yaml
minReplicas: 2
maxReplicas: 10
metrics:
  - CPU: 50% de utilización promedio
  - Memory: 70% de utilización promedio
behavior:
  scaleUp: Agresivo (duplica pods cada 15s)
  scaleDown: Conservador (reduce 50% cada 5 minutos)
```

## Pruebas de Carga con Locust

El script `locustfile.py` simula dos tipos de tráfico:
- **75% GET /**: Ver posts (más frecuente)
- **25% POST /submit**: Crear posts (carga más pesada)

### Escenarios de prueba sugeridos

**Prueba ligera:**
- Usuarios: 20
- Spawn rate: 2/seg
- Duración: 5 min
- Resultado esperado: 2-3 pods

**Prueba media:**
- Usuarios: 50
- Spawn rate: 5/seg
- Duración: 10 min
- Resultado esperado: 4-6 pods

**Prueba intensa:**
- Usuarios: 100-200
- Spawn rate: 10/seg
- Duración: 15 min
- Resultado esperado: 8-10 pods (máximo)

## Verificación del Autoscaling

### 1. Antes de la prueba
```bash
kubectl get hpa
# Debería mostrar CPU y memoria bajos (~5-10%)
# Réplicas: 2-3
```

### 2. Durante la prueba (después de 1-2 minutos)
```bash
kubectl get hpa
# CPU debería subir a 50-80%
# Réplicas empiezan a incrementar
```

### 3. Pico de la prueba (3-5 minutos)
```bash
kubectl get hpa
# CPU al 60-90%
# Réplicas en 5-10
```

### 4. Después de detener (5-10 minutos después)
```bash
kubectl get hpa
# CPU baja gradualmente
# Réplicas se reducen lentamente a 2
```

## Troubleshooting

### HPA muestra `<unknown>` en targets
```bash
# Verificar Metrics Server
kubectl get deployment metrics-server -n kube-system
kubectl logs -n kube-system deployment/metrics-server

# Esperar 1-2 minutos para que se recopilen métricas
```

### Pods no escalan
```bash
# Verificar eventos del HPA
kubectl describe hpa do-sample-app-hpa

# Verificar resources en pods
kubectl describe pod -l app=do-sample-app | grep -A 5 "Requests:"

# Verificar que los requests/limits estén configurados
```

### Locust no genera carga suficiente
- Aumentar número de workers: `kubectl scale deployment locust-worker --replicas=4`
- Aumentar usuarios y spawn rate en la UI
- Verificar conectividad: `kubectl logs -l app=locust-master`

### Grafana no muestra datos
- Verificar que Prometheus está scraping: http://localhost:9090/targets (port-forward)
- Importar dashboards de Kubernetes si no existen
- Esperar 1-2 minutos para que aparezcan datos

## Métricas Clave a Observar

### En kubectl
- Número de réplicas activas
- CPU/Memory utilization %
- Pods en estado Running/Pending

### En Grafana
- CPU Usage por pod
- Memory Usage por pod
- Network I/O
- Request rate
- Response time

### En Locust
- RPS (Requests per second)
- Response times (p50, p95, p99)
- Failure rate
- Número de usuarios simulados

## Costos en DigitalOcean

Esta configuración usa:
- 3+ nodos del cluster
- 1 Load Balancer para Locust (~$12/mes)
- Almacenamiento para Prometheus/Grafana

**Consejo**: Elimina el Load Balancer de Locust después de las pruebas si no lo necesitas.

```bash
# Cambiar a NodePort o port-forward
kubectl patch svc locust-master-service -p '{"spec":{"type":"ClusterIP"}}'
```

## Siguientes Pasos

- [ ] Configurar Vertical Pod Autoscaler (VPA)
- [ ] Implementar Cluster Autoscaler
- [ ] Configurar alertas en Prometheus
- [ ] Crear dashboards personalizados en Grafana
- [ ] Implementar CI/CD para despliegues automatizados
- [ ] Configurar cert-manager para HTTPS

## Recursos Adicionales

- [Kubernetes HPA Docs](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Locust Documentation](https://docs.locust.io/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

## Autor

Demo de autoscaling en Kubernetes con DigitalOcean
