import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io';

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
        useMaterial3: true,
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
            const Text('Press the + button to scan a QR code!'),
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
  String _displayMessage = 'Initializing camera...';
  bool _cameraReady = false;
  bool _isProcessing = false; // Added for preventing multiple scans

  @override
  void reassemble() {
    super.reassemble();
    // This `Platform.isAndroid` check is typically not needed for web,
    // but useful if you were targeting Android. Keeping it as a comment.
    // if (Platform.isAndroid) {
    //   controller?.pauseCamera();
    // }
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
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios), // Corrected icon name
            onPressed: () async {
              await controller?.flipCamera();
              setState(() {
                _displayMessage = 'Camera flipped';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              await controller?.toggleFlash();
              setState(() {
                _displayMessage = 'Flash toggled';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.green,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),
                if (!_cameraReady)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _displayMessage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await controller?.toggleFlash();
                          setState(() {
                            _displayMessage = 'Flash toggled';
                          });
                        },
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Flash'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await controller?.flipCamera();
                          setState(() {
                            _displayMessage = 'Camera flipped';
                          });
                        },
                        icon: const Icon(Icons.flip_camera_ios),
                        label: const Text('Flip'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
      _displayMessage = 'Camera ready! Point at QR code';
      _cameraReady = true;
    });

    controller.scannedDataStream.listen(
      (scanData) {
        if (scanData.code == null || scanData.code!.isEmpty) {
          setState(() {
            _displayMessage = 'Received empty scan data';
          });
          return;
        }

        if (_isProcessing) return; // Prevent processing multiple scans at once

        _isProcessing = true;

        // Pause camera briefly
        controller.pauseCamera();

        String code = scanData.code!;

        if (code.startsWith('upi://pay')) {
          try {
            final uri = Uri.parse(code);
            final params = uri.queryParameters;

            String details = '✅ UPI QR CODE DETECTED!\n\n';
            if (params['pa'] != null) details += 'UPI ID: ${params['pa']}\n';
            if (params['pn'] != null) details += 'Name: ${params['pn']}\n';
            if (params['am'] != null) details += 'Amount: ₹${params['am']}\n';
            if (params['tn'] != null) details += 'Note: ${params['tn']}\n';
            
            setState(() {
              _displayMessage = details;
            });
          } catch (e) {
            setState(() {
              _displayMessage = 'Error parsing UPI: $e';
            });
          }
        } else {
          setState(() {
            _displayMessage = '❌ Not a UPI Code\n\nScanned: ${code.substring(0, code.length > 50 ? 50 : code.length)}...';
          });
        }

        // Resume after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && controller != null) {
            controller!.resumeCamera();
            setState(() {
              _displayMessage = 'Ready to scan again!';
            });
          }
          _isProcessing = false;
        });
      },
      onError: (error) {
        setState(() {
          _displayMessage = 'Scanner error: $error';
        });
      },
      onDone: () {
        // Stream closed, possibly unmount QRView
      },
    );
  }
}