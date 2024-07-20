class TemplateItem {
  String id;
  String text;

  TemplateItem({required this.id, required this.text});

  factory TemplateItem.fromMap(Map<String, dynamic> data) {
    return TemplateItem(id: data["id"], text: data["text"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "text": text,
    };
  }
}
