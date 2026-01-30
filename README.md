# 🚀 Troubleshooting Kubernetes with Postman

> A hands-on demo project for the Postman Meetup - Learn how to use Postman to troubleshoot Kubernetes deployments!

## 📋 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Demo Scenarios](#-demo-scenarios)
- [30-Minute Demo Script](#-30-minute-demo-script)
- [Troubleshooting Guide](#-troubleshooting-guide)
- [Useful Commands](#-useful-commands)

---

## 🎯 Overview

### What is Kubernetes?

Kubernetes (K8s) is a container orchestration platform that:
- **Runs multiple copies** of your app across many machines
- **Auto-restarts** crashed applications
- **Load balances** traffic across instances
- **Scales** based on demand

### What is Postman?

Postman is an API testing tool that helps you:
- **Test APIs** with visual interface
- **Automate tests** with scripts
- **Monitor health** of services
- **Debug issues** with detailed responses

### Why Use Postman for K8s Troubleshooting?

| Traditional Approach | Postman Approach |
|---------------------|------------------|
| `kubectl logs` - manual | Visual test results |
| `curl` commands - no assertions | Automated test scripts |
| Hard to share/reproduce | Shareable collections |
| No history | Request history & environments |

---

## 🛠️ Prerequisites

Make sure you have installed:

- ✅ **Docker Desktop** - [Download](https://www.docker.com/products/docker-desktop)
- ✅ **Minikube** - `choco install minikube`
- ✅ **kubectl** - `choco install kubernetes-cli`
- ✅ **Postman** - [Download](https://www.postman.com/downloads/)

### Verify Installation

```powershell
docker --version
minikube version
kubectl version --client
```

---

## 🚀 Quick Start

### Step 1: Start Minikube

```powershell
# Start the Kubernetes cluster
minikube start

# Verify it's running
minikube status
```

### Step 2: Configure Docker to use Minikube

```powershell
# Point your shell to minikube's Docker daemon
# For PowerShell:
minikube docker-env | Invoke-Expression

# Verify
docker ps
```

### Step 3: Build the Docker Image

```powershell
# Navigate to the app directory
cd app

# Build the image
docker build -t k8s-demo-api:latest .

# Verify the image exists
docker images | Select-String "k8s-demo-api"

# Go back to project root
cd ..
```

### Step 4: Deploy to Kubernetes

```powershell
# Create namespace and deploy
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Watch pods come up
kubectl get pods -n demo -w
```

### Step 5: Get the Service URL

```powershell
# Get the URL to access the service
minikube service demo-api-service -n demo --url
```

Copy this URL - you'll need it for Postman!

### Step 6: Import Postman Collection

1. Open Postman
2. Click **Import**
3. Select `postman/K8s_Troubleshooting_Demo.postman_collection.json`
4. Update the `baseUrl` variable with the URL from Step 5
5. Run the **Health Checks** folder to verify everything works!

---

## 📁 Project Structure

```
Troubleshoot_Kubernetes_Postman/
├── app/                          # Node.js API Application
│   ├── server.js                 # Main application code
│   ├── package.json              # Dependencies
│   └── Dockerfile                # Container build instructions
│
├── k8s/                          # Kubernetes Manifests (Working)
│   ├── namespace.yaml            # Creates 'demo' namespace
│   ├── configmap.yaml            # App configuration
│   ├── deployment.yaml           # Pod deployment (3 replicas)
│   └── service.yaml              # Exposes app on port 30080
│
├── k8s/broken/                   # Broken Configs (For Demo)
│   ├── configmap-broken-db.yaml  # Breaks readiness probe
│   ├── configmap-intermittent.yaml # 50% failure rate
│   ├── deployment-wrong-image.yaml # Image doesn't exist
│   ├── deployment-wrong-port.yaml  # Probe checks wrong port
│   └── service-wrong-selector.yaml # Service finds no pods
│
├── postman/                      # Postman Collection
│   └── K8s_Troubleshooting_Demo.postman_collection.json
│
└── README.md                     # This file
```

---

## 🎭 Demo Scenarios

### Scenario 1: Everything Working ✅

```powershell
# Apply working configuration
kubectl apply -f k8s/configmap.yaml
kubectl rollout restart deployment/demo-api -n demo

# Wait for pods to be ready
kubectl get pods -n demo -w
```

**In Postman:** Run all Health Checks - everything should pass!

---

### Scenario 2: Database Connection Failure ❌

```powershell
# Apply broken database config
kubectl apply -f k8s/broken/configmap-broken-db.yaml
kubectl rollout restart deployment/demo-api -n demo

# Watch pods - they'll show "0/1 Ready"
kubectl get pods -n demo -w
```

**In Postman:** 
- Run "Readiness Check" - will fail with "Database not connected"
- This shows how Postman can identify configuration issues!

**Fix it:**
```powershell
kubectl apply -f k8s/configmap.yaml
kubectl rollout restart deployment/demo-api -n demo
```

---

### Scenario 3: Intermittent Failures 🎲

```powershell
# Apply flaky config (50% failure rate)
kubectl apply -f k8s/broken/configmap-intermittent.yaml
kubectl rollout restart deployment/demo-api -n demo

# Wait for pods
kubectl get pods -n demo
```

**In Postman:**
1. Go to "Health Check - Expect Failure"
2. Click **Run** (Collection Runner)
3. Set iterations to **10**
4. Watch ~50% of requests fail!

**Fix it:**
```powershell
kubectl apply -f k8s/configmap.yaml
kubectl rollout restart deployment/demo-api -n demo
```

---

### Scenario 4: Wrong Image (ImagePullBackOff) 🖼️

```powershell
# Apply deployment with non-existent image
kubectl apply -f k8s/broken/deployment-wrong-image.yaml

# Watch pods fail to start
kubectl get pods -n demo -w
# You'll see: ImagePullBackOff or ErrImageNeverPull
```

**In Postman:** Requests will timeout or fail to connect.

**Fix it:**
```powershell
kubectl apply -f k8s/deployment.yaml
```

---

### Scenario 5: Service Selector Mismatch 🔗

```powershell
# Apply service with wrong selector
kubectl apply -f k8s/broken/service-wrong-selector.yaml

# Check endpoints - will be empty!
kubectl get endpoints demo-api-service -n demo
```

**In Postman:** Connection refused - no pods match the service!

**Fix it:**
```powershell
kubectl apply -f k8s/service.yaml
```

---

## 🎬 30-Minute Demo Script

### Opening (0-5 min)
- Introduce yourself
- "Today we'll learn how Postman helps troubleshoot Kubernetes"
- Quick explanation of K8s concepts (pods, services, deployments)

### Setup Verification (5-8 min)
- Show minikube running: `minikube status`
- Show pods: `kubectl get pods -n demo`
- Open Postman, show the collection

### Demo 1: Working State (8-12 min)
- Run Health Checks in Postman - all green!
- Run "Get App Info" multiple times - show different pods responding
- Use Collection Runner to show load balancing

### Demo 2: Break It! (12-20 min)
- Apply broken config: `kubectl apply -f k8s/broken/configmap-intermittent.yaml`
- Restart pods: `kubectl rollout restart deployment/demo-api -n demo`
- Run Health Check in Postman - show failures
- Run 10 iterations - show 50% failure rate
- **This is the "aha!" moment** - Postman catches what manual testing misses

### Demo 3: Fix It! (20-25 min)
- Apply fix: `kubectl apply -f k8s/configmap.yaml`
- Restart: `kubectl rollout restart deployment/demo-api -n demo`
- Re-run tests - all green!
- Show how Postman can be used for CI/CD validation

### Wrap Up (25-30 min)
- Recap: Postman for API testing, K8s health checks, automated validation
- Q&A

---

## 🔧 Troubleshooting Guide

### Problem: "Connection Refused"

```powershell
# Check if pods are running
kubectl get pods -n demo

# Check service endpoints
kubectl get endpoints demo-api-service -n demo

# Check service URL
minikube service demo-api-service -n demo --url
```

### Problem: Pods in "CrashLoopBackOff"

```powershell
# Check pod logs
kubectl logs -l app=demo-api -n demo

# Describe pod for events
kubectl describe pod -l app=demo-api -n demo
```

### Problem: "ImagePullBackOff"

```powershell
# Make sure you're using minikube's Docker
minikube docker-env | Invoke-Expression

# Rebuild the image
cd app
docker build -t k8s-demo-api:latest .
cd ..

# Restart deployment
kubectl rollout restart deployment/demo-api -n demo
```

### Problem: Pods Running but Not Ready

```powershell
# Check readiness probe
kubectl describe pod -l app=demo-api -n demo | Select-String -Context 0,5 "Readiness"

# Check configmap values
kubectl get configmap demo-config -n demo -o yaml
```

---

## 📝 Useful Commands

### Kubernetes Commands

```powershell
# Start/Stop minikube
minikube start
minikube stop

# View all resources in demo namespace
kubectl get all -n demo

# Watch pods in real-time
kubectl get pods -n demo -w

# View pod logs
kubectl logs -f -l app=demo-api -n demo

# Restart deployment
kubectl rollout restart deployment/demo-api -n demo

# Delete everything and start fresh
kubectl delete namespace demo
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Docker Commands

```powershell
# Use minikube's Docker
minikube docker-env | Invoke-Expression

# Build image
docker build -t k8s-demo-api:latest ./app

# List images
docker images | Select-String "k8s-demo-api"
```

---

## 🎉 Tips for the Demo

1. **Practice beforehand** - Run through the scenarios 2-3 times
2. **Have backup** - Keep the working configs ready to quickly fix issues
3. **Explain as you go** - Narrate what you're doing and why
4. **Show the console** - Postman's console shows detailed request/response info
5. **Use Collection Runner** - It's more impressive than running requests one by one

---

## 📚 Learn More

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Postman Learning Center](https://learning.postman.com/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

---

**Good luck with your demo! 🚀**

