# Changelog - MLflow AI Gateway Standardization

## Changes Made

### 1. Configuration Standardization
- **config.yaml**: Updated to follow MLflow AI Gateway standards
  - Changed `routes` → `endpoints` (the correct MLflow terminology)
  - Changed `route_type` → `endpoint_type` (the correct MLflow terminology)
  - Reference: [MLflow AI Gateway Documentation](https://mlflow.org/docs/latest/genai/governance/ai-gateway/)

### 2. Environment Variables Template
- Created `env.template` file for environment variables
- Updated deployment scripts to support both `env.template` and `.env.example`

### 3. Teleport Integration
- **deploy_to_server.ps1**: Updated to use Teleport (`tsh ssh`, `tsh scp`) instead of SSH/SCP
- **teleport_deploy.sh**: New bash script for Teleport deployment
- **TELEPORT_SETUP.md**: Comprehensive guide for Teleport installation and setup

### 4. Documentation Updates
- **README.md**: Updated with Teleport deployment instructions and project structure
- **DEPLOY_STEPS.md**: Updated all SSH/SCP commands to use Teleport
- **QUICK_DEPLOY.md**: Updated quick deployment guide with Teleport

### 5. Dockerfile Improvements
- Added `curl` installation for healthcheck functionality
- Added HEALTHCHECK instruction to Dockerfile
- Ensures healthcheck works properly in container

### 6. Deployment Scripts
- All deployment scripts now use Teleport for secure access to server 10.3.49.202
- Added Teleport client verification in deployment scripts
- Added Teleport login status checks

## Files Modified
- `config.yaml` - Standardized to MLflow format
- `Dockerfile` - Added curl and healthcheck
- `deploy_to_server.ps1` - Updated to use Teleport
- `README.md` - Updated documentation
- `DEPLOY_STEPS.md` - Updated to use Teleport
- `QUICK_DEPLOY.md` - Updated to use Teleport

## Files Created
- `teleport_deploy.sh` - New bash deployment script for Teleport
- `TELEPORT_SETUP.md` - Teleport setup guide
- `env.template` - Environment variables template
- `CHANGELOG.md` - This file

## Migration Notes

### For Existing Deployments
If you have an existing deployment using the old `routes` format:
1. Update `config.yaml` to use `endpoints` instead of `routes`
2. Update `route_type` to `endpoint_type`
3. Restart the gateway service

### For New Deployments
1. Install Teleport client: See [TELEPORT_SETUP.md](TELEPORT_SETUP.md)
2. Login to Teleport: `tsh login --proxy=<proxy-address>`
3. Run deployment script: `.\deploy_to_server.ps1` or `./teleport_deploy.sh`

## Compliance
- ✅ Follows MLflow AI Gateway standards
- ✅ Uses Teleport for secure server access
- ✅ Includes comprehensive documentation
- ✅ Production-ready Docker configuration

