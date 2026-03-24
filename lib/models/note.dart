class Note {
  final String id;
  final String title;
  final String content;
  final String folder;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.folder,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folder': folder,
      'category': category,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    List<String> parseTags(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      if (value is String) {
        return value
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      return [];
    }

    return Note(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      folder: (map['folder'] ?? 'General').toString(),
      category: (map['category'] ?? 'General').toString(),
      tags: parseTags(map['tags']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }
}
