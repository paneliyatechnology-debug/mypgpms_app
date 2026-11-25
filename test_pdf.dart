import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  final bytes = File('/tmp/receipt_test.pdf').readAsBytesSync();
  try {
    final doc = PdfLoadedDocument(bytes);
    print('Document pages: ${doc.pages.count}');
  } catch (e, st) {
    print('Error loading pdf: $e');
    print(st);
  }
}
