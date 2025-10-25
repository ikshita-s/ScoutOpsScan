import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scout_ops_scan/components/header.dart';
import 'package:scout_ops_scan/services/database.dart' as db;

class QrCodesScreen extends StatefulWidget {
  const QrCodesScreen({super.key});

  @override
  State<QrCodesScreen> createState() => _QrCodesScreenState();
}

class _QrCodesScreenState extends State<QrCodesScreen> {
  final db.DataManager _dbManager = db.DataManager();

  @override
  Widget build(BuildContext context) {
    final allData = _dbManager.getAll();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Header overlay at the top
          Positioned(top: 0, left: 0, right: 0, child: const ScoutHeader()),

          // Main content
          Positioned.fill(
            top: 80, // Account for header
            child: Column(
              children: [
                // Title and stats
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'QR Code Library',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${allData.length} Records Available',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // QR Codes Grid
                Expanded(
                  child: allData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No QR codes available',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scan some data first!',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: allData.length,
                            itemBuilder: (context, index) {
                              final record = allData[index];
                              return _buildQrCodeCard(record);
                            },
                          ),
                        ),
                ),

                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final csv = _dbManager.exportCsv();
                          print('Exported data:\n$csv');
                          
                          // Copy to clipboard
                          await Clipboard.setData(ClipboardData(text: csv));
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Data exported and copied to clipboard'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard(db.QrData record) {
    return GestureDetector(
      onTap: () => _showFullScreenQrCode(record),
      child: Container(
        decoration: BoxDecoration(
          color: record.getAlliance == 'Blue' ? Colors.blue[900]!.withOpacity(0.8) : Colors.red[900]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: record.getAlliance == 'Blue' ? Colors.blue : Colors.red,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (record.getAlliance == 'Blue' ? Colors.blue : Colors.red).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: record.getCsvData,
                version: QrVersions.auto,
                size: 80,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            // Match info
            Text(
              'Quals ${record.getMatch}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // Alliance and station
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${record.getAlliance} • Station ${record.getStation}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Battery level
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.battery_full,
                  color: Colors.green[300],
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '${record.getBatteryLevel}%',
                  style: TextStyle(
                    color: Colors.green[300],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenQrCode(db.QrData record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenQrCodeView(record: record, onDelete: () => setState(() {})),
      ),
    );
  }
}

class FullScreenQrCodeView extends StatelessWidget {
  final db.QrData record;
  final VoidCallback onDelete;

  const FullScreenQrCodeView({
    super.key,
    required this.record,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Header overlay at the top
          Positioned(top: 0, left: 0, right: 0, child: const ScoutHeader()),

          // Main content
          Positioned.fill(
            top: 80, // Account for header
            child: Column(
              children: [
                // Title
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Quals ${record.getMatch} - ${record.getAlliance} Alliance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Large QR Code
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (record.getAlliance == 'Blue' ? Colors.blue : Colors.red).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: record.getCsvData,
                        version: QrVersions.auto,
                        size: MediaQuery.of(context).size.width * 0.7,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ),

                // Record details
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: record.getAlliance == 'Blue' ? Colors.blue[900]!.withOpacity(0.8) : Colors.red[900]!.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: record.getAlliance == 'Blue' ? Colors.blue : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoChip('Station ${record.getStation}', Icons.location_on),
                          _buildInfoChip('${record.getBatteryLevel}% Battery', Icons.battery_full),
                          _buildInfoChip(record.getName, Icons.person),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scanned: ${record.getTimestamp.toString().split('.')[0]}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
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
              final db.DataManager dbManager = db.DataManager();
              final key = '${record.getAlliance}_${record.getMatch}_${record.getStation}';
              dbManager.delete(key);
              onDelete(); // Refresh the parent screen
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to grid
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Record deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}