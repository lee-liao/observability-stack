# Observability Stack

A comprehensive Docker Compose setup for observability including Prometheus, Grafana, Jaeger, Zipkin, and OpenTelemetry Collector.

**Purpose**: This is a development-focused observability stack designed to be reused across multiple projects. It provides a complete telemetry solution with minimal setup overhead.

## Overview

This observability stack provides:
- **Metrics Collection**: Prometheus for scraping and storing metrics
- **Visualization**: Grafana for dashboards and visualization
- **Distributed Tracing**: Jaeger and Zipkin for trace analysis
- **Telemetry Processing**: OpenTelemetry Collector for centralizing telemetry data
- **Multi-Project Support**: Easy configuration for different development projects

## Services & Ports

| Service | Port | Description |
|---------|------|-------------|
| Grafana | 3000 | Web UI for visualization |
| Prometheus | 9090 | Metrics query and management |
| Jaeger UI | 16686 | Distributed tracing UI (Jaeger) |
| Zipkin UI | 9412 | Distributed tracing UI (Zipkin) |
| OTLP gRPC | 4317 | OpenTelemetry gRPC receiver |
| OTLP HTTP | 4318 | OpenTelemetry HTTP receiver |
| Jaeger Zipkin | 9411 | Jaeger's Zipkin compatible endpoint |

## Version Updates

All images have been updated to their latest stable versions:

| Component | Version |
|-----------|---------|
| Jaeger | 2.13.0 |
| Zipkin | 3.5.0 |
| OTel Collector | 0.143.0 |
| Prometheus | v3.1.0 |
| Grafana | 11.4.0 |

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+

### Start the Stack

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service health
docker-compose ps
```

### Stop the Stack

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Key configuration options:
- `GF_SECURITY_ADMIN_USER`: Grafana admin username (default: admin)
- `GF_SECURITY_ADMIN_PASSWORD`: Grafana admin password (default: admin)
- `PROMETHEUS_RETENTION_TIME`: Prometheus data retention (default: 15d)
- `PROJECT_NAME`: Customize for your project (default: my-project)
- `ENVIRONMENT`: Environment label (default: development)

### Using for Multiple Projects

This observability stack is designed to be shared across multiple projects:

**Option 1: Single Stack for All Projects (Recommended for Dev)**
- Use one observability stack for all development projects
- Configure different scrape jobs in `prometheus.yml` for each project
- Use service names and labels to differentiate between projects

**Option 2: Separate Stacks Per Project**
- Copy this entire folder to each project
- Modify `COMPOSE_PROJECT_NAME` in `.env` to avoid conflicts
- Update port mappings in `docker-compose.override.yml` if needed

**Option 3: Shared Stack with Project Isolation**
- Use this stack as a shared service
- Configure your applications to send telemetry with proper service names
- Use Grafana folders and labels to organize by project

### Custom Overrides

Create a `docker-compose.override.yml` for custom configurations without modifying the main file. See `docker-compose.override.yml.example` for examples.

## Key Improvements Made

### 1. Standardized Ports
- OTLP now uses standard ports (4317/4318) via OpenTelemetry Collector
- Jaeger's OTLP endpoints disabled to avoid conflicts
- Zipkin accessible on port 9412 (to avoid conflict with Jaeger's Zipkin endpoint on 9411)
- All telemetry should be sent to the OTel Collector

### 2. Dual Tracing Support
- Traces automatically sent to both Jaeger and Zipkin
- Use Jaeger for advanced features and complex queries
- Use Zipkin for simple, lightweight debugging
- Switch between them without changing application code

### 3. Health Checks
All services now include health checks:
- Services start in dependency order
- Health status available via `docker-compose ps`
- Prevents cascade failures from unhealthy dependencies

### 4. Configuration Fixes
- Fixed duplicate Grafana volumes
- Corrected Prometheus scrape targets
- Aligned OTel Collector config with Docker ports
- Enhanced Grafana datasource configuration with Zipkin

### 5. Better Resource Management
- Added memory limiter to OTel Collector
- Spike limit protection configured
- Health check extensions enabled

### 6. Multi-Project Ready
- Environment variables for project customization
- Flexible configuration for different development setups
- Easy to share across multiple projects

## Sending Telemetry

### OpenTelemetry SDK Configuration

Configure your applications to send telemetry to:

**OTLP gRPC:**
```
endpoint: http://localhost:4317
```

**OTLP HTTP:**
```
endpoint: http://localhost:4318
```

### Example: Python Application

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

otlp_exporter = OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(otlp_exporter))
```

### Example: Java Spring Boot

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info
  metrics:
    export:
      prometheus:
        enabled: true
  otlp:
    tracing:
      endpoint: http://localhost:4317
```

## Accessing Services

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger UI**: http://localhost:16686
- **Zipkin UI**: http://localhost:9412
- **OTel Collector Health**: http://localhost:13133

## Monitoring External Services

To monitor services running on your host machine:

1. Ensure `host.docker.internal` resolves (works with Docker Desktop)
2. Add scrape configs in `prometheus.yml`:

```yaml
- job_name: 'my-service'
  static_configs:
    - targets: ['host.docker.internal:8080']
```

For Linux without Docker Desktop, use:
```yaml
- job_name: 'my-service'
  static_configs:
    - targets: ['172.17.0.1:8080']  # Docker bridge IP
```

## Spring Boot Application Monitoring

This observability stack is pre-configured to monitor Spring Boot applications with Actuator and Prometheus metrics. The stack already includes a configured scrape job for Spring Boot apps.

### Quick Start for Spring Boot Apps

Your Spring Boot application needs:
1. **Spring Boot Actuator** dependency
2. **Micrometer Prometheus** registry
3. Actuator Prometheus endpoint exposed

#### Maven Dependencies (pom.xml)
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-registry-prometheus</artifactId>
    </dependency>
</dependencies>
```

#### Gradle Dependencies (build.gradle)
```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'io.micrometer:micrometer-registry-prometheus'
}
```

