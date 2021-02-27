# Helm chart

Installs the project as a Deployment for monitoring cert-manager.

# Installing chart

```
helm install -n <my-namespace> cert-exporter -f values.yaml .
```

# Configuring the chart

All options are documented in-line in [values.yaml](./values.yaml).

# Dependencies

In order to use the ServiceMonitor CRD (disabled by default), you must have [Prometheus-Operator](https://github.com/prometheus-operator/prometheus-operator) installed to your cluster.
