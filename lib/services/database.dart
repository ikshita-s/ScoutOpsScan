import 'package:hive/hive.dart';

class qrData {
  String csvData = "";
  String batteryLevel = "";
  String name = "";
  String match = "";
  String station = "";
  String alliance = "";

  String getCsvData() {
    return csvData;
  }

  String getAlliance() {
    return alliance;
  }

  String getBatteryLevel() {
    return batteryLevel;
  }

  String getMatch() {
    return match;
  }

  String getStation() {
    return station;
  }

  void setCsvData(String data) {
    csvData = data;
    station = csvData.split(",")[5];
    match = csvData.split(",")[6];
    alliance = csvData.split(",")[3];
  }

  void setBatteryLevel(String percentage) {
    batteryLevel = percentage;
  }

  void setName(String name) {
    this.name = name;
  }

  String getName() {
    return name;
  }
}

class matchData {
  qrData bStation1 = new qrData();
  qrData bStation2 = new qrData();
  qrData bStation3 = new qrData();
  qrData rStation1 = new qrData();
  qrData rStation2 = new qrData();
  qrData rStation3 = new qrData();

  qrData getbStation1() {
    return bStation1;
  }

  qrData getbStation2() {
    return bStation2;
  }

  qrData getbStation3() {
    return bStation3;
  }

  qrData getrStation1() {
    return rStation1;
  }

  qrData getrStation2() {
    return rStation2;
  }

  qrData getrStation3() {
    return rStation3;
  }

  void setbStation(qrData data) {
    bStation1 = data;
  }

  void setbStation2(qrData data) {
    bStation2 = data;
  }

  void setbStation3(qrData data) {
    bStation3 = data;
  }

  void setrStation1(qrData data) {
    rStation1 = data;
  }

  void setrStation2(qrData data) {
    rStation2 = data;
  }

  void setrStation3(qrData data) {
    rStation3 = data;
  }

  // GetBluAllianceData -> List[]

  List<qrData> getBlueAllianceData() {
    return [getbStation1(), getbStation2(), getbStation3()];
  }
  // ["fvgubvfhiedog","vfdgshlbhjdvnhjvl", "veghckebfhcbybfrhgy"]

  List<qrData> getRedAllianceData() {
    return [getrStation1(), getrStation2(), getrStation3()];
  }

  List<List<qrData>> export() {
    return [getBlueAllianceData(), getRedAllianceData()];
  }
}

class dataManager {
  var dataBase = Hive.box("database");

  void insertQrData(qrData data) {
    dataBase.put(
      ("${data.getAlliance()}_${data.getMatch()}_${data.getStation()}"),
      data,
    );
  }

  List<String> exportAllData() {
    List<String> data = [];
    dataBase.keys.forEach((key) {
      data.add(dataBase.get(key).getCsvData());
    });
    return data;
  }

  List<String> exportBlueAllianceData() {
    List<String> blueAllianceData = [];
    dataBase.keys.forEach((key) {
      if (dataBase.get(key).getAlliance() == "Blue") {
        blueAllianceData.add(dataBase.get(key).getCsvData());
      }
    });
    return blueAllianceData;
  }

  List<String> exportRedAllianceData() {
    List<String> redAllianceData = [];
    dataBase.keys.forEach((key) {
      if (dataBase.get(key).getAlliance() == "Red") {
        redAllianceData.add(dataBase.get(key).getCsvData());
      }
    });
    return redAllianceData;
  }



}
