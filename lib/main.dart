import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;

  /*
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  */

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
          children: <Widget>[
            /*
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            */
          ],
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
  Barcode? result;
  String _displayMessage = 'Scan a UPI QR code'; // Initial message
  bool _isProcessing = false; // Add this flag

  @override
  void reassemble() {
    super.reassemble();
    // Handle hot reload
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () {
              controller?.flipCamera();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              controller?.toggleFlash();
            },
          ),
        ],
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(
                    _displayMessage,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
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

    controller.scannedDataStream.listen((scanData) {
      // Prevent processing multiple scans at once
      if (_isProcessing) return;

      // Check if code is not null and not empty
      if (scanData.code == null || scanData.code!.isEmpty) {
        return;
      }

      _isProcessing = true;

      // Pause camera to prevent continuous scanning
      controller.pauseCamera();

      String code = scanData.code!;

      if (code.startsWith('upi://pay')) {
        try {
          final uri = Uri.parse(code);
          final Map<String, String> params = uri.queryParameters;

          String details = '''UPI Details:

''';
          if (params.containsKey('pa')) details += '''UPI ID: ${params['pa']}
''';
          if (params.containsKey('pn')) details += '''Name: ${params['pn']}
''';
          if (params.containsKey('am')) details += '''Amount: ₹${params['am']}
''';
          if (params.containsKey('tn')) details += '''Note: ${params['tn']}
''';
          if (params.containsKey('mc')) details += '''Merchant Code: ${params['mc']}
''';
          if (params.containsKey('tr')) details += '''Transaction Ref: ${params['tr']}
''';

          setState(() {
            result = scanData;
            _displayMessage = details;
          });
        } catch (e) {
          setState(() {
            _displayMessage = 'Error parsing UPI: $e';
          });
        }
      } else {
        setState(() {
          result = scanData;
          _displayMessage = '''Not a UPI QR Code

Scanned: $code''';
        });
      }

      // Resume camera after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          controller.resumeCamera();
          _isProcessing = false;
        }
      });
    });
  }
}