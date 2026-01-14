import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:puremood_frontend/utils/stripe_web_helper.dart';
import 'package:puremood_frontend/widgets/stripe_card_element.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;
  final double amount;
  final String specialistName;
  final String sessionType;
  final String bookingDate;

  const PaymentScreen({
    Key? key,
    required this.bookingId,
    required this.amount,
    required this.specialistName,
    required this.sessionType,
    required this.bookingDate,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  String? _errorMessage;
  CardFieldInputDetails? _cardDetails;
  bool _webStripeReady = false;
  String? _webStripeError;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebStripe();
    }
  }

  Future<void> _initWebStripe() async {
    try {
      setState(() {
        _webStripeReady = false;
        _webStripeError = null;
      });
      await StripeWebHelper.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _webStripeReady = true;
        _webStripeError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      final message = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _webStripeReady = false;
        _webStripeError = 'Payment form failed to load: $message';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: Colors.grey[50],
      webMaxWidth: 960,
      appBar: AppBar(
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF008080),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingSummary(),
            SizedBox(height: 24),
            _buildPaymentMethod(),
            SizedBox(height: 24),
            _buildPriceBreakdown(),
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              _buildErrorMessage(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildPaymentButton(),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF008080), size: 24),
              SizedBox(width: 12),
              Text(
                'Booking Summary',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Divider(height: 24),
          _buildSummaryRow('Specialist', widget.specialistName, Icons.person),
          SizedBox(height: 12),
          _buildSummaryRow('Date', widget.bookingDate, Icons.calendar_today),
          SizedBox(height: 12),
          _buildSummaryRow('Session Type', widget.sessionType, Icons.videocam),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    if (kIsWeb) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Color(0xFF008080), size: 24),
                SizedBox(width: 12),
                Text(
                  'Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Card Details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: StripeCardElement(
                enabled: _webStripeReady,
                height: 64,
              ),
            ),
            if (!_webStripeReady && _webStripeError == null) ...[
              SizedBox(height: 8),
              Text(
                'Loading secure card form...',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (_webStripeError != null) ...[
              SizedBox(height: 12),
              _buildInlineWarning(_webStripeError!),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _initWebStripe,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(
                    'Retry loading payment form',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Color(0xFF008080), size: 24),
              SizedBox(width: 12),
              Text(
                'Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF008080), Color(0xFF006666)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(Icons.credit_card, color: Colors.white, size: 32),
                ),
                SizedBox(height: 12),
                Text(
                  'Stripe Secure Payment',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fast, secure, and reliable',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.check_circle, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Card Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: CardFormField(
              onCardChanged: (card) {
                setState(() {
                  _cardDetails = card;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final serviceFee = widget.amount * 0.05; // 5% service fee
    final total = widget.amount + serviceFee;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Color(0xFF008080), size: 24),
              SizedBox(width: 12),
              Text(
                'Price Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Divider(height: 24),
          _buildPriceRow('Session Price', '\$${widget.amount.toStringAsFixed(2)}'),
          SizedBox(height: 12),
          _buildPriceRow('Service Fee (5%)', '\$${serviceFee.toStringAsFixed(2)}'),
          Divider(height: 24),
          _buildPriceRow(
            'Total Amount',
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Color(0xFF008080) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    final isWebDisabled = kIsWeb && !_webStripeReady;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: (_isProcessing || isWebDisabled) ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF008080),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pay Now',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (kIsWeb) {
      await _processWebPayment();
    } else {
      await _processMobilePayment();
    }
  }

  Future<void> _processWebPayment() async {
    if (!_webStripeReady) {
      setState(() {
        _errorMessage = 'Payment form is still loading. Please wait a moment.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final paymentData = await _paymentService.createPaymentIntent(widget.bookingId);
      final clientSecret = paymentData['clientSecret'];
      final paymentIntentId = clientSecret.split('_secret_')[0];

      final errorMessage = await StripeWebHelper.confirmPayment(clientSecret);
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }

      await _paymentService.confirmPaymentSuccess(
        bookingId: widget.bookingId,
        paymentIntentId: paymentIntentId,
      );

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processMobilePayment() async {
    if (_cardDetails == null || !_cardDetails!.complete) {
      setState(() {
        _errorMessage = 'Please enter complete card details.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('Creating payment intent for booking ${widget.bookingId}...');
      final paymentData = await _paymentService.createPaymentIntent(widget.bookingId);

      final clientSecret = paymentData['clientSecret'];
      final paymentIntentId = clientSecret.split('_secret_')[0];

      print('Payment intent created: $paymentIntentId');

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: const PaymentMethodData(),
        ),
      );

      print('Payment confirmed via custom UI');

      await _paymentService.confirmPaymentSuccess(
        bookingId: widget.bookingId,
        paymentIntentId: paymentIntentId,
      );

      _showSuccessDialog();
    } catch (e) {
      print('Payment error: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildInlineWarning(String message) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text(
              'Payment Successful!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Your booking has been confirmed. You will receive a confirmation email shortly.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to previous screen with success
            },
            child: Text(
              'Done',
              style: GoogleFonts.poppins(
                color: Color(0xFF008080),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

