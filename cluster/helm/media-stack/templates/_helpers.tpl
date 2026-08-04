{{- /*
  Helper functions for media-stack chart
*/ -}}
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
