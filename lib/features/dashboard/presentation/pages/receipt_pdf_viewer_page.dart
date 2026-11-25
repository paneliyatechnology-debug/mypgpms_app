import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/payments_remote_data_source.dart';
import '../../data/models/payment_item_model.dart';

class ReceiptPdfViewerPage extends StatefulWidget {
  final dynamic arguments;

  const ReceiptPdfViewerPage({super.key, this.arguments});

  @override
  State<ReceiptPdfViewerPage> createState() => _ReceiptPdfViewerPageState();
}

class _ReceiptPdfViewerPageState extends State<ReceiptPdfViewerPage> {
  PaymentReceiptDataModel? _receiptData;
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _isDownloading = false;
  double? _downloadProgress;
  String? _errorMessage;
  String? _downloadedFilePath;
  dynamic _paymentId;

  @override
  void initState() {
    super.initState();
    _parseArguments();
  }

  void _parseArguments() {
    final args = widget.arguments;
    if (args is PaymentReceiptDataModel) {
      _receiptData = args;
      _paymentId = args.paymentId;
      _loadPdf(args.fileUrl);
    } else if (args is Map) {
      _paymentId = args['paymentId'] ?? args['id'];
      final fileUrl = args['file_url'] ?? args['fileUrl'];
      if (fileUrl != null && fileUrl.toString().isNotEmpty) {
        _receiptData = PaymentReceiptDataModel(
          fileUrl: fileUrl.toString(),
          receiptNo: args['receipt_no']?.toString() ?? args['receiptNo']?.toString(),
          paymentId: _paymentId is int ? _paymentId : int.tryParse(_paymentId?.toString() ?? ''),
          residentName: args['resident_name']?.toString() ?? args['residentName']?.toString(),
          amount: args['amount'] is num ? args['amount'] : null,
          status: args['status']?.toString(),
        );
        _loadPdf(fileUrl.toString());
      } else if (_paymentId != null) {
        _fetchReceipt();
      }
    } else if (args is int || args is String) {
      _paymentId = args;
      _fetchReceipt();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No payment receipt information provided';
      });
    }
  }

  Future<void> _fetchReceipt() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final response = await dataSource.getPaymentReceipt(_paymentId);

      if (mounted) {
        if (response.data != null && response.data!.fileUrl.isNotEmpty) {
          setState(() {
            _receiptData = response.data;
          });
          await _loadPdf(response.data!.fileUrl);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response.message ?? 'Payment receipt is not available yet.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
        });
      }
    }
  }

  Future<void> _loadPdf(String fileUrl) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        fileUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted && response.data != null) {
        setState(() {
          _pdfBytes = Uint8List.fromList(response.data!);
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to stream PDF: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _downloadReceipt() async {
    final fileUrl = _receiptData?.fileUrl;
    if (_pdfBytes == null && fileUrl != null && fileUrl.isNotEmpty) {
      await _loadPdf(fileUrl);
    }

    if (_pdfBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading receipt data, please try again in a moment.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getDownloadsDirectory() ?? await getExternalStorageDirectory();
      }
      directory ??= await getApplicationDocumentsDirectory();

      final rawName = _receiptData?.filename ?? _receiptData?.fileUrl.split('/').last ?? 'receipt.pdf';
      final fileName = rawName.contains('.pdf') ? rawName : '$rawName.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(_pdfBytes!);

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadedFilePath = file.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F4734),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.0),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'Saved to Downloads: $fileName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.0),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            content: Text(
              'Failed to save receipt: ${e.toString()}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.0),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptNo = _receiptData?.receiptNo ?? 'Receipt';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Receipt',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (_receiptData?.receiptNo != null && _receiptData!.receiptNo!.isNotEmpty)
              Text(
                receiptNo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        actions: [
          if (_receiptData != null) ...[
            if (_isDownloading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0),
                  child: SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.0),
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Download Receipt',
                icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 24.0),
                onPressed: _downloadReceipt,
              ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _receiptData != null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0)),
                  boxShadow: [
                    BoxShadow(color: Color(0x06000000), blurRadius: 8.0, offset: Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _isDownloading ? null : _downloadReceipt,
                        borderRadius: BorderRadius.circular(999.0),
                        child: Container(
                          height: 48.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F4734),
                            borderRadius: BorderRadius.circular(999.0),
                          ),
                          child: _isDownloading
                              ? const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.download_rounded, color: Colors.white, size: 20.0),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      _downloadedFilePath != null ? 'Download Again (PDF)' : 'Download Receipt PDF',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      final progress = _downloadProgress;
      final percentText = progress != null ? '${(progress * 100).toInt()}%' : '';

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.8),
              const SizedBox(height: 16.0),
              Text(
                'Loading PDF file $percentText...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 12.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5.0,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 54.0, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 14.0),
              Text(
                'Failed to Load PDF',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                onPressed: () {
                  if (_receiptData?.fileUrl != null && _receiptData!.fileUrl.isNotEmpty) {
                    _loadPdf(_receiptData!.fileUrl);
                  } else {
                    _fetchReceipt();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 10.0),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18.0),
                label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes != null) {
      return SfPdfViewer.memory(
        _pdfBytes!,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoadFailed: (details) {
          if (mounted) {
            setState(() {
              _errorMessage = details.description;
            });
          }
        },
      );
    }

    if (_receiptData?.fileUrl != null && _receiptData!.fileUrl.isNotEmpty) {
      return SfPdfViewer.network(
        _receiptData!.fileUrl,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoadFailed: (details) {
          if (mounted) {
            setState(() {
              _errorMessage = details.description;
            });
          }
        },
      );
    }

    return const SizedBox.shrink();
  }
}
