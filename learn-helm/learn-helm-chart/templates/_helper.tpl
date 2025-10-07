{{- define "robo.metadata" }}
name: {{ default "noname" .Values.component_name }}
namespace: roboshop
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