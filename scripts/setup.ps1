# ============================================
# K8s Troubleshooting Demo - Setup Script
# ============================================
# Run this script to set up the entire demo environment

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     K8s Troubleshooting Demo - Setup Script            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

$hasDocker = Get-Command docker -ErrorAction SilentlyContinue
$hasMinikube = Get-Command minikube -ErrorAction SilentlyContinue
$hasKubectl = Get-Command kubectl -ErrorAction SilentlyContinue

if (-not $hasDocker) {
    Write-Host "❌ Docker not found. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}
if (-not $hasMinikube) {
    Write-Host "❌ Minikube not found. Run: choco install minikube" -ForegroundColor Red
    exit 1
}
if (-not $hasKubectl) {
    Write-Host "❌ kubectl not found. Run: choco install kubernetes-cli" -ForegroundColor Red
    exit 1
}

Write-Host "✅ All prerequisites installed!" -ForegroundColor Green
Write-Host ""

# Step 2: Start Minikube
Write-Host "🚀 Starting Minikube..." -ForegroundColor Yellow
minikube start

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start Minikube" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Minikube started!" -ForegroundColor Green
Write-Host ""

# Step 3: Configure Docker environment
Write-Host "🐳 Configuring Docker to use Minikube..." -ForegroundColor Yellow
minikube docker-env | Invoke-Expression
Write-Host "✅ Docker configured!" -ForegroundColor Green
Write-Host ""

# Step 4: Build Docker image
Write-Host "🔨 Building Docker image..." -ForegroundColor Yellow
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
Set-Location "$projectRoot\app"

docker build -t k8s-demo-api:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build Docker image" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker image built!" -ForegroundColor Green
Write-Host ""

# Step 5: Deploy to Kubernetes
Write-Host "☸️ Deploying to Kubernetes..." -ForegroundColor Yellow
Set-Location $projectRoot

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

Write-Host "✅ Deployed to Kubernetes!" -ForegroundColor Green
Write-Host ""

# Step 6: Wait for pods
Write-Host "⏳ Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=demo-api -n demo --timeout=120s

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Some pods may not be ready yet. Check with: kubectl get pods -n demo" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Get service URL
Write-Host "🌐 Getting service URL..." -ForegroundColor Yellow
$serviceUrl = minikube service demo-api-service -n demo --url
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    SETUP COMPLETE!                      ║" -ForegroundColor Green
Write-Host "╠════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Service URL: $serviceUrl" -ForegroundColor Green
Write-Host "║                                                         ║" -ForegroundColor Green
Write-Host "║  Next Steps:                                            ║" -ForegroundColor Green
Write-Host "║  1. Open Postman                                        ║" -ForegroundColor Green
Write-Host "║  2. Import: postman/K8s_Troubleshooting_Demo...json     ║" -ForegroundColor Green
Write-Host "║  3. Update baseUrl variable to: $serviceUrl" -ForegroundColor Green
Write-Host "║  4. Run the Health Checks folder!                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green

