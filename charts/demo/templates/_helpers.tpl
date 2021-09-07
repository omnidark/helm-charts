{{- define "env.app_name" -}}
{{- printf .Release.Name | default "saas" }}
{{- end -}}

{{- define "platform.host" -}}
{{- printf "%s.%s.govirto.com" .Release.Name .Release.Namespace }}
{{- end -}}

{{- define "storefront.host" -}}
{{- printf "%s-storefront.%s.govirto.com" .Release.Name .Release.Namespace }}
{{- end -}}

{{- define "db.connection_string" -}}
{{- $server := .Values.platform.db.server | default "vc-prod-dbserver.database.windows.net" -}}
{{- $db_name := .Values.platform.db.db_name | default (printf "%s-platform_saas" .Release.Name) -}}
{{- $sql_server := .Values.platform.db.sql_server | default "vc-prod-dbserver" -}}
{{- $db_username := .Values.platform.db.username | default (printf "%s_%s_user" .Release.Name .Release.Namespace) -}}
{{- printf "Server=tcp:%s,1433;Database=%s;User ID=%s@%s;Password={{ .Data.PASS }};Trusted_Connection=False;Encrypt=True;" $server $db_name $db_username $sql_server -}}
{{- end -}}



{{- define "redis.connection_string" -}}
{{- $redis_service := .Values.platform.redis.service | default "redis-cluster.redis:6379" -}}
{{- $chanel_prefix := .Values.platform.redis.chanel | default (printf "%s-%s-chanel" .Release.Name .Release.Namespace ) -}}
{{- printf "%s,password={{ .Data.REDIS_CLUSTER_PASS }},ssl=False,abortConnect=False,channelPrefix=%s" $redis_service $chanel_prefix -}}
{{- end -}}

{{- define "vault.secrets" -}}
{{- $redis := (include "redis.connection_string" .) | trimPrefix " " -}}
{{- $db := (include "db.connection_string" .) | trimPrefix " " -}}
{{ printf "{{ with secret \"secret/elastic\" }}" }}
{{ printf "export Search__ElasticSearch__Key={{ .Data.ELASTIC_PASS }}" }}
{{ printf "{{ end }}" }}
{{ printf "{{ with secret \"secret/redis_cluster\" }}" }}
{{ printf "export ConnectionStrings__RedisConnectionString=\"%s\"" $redis }}
{{ printf "{{ end }}" }}
{{ printf "{{ with secret \"secret/saas-mssql\" }}" }}
{{ printf "export ConnectionStrings__VirtoCommerce=\"%s\"" $db }}
{{ printf "{{ end }}" }}
{{ if .Values.platform.vault.secrets }}
{{ range $secret, $template := .Values.platform.vault.secrets }}
{{ printf "{{ with secret \"secret/%s\" }}" $secret }}
{{ printf "export %s" $template }}
{{ printf "{{ end }}" }}
{{ end }}
{{ end }}
{{ end }}

{{- define "platform.configmaps" -}}
{{- $platform_cm := include (print $.Template.BasePath "/platform-cm.yaml") . | sha256sum -}}
{{- $secrets_cm := include (print $.Template.BasePath "/secrets.yaml") . | sha256sum -}}
{{- printf "%s-%s" $platform_cm $secrets_cm | quote -}}
{{- end -}}

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

{{/*
Platform Selector labels
*/}}
{{- define "app.platformLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}-platform
{{- end -}}

{{/*
Storefront Selector labels
*/}}
{{- define "app.storefrontLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}-storefront
{{- end -}}