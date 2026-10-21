// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_aws_textract/otel_aws_textract.dart';

/// Traces Aws Textract calls with OpenTelemetry.
///
/// `otel_aws_textract` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Aws Textract call in
/// [tracedAwsTextract]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'aws-textract-example');

  // Wraps an AWS Textract operation in a CLIENT span.
  final awsTextractId = await tracedAwsTextract<String>(
    operation: 'create',
    featureTypes: ['standard'],
    region: 'us-east-1',
    invoke: () async {
      // Make the Aws Textract call here, then report what it returned.
      const id = 'aws_textract_8f3a2c';
      return const AwsTextractCallResult(
          value: id,
          result: AwsTextractResult(
              pageCount: 3,
              blockCount: 3,
              wordCount: 3,
              tableCount: 3,
              formFieldCount: 3,
              queryCount: 3,
              jobId: 'job_8f3a2c',
              jobStatus: 'IN_PROGRESS'));
    },
  );
  OTelLog.info('tracedAwsTextract create returned $awsTextractId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutAwsTextractInstrumentationAsync.
  await runWithoutAwsTextractInstrumentationAsync(
    () => tracedAwsTextract<String>(
      operation: 'create',
      featureTypes: ['standard'],
      region: 'us-east-1',
      invoke: () async {
        const id = 'aws_textract_8f3a2c';
        return const AwsTextractCallResult(
            value: id,
            result: AwsTextractResult(
                pageCount: 3,
                blockCount: 3,
                wordCount: 3,
                tableCount: 3,
                formFieldCount: 3,
                queryCount: 3,
                jobId: 'job_8f3a2c',
                jobStatus: 'IN_PROGRESS'));
      },
    ),
  );

  await OTel.shutdown();
}
