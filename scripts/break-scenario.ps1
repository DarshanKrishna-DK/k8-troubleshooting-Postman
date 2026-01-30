# ============================================
# K8s Troubleshooting Demo - Break Scenarios
# ============================================
# Use this script to quickly apply broken configurations

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("db", "intermittent", "image", "port", "selector", "fix")]
    [string]$Scenario = "help"
)

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     K8s Troubleshooting Demo - Break Scenarios         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

switch ($Scenario) {
    "db" {
        Write-Host "💥 Applying BROKEN DB configuration..." -ForegroundColor Red
        Write-Host "   Effect: Readiness probe will fail" -ForegroundColor Yellow
        kubectl apply -f "$projectRoot\k8s\broken\configmap-broken-db.yaml"
        kubectl rollout restart deployment/demo-api -n demo
        Write-Host ""
        Write-Host "⏳ Waiting for rollout..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        kubectl get pods -n demo
    }
    "intermittent" {
        Write-Host "💥 Applying INTERMITTENT failure configuration..." -ForegroundColor Red
        Write-Host "   Effect: 50% of health checks will fail" -ForegroundColor Yellow
        kubectl apply -f "$projectRoot\k8s\broken\configmap-intermittent.yaml"
        kubectl rollout restart deployment/demo-api -n demo
        Write-Host ""
        Write-Host "⏳ Waiting for rollout..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        kubectl get pods -n demo
    }
    "image" {
        Write-Host "💥 Applying WRONG IMAGE configuration..." -ForegroundColor Red
        Write-Host "   Effect: Pods will fail with ImagePullBackOff" -ForegroundColor Yellow
        kubectl apply -f "$projectRoot\k8s\broken\deployment-wrong-image.yaml"
        Write-Host ""
        Write-Host "⏳ Waiting for pods..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        kubectl get pods -n demo
    }
    "port" {
        Write-Host "💥 Applying WRONG PORT configuration..." -ForegroundColor Red
        Write-Host "   Effect: Health probes will fail (wrong port)" -ForegroundColor Yellow
        kubectl apply -f "$projectRoot\k8s\broken\deployment-wrong-port.yaml"
        Write-Host ""
        Write-Host "⏳ Waiting for pods..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        kubectl get pods -n demo
    }
    "selector" {
        Write-Host "💥 Applying WRONG SELECTOR configuration..." -ForegroundColor Red
        Write-Host "   Effect: Service will have no endpoints" -ForegroundColor Yellow
        kubectl apply -f "$projectRoot\k8s\broken\service-wrong-selector.yaml"
        Write-Host ""
        kubectl get endpoints demo-api-service -n demo
    }
    "fix" {
        Write-Host "🔧 Applying WORKING configuration..." -ForegroundColor Green
        kubectl apply -f "$projectRoot\k8s\configmap.yaml"
        kubectl apply -f "$projectRoot\k8s\deployment.yaml"
        kubectl apply -f "$projectRoot\k8s\service.yaml"
        kubectl rollout restart deployment/demo-api -n demo
        Write-Host ""
        Write-Host "⏳ Waiting for pods to be ready..." -ForegroundColor Yellow
        kubectl wait --for=condition=ready pod -l app=demo-api -n demo --timeout=60s
        kubectl get pods -n demo
        Write-Host ""
        Write-Host "✅ Everything should be working now!" -ForegroundColor Green
    }
    default {
        Write-Host "Usage: .\break-scenario.ps1 -Scenario <scenario>" -ForegroundColor White
        Write-Host ""
        Write-Host "Available scenarios:" -ForegroundColor Yellow
        Write-Host "  db          - Break database connection (readiness fails)" -ForegroundColor White
        Write-Host "  intermittent - 50% random failures" -ForegroundColor White
        Write-Host "  image       - Wrong Docker image (ImagePullBackOff)" -ForegroundColor White
        Write-Host "  port        - Wrong port in probes" -ForegroundColor White
        Write-Host "  selector    - Service finds no pods" -ForegroundColor White
        Write-Host "  fix         - Restore working configuration" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\break-scenario.ps1 -Scenario db" -ForegroundColor Gray
        Write-Host "  .\break-scenario.ps1 -Scenario fix" -ForegroundColor Gray
    }
}

Write-Host ""

