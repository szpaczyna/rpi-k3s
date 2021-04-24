{{- define "redis" }}
- name: redis
  image: {{ .Values.images.redis }}
  imagePullPolicy: {{ .Values.images.imagePullPolicy }}
  ports:
  - name: redis
    containerPort: 6379
  livenessProbe:
    tcpSocket:
      port: redis
    initialDelaySeconds: 30
    timeoutSeconds: 5
  readinessProbe:
    tcpSocket:
      port: redis
    initialDelaySeconds: 5
    timeoutSeconds: 1
  securityContext:
    runAsUser: 1000
  resources:
{{ toYaml .Values.resources.redis | indent 10 }}
{{- end }}loglevel  
