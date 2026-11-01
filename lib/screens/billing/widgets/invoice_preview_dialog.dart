import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../models/invoice.dart';
import '../../../services/invoice_print_format.dart';
import '../../../theme/app_theme.dart';
import '../models/bill_state.dart';

/// Shows the receipt exactly as it will be printed, without saving anything.
class InvoicePreviewDialog extends StatelessWidget {
  final Invoice invoice;
  final List<BillLineItem> lineItems;
  final String? customerName;
  final String? customerMobile;

  const InvoicePreviewDialog({
    super.key,
    required this.invoice,
    required this.lineItems,
    this.customerName,
    this.customerMobile,
  });

  static Future<void> show(
    BuildContext context, {
    required Invoice invoice,
    required List<BillLineItem> lineItems,
    String? customerName,
    String? customerMobile,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => InvoicePreviewDialog(
        invoice: invoice,
        lineItems: lineItems,
        customerName: customerName,
        customerMobile: customerMobile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Invoice Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (_) => InvoicePrintFormat.generateReceipt(
                  invoice: invoice,
                  lineItems: lineItems,
                  customerName: customerName,
                  customerMobile: customerMobile,
                ),
                useActions: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                allowPrinting: false,
                allowSharing: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
