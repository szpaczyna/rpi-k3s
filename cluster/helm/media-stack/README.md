# Media Stack Helm Chart

This Helm chart deploys a media application stack on Kubernetes, including popular applications such as Bazarr, Calibre Web, Lidarr, Prowlarr, Radarr, Readarr, Sonarr, and Transmission. 

## Prerequisites

- Kubernetes cluster (v1.16+)
- Helm (v3.0+)

## Installation

To install the media stack Helm chart, follow these steps:

1. **Add the Helm repository (if applicable)**:
   ```bash
   helm repo add <repository-name> <repository-url>
   ```

2. **Install the chart**:
   ```bash
   helm install <release-name> ./media-stack-helm \
     --set global.timezone="Europe/Warsaw" \
     --set global.runAsUser=568 \
     --set global.runAsGroup=568
   ```

3. **Verify the installation**:
   ```bash
   helm list
   ```

## Configuration

You can customize the deployment by modifying the `values.yaml` file. This file contains default configuration values for the applications, including resource limits, environment variables, and more.

## Uninstallation

To uninstall the media stack, run:
```bash
helm uninstall <release-name>
```

## Notes

- Ensure that your Kubernetes cluster has sufficient resources to run all the applications.
- You may need to configure your Ingress controller to handle external traffic properly.

For more information on each application, refer to their respective documentation.
