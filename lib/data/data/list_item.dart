class ListItem {
  String id;
  String text;
  bool checked;
  int? index;

  ListItem(
      {required this.id,
      required this.text,
      required this.checked,
      required this.index});

  factory ListItem.fromMap(Map<String, dynamic> data) {
    int index = data["index"] ?? 0;
    return ListItem(
        id: data["id"],
        checked: data["checked"],
        text: data["text"],
        index: index);
  }

  Map<String, dynamic> toMap() {
    return {"checked": checked, "text": text, "index": index};
  }
}
