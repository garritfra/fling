class TemplateItem {
  String id;
  String text;
  List<String> tags;

  TemplateItem({required this.id, required this.text, this.tags = const []});

  factory TemplateItem.fromMap(Map<String, dynamic> data) {
    return TemplateItem(
        id: data["id"],
        text: data["text"],
        tags: data["tags"] != null ? List<String>.from(data["tags"]) : []);
  }

  Map<String, dynamic> toMap() {
    return {
      "text": text,
      "tags": tags,
    };
  }
}
