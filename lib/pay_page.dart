import 'package:flutter/material.dart';

// Class to hold parsed UPI details
class UpiDetails {
  final String payeeAddress;
  final String payeeName;
  final String? amount;
  final String? transactionNote;
  final String? merchantCode;
  final String? transactionRef;

  UpiDetails({
    required this.payeeAddress,
    required this.payeeName,
    this.amount,
    this.transactionNote,
    this.merchantCode,
    this.transactionRef,
  });

  String toDisplayString() {
    String display = 'Payee: $payeeName\nUPI ID: $payeeAddress';
    if (amount != null) display += '\nAmount: Rs.$amount';
    if (transactionNote != null) display += '\nNote: $transactionNote';
    return display;
  }
}

class PayPage extends StatelessWidget {
  final UpiDetails upiDetails;

  const PayPage({super.key, required this.upiDetails});

  @override
  Widget build(BuildContext context) {
    // Placeholder for amount input
    TextEditingController amountController = TextEditingController(text: upiDetails.amount);
    TextEditingController messageController = TextEditingController(text: upiDetails.transactionNote);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Pay', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              // Handle help action
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: Text(
                          'MM', // Placeholder for payee initials
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upiDetails.payeeName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            upiDetails.payeeAddress,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.none, // Custom keypad will handle input
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                      decoration: const InputDecoration(
                        prefixText: 'Rs. ',
                        prefixStyle: TextStyle(color: Colors.white, fontSize: 24),
                        hintText: 'Enter Amount',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 24),
                        border: InputBorder.none,
                      ),
                      readOnly: true, // Prevent native keyboard
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a message (optional)',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Numeric Keypad
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    List<String> keys = [
                      '1', '2', '3',
                      '4', '5', '6',
                      '7', '8', '9',
                      '.', '0', 'DEL',
                    ];
                    String key = keys[index];

                    if (key == 'DEL') {
                      return _buildKey(key, () {
                        if (amountController.text.isNotEmpty) {
                          amountController.text = amountController.text
                              .substring(0, amountController.text.length - 1);
                        }
                      }, icon: Icons.backspace);
                    } else if (key == '.') {
                      return _buildKey(key, () {
                        if (!amountController.text.contains('.')) {
                          amountController.text += key;
                        }
                      });
                    } else {
                      return _buildKey(key, () {
                        amountController.text += key;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Handle Proceed to Pay
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'PROCEED TO PAY',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String text, VoidCallback onPressed, {IconData? icon}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.zero, // Remove default padding
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: 28)
          : Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
    );
  }
}
