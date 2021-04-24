{{- define "init" }}
- name: init
  image: {{ .Values.images.gitea }}
  imagePullPolicy: {{ .Values.images.imagePullPolicy }}
  env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbPassword
  - name: SCRIPT
    value: &script |-
      for f in attachments avatars git gitea lfs queues repo-avatars sessions ssh;
        do mkdir -p /datatmp/$f;
        done
      mkdir -p /datatmp/gitea/conf/
      chown git:git /datatmp/* -R
      if [ ! -f /datatmp/gitea/conf/app.ini ]; then
        sed "s/POSTGRES_PASSWORD/${POSTGRES_PASSWORD}/g" < /etc/gitea/app.ini > /datatmp/gitea/conf/app.ini
      fi
  command: ["/bin/sh",'-c', *script]
  volumeMounts:
  - name: gitea-data
    mountPath: /datatmp
  - name: gitea-config
    mountPath: /etc/gitea
{{- end }}
