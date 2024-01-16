# AWS X-Ray Tracing Exporter for OpenTelemetry Collector

<!-- status autogenerated section -->
| Status        |           |
| ------------- |-----------|
| Stability     | [beta]: traces   |
| Distributions | [contrib], [aws], [liatrio], [observiq] |
| Issues        | [![Open issues](https://img.shields.io/github/issues-search/open-telemetry/opentelemetry-collector-contrib?query=is%3Aissue%20is%3Aopen%20label%3Aexporter%2Fawsxray%20&label=open&color=orange&logo=opentelemetry)](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues?q=is%3Aopen+is%3Aissue+label%3Aexporter%2Fawsxray) [![Closed issues](https://img.shields.io/github/issues-search/open-telemetry/opentelemetry-collector-contrib?query=is%3Aissue%20is%3Aclosed%20label%3Aexporter%2Fawsxray%20&label=closed&color=blue&logo=opentelemetry)](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues?q=is%3Aclosed+is%3Aissue+label%3Aexporter%2Fawsxray) |
| [Code Owners](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/CONTRIBUTING.md#becoming-a-code-owner)    | [@wangzlei](https://www.github.com/wangzlei), [@srprash](https://www.github.com/srprash) |

[beta]: https://github.com/open-telemetry/opentelemetry-collector#beta
[contrib]: https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib
[aws]: https://github.com/aws-observability/aws-otel-collector
[liatrio]: https://github.com/liatrio/liatrio-otel-collector
[observiq]: https://github.com/observIQ/observiq-otel-collector
<!-- end autogenerated section -->

This exporter converts OpenTelemetry spans to
[AWS X-Ray Segment Documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)
and then sends them directly to X-Ray using the
[PutTraceSegments](https://docs.aws.amazon.com/xray/latest/api/API_PutTraceSegments.html) API.

## Data Conversion

Trace IDs and Span IDs are expected to be originally generated by either AWS API Gateway or AWS ALB and
propagated by them using the `X-Amzn-Trace-Id` HTTP header. However, other generation sources are
supported by replacing fully-random Trace IDs with X-Ray formatted Trace IDs where necessary:

> AWS X-Ray IDs are the same size as W3C Trace Context IDs but differ in that the first 32 bits of a Trace ID
> is the Unix epoch time when the trace was started. Note that X-Ray only allows submission of Trace IDs from
> the past 30 days, otherwise the trace is dropped by X-Ray. The Exporter will not validate this timestamp.

This means that until X-Ray supports Trace Ids consisting of fully random bits, in order for spans to appear in X-Ray, the client SDK MUST use an X-Ray ID generator. For more
information, see
[configuring the X-Ray exporter](https://aws-otel.github.io/docs/getting-started/x-ray#configuring-the-aws-x-ray-exporter).

The `http` object is populated when the `component` attribute value is `grpc` as well as `http`. Other
synchronous call types should also result in the `http` object being populated.

## AWS Specific Attributes

The following AWS-specific Span attributes are supported in addition to the standard names and values
defined in the OpenTelemetry Semantic Conventions.

| Attribute name   | Notes and examples                                                     | Required? |
| :--------------- | :--------------------------------------------------------------------- | --------- |
| `aws.operation`  | The name of the API action invoked against an AWS service or resource. | No        |
| `aws.account_id` | The AWS account number if accessing resource in different account.     | No        |
| `aws.region`     | The AWS region if accessing resource in different region from app.     | No        |
| `aws.request_id` | AWS-generated unique identifier for the request.                       | No        |
| `aws.queue_url`  | For operations on an Amazon SQS queue, the queue's URL.                | No        |
| `aws.table_name` | For operations on a DynamoDB table, the name of the table.             | No        |

Any of these values supplied are used to populate the `aws` object in addition to any relevant data supplied
by the Span Resource object. X-Ray uses this data to generate inferred segments for the remote APIs.

## Exporter Configuration

The following exporter configuration parameters are supported. They mirror and have the same effect as the
comparable AWS X-Ray Daemon configuration values.

| Name                         | Description                                                                                                        | Default |
|:-----------------------------|:-------------------------------------------------------------------------------------------------------------------| ------- |
| `num_workers`                | Maximum number of concurrent calls to AWS X-Ray to upload documents.                                               | 8       |
| `endpoint`                   | Optionally override the default X-Ray service endpoint.                                                            |         |
| `request_timeout_seconds`    | Number of seconds before timing out a request.                                                                     | 30      |
| `max_retries`                | Maximun number of attempts to post a batch before failing.                                                         | 2       |
| `no_verify_ssl`              | Enable or disable TLS certificate verification.                                                                    | false   |
| `proxy_address`              | Upload segments to AWS X-Ray through a proxy.                                                                      |         |
| `region`                     | Send segments to AWS X-Ray service in a specific region.                                                           |         |
| `local_mode`                 | Local mode to skip EC2 instance metadata check.                                                                    | false   |
| `resource_arn`               | Amazon Resource Name (ARN) of the AWS resource running the collector.                                              |         |
| `role_arn`                   | IAM role to upload segments to a different account.                                                                |         |
| `indexed_attributes`         | List of attribute names to be converted to X-Ray annotations.                                                      |         |
| `index_all_attributes`       | Enable or disable conversion of all OpenTelemetry attributes to X-Ray annotations.                                 | false   |
| `aws_log_groups`             | List of log group names for CloudWatch.                                                                            | []      |
| `telemetry.enabled`          | Whether telemetry collection is enabled at all.                                                                    | false   |
| `telemetry.include_metadata` | Whether to include metadata in the telemetry (InstanceID, Hostname, ResourceARN)                                   | false   |
| `telemetry.contributors`     | List of X-Ray component IDs contributing to the telemetry (ex. for multiple X-Ray receivers: awsxray/1, awsxray/2) |         |
| `telemetry.hostname`         | Sets the Hostname included in the telemetry.                                                                       |         |
| `telemetry.instance_id`      | Sets the InstanceID included in the telemetry.                                                                     |         |
| `telemetry.resource_arn`     | Sets the Amazon Resource Name (ARN) included in the telemetry.                                                     |         |

## Traces and logs correlation

AWS X-Ray can be integrated with CloudWatch Logs to correlate traces with logs. For this integration to work, the X-Ray
segments must have the AWS Property `cloudwatch_logs` set. This property is set using the AWS X-Ray exporter with the
following values that are evaluated in this order:

1. `aws.log.group.arns` resource attribute.
2. `aws.log.group.names` resource attribute.
3. `aws_log_groups` configuration property.

In the case of multiple values are defined, the value with higher precedence will be used to set the `cloudwatch_logs` AWS Property.

`aws.log.group.arns` and `aws.log.group.names` are slice resource attributes that can be set programmatically.
Alternatively those resource attributes can be set using the [`OTEL_RESOURCE_ATTRIBUTES` environment variable](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/resource/sdk.md#specifying-resource-information-via-an-environment-variable). In this case only a single log group/log group arn can
be provided as a string rather than a slice.

## AWS Credential Configuration

This exporter follows default credential resolution for the
[aws-sdk-go](https://docs.aws.amazon.com/sdk-for-go/api/index.html).

Follow the [guidelines](https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html) for the
credential configuration.

[beta]:https://github.com/open-telemetry/opentelemetry-collector#beta
[contrib]:https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib
[AWS]:https://aws-otel.github.io/docs/getting-started/x-ray#configuring-the-aws-x-ray-exporter