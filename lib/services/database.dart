import 'package:hive/hive.dart';

/// Represents data extracted from a QR code.
/// Includes CSV parsing, validation, and export utilities.
class QrData {
  String csvData;
  String batteryLevel;
  String name;
  String match;
  String station;
  String alliance;
  DateTime timestamp;
  bool transmitted;

  QrData({
    this.csvData = '',
    this.batteryLevel = '',
    this.name = '',
    this.match = '',
    this.station = '',
    this.alliance = '',
    DateTime? timestamp,
    this.transmitted = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// --- Getters ---
  String get getCsvData => csvData;
  String get getAlliance => alliance;
  String get getBatteryLevel => batteryLevel;
  String get getMatch => match;
  String get getStation => station;
  DateTime get getTimestamp => timestamp;
  bool get isTransmitted => transmitted;
  String get getName => name;

  /// --- Setters ---
  /// CSV Format: battery,index,name,match_key,alliance,event_key,station,match_num,...
  /// Example: "65,5641,Ritesh,2025mirr_qm16,Blue,2025mirr,3,16,..."
  void setCsvData(String data) {
    try {
      // Remove surrounding quotes if present
      csvData = data.replaceAll(RegExp(r'^"|"$'), '');
      final parts = csvData.split(',');
      
      // Index 0 = battery percentage
      // Index 4 = alliance (Blue/Red)
      // Index 5 = event_key (2025mirr)
      // Index 6 = station number (1-3)
      // Index 7 = match number (qualification match number)
      if (parts.length > 0) batteryLevel = parts[0].trim();
      if (parts.length > 4) alliance = parts[4].trim();
      if (parts.length > 6) station = parts[6].trim();
      if (parts.length > 7) match = parts[7].trim(); // Use match number instead of event key
      
      timestamp = DateTime.now();
      print('Parsed CSV: Alliance=$alliance, Match=$match, Station=$station, Battery=$batteryLevel%');
    } catch (e) {
      print('Error parsing CSV data: $e');
    }
  }

  void setBatteryLevel(String percentage) => batteryLevel = percentage;
  void setName(String value) => name = value;
  void setAlliance(String value) => alliance = value;
  void setMatch(String value) => match = value;
  void setStation(String value) => station = value;
  void setTransmitted(bool value) => transmitted = value;

  /// --- Utility Methods ---
  String toDisplayString() =>
      '$name | Match: $match | Station: $station | Alliance: $alliance | Battery: ${batteryLevel.isNotEmpty ? batteryLevel + "%" : ""}';

  Map<String, dynamic> toJson() => {
        'name': name,
        'match': match,
        'station': station,
        'alliance': alliance,
        'battery': batteryLevel,
        'csvData': csvData,
        'timestamp': timestamp.toIso8601String(),
        'transmitted': transmitted,
      };
}

/// Represents data for both alliances in a match.
class MatchData {
  final QrData b1;
  final QrData b2;
  final QrData b3;
  final QrData r1;
  final QrData r2;
  final QrData r3;

  MatchData({
    QrData? b1,
    QrData? b2,
    QrData? b3,
    QrData? r1,
    QrData? r2,
    QrData? r3,
  })  : b1 = b1 ?? QrData(),
        b2 = b2 ?? QrData(),
        b3 = b3 ?? QrData(),
        r1 = r1 ?? QrData(),
        r2 = r2 ?? QrData(),
        r3 = r3 ?? QrData();

  List<QrData> get blueAlliance => [b1, b2, b3];
  List<QrData> get redAlliance => [r1, r2, r3];
  List<List<QrData>> get exportAll => [blueAlliance, redAlliance];
}

/// Hive database manager for managing QR match data.
class DataManager {
  static const String _boxName = 'database';
  late Box _db;
  bool _initialized = false;

  Future<void> init() async {
    try {
      // Register the adapter before opening the box
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(QrDataAdapter());
      }

      _db = await Hive.openBox(_boxName);
      _initialized = true;
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      try {
        _db = Hive.box(_boxName);
        _initialized = true;
      } catch (e) {
        throw Exception('Database not initialized. Run init() first.');
      }
    }
  }

  /// Insert validated QR data
  bool insert(QrData data) {
    _ensureInitialized();
    if (data.getAlliance.isEmpty || data.getMatch.isEmpty) {
      print('Error: Alliance and Match required');
      return false;
    }

    try {
      final key = '${data.getAlliance}_${data.getMatch}_${data.getStation}';
      _db.put(key, data);
      print('Inserted: $key');
      return true;
    } catch (e) {
      print('Insert failed: $e');
      return false;
    }
  }

  /// --- Data Retrieval ---
  Iterable<QrData> _allRecords() sync* {
    _ensureInitialized();
    for (var record in _db.values) {
      if (record is QrData) yield record;
    }
  }

  List<QrData> getAll() => _allRecords().toList();
  List<QrData> getByMatch(String match) =>
      _allRecords().where((e) => e.getMatch == match).toList();
  List<QrData> getByStation(String station) =>
      _allRecords().where((e) => e.getStation == station).toList();

  /// --- Sorting Methods ---
  List<QrData> getSortedByMatch({bool ascending = true}) {
    final records = _allRecords().toList();
    records.sort((a, b) {
      final aMatch = int.tryParse(a.getMatch) ?? 0;
      final bMatch = int.tryParse(b.getMatch) ?? 0;
      return ascending ? aMatch.compareTo(bMatch) : bMatch.compareTo(aMatch);
    });
    return records;
  }

  List<QrData> getSortedByBattery({bool ascending = true}) {
    final records = _allRecords().toList();
    records.sort((a, b) {
      final aBattery = int.tryParse(a.getBatteryLevel) ?? 0;
      final bBattery = int.tryParse(b.getBatteryLevel) ?? 0;
      return ascending ? aBattery.compareTo(bBattery) : bBattery.compareTo(aBattery);
    });
    return records;
  }

  List<QrData> getSortedByTimestamp({bool ascending = true}) {
    final records = _allRecords().toList();
    records.sort((a, b) => ascending
        ? a.getTimestamp.compareTo(b.getTimestamp)
        : b.getTimestamp.compareTo(a.getTimestamp));
    return records;
  }

  List<QrData> search(String query) {
    final q = query.toLowerCase();
    return _allRecords().where((e) {
      return e.getName.toLowerCase().contains(q) ||
          e.getMatch.toLowerCase().contains(q) ||
          e.getStation.toLowerCase().contains(q) ||
          e.getAlliance.toLowerCase().contains(q) ||
          e.getCsvData.toLowerCase().contains(q);
    }).toList();
  }

  List<QrData> getUntransmitted() =>
      _allRecords().where((e) => !e.isTransmitted).toList();

  /// --- Data Updates ---
  void markAsTransmitted(String key) {
    final record = _db.get(key);
    if (record is QrData) {
      record.setTransmitted(true);
      _db.put(key, record);
    }
  }

  void markAllTransmitted() {
    for (var key in _db.keys) {
      markAsTransmitted(key);
    }
  }

  /// --- Statistics ---
  Map<String, dynamic> getStats() {
    int blue = 0, red = 0, transmitted = 0;
    for (var r in _allRecords()) {
      if (r.getAlliance == 'Blue') blue++;
      if (r.getAlliance == 'Red') red++;
      if (r.isTransmitted) transmitted++;
    }
    final total = _db.length;
    return {
      'total': total,
      'blue': blue,
      'red': red,
      'transmitted': transmitted,
      'pending': total - transmitted,
    };
  }

  /// --- Export Utilities ---
  List<Map<String, dynamic>> exportJson() =>
      _allRecords().map((e) => e.toJson()).toList();

  String exportCsv() {
    final buffer = StringBuffer('Name,Match,Station,Alliance,Battery,Timestamp,Transmitted\n');
    for (var r in _allRecords()) {
      buffer.writeln([
        r.getName,
        r.getMatch,
        r.getStation,
        r.getAlliance,
        r.getBatteryLevel,
        r.getTimestamp.toIso8601String(),
        r.isTransmitted ? 'Yes' : 'No'
      ].join(','));
    }
    return buffer.toString();
  }

  /// --- Deletion ---
  void delete(String key) => _db.delete(key);
  void clear() => _db.clear();

  /// --- Utility ---
  Set<String> getAllMatches() =>
      _allRecords().map((e) => e.getMatch).toSet();
  Set<String> getAllStations() =>
      _allRecords().map((e) => e.getStation).toSet();
}

/// Hive adapter for QrData serialization
class QrDataAdapter extends TypeAdapter<QrData> {
  @override
  final int typeId = 0; // Unique type ID for this adapter

  @override
  QrData read(BinaryReader reader) {
    final csvData = reader.readString();
    final batteryLevel = reader.readString();
    final name = reader.readString();
    final match = reader.readString();
    final station = reader.readString();
    final alliance = reader.readString();
    final timestampMillis = reader.readInt();
    final transmitted = reader.readBool();

    return QrData(
      csvData: csvData,
      batteryLevel: batteryLevel,
      name: name,
      match: match,
      station: station,
      alliance: alliance,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
      transmitted: transmitted,
    );
  }

  @override
  void write(BinaryWriter writer, QrData obj) {
    writer.writeString(obj.csvData);
    writer.writeString(obj.batteryLevel);
    writer.writeString(obj.name);
    writer.writeString(obj.match);
    writer.writeString(obj.station);
    writer.writeString(obj.alliance);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeBool(obj.transmitted);
  }
}
