{{- define "robo.metadata" }}
name: {{ default "noname" .Values.component_name }}
namespace: roboshop
{{- end }}

{{- define "robo.resource" }}
resources:
    requests:
        cpu: {{ default "100m" .Values.resource.minCpu }}
        memory: {{ default "128Mi" .Values.resource.minMemory }}
    limits:
        cpu: {{ default "100m" .Values.resource.maxCpu }}
        memory: {{ default "128Mi" .Values.resource.maxCpu }}
{{- end }}

{{- define "robo.service.ports" }}
- port: {{ default 8080 .Values.service.port }}
  targetPort: {{ default 8080 .Values.service.targetPort }}
{{- end }}