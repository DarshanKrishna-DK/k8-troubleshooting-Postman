# Troubleshooting Kubernetes with Postman

A hands-on project demonstrating how to use Postman for troubleshooting and testing Kubernetes deployments. Includes a sample Node.js API, working Kubernetes manifests, intentionally broken configurations for practice, and a ready-to-use Postman collection.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [API Endpoints](#api-endpoints)
- [Troubleshooting Scenarios](#troubleshooting-scenarios)
- [Useful Commands](#useful-commands)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This project provides a complete environment to learn Kubernetes troubleshooting using Postman as your testing tool. It includes:

- **Sample API**: A Node.js Express application with health checks, product endpoints, and chaos testing endpoints
- **Kubernetes Manifests**: Namespace, ConfigMap, Deployment, and Service configurations
- **Broken Scenarios**: Intentionally misconfigured manifests to practice troubleshooting
- **Postman Collection**: Pre-built API tests with assertions and environment variables

### Why Postman for Kubernetes Troubleshooting?

| Traditional Approach | Postman Approach |
|---------------------|------------------|
| `kubectl logs` - manual inspection | Visual test results with assertions |
| `curl` commands - no validation | Automated test scripts |
| Hard to share/reproduce | Shareable collections |
| No history tracking | Request history & environments |

---

## Prerequisites

Ensure you have the following installed:

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Postman](https://www.postman.com/downloads/)

### Verify Installation

```powershell
docker --version
minikube version
kubectl version --client
```

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/DarshanKrishna-DK/k8-troubleshooting-Postman.git
cd k8-troubleshooting-Postman
```

### 2. Start Minikube

```powershell
minikube start
minikube status
```

### 3. Configure Docker to Use Minikube

```powershell
# PowerShell
minikube docker-env | Invoke-Expression

# Bash
eval $(minikube docker-env)
```

### 4. Build the Docker Image

```powershell
cd app
docker build -t k8s-demo-api:latest .
cd ..
```

### 5. Deploy to Kubernetes

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Watch pods come up
kubectl get pods -n demo -w
```

### 6. Get the Service URL

```powershell
minikube service demo-api-service -n demo --url
```

Copy this URL - you'll use it as the `baseUrl` in Postman.

### 7. Import Postman Collection

1. Open Postman
2. Click **Import**
3. Select `postman/K8s_Troubleshooting_Demo.postman_collection.json`
4. Update the `baseUrl` variable with your service URL
5. Run the **Health Checks** folder to verify everything works

---

## Project Structure

```
k8-troubleshooting-Postman/
├── app/                              # Node.js API Application
│   ├── server.js                     # Main application code
│   ├── package.json                  # Dependencies
│   ├── Dockerfile                    # Container build instructions
│   └── .dockerignore                 # Docker ignore file
│
├── k8s/                              # Kubernetes Manifests (Working)
│   ├── namespace.yaml                # Creates 'demo' namespace
│   ├── configmap.yaml                # App configuration
│   ├── deployment.yaml               # Pod deployment (3 replicas)
│   ├── service.yaml                  # Exposes app via NodePort
│   └── broken/                       # Broken Configs (For Practice)
│       ├── configmap-broken-db.yaml  # Invalid database config
│       ├── configmap-intermittent.yaml # 50% failure rate
│       ├── deployment-wrong-image.yaml # Non-existent image
│       ├── deployment-wrong-port.yaml  # Wrong probe port
│       ├── deployment-no-resources.yaml # No resource limits
│       └── service-wrong-selector.yaml # Mismatched selector
│
├── postman/                          # Postman Collection
│   └── K8s_Troubleshooting_Demo.postman_collection.json
│
├── scripts/                          # Utility Scripts
│   ├── setup.ps1                     # Setup automation
│   ├── cleanup.ps1                   # Cleanup resources
│   └── break-scenario.ps1            # Apply broken configs
│
└── README.md
```

---

## API Endpoints

### Health Checks

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Liveness probe - is the app alive? |
| `GET /ready` | Readiness probe - is the app ready for traffic? |

### Application Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/info` | Application information (pod name, config, etc.) |
| `GET /api/products` | List all products |
| `GET /api/products/:id` | Get product by ID |
| `GET /api/products?category=Books` | Filter products by category |
| `GET /api/products?inStock=true` | Filter products by availability |

### Testing Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/slow?delay=5000` | Simulates slow response (default 5s) |
| `GET /api/error` | Always returns 500 error |
| `GET /api/chaos?failChance=0.5` | Random failures (50% by default) |
| `GET /api/memory-hog?size=50` | Allocates memory (in MB) |
| `GET /api/cpu-intensive?iterations=1000000` | CPU stress test |

---

## Troubleshooting Scenarios

### Scenario 1: Database Connection Failure

Simulates a misconfigured database connection.

```powershell
kubectl apply -f k8s/broken/configmap-broken-db.yaml
kubectl rollout restart deployment/demo-api -n demo
```

**Symptoms**: Pods show `0/1 Ready`, readiness probe fails.

**Fix**:
```powershell
kubectl apply -f k8s/configmap.yaml
kubectl rollout restart deployment/demo-api -n demo
```

### Scenario 2: Intermittent Failures

Simulates flaky services with 50% failure rate.

```powershell
kubectl apply -f k8s/broken/configmap-intermittent.yaml
kubectl rollout restart deployment/demo-api -n demo
```

**Test in Postman**: Run health check 10 times using Collection Runner.

**Fix**:
```powershell
kubectl apply -f k8s/configmap.yaml
kubectl rollout restart deployment/demo-api -n demo
```

### Scenario 3: Wrong Image (ImagePullBackOff)

Deploys with a non-existent Docker image.

```powershell
kubectl apply -f k8s/broken/deployment-wrong-image.yaml
```

**Symptoms**: Pods stuck in `ImagePullBackOff` or `ErrImageNeverPull`.

**Fix**:
```powershell
kubectl apply -f k8s/deployment.yaml
```

### Scenario 4: Service Selector Mismatch

Service cannot find any pods due to wrong selector.

```powershell
kubectl apply -f k8s/broken/service-wrong-selector.yaml
```

**Symptoms**: `kubectl get endpoints` shows no endpoints.

**Fix**:
```powershell
kubectl apply -f k8s/service.yaml
```

### Scenario 5: Wrong Probe Port

Health probe checks wrong port, causing pods to restart.

```powershell
kubectl apply -f k8s/broken/deployment-wrong-port.yaml
```

**Symptoms**: Pods restart repeatedly (CrashLoopBackOff).

**Fix**:
```powershell
kubectl apply -f k8s/deployment.yaml
```

---

## Useful Commands

### Kubernetes

```powershell
# View all resources in demo namespace
kubectl get all -n demo

# Watch pods in real-time
kubectl get pods -n demo -w

# View pod logs
kubectl logs -f -l app=demo-api -n demo

# Describe pod (detailed info + events)
kubectl describe pod -l app=demo-api -n demo

# Check service endpoints
kubectl get endpoints demo-api-service -n demo

# Restart deployment
kubectl rollout restart deployment/demo-api -n demo

# Delete and recreate everything
kubectl delete namespace demo
kubectl apply -f k8s/
```

### Minikube

```powershell
# Start/Stop cluster
minikube start
minikube stop

# Get service URL
minikube service demo-api-service -n demo --url

# Open Kubernetes dashboard
minikube dashboard

# SSH into minikube node
minikube ssh
```

### Docker

```powershell
# Use minikube's Docker daemon
minikube docker-env | Invoke-Expression

# Build image
docker build -t k8s-demo-api:latest ./app

# List images
docker images | grep k8s-demo-api
```

---

## Troubleshooting Guide

### Connection Refused

```powershell
# Check if pods are running
kubectl get pods -n demo

# Check service endpoints
kubectl get endpoints demo-api-service -n demo

# Verify service URL
minikube service demo-api-service -n demo --url
```

### Pods in CrashLoopBackOff

```powershell
# Check pod logs
kubectl logs -l app=demo-api -n demo --previous

# Describe pod for events
kubectl describe pod -l app=demo-api -n demo
```

### ImagePullBackOff

```powershell
# Ensure using minikube's Docker
minikube docker-env | Invoke-Expression

# Rebuild image
docker build -t k8s-demo-api:latest ./app

# Restart deployment
kubectl rollout restart deployment/demo-api -n demo
```

### Pods Running but Not Ready

```powershell
# Check readiness probe config
kubectl describe pod -l app=demo-api -n demo | Select-String -Context 0,5 "Readiness"

# Check configmap values
kubectl get configmap demo-config -n demo -o yaml
```

---

## Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-scenario`)
3. Commit your changes (`git commit -m 'Add new troubleshooting scenario'`)
4. Push to the branch (`git push origin feature/new-scenario`)
5. Open a Pull Request

---

## License

This project is open source and available under the [MIT License](LICENSE).

---

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Postman Learning Center](https://learning.postman.com/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