#### Application Configuration (application.yml)
```yaml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info,metrics
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
      environment: ${spring.profiles.active:default}
      project: my-project
```

### Current Configuration

The stack includes a pre-configured scrape job for Spring Boot applications in `prometheus.yml`:

```yaml
- job_name: 'spring-ai-observability'
  metrics_path: '/actuator/prometheus'
  static_configs:
    - targets: ['host.docker.internal:8080']
      labels:
        application: 'chat-client'
        environment: 'development'
        project: 'spring-ai-parent'
        module: '10observability-actuator'
        instance: 'chat-client:8080'
  scrape_interval: 5s
  scrape_timeout: 5s
```

**Status**: ✅ Active and monitoring Spring Boot applications on port 8080

### Adding Your Spring Boot Application

#### Step 1: Update prometheus.yml

Edit `prometheus.yml` and add/update your application's scrape configuration:

```yaml
scrape_configs:
  # Add your Spring Boot application
  - job_name: 'my-spring-app'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['host.docker.internal:YOUR_PORT']
        labels:
          application: 'your-app-name'
          environment: 'development'
          project: 'your-project'
          module: 'your-module'
          instance: 'your-app:PORT'
    scrape_interval: 5s
    scrape_timeout: 5s
```

#### Step 2: Reload Prometheus

Use the provided reload script to apply changes without restarting:

**Windows:**
```cmd
reload-prometheus.bat
```

**Linux/Mac:**
```bash
curl -X POST http://localhost:9090/-/reload
```

#### Step 3: Verify Configuration

Check that your application is being scraped:

```bash
# View target status
curl http://localhost:9090/api/v1/targets | grep "your-app-name"

# Or open in browser
http://localhost:9090/targets
```

Look for:
- **Health**: "up" (green)
- **Last Scrape**: Recent timestamp
- **Scrape Duration**: < 1s

### Reload Script (Windows)

The `reload-prometheus.bat` script provides easy configuration management:

**Features:**
- ✅ Hot-reload Prometheus without restart
- ✅ Show all target statuses
- ✅ Verify configuration syntax
- ✅ Display errors if any

**Usage:**
```cmd
# From observability directory
reload-prometheus.bat
```

**When to use:**
- After adding new applications
- After modifying scrape intervals
- After changing labels
- After updating target addresses

### Sample Prometheus Queries

