import 'package:flutter/material.dart';

class MockPaymentWidget extends StatefulWidget {
  final double amount;
  final Function(String transactionId) onPaymentSuccess;
  final Function(String errorMessage) onPaymentFailure;
  final bool isProcessing;

  const MockPaymentWidget({
    Key? key,
    required this.amount,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  _MockPaymentWidgetState createState() => _MockPaymentWidgetState();
}

class _MockPaymentWidgetState extends State<MockPaymentWidget> {
  final TextEditingController _cardController = TextEditingController();
  final String _selectedPaymentMethod = 'card'; // Only card payment

  @override
  void initState() {
    super.initState();
    _cardController.text = '';
  }

  void _processMockPayment() async {
    String cardNumber = _cardController.text.replaceAll(' ', '');

    // Validate card number
    if (cardNumber.isEmpty) {
      widget.onPaymentFailure('Please enter your card number.');
      return;
    }

    if (cardNumber.length < 16) {
      widget.onPaymentFailure('Invalid card number. Please check and try again.');
      return;
    }

    // Process card payment
    widget.onPaymentSuccess('pi_${DateTime.now().millisecondsSinceEpoch}');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text('LKR ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Card Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextFormField(
                controller: _cardController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'Enter your 16-digit card number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'Name on card',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.name,
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.isProcessing ? null : _processMockPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: widget.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.lock),
                label: Text(
                  widget.isProcessing ? 'Processing Payment...' : 'Pay Now',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Secure payment powered by SSL encryption',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}