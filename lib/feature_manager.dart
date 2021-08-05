class Feature {
  String name;
  bool isEnabled;

  Feature({ this.name, this.isEnabled });
}

class FeatureManager {
  static var SETTINGS = Feature(name: "Settings", isEnabled: false);
}
