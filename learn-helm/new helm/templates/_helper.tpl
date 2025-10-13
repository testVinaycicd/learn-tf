{{- define "robo.metadata" }}
name: {{ default "noname" .Values.component_name }}
# namespace: roboshop
{{- end }}

{{- define "robo.resource" }}
resources:
    requests:
        cpu: {{  .Values.resource.minCpu }}
        memory: {{  .Values.resource.minMemory }}
    limits:
        cpu: {{  .Values.resource.maxCpu }}
        memory: {{  .Values.resource.maxMemory}}
{{- end }}

{{- define "robo.service.ports" }}
- port: {{ default 8080 .Values.service.port }}
  targetPort: {{ default 8080 .Values.service.targetPort }}
{{- end }}

{{- define "robo.rediness.frontend" }}
readinessProbe:
  httpGet: { path: "/", port: {{ .Values.service.targetPort }} }
  initialDelaySeconds: 5
  periodSeconds: 5
livenessProbe:
  httpGet: { path: "/", port: {{ .Values.service.targetPort }} }
  initialDelaySeconds: 15
  periodSeconds: 10
{{- end }}


{{- define "robo.rediness.mongodb" }}
livenessProbe:
  tcpSocket:
    port: 27017
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 2
  failureThreshold: 3
readinessProbe:
  tcpSocket:
    port: 27017
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 2
  failureThreshold: 3
{{- end }}