Query your Spring Boot metrics in Prometheus (http://localhost:9090/graph):

#### Application Metrics
```promql
# All metrics from your application
{application="chat-client"}

# All metrics from your project
{project="spring-ai-parent"}

# Specific module metrics
{module="10observability-actuator"}
```

#### JVM Metrics
```promql
# JVM Memory Usage
jvm_memory_used_bytes{application="chat-client"}

# JVM Memory Usage by Area
jvm_memory_used_bytes{application="chat-client", area="heap"}

# JVM Memory Max
jvm_memory_max_bytes{application="chat-client"}

# Garbage Collection Time
rate(jvm_gc_pause_seconds_sum{application="chat-client"}[5m])

# Thread Count
jvm_threads_live_threads{application="chat-client"}
```

#### HTTP Request Metrics
```promql
# Request Rate
rate(http_server_requests_seconds_count{application="chat-client"}[5m])

# Request Duration (p95)
histogram_quantile(0.95,
  rate(http_server_requests_seconds_sum{application="chat-client"}[5m]) /
  rate(http_server_requests_seconds_count{application="chat-client"}[5m])
)

# Request Errors
rate(http_server_requests_seconds_count{application="chat-client",status=~"5.."}[5m])

# Slow Requests (> 1s)
rate(http_server_requests_seconds_count{application="chat-client"}[5m]) > 0.001
```

#### System Metrics
```promql
# CPU Usage
rate(process_cpu_usage{application="chat-client"}[5m])

# System Load Average
system_load_average_1m{application="chat-client"}

# File Descriptor Usage
process_files_open_files{application="chat-client"}
```

#### Spring Boot Specific
```promql
# Tomcat Metrics
tomcat_sessions_active_current_sessions{application="chat-client"}

# HikariCP Connection Pool
hikaricp_connections_active{application="chat-client"}
hikaricp_connections_idle{application="chat-client"}
hikaricp_connections_max{application="chat-client"}

# Cache Metrics
cache_gets{application="chat-client"}
cache_puts{application="chat-client"}
cache_hits{application="chat-client"}
```

#### AI/LLM Token Usage Metrics (Spring AI Built-in)

**Great news!** Spring AI provides **built-in token usage metrics** through Micrometer. No custom implementation needed!

The main metric is: `gen_ai_client_token_usage_total`

**Available Labels:**
- `gen_ai_token_type`: `input` (prompt), `output` (completion), `total`
- `gen_ai_system`: AI provider (deepseek, openai, anthropic, etc.)
- `gen_ai_request_model`: Model name (deepseek-chat, gpt-4, etc.)
- `gen_ai_operation_name`: Operation type (chat, embedding, etc.)
- `application`: Your application name
- `environment`: Environment label

```promql
# ========== TOKEN USAGE ==========

# Total tokens (all models and providers)
sum(rate(gen_ai_client_token_usage_total{application="chat-client"}[5m]))

# Total tokens by model
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[5m])) by (gen_ai_request_model)

# Total tokens by AI provider
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[5m])) by (gen_ai_system)

# Input tokens (prompt) vs Output tokens (completion) by model
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="input"}[5m])) by (gen_ai_request_model)
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="output"}[5m])) by (gen_ai_request_model)

# Input vs Output tokens stacked
sum(rate(gen_ai_client_token_usage_total{application="chat-client"}[5m])) by (gen_ai_token_type, gen_ai_request_model)

# Total accumulated tokens (counter, not rate)
gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}

# Token usage rate per minute
rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[1m])

# ========== REQUEST METRICS ==========

# Total requests by model
sum(rate(gen_ai_client_requests_total{application="chat-client"}[5m])) by (gen_ai_request_model)

# Total requests by provider
sum(rate(gen_ai_client_requests_total{application="chat-client"}[5m])) by (gen_ai_system)

# Requests by operation type
sum(rate(gen_ai_client_requests_total{application="chat-client"}[5m])) by (gen_ai_operation_name)

# ========== PERFORMANCE & LATENCY ==========

# P95 Request latency by model
histogram_quantile(0.95,
  sum(rate(gen_ai_client_operation_duration_seconds_sum{application="chat-client"}[5m])) by (gen_ai_request_model) /
  sum(rate(gen_ai_client_operation_duration_seconds_count{application="chat-client"}[5m])) by (gen_ai_request_model)
)

# Average request duration by provider
sum(rate(gen_ai_client_operation_duration_seconds_sum{application="chat-client"}[5m])) by (gen_ai_system) /
sum(rate(gen_ai_client_operation_duration_seconds_count{application="chat-client"}[5m])) by (gen_ai_system)

# ========== COST CALCULATION EXAMPLES ==========

# Estimate cost (assuming $0.01 per 1K tokens)
# Adjust multiplier based on your provider's pricing
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[5m])) * 0.00001

# Cost by model (example: gpt-4 pricing)
# GPT-4: ~$0.03 per 1K prompt tokens, $0.06 per 1K completion tokens
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_request_model="gpt-4", gen_ai_token_type="input"}[5m])) * 0.00003
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_request_model="gpt-4", gen_ai_token_type="output"}[5m])) * 0.00006

# ========== ADVANCED QUERIES ==========

# Tokens per operation type
sum(rate(gen_ai_client_token_usage_total{application="chat-client"}[5m])) by (gen_ai_operation_name, gen_ai_token_type)

# Average tokens per request
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[5m])) /
sum(rate(gen_ai_client_requests_total{application="chat-client"}[5m]))

# Compare providers side by side
sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[5m])) by (gen_ai_system, gen_ai_request_model)

# Token usage trends (last hour)
increase(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[1h])

# ========== ERROR TRACKING ==========

# If error metrics are available
sum(rate(gen_ai_client_requests_total{application="chat-client",error="true"}[5m])) by (gen_ai_request_model)

# Success rate
sum(rate(gen_ai_client_requests_total{application="chat-client"}[5m])) by (gen_ai_request_model)
-
sum(rate(gen_ai_client_requests_total{application="chat-client",error="true"}[5m])) by (gen_ai_request_model)
```

**Custom Token Metrics Examples:**

If your Spring Boot app uses custom metrics for token tracking:

```promql
# Custom OpenAI token metrics
openai_tokens_used_total{application="chat-client"}
openai_prompt_tokens_total{application="chat-client"}
openai_completion_tokens_total{application="chat-client"}

# Token usage by operation type
sum(rate(spring_ai_tokens_total{application="chat-client"}[5m])) by (operation)

# Chat-specific metrics
chat_tokens_per_message{application="chat-client"}
chat_total_messages{application="chat-client"}

# Cost tracking (if you track costs)
llm_cost_total{application="chat-client"}
sum(rate(llm_cost_total{application="chat-client"}[1h])) # Cost per hour
```

**Creating Grafana Panels for Token Usage:**

1. **Token Usage Over Time by Model**
   ```promql
   sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[5m])) by (gen_ai_request_model)
   ```
   - Panel type: Graph
   - Legend: {{gen_ai_request_model}}
   - Unit: tokens/sec
   - Title: Token Usage Rate by Model

2. **Input vs Output Tokens Stacked**
   ```promql
   sum(rate(gen_ai_client_token_usage_total{application="chat-client"}[5m])) by (gen_ai_token_type, gen_ai_request_model)
   ```
   - Panel type: Graph
   - Stack: Yes
   - Legend: {{gen_ai_token_type}} {{gen_ai_request_model}}
   - Title: Input (Prompt) vs Output (Completion) Tokens

3. **Total Token Cost (Estimated)**
   ```promql
   sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_token_type="total"}[5m])) * 0.00001
   ```
   - Panel type: Stat
   - Unit: currency (USD)
   - Title: Hourly Cost Rate (estimated)
   - Description: Adjust multiplier based on your provider's pricing

4. **Request Rate by Provider**
   ```promql
   sum(rate(gen_ai_client_requests_total{application="chat-client"}[5m])) by (gen_ai_system)
   ```
   - Panel type: Graph
   - Legend: {{gen_ai_system}}
   - Unit: requests/sec
   - Title: AI Provider Request Rate

5. **P95 Latency by Model**
   ```promql
   histogram_quantile(0.95,
     sum(rate(gen_ai_client_operation_duration_seconds_sum{application="chat-client"}[5m])) by (gen_ai_request_model) /
     sum(rate(gen_ai_client_operation_duration_seconds_count{application="chat-client"}[5m])) by (gen_ai_request_model)
   )
   ```
   - Panel type: Graph
   - Legend: {{gen_ai_request_model}}
   - Unit: seconds
   - Title: 95th Percentile Request Latency

6. **Cost Comparison by Model**
   ```promql
   # DeepSeek (example: $0.14 per 1K tokens)
   sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_system="deepseek", gen_ai_token_type="total"}[5m])) * 0.00014

  # GPT-4 (example: $0.03 per 1K input, $0.06 per 1K output)
  (sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_system="openai", gen_ai_request_model="gpt-4", gen_ai_token_type="input"}[5m])) * 0.00003) +
  (sum(rate(gen_ai_client_token_usage_total{application="chat-client", gen_ai_system="openai", gen_ai_request_model="gpt-4", gen_ai_token_type="output"}[5m])) * 0.00006)
   ```
   - Panel type: Graph
   - Legend: DeepSeek, GPT-4
   - Unit: currency (USD/min)
   - Title: Estimated Cost by Model

**Spring AI Built-in Metrics Setup:**

Spring AI automatically tracks token usage and metrics through Micrometer. To enable these built-in metrics:

**1. Add Dependencies (already in place):**
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-registry-prometheus</artifactId>
    </dependency>
    <!-- Spring AI dependency -->
    <dependency>
        <groupId>org.springframework.ai</groupId>
        <artifactId>spring-ai-openai-spring-boot-starter</artifactId>
    </dependency>
</dependencies>
```

**2. Enable Metrics in application.yml:**
```yaml
spring:
  application:
    name: chat-client

management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
      environment: ${spring.profiles.active:development}
      project: spring-ai-parent
```

**3. That's it!** Spring AI automatically publishes metrics:
- ✅ `gen_ai_client_token_usage_total` - Token counts
- ✅ `gen_ai_client_requests_total` - Request counts
- ✅ `gen_ai_client_operation_duration_*` - Latency histograms

No custom service implementation needed!

**Verify metrics are available:**
```bash
# Check your metrics endpoint
curl http://localhost:8080/actuator/prometheus | grep gen_ai
```

You should see output like:
```
gen_ai_client_token_usage_total{application="chat-client",gen_ai_operation_name="chat",gen_ai_request_model="deepseek-chat",gen_ai_system="deepseek",gen_ai_token_type="input",} 1234.0
gen_ai_client_token_usage_total{application="chat-client",gen_ai_operation_name="chat",gen_ai_request_model="deepseek-chat",gen_ai_system="deepseek",gen_ai_token_type="output",} 567.0
gen_ai_client_token_usage_total{application="chat-client",gen_ai_operation_name="chat",gen_ai_request_model="deepseek-chat",gen_ai_system="deepseek",gen_ai_token_type="total",} 1801.0
gen_ai_client_requests_total{application="chat-client",gen_ai_operation_name="chat",gen_ai_request_model="deepseek-chat",gen_ai_system="deepseek",} 42.0
```

**Sample Queries for Verification:**
```promql
# Check if metrics are being collected
gen_ai_client_token_usage_total

# Total tokens in the last 5 minutes
rate(gen_ai_client_token_usage_total{gen_ai_token_type="total"}[5m])

# Tokens by your application
gen_ai_client_token_usage_total{application="chat-client"}
```

### Grafana Dashboard Creation

Create dashboards in Grafana (http://localhost:3000) to visualize your metrics:

#### Quick Dashboard Setup

1. **Create New Dashboard**
   - Click "+" → "Dashboard"
   - Click "Add visualization"

2. **Select Prometheus Datasource**
   - Choose "Prometheus" as datasource

3. **Add Panels with Sample Queries**

**JVM Memory Panel:**
```promql
jvm_memory_used_bytes{application="chat-client", area="heap"}
```

**Request Rate Panel:**
```promql
sum(rate(http_server_requests_seconds_count{application="chat-client"}[5m])) by (uri)
```

**Error Rate Panel:**
```promql
sum(rate(http_server_requests_seconds_count{application="chat-client",status=~"5.."}[5m])) by (uri)
```

4. **Save Dashboard**
   - Name it after your application
   - Add to folder for organization

#### Import Pre-built Dashboards

Grafana offers pre-built Spring Boot dashboards:

1. Go to http://localhost:3000/dashboard/import
2. Enter Dashboard ID: `4701` (JVM Micrometer)
3. Select Prometheus datasource
4. Click "Import"

Or use ID `12900` for Spring Boot Statistics.

### Verification Checklist

Verify your Spring Boot monitoring setup:

- [ ] Actuator endpoints enabled: `curl http://localhost:8080/actuator`
- [ ] Prometheus metrics available: `curl http://localhost:8080/actuator/prometheus`
- [ ] Application added to prometheus.yml
- [ ] Prometheus reloaded: `reload-prometheus.bat`
- [ ] Target showing "UP" in http://localhost:9090/targets
- [ ] Metrics appearing in Prometheus: `{application="your-app"}`
- [ ] Dashboard created in Grafana

### Troubleshooting Spring Boot Monitoring

#### Application Not Being Scraped

**Problem**: Target shows "down" in Prometheus

**Solutions:**
1. Verify Actuator is enabled:
   ```bash
   curl http://localhost:8080/actuator/health
   ```

2. Check metrics endpoint:
   ```bash
   curl http://localhost:8080/actuator/prometheus
   ```

3. Verify port mapping:
   - Ensure `host.docker.internal:PORT` matches your app's port
   - On Linux, use Docker bridge IP: `172.17.0.1:PORT`

4. Check firewall rules

#### No Metrics Appearing

**Problem**: Target is "up" but no metrics visible

**Solutions:**
1. Check Prometheus logs:
   ```bash
   docker-compose logs prometheus | grep scrape
   ```

2. Verify metrics format:
   ```bash
   curl http://localhost:8080/actuator/prometheus | head -20
   ```

3. Test query in Prometheus:
   ```promql
   {application="your-app"}
   up{job="your-job-name"}
   ```

#### Missing JVM Metrics

**Problem**: JVM metrics not available

**Solutions:**
1. Ensure micrometer-registry-prometheus dependency is included
2. Check metrics are enabled in application.yml
3. Verify metrics binding:
   ```bash
   curl http://localhost:8080/actuator/prometheus | grep jvm_
   ```

### Example: Complete Spring Boot Monitoring Setup

#### 1. Application (application.yml)
```yaml
spring:
  application:
    name: chat-client

management:
  endpoints:
    web:
      exposure:
        include: '*'
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
      environment: ${spring.profiles.active:development}
      project: spring-ai-parent
      module: 10observability-actuator
```

#### 2. Prometheus (prometheus.yml)
```yaml
scrape_configs:
  - job_name: 'chat-client'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['host.docker.internal:8080']
        labels:
          application: 'chat-client'
          environment: 'development'
          project: 'spring-ai-parent'
          module: '10observability-actuator'
    scrape_interval: 5s
```

#### 3. Reload
```cmd
reload-prometheus.bat
```

#### 4. Verify
```bash
# Check target status
curl http://localhost:9090/api/v1/targets | grep chat-client

# Query metrics
curl 'http://localhost:9090/api/v1/query?query={application="chat-client"}'
```

#### 5. View in Grafana
- Open http://localhost:3000
- Create dashboard with your application's metrics
- Organize by project and environment labels

## Deployment Notes & Known Issues

### Issues Encountered and Fixed

During initial deployment, several issues were identified and resolved:

#### 1. Jaeger Image Version Issue
**Problem:** Image tag `jaegertracing/all-in-one:2.13.0` does not exist on Docker Hub.

**Solution:** Use `jaegertracing/all-in-one:latest` or check [Jaeger releases](https://www.jaegertracing.io/download/) for valid version tags.

**Location:** `docker-compose.yml:6`

#### 2. Grafana Plugin Installation Error
**Problem:** Error: `plugin grafana-pyroscope-datasource is a core plugin and cannot be installed separately`

**Solution:** Removed `GF_INSTALL_PLUGINS` environment variable as Pyroscope is now a built-in core plugin in Grafana 11.x.

**Location:** `docker-compose.yml:86`

#### 3. OTel Collector Deprecated Exporter
**Problem:** Error: `the logging exporter has been deprecated, use the debug exporter instead`

**Solution:** Replaced all instances of `logging` exporter with `debug` exporter in OTel Collector configuration.

**Location:** `otel-collector-config.yaml:72,81,86,91`

#### 4. OTel Collector Health Check Failure
**Problem:** Health check fails because `wget` command not found in OTel Collector container.

**Solution:** Removed health check for OTel Collector (service runs correctly without it). Health endpoint is still available at http://localhost:13133 for manual verification.

**Location:** `docker-compose.yml:61` (removed healthcheck, added restart policy)

#### 5. Jaeger OTLP Connection Refused
**Problem:** OTel Collector cannot connect to Jaeger on port 4317 because OTLP was disabled.

**Solution:** Enabled OTLP on Jaeger with `COLLECTOR_OTLP_ENABLED=true`. Jaeger's OTLP endpoint is accessible within Docker network but not exposed to host (avoids port conflict with OTel Collector).

**Location:** `docker-compose.yml:14`

#### 6. Obsolete Docker Compose Version
**Problem:** Warning: `the attribute 'version' is obsolete`

**Solution:** Removed `version: '3.8'` from docker-compose.yml (not required in Docker Compose v2+).

**Location:** `docker-compose.yml:1`

### Verification Steps

After deployment, verify all services are accessible:

```bash
# Check service status
docker-compose ps

# Test all endpoints
curl http://localhost:3000/api/health      # Grafana
curl http://localhost:9090/-/healthy       # Prometheus
curl http://localhost:16686/api/status     # Jaeger
curl http://localhost:9412/health          # Zipkin
curl http://localhost:13133/               # OTel Collector (via curl, not wget)
```

### Current Known Issues

1. **OTel Collector shows "unhealthy" in docker-compose ps**
   - **Impact:** None - service runs correctly
   - **Reason:** Health check uses `wget` which isn't available in container
   - **Workaround:** Verify manually: `curl http://localhost:13133/`
   - **Status:** Acceptable for development use

2. **Jaeger uses `latest` tag**
   - **Impact:** Image may update unexpectedly
   - **Reason:** Specific version tags like `2.13.0` don't exist on Docker Hub
   - **Workaround:** Pin to specific version if available (check Docker Hub for valid tags)
   - **Status:** Monitor for breaking changes

### Deployment Checklist

Before deploying:
- [ ] Docker Engine 20.10+ installed
- [ ] Docker Compose 2.0+ installed
- [ ] No conflicting services on ports 3000, 9090, 4317, 4318, 9411, 9412, 16686

After deploying:
- [ ] All containers running: `docker-compose ps`
- [ ] Grafana accessible: http://localhost:3000
- [ ] Prometheus healthy: http://localhost:9090/-/healthy
- [ ] Jaeger UI accessible: http://localhost:16686
- [ ] Zipkin UI accessible: http://localhost:9412
- [ ] OTLP endpoints responding: `curl http://localhost:4317/`
- [ ] Volumes created: `docker volume ls | grep observability`

## Troubleshooting

### Services Not Starting

Check health status:
```bash
docker-compose ps
docker-compose logs <service-name>
```

### OTLP Connection Refused

- Verify OTel Collector is running: `curl http://localhost:13133`
- Check firewall rules for ports 4317/4318
- Ensure no conflicting services

### Prometheus Not Scraping

- Check targets in Prometheus UI: http://localhost:9090/targets
- Verify network connectivity: `docker-compose exec prometheus ping otel-collector`
- Review Prometheus logs: `docker-compose logs prometheus`

### Jaeger Not Showing Traces

- Verify traces are sent to OTLP, not Jaeger directly
- Check OTel Collector logs: `docker-compose logs otel-collector`
- Confirm Jaeger connection: `docker-compose exec otel-collector ping jaeger`

### Zipkin Not Showing Traces

- Verify traces are sent to OTLP (collector forwards to Zipkin)
- Check OTel Collector logs: `docker-compose logs otel-collector`
- Confirm Zipkin connection: `docker-compose exec otel-collector ping zipkin`
- Access Zipkin UI at http://localhost:9412

### Traces in One System But Not the Other

- Both Jaeger and Zipkin receive traces from OTel Collector
- Check OTel Collector pipeline configuration
- Verify exporters are listed: `exporters: [otlp/jaeger, zipkin, debug]`
- Check OTel Collector logs for export errors

## Data Persistence

Persistent data is stored in Docker volumes:
- `prometheus-data`: Metrics time-series data
- `grafana-data`: Grafana dashboards and settings

To backup:
```bash
docker run --rm -v observability_prometheus-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/prometheus-backup.tar.gz -C /data .
```

## Maintenance

### Update Images

```bash
# Pull latest images
docker-compose pull

# Recreate containers with new images
docker-compose up -d
```

### Clean Old Data

```bash
# Stop stack
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker volume rm observability_prometheus-data observability_grafana-data

# Restart
docker-compose up -d
```

## Architecture

### High-Level Service Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DEVELOPMENT WORKSTATION / HOST                        │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Project A   │  │  Project B   │  │  Project C   │  │  External    │  │
│  │  (Python)    │  │  (Java)      │  │  (Node.js)   │  │  Services    │  │
│  │  :8000       │  │  :8080       │  │  :3000       │  │  :8080       │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │                 │           │
│         └─────────────────┴─────────────────┴─────────────────┘           │
│                                   │                                        │
│                    OTLP Protocol (gRPC/HTTP)                                │
│                                   ↓                                        │
└───────────────────────────────────┼────────────────────────────────────────┘
                                    │
┌───────────────────────────────────┼────────────────────────────────────────┐
│                      OBSERVABILITY NETWORK (bridge)                         │
│                                   │                                        │
│                    ┌──────────────▼───────────────┐                        │
│                    │   OpenTelemetry Collector    │                        │
│                    │   (Central Telemetry Hub)    │                        │
│                    │   Port: 4317 (gRPC)          │                        │
│                    │         4318 (HTTP)          │                        │
│                    │   Health: 13133              │                        │
│                    └──────────┬──────────┬────────┘                        │
│                               │          │                                 │
│              ┌────────────────┘          └────────────────┐                │
│              │ Traces (OTLP)              Metrics (Prom)  │                │
│              ↓                            ↓                │                │
│    ┌─────────────────┐         ┌─────────────────┐       │                │
│    │   Jaeger        │         │   Prometheus    │       │                │
│    │   Port: 16686   │         │   Port: 9090    │       │                │
│    │   (Traces)      │         │   (Metrics)     │       │                │
│    └────────┬────────┘         └────────┬────────┘       │                │
│             │                           │                │                │
│    ┌────────▼────────┐                 │                │                │
│    │   Zipkin        │                 │                │                │
│    │   Port: 9412    │                 │                │                │
│    │   (Traces)      │                 │                │                │
│    └────────┬────────┘                 │                │                │
│             └──────────────────────────┘                │                │
│                           │                             │                │
└───────────────────────────┼─────────────────────────────┘                │
                            │                                              │
                            ↓ Visualization                                │
│                    ┌───────────────┐                                      │
│                    │   Grafana     │                                      │
│                    │   Port: 3000  │                                      │
│                    │   (Dashboard) │                                      │
│                    └───────────────┘                                      │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           TELEMETRY DATA FLOW                            │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────┐
│ Application │
│   Service   │
└──────┬──────┘
       │
       │ 1. GENERATE TELEMETRY
       │    - Traces (Spans)
       │    - Metrics (Counters, Gauges, Histograms)
       │    - Logs (Optional)
       │
       ↓
┌─────────────────────┐
│ OpenTelemetry SDK   │
└──────┬──────────────┘
       │
       │ 2. EXPORT TO COLLECTOR
       │    OTLP gRPC: localhost:4317
       │    OTLP HTTP: localhost:4318
       │
       ↓
┌─────────────────────────────────────┐
│      OpenTelemetry Collector        │
│  ┌───────────────────────────────┐  │
│  │ Receivers                      │  │
│  │ • otlp (4317/4318)            │  │
│  └────────┬──────────────────────┘  │
│           │                          │
│  ┌────────▼──────────────────────┐  │
│  │ Processors                     │  │
│  │ • memory_limiter               │  │
│  │ • resource (add attributes)    │  │
│  │ • transform                    │  │
│  │ • batch                        │  │
│  └────────┬──────────────────────┘  │
│           │                          │
│  ┌────────▼──────────────────────┐  │
│  │ Exporters                      │  │
│  │                                │  │
│  │ ┌──────────────────────────┐  │  │
│  │ │ otlp/jaeger (→ Jaeger)   │  │  │
│  │ │ zipkin   (→ Zipkin)      │  │  │
│  │ │ logging  (Console)       │  │  │
│  │ └──────────────────────────┘  │  │
│  │                                │  │
│  │ ┌──────────────────────────┐  │  │
│  │ │ prometheus (8889)         │  │  │
│  │ │ logging  (Console)       │  │  │
│  │ └──────────────────────────┘  │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
       │                    │
       │ Traces             │ Metrics
       ↓                    ↓
┌─────────────┐    ┌─────────────┐
│   Jaeger    │    │ Prometheus  │
│   Zipkin    │    │             │
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
                ↓
         ┌─────────────┐
         │  Grafana    │
         │ (Query API) │
         └─────────────┘
```

### Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                      DOCKER NETWORK                              │
│                  Name: observability (bridge)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Container Name          │    IP Address    │    Exposed Ports  │
│  ────────────────────────┼──────────────────┼──────────────────│
│  grafana                 │   172.18.0.X     │   3000 → 3000    │
│  prometheus              │   172.18.0.X     │   9090 → 9090    │
│  jaeger                  │   172.18.0.X     │   16686 → 16686  │
│                           │                 │   14268 → 14268  │
│                           │                 │   14250 → 14250  │
│                           │                 │   9411 → 9411    │
│  zipkin                  │   172.18.0.X     │   9412 → 9411    │
│  otel-collector          │   172.18.0.X     │   4317 → 4317    │
│                           │                 │   4318 → 4318    │
│                           │                 │   8888 → 8888    │
│                           │                 │   8889 → 8889    │
│                           │                 │   13133 → 13133  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                           │
                           │ DNS Resolution
                           │
         All containers can reach each other by:
         • Service name (e.g., http://prometheus:9090)
         • Container name (e.g., http://grafana:3000)
         • Network alias (if configured)
```

### Component Interactions

```
┌──────────────────────────────────────────────────────────────────────┐
│                    SERVICE INTERACTIONS & DEPENDENCIES               │
└──────────────────────────────────────────────────────────────────────┘

  Application                 OTel Collector              Storage/Backend
       │                            │                            │
       │  OTLP Export               │                            │
       ├─────────────────────────>  │                            │
       │  (Traces + Metrics)        │                            │
       │                            │                            │
       │                            │  OTLP Export              │
       │                            ├─────────────────────────>  │
       │                            │  (Traces)                  │
       │                            │                            │
       │                            │  Zipkin Export            │
       │                            ├─────────────────────────>  │
       │                            │  (Traces)                  │
       │                            │                            │
       │                            │  Prometheus Export        │
       │                            ├─────────────────────────>  │
       │                            │  (Metrics on :8889)        │
       │                            │                            │
       │                                                         │
       │  Prometheus Scrape                                       │
       ├<────────────────────────────────────────────────────────  │
       │  (Metrics from :8889)                                     │
       │                                                         │

  User Interface                                                  │
       │                                                         │
       │  HTTP Query                                             │
       ├─────────────────────────────────────────────────────>  │
       │                                                         │
       │  Return Metrics/Traces                                  │
       ├<──────────────────────────────────────────────────────  │
       │                                                         │

       │                                                         │
       ↓                                                         ↓
  ┌─────────┐                                            ┌──────────┐
  │ Grafana │                                            │ Jaeger   │
  │ Zipkin  │                                            │ Zipkin   │
  └─────────┘                                            └──────────┘
```

### Health Check Dependencies

```
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE STARTUP ORDER                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. jaeger        ────► HEALTHY ──┐                            │
│                                     │                            │
│  2. zipkin        ────► HEALTHY ──┼───► ALLOW                   │
│                                     │                            │
│  3. otel-collector ───► HEALTHY ──┘     otel-collector           │
│                                           to start              │
│  4. prometheus     ────► HEALTHY ──┐                            │
│                                     │                            │
│  5. grafana       ────► HEALTHY ───┴───► ALLOW                   │
│                                              grafana             │
│                                              to start            │
│                                                                  │
│  Each service waits for dependencies to be healthy before       │
│  starting, ensuring proper initialization order.                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Storage & Persistence

```
┌─────────────────────────────────────────────────────────────────┐
│                      DATA PERSISTENCE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Service          │  Storage Type  │  Volume Name    │  Mount   │
│  ────────────────┼────────────────┼─────────────────┼──────────│
│  Prometheus      │  Time-series DB│  prometheus-data │ /prom    │
│                   │  (Disk)        │                 │          │
│  ────────────────┼────────────────┼─────────────────┼──────────│
│  Grafana         │  SQLite/Config │  grafana-data    │ /var/... │
│                   │  (Disk)        │                 │          │
│  ────────────────┼────────────────┼─────────────────┼──────────│
│  Jaeger          │  Memory        │  None           │  N/A     │
│                   │  (Ephemeral)   │                 │          │
│  ────────────────┼────────────────┼─────────────────┼──────────│
│  Zipkin          │  Memory        │  None           │  N/A     │
│                   │  (Ephemeral)   │                 │          │
│  ────────────────┼────────────────┼─────────────────┼──────────│
│  OTel Collector  │  Memory        │  None           │  N/A     │
│                   │  (Ephemeral)   │                 │          │
│                                                                  │
│  NOTE: Jaeger, Zipkin, and OTel Collector use in-memory storage │
│        suitable for development. Data is lost on restart.       │
│        For production, configure persistent backends.           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Dual Tracing Support**: Traces are sent to both Jaeger and Zipkin, allowing you to use either interface depending on your preference or requirements.

## Choosing Between Jaeger and Zipkin

Both Jaeger and Zipkin are distributed tracing systems, but they have different strengths:

### Jaeger
- **Better for**: Complex microservices architectures, advanced filtering
- **Features**:
  - Advanced search and filtering capabilities
  - Service dependency graphs
  - Performance metrics and monitoring
  - Sampling strategies
  - Modern, feature-rich UI

### Zipkin
- **Better for**: Simple setups, legacy applications, resource-constrained environments
- **Features**:
  - Lightweight and fast
  - Simple, straightforward UI
  - Lower resource requirements
  - Widely adopted, many client libraries
  - Great for quick debugging

**Recommendation**: Start with Jaeger for comprehensive tracing, use Zipkin for simpler needs or legacy compatibility. Since traces are sent to both, you can switch between them as needed.

## Sentry vs. OpenTelemetry Stack

### Sentry's Role in Observability

Sentry is a powerful **error tracking and issue management** platform that complements your OpenTelemetry stack. Understanding when to use Sentry versus your OTLP pipeline is crucial for effective observability.

### Sentry Support for OTLP (Current State - 2026)

| Feature | Support Status | Notes |
|---------|---------------|-------|
| **Traces via OTLP** | ⚠️ Open Beta | Limited features (no span events, partial links support) |
| **Logs via OTLP** | ⚠️ Open Beta | Available but in development |
| **Metrics via OTLP** | ❌ Not Supported | Use Sentry SDK metrics or Prometheus |
| **Error Tracking** | ✅ Full Support | Core strength - production-ready |

### Recommended Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION                                  │
│                 (Your Services)                                 │
└────────┬──────────────────────────────────────────┬─────────────┘
         │                                          │
         │ Errors & Issues                          │ Telemetry
         │                                          │ (Traces + Metrics)
         ↓                                          ↓
┌──────────────────┐                    ┌──────────────────────┐
│   Sentry SDK     │                    │   OTLP SDK           │
│  (Error Focus)   │                    │ (Telemetry Focus)    │
└────────┬─────────┘                    └──────────┬───────────┘
         │                                         │
         ↓                                         ↓
┌──────────────────┐                    ┌──────────────────────┐
│     Sentry       │                    │  OTEL Collector      │
│  (SaaS/Self-host)│                    │                      │
│                  │                    │  ├─► Jaeger (Traces) │
│  • Errors        │                    │  ├─► Prometheus      │
│  • Issues        │                    │  └─► Zipkin          │
│  • Alerts        │                    └──────────────────────┘
│  • Release Track │
└──────────────────┘
```

### Tool Comparison: When to Use What

| Use Case | Recommended Tool | Why |
|----------|-----------------|-----|
| **Error Tracking** | **Sentry** | Stack traces, issue management, breadcrumbs, alerting |
| **Distributed Tracing** | **Jaeger** | Full OTLP support, trace visualization, dependency graphs |
| **Metrics Storage** | **Prometheus** | Long-term storage, PromQL queries, trend analysis |
| **Dashboards** | **Grafana** | Flexible visualization, multi-datasource support |
| **Performance Monitoring** | **Jaeger + Prometheus** | Jaeger for traces, Prometheus for metrics |
| **Alerting** | **Sentry / AlertManager** | Sentry for errors, Prometheus AlertManager for metrics |
| **Release Tracking** | **Sentry** | Deployment monitoring, error rate changes, rollbacks |

### Practical Implementation

#### Option 1: Separate SDKs (Recommended for Production)

```python
import sentry_sdk
from opentelemetry import trace, metrics
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Sentry: Error tracking & issue management
sentry_sdk.init(
    dsn="__YOUR_SENTRY_DSN__",
    traces_sample_rate=0.1,  # Send 10% of transactions to Sentry
    environment="production"
)

# OpenTelemetry: Full telemetry pipeline
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint="http://localhost:4317"))
)

