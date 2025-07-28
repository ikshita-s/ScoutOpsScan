import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'components/header.dart';
import 'components/battery_indicator.dart';
import 'components/serial_display.dart';
import 'components/control_button.dart';
import 'components/shutter_button.dart';
import 'components/qr_code_overlay.dart';
import 'services/scout_ops_service.dart';
import 'models/scout_ops_data.dart';

class ScoutOpsScanner extends StatefulWidget {
  const ScoutOpsScanner({super.key});

  @override
  State<ScoutOpsScanner> createState() => _ScoutOpsScannerState();
}

class _ScoutOpsScannerState extends State<ScoutOpsScanner> {
  Barcode? _barcode;
  MobileScannerController controller = MobileScannerController();
  final ScoutOpsService _service = ScoutOpsService();
  int batteryPercentage = 0;
  Socket? socket;

  @override
  void initState() {
    super.initState();
    _service.startBatterySimulation();
  

    // Ensure immersive mode is maintained
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      
      setState(() {
        _barcode = barcodes.barcodes.isNotEmpty
            ? barcodes.barcodes.first
            : null;

        batteryPercentage = _parseBatteryPercentage(_removequote(
          barcodes.barcodes.isNotEmpty
              ? barcodes.barcodes.first.rawValue
              : null,
        ));
      });
      if (_barcode != null) {
        _service.updateLastScan(_barcode!.rawValue ?? 'Unknown');
        sendData (_barcode!.rawValue ?? 'No idea');
      }
    }
  }

  void sendData  (String data) async {
    print(data);
    socket = await Socket.connect("10.182.101.132", 12345).timeout(const Duration(seconds: 10));
    socket!.write(data);

  }

  String _removequote(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return '';
    }
    
    return rawValue.replaceAll('"', '').trim();
  }

  int _parseBatteryPercentage(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return 0;
    }
    final match = rawValue.split(',').first.trim();
    print('Parsed battery percentage: $match');
    return int.tryParse(match) ?? 0;
  }

  void _onReset() {
    setState(() {
      _barcode = null;
    });
    _service.resetData();
  }

  void _onTest() {
    // Handle test functionality
    print('Test button pressed');
  }

  void _onShutter() {
    // Handle shutter/capture functionality
    print('Shutter pressed');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScoutOpsData>(
      stream: _service.dataStream,
      initialData: _service.currentData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _service.currentData;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
            
              // Full-screen camera feed
              MobileScanner(
                controller: controller,
                onDetect: _handleBarcode,
                fit: BoxFit.cover,
              ),

              // QR code overlay
              QRCodeOverlay(
                barcode: _barcode,
                onTap: () {
                  // Handle QR code tap
                  print('QR Code tapped: ${_barcode?.rawValue}');
                },
              ),
              // Header overlay at the top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: const ScoutHeader(),
              ),

              // Bottom control panel overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(1.0),
                        Colors.black.withOpacity(1.0),
                        Colors.black.withOpacity(1.0),
                        Colors.black.withOpacity(0.95),
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.15),
                        Colors.transparent,
                      ],
                      stops: [
                        0.0,
                        0.3,
                        0.4,
                        0.5,
                        0.6,
                        0.7,
                        0.8,
                        0.85,
                        0.9,
                        1.0,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - Battery indicators and serial
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 100),
                          BatteryIndicator(
                            percentage: 76,
                            label: 'MODULE BATTERY',
                          ),
                          const SizedBox(height: 8),
                          BatteryIndicator(
                            percentage: batteryPercentage,
                            label: 'TARGET BATTERY',
                          ),
                          const SizedBox(height: 8),
                          SerialDisplay(
                            serialNumber: data.serialNumber,
                          ),
                        ],
                      ),

                      // Center - Shutter button
                      ShutterButton(onPressed: _onShutter, size: 80),

                      // Right side - Control buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ControlButton(
                            text: 'RESET',
                            backgroundColor: Colors.red,
                            onPressed: _onReset,
                          ),
                          const SizedBox(height: 8),
                          ControlButton(
                            text: 'TEST',
                            backgroundColor: Colors.green,
                            onPressed: _onTest,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
