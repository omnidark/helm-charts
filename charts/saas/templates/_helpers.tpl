{{- define "env.app_name" -}}
{{- $name := trimSuffix .Release.Name "-" | trimSuffix "-" | default "saas" -}}
{{- printf $name }}
{{- end -}}

{{- define "platform.host" -}}
{{- $name := trimSuffix .Release.Name "-" | trimSuffix "-" -}}
{{- printf "%s.%s.govirto.com" $name .Release.Namespace }}
{{- end -}}

{{- define "db.connection_string" -}}
{{- $server := .Values.platform.db.server | default "vc-prod-dbserver.database.windows.net" -}}
{{- $db_name := .Values.platform.db.db_name | default .Release.Name -}}
{{- $sql_username := .Values.platform.db.sql_username | default | printf "%s-user" .Release.Name -}}
{{- $sql_server := .Values.platform.db.sql_server | default "vc-prod-dbserver" -}}
{{- printf "Server=tcp:%s,1433;Database=%s;User ID=%s@%s;Password={{ .Data.db_password }};Trusted_Connection=False;Encrypt=True;" $server $db_name $sql_username $sql_server -}}
{{- end -}}



{{- define "redis.connection_string" -}}
{{- $redis_service := .Values.platform.redis.service | default "redis-master.redis:6379" -}}
{{- $chanel_prefix := .Values.platform.redis.chanel | default "%s-%s-chanel" .Release.Name .Release.Namespace -}}
{{- printf "%s,password={{ .Data.REDIS_PASS }},ssl=False,abortConnect=False,channelPrefix=%s" $redis_service $chanel_prefix -}}
{{- end -}}


{{- define "vault.secrets" -}}
{{- printf "{{ with secret \"secret/elastic\" }}" }}
{{- printf "export Search__ElasticSearch__Key={{ .Data.ELASTIC_PASS }}" }}
{{- printf "{{ end }}" }}
{{- printf "{{ with secret \"secret/redis\" }}" }}
{{- printf "export ConnectionStrings__RedisConnectionString=%s" (include "redis.connection_string" .) }}
{{- printf "{{ end }}" }}
{{- printf "{{ with secret \"secret/mssql\" }}" }}
{{- printf "export ConnectionStrings__VirtoCommerce=%s" (include "db.connection_string" .) }}
{{- printf "{{ end }}" }}
{{- range $secret, $template := .Values.vault.secrets }}
{{- printf "{{ with secret \"secret/%s\" }}" $secret }}
{{- printf "{{ export %s }}" $template }}
{{- printf "{{ end }}" }}
{{- end }}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
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