# Application code
try:
    do_something()
except Exception as e:
    # Sentry: Error tracking
    sentry_sdk.capture_exception(e)

    # OTLP: Trace context (if available)
    span = trace.get_current_span()
    if span:
        span.record_exception(e)

    raise
```

**Benefits:**
- ✅ Best of both worlds
- ✅ Sentry's excellent error tracking
- ✅ Full OTLP telemetry to your local stack
- ✅ No beta limitations

#### Option 2: OTLP to Sentry (Not Recommended Yet)

```yaml
# otel-collector-config.yaml
exporters:
  otlp/sentry:
    endpoint: "https://otlp.sentry.io:4317"
    headers:
      "X-Sentry-Auth-Token": "__YOUR_TOKEN__"
```

**Limitations:**
- ⚠️ OTLP support in beta (as of 2026)
- ⚠️ No metrics support via OTLP
- ⚠️ Limited trace features (no span events, partial links)
- ⚠️ May have breaking changes

### Key Differences

| Aspect | Sentry | OTLP Stack (Jaeger + Prometheus) |
|--------|--------|---------------------------------|
| **Primary Focus** | Error tracking & issues | Full observability telemetry |
| **Data Model** | Issues, Events, Transactions | Spans, Metrics, Logs |
| **Strengths** | Alerting, issue management, stack traces | Deep performance analysis, trends |
| **Storage** | Cloud (SaaS) or self-hosted | Local (Prometheus + Jaeger) |
| **Query Language** | Sentry search UI | PromQL + Jaeger UI |
| **Cost** | Based on volume | Free (self-hosted) |
| **Setup Complexity** | Simple (SDK + DSN) | Moderate (Docker Compose) |

### When to Add Sentry

**Add Sentry when you need:**

1. **Production Error Monitoring**
   - Get notified immediately when errors occur
   - Track error rates across releases
   - Assign and prioritize issues

2. **Alerting**
   - Email/Slack notifications on errors
   - Anomaly detection
   - Custom alert rules

3. **Release Tracking**
   - Monitor deployments
   - Compare error rates before/after releases
   - Identify problematic releases quickly

4. **User Context**
   - See which users are affected
   - User feedback integration
   - Session replay (with paid plan)

5. **Team Collaboration**
   - Issue assignment
   - Comment threads
   - Resolution tracking

### When to Use OTLP Stack Only

**Use OTLP stack (Jaeger + Prometheus) when:**

1. **Development Environment**
   - Full control over data
   - No external dependencies
   - Cost-free

2. **Performance Analysis**
   - Deep distributed tracing
   - Performance bottleneck identification
   - Service dependency mapping

3. **Metrics & Trends**
   - Long-term metric storage
   - Custom dashboards
   - Historical data analysis

4. **Compliance / Data Privacy**
   - On-premises data storage
   - No data leaving your infrastructure
   - Full data control

### Hybrid Setup Example

```yaml
# Production architecture
Application:
  ├─ Sentry SDK (errors, transactions)
  └─ OTLP SDK (traces, metrics)

