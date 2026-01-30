# ============================================
# K8s Troubleshooting Demo - Cleanup Script
# ============================================
# Run this script to clean up the demo environment

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     K8s Troubleshooting Demo - Cleanup Script          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Delete Kubernetes resources
Write-Host "🗑️ Deleting Kubernetes resources..." -ForegroundColor Yellow
kubectl delete namespace demo --ignore-not-found

Write-Host "✅ Kubernetes resources deleted!" -ForegroundColor Green
Write-Host ""

# Ask about stopping minikube
$response = Read-Host "Do you want to stop Minikube? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host "🛑 Stopping Minikube..." -ForegroundColor Yellow
    minikube stop
    Write-Host "✅ Minikube stopped!" -ForegroundColor Green
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                   CLEANUP COMPLETE!                     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green

