param (
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [Parameter(Mandatory=$true)]
    [string]$OrderId
)

# Script to automatically add a purchase to purchases.json and commit changes
# Usage: .\auto-update-purchases.ps1 -Email "customer@example.com" -OrderId "ORDER123"

# Configuration - Change these values
$repoPath = "C:\darkhouseaudio" # Path to your local repository
$purchasesFile = "purchases.json" # Path to purchases.json relative to $repoPath

Write-Host "Starting automatic purchase update for $Email / $OrderId..." -ForegroundColor Cyan

# Ensure we're in the repository directory
Set-Location $repoPath

# Check if purchases.json exists
if (-not (Test-Path $purchasesFile)) {
    Write-Error "$purchasesFile not found in $repoPath"
    exit 1
}

try {
    # Read the current purchases.json file
    $purchasesJson = Get-Content $purchasesFile -Raw | ConvertFrom-Json
    
    # Check if purchase already exists to avoid duplicates
    $existingPurchase = $purchasesJson.purchases | Where-Object { $_.email -eq $Email -and $_.orderId -eq $OrderId }
    
    if ($existingPurchase) {
        Write-Host "Purchase already exists in database, skipping..." -ForegroundColor Yellow
        exit 0
    }
    
    # Create new purchase object
    $newPurchase = @{
        email = $Email
        orderId = $OrderId
        date = (Get-Date -Format "yyyy-MM-dd")
    }
    
    # Add to purchases array
    $purchasesJson.purchases += $newPurchase
    
    # Write updated JSON back to file
    $purchasesJson | ConvertTo-Json -Depth 10 | Set-Content $purchasesFile
    
    Write-Host "Updated $purchasesFile with new purchase" -ForegroundColor Green
    
    # Git operations
    Write-Host "Committing changes to Git..." -ForegroundColor Cyan
    
    # Add the file
    git add $purchasesFile
    
    # Commit with a descriptive message
    git commit -m "Add purchase: $Email - $OrderId"
    
    # Push changes
    git push
    
    Write-Host "Changes pushed to GitHub successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Error updating purchases: $_"
    exit 1
} 