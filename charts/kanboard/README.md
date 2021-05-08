# Kanboard

[Kanboard](https://kanboard.org/) is a free and open source Kanban project management software.

## Introduction

This chart bootstraps a Kanboard deployment on a Kubernetes cluster using the Helm package manager.

## Installation
```sh
cd <path-to-repo>
helm install -n <my-namespace> kanboard -f values.yaml .
```

## Parameters
The following table lists the configurable parameters of the Kanboard chart and their default values.

| Parameter                            | Description                                                                                            | Default                                                      |
|--------------------------------------|--------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `global.imageRegistry`               | Global Docker image registry                                                                           | `nil`                                                        |
| `global.imagePullSecrets`            | Global Docker registry secret names as an array                                                        | `[]` (does not add image pull secrets to deployed pods)      |
| `image.repository`                   | Kanboard Image name                                                                                   | `kanboard/kanboard`                                          |
| `image.tag`                          | Kanboard Image tag                                                                                    | `v1.2.19`                                                 |
| `image.pullPolicy`                   | Image pull policy                                                                                      | `IfNotPresent`                                               |
| `nameOverride`                       | String to partially override kanboard.fullname template with a string (will prepend the release name) | `nil`                                                        |
| `fullnameOverride`                   | String to fully override kanboard.fullname template with a string                                     | `nil`                                                        |

## Additional Parameters

| Parameter                            | Default                 |
|--------------------------------------|-------------------------|
| `persistence`                        | `true`                  |
| `hpa`                                | `enabled`               |
| `podDisruptionBudget`                | `minUnavailable: 1`     |
| `ingress`                            | `true`                  |
