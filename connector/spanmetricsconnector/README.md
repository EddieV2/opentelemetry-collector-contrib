# Span Metrics Connector

<!-- status autogenerated section -->
| Status        |           |
| ------------- |-----------|
| Distributions | [contrib], [grafana], [liatrio], [splunk], [sumo] |
| Issues        | [![Open issues](https://img.shields.io/github/issues-search/open-telemetry/opentelemetry-collector-contrib?query=is%3Aissue%20is%3Aopen%20label%3Aconnector%2Fspanmetrics%20&label=open&color=orange&logo=opentelemetry)](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues?q=is%3Aopen+is%3Aissue+label%3Aconnector%2Fspanmetrics) [![Closed issues](https://img.shields.io/github/issues-search/open-telemetry/opentelemetry-collector-contrib?query=is%3Aissue%20is%3Aclosed%20label%3Aconnector%2Fspanmetrics%20&label=closed&color=blue&logo=opentelemetry)](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues?q=is%3Aclosed+is%3Aissue+label%3Aconnector%2Fspanmetrics) |
| [Code Owners](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/CONTRIBUTING.md#becoming-a-code-owner)    | [@albertteoh](https://www.github.com/albertteoh) |

[alpha]: https://github.com/open-telemetry/opentelemetry-collector#alpha
[contrib]: https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib
[grafana]: https://github.com/grafana/agent
[liatrio]: https://github.com/liatrio/liatrio-otel-collector
[splunk]: https://github.com/signalfx/splunk-otel-collector
[sumo]: https://github.com/SumoLogic/sumologic-otel-collector

## Supported Pipeline Types

| [Exporter Pipeline Type] | [Receiver Pipeline Type] | [Stability Level] |
| ------------------------ | ------------------------ | ----------------- |
| traces | metrics | [alpha] |

[Exporter Pipeline Type]: https://github.com/open-telemetry/opentelemetry-collector/blob/main/connector/README.md#exporter-pipeline-type
[Receiver Pipeline Type]: https://github.com/open-telemetry/opentelemetry-collector/blob/main/connector/README.md#receiver-pipeline-type
[Stability Level]: https://github.com/open-telemetry/opentelemetry-collector#stability-levels
<!-- end autogenerated section -->

## Overview

Aggregates Request, Error and Duration (R.E.D) OpenTelemetry metrics from span data.

**Request** counts are computed as the number of spans seen per unique set of
dimensions, including Errors. Multiple metrics can be aggregated if, for instance,
a user wishes to view call counts just on `service.name` and `span.name`.

```
calls{service.name="shipping",span.name="get_shipping/{shippingId}",span.kind="SERVER",status.code="Ok"}
```

**Error** counts are computed from the Request counts which have an `Error` Status Code metric dimension.

```
calls{service.name="shipping",span.name="get_shipping/{shippingId},span.kind="SERVER",status.code="Error"}
```

**Duration** is computed from the difference between the span start and end times and inserted into the
relevant duration histogram time bucket for each unique set dimensions.

```
duration{service.name="shipping",span.name="get_shipping/{shippingId}",span.kind="SERVER",status.code="Ok"}
```

Each metric will have _at least_ the following dimensions because they are common
across all spans:

- `service.name`
- `span.name`
- `span.kind`
- `status.code`


## Span to Metrics processor to Span to metrics connector

The spanmetrics connector is a port of the [spanmetrics](../../processor/spanmetricsprocessor/README.md) processor, but with multiple improvements
and breaking changes. It was done to bring the `spanmetrics` connector closer to the OpenTelemetry
specification and make the component agnostic to exporters logic. The `spanmetrics` processor
essentially was mixing the OTel with Prometheus conventions by using the OTel data model and
the Prometheus metric and attributes naming convention.

The following changes were done to the connector component.

Breaking changes:
- The `operation` metric attribute was renamed to `span.name`.
- The `latency` histogram metric name was changed to `duration`.
- The `_total` metric prefix was dropped from generated metrics names.
- The Prometheus-specific metrics labels sanitization was dropped.

Improvements:
- Added support for OTel exponential histograms for recording span duration measurements.
- Added support for the milliseconds and seconds histogram units.
- Added support for generating metrics resource scope attributes. The `spanmetrics` connector will
generate the number of metrics resource scopes that corresponds to the number of the spans resource
scopes meaning that more metrics are generated now. Previously, `spanmetrics` generated a single
metrics resource scope.

## Configurations

If you are not already familiar with connectors, you may find it helpful to first
visit the [Connectors README].

The following settings can be optionally configured:

- `histogram` (default: `explicit`): Use to configure the type of histogram to record
  calculated from spans duration measurements. Must be either `explicit` or `exponential`.
  - `disable` (default: `false`): Disable all histogram metrics.
  - `unit` (default: `ms`): The time unit for recording duration measurements.
  calculated from spans duration measurements. One of either: `ms` or `s`.
  - `explicit`:
    - `buckets`: the list of durations defining the duration histogram time buckets. Default
      buckets: `[2ms, 4ms, 6ms, 8ms, 10ms, 50ms, 100ms, 200ms, 400ms, 800ms, 1s, 1400ms, 2s, 5s, 10s, 15s]`
  - `exponential`:
    - `max_size` (default: `160`) the maximum number of buckets per positive or negative number range.
- `dimensions`: the list of dimensions to add together with the default dimensions defined above.
  
  Each additional dimension is defined with a `name` which is looked up in the span's collection of attributes or
  resource attributes (AKA process tags) such as `ip`, `host.name` or `region`.
  
  If the `name`d attribute is missing in the span, the optional provided `default` is used.
  
  If no `default` is provided, this dimension will be **omitted** from the metric.
- `exclude_dimensions`: the list of dimensions to be excluded from the default set of dimensions. Use to exclude unneeded data from metrics. 
- `dimensions_cache_size` (default: `1000`): the size of cache for storing Dimensions to improve collectors memory usage. Must be a positive number. 
- `resource_metrics_cache_size` (default: `1000`): the size of the cache holding metrics for a service. This is mostly relevant for
   cumulative temporality to avoid memory leaks and correct metric timestamp resets.
- `aggregation_temporality` (default: `AGGREGATION_TEMPORALITY_CUMULATIVE`): Defines the aggregation temporality of the generated metrics. 
  One of either `AGGREGATION_TEMPORALITY_CUMULATIVE` or `AGGREGATION_TEMPORALITY_DELTA`.
- `namespace`: Defines the namespace of the generated metrics. If `namespace` provided, generated metric name will be added `namespace.` prefix.
- `metrics_flush_interval` (default: `15s`): Defines the flush interval of the generated metrics.
- `exemplars`:  Use to configure how to attach exemplars to histograms
  - `enabled` (default: `false`): enabling will add spans as Exemplars.
- `events`: Use to configure the events metric.
  - `enabled`: (default: `false`): enabling will add the events metric.
  - `dimensions`: (mandatory if `enabled`) the list of the span's event attributes to add as dimensions to the events metric, which will be included _on top of_ the common and configured `dimensions` for span and resource attributes.

## Examples

The following is a simple example usage of the `spanmetrics` connector.

For configuration examples on other use cases, please refer to [More Examples](#more-examples).

The full list of settings exposed for this connector are documented [here](../../connector/spanmetricsconnector/config.go).

```yaml
receivers:
  nop:

exporters:
  nop:

connectors:
  spanmetrics:
    histogram:
      explicit:
        buckets: [100us, 1ms, 2ms, 6ms, 10ms, 100ms, 250ms]
    dimensions:
      - name: http.method
        default: GET
      - name: http.status_code
    exemplars:
      enabled: true
    exclude_dimensions: ['status.code']
    dimensions_cache_size: 1000
    aggregation_temporality: "AGGREGATION_TEMPORALITY_CUMULATIVE"    
    metrics_flush_interval: 15s
    events:
      enabled: true
      dimensions:
        - name: exception.type
        - name: exception.message

service:
  pipelines:
    traces:
      receivers: [nop]
      exporters: [spanmetrics]
    metrics:
      receivers: [spanmetrics]
      exporters: [nop]
```

### Using `spanmetrics` with Prometheus components

The `spanmetrics` connector can be used with Prometheus exporter components.

For some functionality of the exporters, e.g. like generation of the `target_info` metric the
incoming spans resource scope attributes must contain `service.name` and `service.instance.id`
attributes.

Let's look at the example of using the `spanmetrics` connector with the `prometheusremotewrite` exporter:

```yaml
receivers:
  otlp:
    protocols:
      http:
      grpc:

exporters:
  prometheusremotewrite:
    endpoint: http://localhost:9090/api/v1/write
    target_info:
      enabled: true

connectors:
  spanmetrics:
    namespace: span.metrics

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [spanmetrics]
    metrics:
      receivers: [spanmetrics]
      exporters: [prometheusremotewrite]
```

This configures the `spanmetrics` connector to generate metrics from received spans and export the
metrics to the Prometheus Remote Write exporter. The `target_info` metric will be generated for each
resource scope, while OpenTelemetry metric names and attributes will be [normalized](../../exporter/prometheusremotewriteexporter/README.md)
to be compliant with Prometheus naming rules. For example, the generated `calls` OTel sum metric can
result in multiple Prometheus `calls_total` (counter type) time series and the `target_info` time series.
For example:

```
target_info{job="shippingservice", instance="...", ...} 1
calls_total{span_name="/Address", service_name="shippingservice", span_kind="SPAN_KIND_SERVER", status_code="STATUS_CODE_UNSET", ...} 142
```

### More Examples

For more example configuration covering various other use cases, please visit the [testdata directory](../../connector/spanmetricsconnector/testdata).

[Connectors README]: https://github.com/open-telemetry/opentelemetry-collector/blob/main/connector/README.md