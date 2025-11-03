# ⚡ Quick Start - Autoscaling Demo

## 🚀 Inicio Rápido (5 minutos)

### Opción 1: Script Interactivo (Más Fácil)

```bash
./autoscaling-manager.sh
```

Selecciona la opción que necesites del menú interactivo.

---

### Opción 2: Comandos Directos con Ansible

```bash
cd ansible

# 1. Desplegar todo (ya está hecho)
ansible-playbook deploy-autoscaling.yml

# 2. Ejecutar prueba de carga con monitoreo
ansible-playbook run-load-test.yml

# 3. Limpiar recursos
ansible-playbook cleanup.yml
```

---

## 📊 Accesos Rápidos

### Aplicación Web
```
http://45.55.116.144
```

### Locust (Pruebas de Carga)
```
http://138.197.240.205:8089
```

### Grafana (Monitoreo)
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000
# User: admin
# Pass: prom-operator
```

---

## ⚡ Demo Rápida (10 minutos)

### Terminal 1: Monitorear HPA
```bash
kubectl get hpa -w
```

### Terminal 2: Monitorear Pods
```bash
kubectl get pods -l app=do-sample-app -w
```

### Terminal 3: Port-forward Grafana
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

### Navegador 1: Locust
1. Ir a http://138.197.240.205:8089
2. Host: `http://do-sample-app-service:8080`
3. Users: `100`
4. Spawn rate: `10`
5. Click "Start swarming"

### Navegador 2: Grafana
1. Ir a http://localhost:3000
2. Login: admin / prom-operator
3. Dashboards → Kubernetes → Compute Resources → Namespace (Pods)
4. Namespace: default

### Observar:
- ✅ CPU subiendo en HPA
- ✅ Nuevos pods creándose
- ✅ Gráficas en Grafana
- ✅ RPS incrementando en Locust

---

## 🔍 Comandos Útiles

```bash
# Estado general
kubectl get hpa
kubectl get pods -l app=do-sample-app
kubectl top pods

# Ver eventos de scaling
kubectl describe hpa do-sample-app-hpa

# Logs
kubectl logs -f deployment/do-sample-app

# Forzar scale manual (testing)
kubectl scale deployment do-sample-app --replicas=5

# Ver todo
kubectl get all --all-namespaces | grep -E "do-sample-app|locust|prometheus"
```

---

## 🎯 Escenarios de Prueba

### Light (Primera prueba)
- Users: **50**
- Spawn Rate: **5**/seg
- Duration: **5** min
- Expected: **3-4 pods**

### Medium (Demo estándar)
- Users: **100**
- Spawn Rate: **10**/seg
- Duration: **10** min
- Expected: **5-7 pods**

### Heavy (Stress test)
- Users: **200**
- Spawn Rate: **20**/seg
- Duration: **10** min
- Expected: **8-10 pods**

---

## 🎬 Workflow de Demo

1. Mostrar estado inicial (2 pods, CPU bajo)
2. Abrir Locust + Grafana
3. Iniciar carga (100 users)
4. Mostrar terminales con HPA y pods escalando
5. Esperar pico (3-5 min)
6. Detener carga
7. Mostrar scale down gradual
8. Vuelta a 2 pods (5-10 min)

---

## 📚 Documentación Completa

- **Setup completo**: Ver `DEMO-GUIDE.md`
- **Ansible details**: Ver `ansible/README.md`
- **Original setup**: Ver `README.md`

---

## ✅ Checklist Pre-Demo

- [ ] Cluster conectado: `kubectl cluster-info`
- [ ] HPA activo: `kubectl get hpa`
- [ ] Locust corriendo: `kubectl get pods -l app=locust-master`
- [ ] Grafana accesible: `kubectl get pods -n monitoring | grep grafana`
- [ ] Metrics Server: `kubectl top nodes`
- [ ] App funcionando: `http://45.55.116.144`

---

## 🆘 Troubleshooting Rápido

### HPA muestra `<unknown>`
```bash
# Esperar 2 minutos o verificar Metrics Server
kubectl get deployment metrics-server -n kube-system
```

### Pods no escalan
```bash
# Verificar resources configurados
kubectl describe deployment do-sample-app | grep -A 5 "Limits"
```

### Locust no carga
```bash
# Verificar workers
kubectl get pods -l app=locust-worker
kubectl scale deployment locust-worker --replicas=4
```

---

## 🧹 Cleanup

```bash
# Con Ansible
cd ansible && ansible-playbook cleanup.yml

# O manual
kubectl delete -f manifests/locust.yaml
kubectl delete -f manifests/hpa.yaml
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

---

**¡Listo para demostrar! 🎉**
