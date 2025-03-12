// lib/data/list_item.dart
class ListItem {
  String id;
  String text;
  bool checked;
  List<String> tags;

  ListItem(
      {required this.id,
      required this.text,
      required this.checked,
      this.tags = const []});

  factory ListItem.fromMap(Map<String, dynamic> data) {
    return ListItem(
        id: data["id"],
        checked: data["checked"],
        text: data["text"],
        tags: data["tags"] != null ? List<String>.from(data["tags"]) : []);
  }

  Map<String, dynamic> toMap() {
    return {
      "checked": checked,
      "text": text,
      "tags": tags,
    };
  }
}