Destinations:
  ├─ Sentry (errors, alerts, issues)
  ├─ Jaeger (distributed traces)
  └─ Prometheus (metrics, trends)

Visualization:
  ├─ Sentry UI (error investigation)
  └─ Grafana (performance dashboards)
```

### Summary

| Question | Answer |
|----------|--------|
| **Should I use Sentry for OTLP?** | ❌ Not recommended (yet) - still beta, limited features |
| **Should I use Sentry for errors?** | ✅ **YES!** - That's its core strength |
| **Can I use both?** | ✅ **YES!** - Sentry SDK for errors + OTLP for telemetry |
| **What's the best combo?** | Sentry (errors) + Jaeger (traces) + Prometheus (metrics) + Grafana (dashboards) |

**Bottom Line:** Your current OTLP stack is **well-architected** for development and self-hosted observability. Sentry would be an **excellent addition** for production error tracking and alerting, but should complement (not replace) your OTLP pipeline.

### Additional Resources

- [Sentry OpenTelemetry Documentation](https://docs.sentry.io/platforms/python/performance/instrumentation/opentelemetry/)
- [Sentry OTLP Protocol (Beta)](https://docs.sentry.io/concepts/otlp/)
- [OpenTelemetry + Sentry Integration](https://sentry.io/for/opentelemetry/)
- [Choosing an Observability Tool](https://www.jaegertracing.io/docs/latest/)

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Zipkin Documentation](https://zipkin.io/pages/quickstart)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [OpenTelemetry Standards](https://opentelemetry.io/docs/reference/specification/)

## Contributing

When making changes:
1. Test configuration changes locally first
2. Update this README if adding/changing services
3. Maintain backward compatibility when possible
4. Document breaking changes clearly

## License

This configuration is provided as-is for observability setup.
