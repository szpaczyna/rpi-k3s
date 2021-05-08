{{- define "redis" }}
- name: redis
  image: {{ .Values.redis.image }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  command:
    - redis-server
    - '--save "" --appendonly no'
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
{{ toYaml .Values.redis.resources | indent 4 }}
{{- end }}loglevel  
