class qrData {
  String csvData = "";
  String batteryLevel = "";
  String name = "";

  String getCsvData() {
    return csvData;
  }

  String getBatteryLevel() {
    return batteryLevel;
  }

  void setCsvData(String data) {
    csvData = data;
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
  String bStation2 = "";
  String bStation3 = "";
  String rStation1 = "";
  String rStation2 = "";
  String rStation3 = "";

  String getbStation1() {
    return bStation1;
  }

  String getbStation2() {
    return bStation2;
  }

  String getbStation3() {
    return bStation3;
  }

  String getrStation1() {
    return rStation1;
  }

  String getrStation2() {
    return rStation2;
  }

  String getrStation3() {
    return rStation3;
  }

  void setbStation(String data) {
    bStation1 = data;
  }

  void setbStation2(String data) {
    bStation2 = data;
  }

  void setbStation3(String data) {
    bStation3 = data;
  }

  void setrStation1(String data) {
    rStation1 = data;
  }

  void setrStation2(String data) {
    rStation2 = data;
  }

  void setrStation3(String data) {
    rStation3 = data;
  }

  // GetBluAllianceData -> List[]

  List<String> getBlueAllianceData() {
    return [getbStation1(), getbStation2(), getbStation3()];
  }
  // ["fvgubvfhiedog","vfdgshlbhjdvnhjvl", "veghckebfhcbybfrhgy"]

  List<String> getRedAllianceData() {
    return [getrStation1(), getrStation2(), getrStation3()];
  }

  List<List<String>> export() {
    return [getBlueAllianceData(), getRedAllianceData()];
  }
}
