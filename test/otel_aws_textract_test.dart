// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_aws_textract/otel_aws_textract.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_aws_textract-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('AnalyzeDocument with TABLES + FORMS', () async {
    await tracedAwsTextract<String>(
      operation: 'AnalyzeDocument',
      featureTypes: const ['TABLES', 'FORMS'],
      invoke: () async => const AwsTextractCallResult(
        value: 'ok',
        result: AwsTextractResult(
          pageCount: 4,
          blockCount: 312,
          wordCount: 850,
          tableCount: 3,
          formFieldCount: 22,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('textract AnalyzeDocument')!);
    expect(a['rpc.service'], 'Textract');
    expect(a['aws.textract.feature_types'], 'TABLES,FORMS');
    expect(a['aws.textract.page_count'], 4);
    expect(a['aws.textract.table_count'], 3);
    expect(a['aws.textract.form_field_count'], 22);
  });

  test('PARTIAL_SUCCESS maps to span error', () async {
    await tracedAwsTextract<String>(
      operation: 'GetDocumentAnalysis',
      invoke: () async => const AwsTextractCallResult(
        value: 'ok',
        result: AwsTextractResult(
          jobId: 'j-1',
          jobStatus: 'PARTIAL_SUCCESS',
        ),
      ),
    );
    expect(
      spans.findSpanByName('textract GetDocumentAnalysis')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutAwsTextractInstrumentationAsync(() async {
      await tracedAwsTextract<String>(
        operation: 'DetectDocumentText',
        invoke: () async => const AwsTextractCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('textract '), isEmpty);
  });
}
