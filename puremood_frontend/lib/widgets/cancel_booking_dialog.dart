import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/refund_service.dart';
import '../services/notification_service.dart';

/// Dialog to cancel a booking with refund policy details
class CancelBookingDialog extends StatefulWidget {
  final int bookingId;
  final DateTime bookingDate;
  final double price;
  final String cancelledBy; // 'patient' or 'specialist'
  final VoidCallback onCancelled;

  const CancelBookingDialog({
    Key? key,
    required this.bookingId,
    required this.bookingDate,
    required this.price,
    required this.cancelledBy,
    required this.onCancelled,
  }) : super(key: key);

  @override
  _CancelBookingDialogState createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<CancelBookingDialog> {
  final RefundService _refundService = RefundService();
  final TextEditingController _reasonController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _refundInfo;

  String _getRefundMessage(int refundPercentage) {
    if (widget.cancelledBy == 'specialist') {
      return 'Full refund (100%) - Cancelled by specialist';
    }

    if (refundPercentage >= 100) {
      return 'Full refund (100%) - Cancellation before 24 hours';
    }
    if (refundPercentage >= 50) {
      return 'Partial refund (50%) - Cancellation within 24 hours';
    }
    return 'No refund - Booking time has passed';
  }

  @override
  void initState() {
    super.initState();
    _calculateRefund();
  }

  void _calculateRefund() {
    setState(() {
      _refundInfo = _refundService.calculateRefundPercentage(
        bookingDate: widget.bookingDate,
        cancelledBy: widget.cancelledBy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_refundInfo == null) {
      return Center(child: CircularProgressIndicator());
    }

    final refundPercentage = _refundInfo!['percentage'];
    final refundAmount = _refundService.calculateRefundAmount(
      originalAmount: widget.price,
      refundPercentage: refundPercentage,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 32,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Confirm Cancellation',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Refund info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: refundPercentage >= 100
                    ? Colors.green.shade50
                    : refundPercentage >= 50
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: refundPercentage >= 100
                      ? Colors.green
                      : refundPercentage >= 50
                          ? Colors.orange
                          : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        refundPercentage >= 100
                            ? Icons.check_circle
                            : refundPercentage >= 50
                                ? Icons.warning
                                : Icons.cancel,
                        color: refundPercentage >= 100
                            ? Colors.green
                            : refundPercentage >= 50
                                ? Colors.orange
                                : Colors.red,
                        size: 48,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Refund Percentage',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '$refundPercentage%',
                              style: GoogleFonts.cairo(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: refundPercentage >= 100
                                    ? Colors.green
                                    : refundPercentage >= 50
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    _getRefundMessage(refundPercentage),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Amount details
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildAmountRow('Original Amount', '\$${widget.price.toStringAsFixed(2)}', false),
                  if (refundAmount > 0) ...[
                    SizedBox(height: 8),
                    Divider(),
                    SizedBox(height: 8),
                    _buildAmountRow('Refund Amount', '\$${refundAmount.toStringAsFixed(2)}', true),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Cancellation reason
            Text(
              'Cancellation Reason (optional)',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type the reason...',
                hintStyle: GoogleFonts.cairo(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: GoogleFonts.cairo(),
            ),
            
            SizedBox(height: 16),
            
            // Cancellation policy
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cancellation Policy',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildPolicyPoint('Cancellation before 24 hours: 100% refund'),
                  _buildPolicyPoint('Cancellation after 24 hours: 50% refund'),
                  _buildPolicyPoint('No-show: No refund'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Back',
            style: GoogleFonts.cairo(),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _cancelBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Confirm Cancellation',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, String amount, bool isRefund) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isRefund ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue[700])),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking() async {
    setState(() => _isLoading = true);

    try {
      final result = await _refundService.cancelBooking(
        bookingId: widget.bookingId,
        cancelledBy: widget.cancelledBy,
        reason: _reasonController.text.trim(),
      );

      if (result['success']) {
        try {
          await cancelSessionReminders(bookingId: widget.bookingId);
        } catch (e) {
          print('Failed to cancel session reminders: $e');
        }

        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${result['message']}\nRefund Amount: \$${result['refund_amount']}",
                    style: GoogleFonts.cairo(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        
        widget.onCancelled();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cancellation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}

/// Helper function to show the dialog
Future<void> showCancelBookingDialog(
  BuildContext context, {
  required int bookingId,
  required DateTime bookingDate,
  required double price,
  required String cancelledBy,
  required VoidCallback onCancelled,
}) {
  return showDialog(
    context: context,
    builder: (context) => CancelBookingDialog(
      bookingId: bookingId,
      bookingDate: bookingDate,
      price: price,
      cancelledBy: cancelledBy,
      onCancelled: onCancelled,
    ),
  );
}
