# Script to generate Firebase configuration files for different environments/flavors
# Converted from shell script for Windows compatibility

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "stg", "staging", "prod")]
    [string]$EnvName
)

# Function to ensure directory exists
function Ensure-Directory($path) {
    if (-not (Test-Path -Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "Created directory: $path"
    }
}

# Normalize 'stg' to 'staging'
if ($EnvName -eq 'stg') {
    $EnvName = 'staging'
}

switch ($EnvName) {
    "dev" {
        Write-Host "Configuring for dev environment..."
        Ensure-Directory "ios/flavors/dev"
        Ensure-Directory "android/app/src/dev"

        flutterfire config `
            --project=gestion-transporte-dev `
            --out=lib/firebase_options_dev.dart `
            --ios-bundle-id=com.example.myapp.dev `
            --ios-out=ios/flavors/dev/GoogleService-Info.plist `
            --android-package-name=com.example.myapp.dev `
            --android-out=android/app/src/dev/google-services.json
    }
    "staging" {
        Write-Host "Configuring for staging environment..."
        Ensure-Directory "ios/flavors/staging"
        Ensure-Directory "android/app/src/staging"

        flutterfire config `
            --project=gestion-transporte-stg `
            --out=lib/firebase_options_staging.dart `
            --ios-bundle-id=com.example.myapp.staging `
            --ios-out=ios/flavors/staging/GoogleService-Info.plist `
            --android-package-name=com.example.myapp.staging `
            --android-out=android/app/src/staging/google-services.json
    }
    "prod" {
        Write-Host "Configuring for prod environment..."
        Ensure-Directory "ios/flavors/prod"
        Ensure-Directory "android/app/src/prod"

        flutterfire config `
            --project=gestion-transporte-prod `
            --out=lib/firebase_options_prod.dart `
            --ios-bundle-id=com.example.myapp `
            --ios-out=ios/flavors/prod/GoogleService-Info.plist `
            --android-package-name=com.example.myapp `
            --android-out=android/app/src/prod/google-services.json
    }
}

Write-Host "Configuration complete for $EnvName."

