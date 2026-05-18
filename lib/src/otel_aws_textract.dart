// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_aws_textract_suppression.dart';

const _tracerName = 'dartastic_otel_libs_aws_textract';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class AwsTextractResult {
  const AwsTextractResult({
    this.pageCount,
    this.blockCount,
    this.wordCount,
    this.tableCount,
    this.formFieldCount,
    this.queryCount,
    this.jobId,
    this.jobStatus,
  });

  /// Pages processed — Textract bills per page.
  final int? pageCount;
  final int? blockCount;
  final int? wordCount;
  final int? tableCount;
  final int? formFieldCount;
  final int? queryCount;

  /// Async job id for StartDocumentAnalysis / StartDocumentTextDetection.
  final String? jobId;

  /// `IN_PROGRESS`, `SUCCEEDED`, `FAILED`, `PARTIAL_SUCCESS`.
  final String? jobStatus;
}

class AwsTextractCallResult<T> {
  const AwsTextractCallResult({required this.value, this.result});
  final T value;
  final AwsTextractResult? result;
}

/// Wraps an AWS Textract operation in a CLIENT span. [operation] is
/// the API method (`DetectDocumentText`, `AnalyzeDocument`,
/// `AnalyzeExpense`, `AnalyzeID`, `StartDocumentAnalysis`,
/// `GetDocumentAnalysis`, etc.).
///
/// [featureTypes] for AnalyzeDocument: TABLES, FORMS, QUERIES,
/// SIGNATURES, LAYOUT — each unlocks a billing tier.
Future<T> tracedAwsTextract<T>({
  required String operation,
  required Future<AwsTextractCallResult<T>> Function() invoke,
  List<String>? featureTypes,
  String? region,
}) async {
  if (awsTextractInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'aws-api',
    'rpc.service': 'Textract',
    'rpc.method': operation,
  };
  if (featureTypes != null && featureTypes.isNotEmpty) {
    m['aws.textract.feature_types'] = featureTypes.join(',');
  }
  if (region != null) m['cloud.region'] = region;

  final span = _tracer().startSpan(
    'textract $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.pageCount != null) {
        extras.add(OTel.attributeInt(
          'aws.textract.page_count',
          r.result!.pageCount!,
        ));
      }
      if (r.result!.blockCount != null) {
        extras.add(OTel.attributeInt(
          'aws.textract.block_count',
          r.result!.blockCount!,
        ));
      }
      if (r.result!.wordCount != null) {
        extras.add(OTel.attributeInt(
          'aws.textract.word_count',
          r.result!.wordCount!,
        ));
      }
      if (r.result!.tableCount != null) {
        extras.add(OTel.attributeInt(
          'aws.textract.table_count',
          r.result!.tableCount!,
        ));
      }
      if (r.result!.formFieldCount != null) {
        extras.add(OTel.attributeInt(
          'aws.textract.form_field_count',
          r.result!.formFieldCount!,
        ));
      }
      if (r.result!.queryCount != null) {
        extras.add(OTel.attributeInt(
          'aws.textract.query_count',
          r.result!.queryCount!,
        ));
      }
      if (r.result!.jobId != null) {
        extras.add(OTel.attributeString(
          'aws.textract.job.id',
          r.result!.jobId!,
        ));
      }
      if (r.result!.jobStatus != null) {
        extras.add(OTel.attributeString(
          'aws.textract.job.status',
          r.result!.jobStatus!,
        ));
        if (r.result!.jobStatus == 'FAILED') {
          span.setStatus(SpanStatusCode.Error, 'Textract job FAILED');
        } else if (r.result!.jobStatus == 'PARTIAL_SUCCESS') {
          span.setStatus(
            SpanStatusCode.Error,
            'Textract job PARTIAL_SUCCESS',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
