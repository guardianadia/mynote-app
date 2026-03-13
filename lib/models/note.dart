class Note {
  final String id;
  final String title;
  final String content;

  // Organize
  final String folder;      // e.g., "CSIT 112" / "Chores"
  final String category;    // e.g., "Homework" / "Work"
  final List<String> tags;  // e.g., ["week3", "exam"]

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
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<dynamic, dynamic> map) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    int parseMs(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? nowMs;
    }

    List<String> parseTags(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
      if (v is String) {
        return v
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    final updatedMs = parseMs(map['updatedAt']);
    final createdMsRaw = map['createdAt'];
    final createdMs = createdMsRaw == null ? updatedMs : parseMs(createdMsRaw);

    return Note(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),

      //  Backward compatible defaults
      folder: (map['folder'] ?? 'General').toString(),
      category: (map['category'] ?? 'General').toString(),
      tags: parseTags(map['tags']),

      createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedMs),
    );
  }
}