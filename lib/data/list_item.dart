class ListItem {
  String id;
  String text;
  bool checked;

  ListItem({required this.id, required this.text, required this.checked});

  factory ListItem.fromMap(Map<String, dynamic> data) {
    return ListItem(
        id: data["id"], checked: data["checked"], text: data["text"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "checked": checked,
      "text": text,
    };
  }
}
