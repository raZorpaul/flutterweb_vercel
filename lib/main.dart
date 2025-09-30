import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io';
import 'package:flutterweb_vercel/pay_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page V2 vserion 2'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRViewExample()),
          );
        },
        tooltip: 'Scan QR Code',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String displayText = 'Camera ready! Point at QR code';
  String? upiId;
  bool hasNavigated = false;
  StreamSubscription? scanSubscription;
  UpiDetails? parsedUpiDetails;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: InkWell(
                onTap: parsedUpiDetails == null
                    ? null
                    : () {
                        final currentController = controller;
                        controller = null;
                        scanSubscription?.cancel();
                        scanSubscription = null;
                        currentController?.dispose();

                        if (!mounted) return;
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => PayPage(upiDetails: parsedUpiDetails!),
                          ),
                        );
                      },
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 18,
                    color: parsedUpiDetails != null ? Colors.blue : Colors.black,
                    decoration: parsedUpiDetails != null ? TextDecoration.underline : TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    scanSubscription = controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && scanData.code!.isNotEmpty && !hasNavigated) {
        String code = scanData.code!;

        if (code.startsWith('upi://pay')) {
          try {
            final uri = Uri.parse(code);
            final params = uri.queryParameters;

            if (params['pa'] != null && !hasNavigated) {
              // Set flag immediately to prevent multiple navigations
              hasNavigated = true;

              setState(() {
                upiId = params['pa']!;
                parsedUpiDetails = UpiDetails(
                  payeeAddress: params['pa']!,
                  payeeName: params['pn'] ?? 'Unknown',
                  amount: params['am'],
                  transactionNote: params['tn'],
                  merchantCode: params['mc'],
                  transactionRef: params['tr'],
                );
                displayText = 'Proceed with ${upiId!}';
              });
              // Do not navigate automatically; user will tap the link
            }
          } catch (e) {
            // If parsing fails, just keep scanning
            print('Error parsing QR code: $e');
          }
        } else if (code.contains('@') && !hasNavigated) {
          // Fallback: handle plain UPI IDs encoded as text
          hasNavigated = true;
          setState(() {
            upiId = code;
            parsedUpiDetails = UpiDetails(
              payeeAddress: code,
              payeeName: 'Unknown',
              amount: null,
              transactionNote: null,
              merchantCode: null,
              transactionRef: null,
            );
            displayText = 'Proceed with $code';
          });
          // Do not navigate automatically; user will tap the link
        }
      }
    });
  }
}

class HelloWorldPage extends StatelessWidget {
  final String upiId;
  const HelloWorldPage({super.key, required this.upiId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello World'),
      ),
      body: Center(
        child: Text(
          'Hello World, UPI ID: $upiId',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}