# Kanboard

[Kanboard](https://kanboard.org/) is a free and open source Kanban project management software.

## TL;DR;
```console
$ helm repo add aegiszero https://storage.aegiszero.is/helm-charts/
$ helm install my-release aegiszero/kanboard
```

## Introduction

This chart bootstraps a Kanboard deployment on a Kubernetes cluster using the Helm package manager.

## Prerequisites
- Kubernetes 1.12+
- Helm 2.12+ or Helm 3.0-beta3+
- PV provisioner support in the underlying infrastructure for persistence

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install my-release aegiszero/kanboard
```

The command deploys Kanboard on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters
The following table lists the configurable parameters of the Kanboard chart and their default values.

| Parameter                            | Description                                                                                            | Default                                                      |
|--------------------------------------|--------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `global.imageRegistry`               | Global Docker image registry                                                                           | `nil`                                                        |
| `global.imagePullSecrets`            | Global Docker registry secret names as an array                                                        | `[]` (does not add image pull secrets to deployed pods)      |
| `image.repository`                   | Kanboard Image name                                                                                   | `bitnami/kanboard`                                          |
| `image.tag`                          | Kanboard Image tag                                                                                    | `{TAG_NAME}`                                                 |
| `image.pullPolicy`                   | Image pull policy                                                                                      | `IfNotPresent`                                               |
| `nameOverride`                       | String to partially override kanboard.fullname template with a string (will prepend the release name) | `nil`                                                        |
| `fullnameOverride`                   | String to fully override kanboard.fullname template with a string                                     | `nil`                                                        |

## Persistence