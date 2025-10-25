import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scout_ops_scan/components/display_number.dart';
import 'package:scout_ops_scan/services/database.dart' as db;
import 'components/header.dart';
import 'components/battery_indicator.dart';
import 'components/serial_display.dart';
import 'components/control_button.dart';
import 'components/qr_code_overlay.dart';
import 'services/scout_ops_service.dart';
import 'models/scout_ops_data.dart';
import 'qr_codes_screen.dart';

class ScoutOpsScanner extends StatefulWidget {
  const ScoutOpsScanner({super.key});

  @override
  State<ScoutOpsScanner> createState() => _ScoutOpsScannerState();
}

class _ScoutOpsScannerState extends State<ScoutOpsScanner> {
  Barcode? _barcode;
  MobileScannerController controller = MobileScannerController(
    // Optimize camera settings to prevent buffer overflow
    cameraResolution: const Size(
      640,
      480,
    ), // Lower resolution for better performance
    detectionSpeed: DetectionSpeed.normal, // Balanced detection speed
    detectionTimeoutMs:
        250, // Prevent too frequent detections (4 per second max)
    returnImage: false, // Don't return images to reduce memory usage
  );
  final ScoutOpsService _service = ScoutOpsService();
  final db.DataManager _dbManager = db.DataManager();
  Socket? socket;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      final scannedData = barcodes.barcodes.first.rawValue;

      // Remove surrounding quotes if present
      final String cleanData = scannedData!.replaceAll(RegExp(r'^"|"$'), '');
      print('$cleanData');
      _saveQRData(cleanData);
    } else {
      print('Widget not mounted, cannot handle barcode.');
    }
  }

  void _saveQRData(String qrCodeData) {
    try {
      final qr = db.QrData();
      qr.setCsvData(qrCodeData);

      // Extract name from CSV (typically first field)
      final parts = qrCodeData.split(",");
      if (parts.isNotEmpty) {
        qr.setName(parts[0]);
      }

      print(
        'Attempting to save: Alliance=${qr.getAlliance}, Match=${qr.getMatch}, Station=${qr.getStation}',
      );
      final success = _dbManager.insert(qr);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Saved: ${qr.toDisplayString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        print('✓ QR Data saved: ${qr.toDisplayString()}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Failed to save data'),
            backgroundColor: Colors.red,
          ),
        );
        print('✗ Failed to save QR data');
      }
    } catch (e) {
      print('Error saving QR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✗ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSavedMatches() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final allData = _dbManager.getAll();

          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Matches (${allData.length})',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                if (allData.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    onPressed: () =>
                        _showDeleteAllConfirmation(context, setState),
                    tooltip: 'Delete All',
                  ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: allData.isEmpty
                  ? const Center(
                      child: Text(
                        'No saved data',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: allData.length,
                      itemBuilder: (context, index) {
                        final record = allData[index];
                        final key =
                            '${record.getAlliance}_${record.getMatch}_${record.getStation}';

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: record.getAlliance == 'Blue'
                                ? Colors.blue[900]
                                : Colors.red[900],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: record.getAlliance == 'Blue'
                                  ? Colors.blue
                                  : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Quals ${record.getMatch}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Station ${record.getStation}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _showDeleteConfirmation(
                                              context,
                                              key,
                                              record,
                                              setState,
                                            ),
                                        tooltip: 'Delete this record',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      record.getName,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.battery_full,
                                    color: Colors.green[300],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${record.getBatteryLevel}%',
                                    style: TextStyle(
                                      color: Colors.green[300],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scanned: ${record.getTimestamp.toString().split('.')[0]}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.cyan),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final csv = _dbManager.exportCsv();
                  print('Exported data:\n$csv');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Data exported to logs'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                child: const Text('Export'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String key,
    db.QrData record,
    StateSetter setState,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Record',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this record?\n\nQuals ${record.getMatch} - Station ${record.getStation} - ${record.getAlliance} Alliance',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _dbManager.delete(key);
              setState(() {}); // Refresh the list
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Record deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation(BuildContext context, StateSetter setState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete All Records',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete ALL saved records?\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _dbManager.clear();
              setState(() {}); // Refresh the list
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ All records deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _transmitData() {
    final stats = _dbManager.getStats();
    final blueCount = stats['blue'] ?? 0;
    final redCount = stats['red'] ?? 0;
    final totalCount = stats['total'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Transmit Data',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Records: $totalCount',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Blue Alliance: $blueCount records',
                style: const TextStyle(color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'Red Alliance: $redCount records',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ready to send to server',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Data transmission initiated...'),
                  backgroundColor: Colors.green,
                ),
              );
              print(
                'Would send $totalCount records ($blueCount blue + $redCount red)',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Send'),
          ),
        ],
      ),
    );
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
              MobileScanner(
                controller: controller,
                onDetect: _handleBarcode,
                fit: BoxFit.cover,
                errorBuilder: (context, error) {
                  // Handle camera errors gracefully
                  debugPrint('Camera error: $error');
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Camera Error',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please check camera permissions',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              QRCodeOverlay(
                barcode: _barcode,
                onTap: () {
                  // Handle QR code tap
                  print('QR Code tapped: ${_barcode?.rawValue}');
                },
              ),
              // Header overlay at the top
              Positioned(top: 0, left: 0, right: 0, child: const ScoutHeader()),

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
                          DisplayNumber(
                            value: "69", //omg!!!!!!!!!!
                            label: '  MATCH NUMBER ',
                            color: Colors.cyan,
                          ),
                          const SizedBox(height: 8),
                          BatteryIndicator(
                            percentage: 69,
                            label: 'TARGET BATTERY',
                          ),
                          const SizedBox(height: 8),
                          SerialDisplay(serialNumber: data.serialNumber),
                        ],
                      ),

                      // Right side - Control buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 30),
                          ControlButton(
                            text: 'SEND',
                            backgroundColor: Colors.red,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QrCodesScreen(),
                              ),
                            ),
                            width: 100,
                          ),
                          const SizedBox(height: 8),
                          ControlButton(
                            width: 100,
                            text: 'TRANSMIT',
                            backgroundColor: Colors.green,
                            onPressed: _transmitData,
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
