{{- /*
  Helper functions for media-stack chart
*/ -}}
{{- define "media-stack.image" -}}
{{- $name := .name -}}
{{- $root := .root -}}
{{- $img := index $root.Values.images $name -}}
{{- if $img }}{{ printf "%s:%s" $img.repository $img.tag }}{{- else }}{{- printf "" -}}{{- end -}}
{{- end -}}
