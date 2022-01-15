class Feature {
  String name;
  bool isEnabled;

  Feature({this.name, this.isEnabled});
}

class FeatureManager {
  static final Feature settings = Feature(name: "Settings", isEnabled: false);
}
