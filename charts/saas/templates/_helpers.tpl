{{- define "env.app_name" -}}
{{- printf .Release.Name | default "saas" }}
{{- end -}}

{{- define "platform.host" -}}
{{- printf "%s.%s.govirto.com" .Release.Name .Release.Namespace }}
{{- end -}}

{{- define "db.connection_string" -}}
{{- $server := .Values.platform.db.server | default "vc-prod-dbserver.database.windows.net" -}}
{{- $db_name := .Values.platform.db.db_name | default .Release.Name -}}
{{- $sql_server := .Values.platform.db.sql_server | default "vc-prod-dbserver" -}}
{{- printf "Server=tcp:%s,1433;Database=%s;User ID=%s-user@%s;Password={{ .Data.db_password }};Trusted_Connection=False;Encrypt=True;" $server $db_name .Release.Name $sql_server -}}
{{- end -}}



{{- define "redis.connection_string" -}}
{{- $redis_service := .Values.platform.redis.service | default "redis-master.redis:6379" -}}
{{- $chanel_prefix := .Values.platform.redis.chanel | default "%s-%s-chanel" .Release.Name .Release.Namespace -}}
{{- printf "%s,password={{ .Data.REDIS_PASS }},ssl=False,abortConnect=False,channelPrefix=%s" $redis_service $chanel_prefix -}}
{{- end -}}

{{- define "vault.secrets" -}}
{{ println "{{ with secret \"secret/elastic\" }}" }}
{{ println "export Search__ElasticSearch__Key={{ .Data.ELASTIC_PASS }}" }}
{{ println "{{ end }}" }}
{{ println "{{ with secret \"secret/redis\" }}" }}
{{ println "export ConnectionStrings__RedisConnectionString=%s" (include "redis.connection_string" .) }}
{{ println "{{ end }}" }}
{{ println "{{ with secret \"secret/mssql\" }}" }}
{{ println "export ConnectionStrings__VirtoCommerce=%s" (include "db.connection_string" .)  }}
{{ println "{{ end }}" }}
{{ range $secret, $template := .Values.platform.vault.secrets }}
{{ println "{{ with secret \"secret/%s\" }}" $secret }}
{{ println "{{ export %s }}" $template }}
{{ println "{{ end }}" }}
{{ end }}
{{ end }}


{{/*
Create chart name and version as used by the chart label. {{- define "vault.secrets" -}}
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
template: {{ .Values.saas.template }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
