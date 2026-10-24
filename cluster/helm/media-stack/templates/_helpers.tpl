{{- /*
  Helper functions for media-stack chart
*/ -}}

{{- define "media-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "media-stack.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "media-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
  Standard labels for a named app in the stack. Pass name and root:
  {{ include "media-stack.labels" (dict "name" $name "root" $) }}
*/ -}}
{{- define "media-stack.labels" -}}
helm.sh/chart: {{ include "media-stack.chart" .root }}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- if .root.Chart.AppVersion }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end -}}
{{- define "media-stack.image" -}}
{{- $name := .name -}}
{{- $root := .root -}}
{{- $img := index $root.Values.images $name -}}
{{- if $img }}{{ printf "%s:%s" $img.repository $img.tag }}{{- else }}{{- printf "" -}}{{- end -}}
{{- end -}}

{{- /*
  Resolve resources for an app: uses .resourceProfile (looked up in
  .Values.resourceProfiles) if set, otherwise falls back to .Values.global.resources.
  Usage: {{ include "media-stack.resources" (dict "profile" $svc.resourceProfile "root" $) }}
*/ -}}
{{- define "media-stack.resources" -}}
{{- $root := .root -}}
{{- $profile := .profile -}}
{{- $resources := $root.Values.global.resources -}}
{{- if and $profile $root.Values.resourceProfiles }}
{{- $found := index $root.Values.resourceProfiles $profile -}}
{{- if $found }}{{ $resources = $found }}{{- end -}}
{{- end -}}
{{- toYaml $resources -}}
{{- end -}}
