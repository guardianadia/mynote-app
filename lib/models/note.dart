class Note {
  final String id;
  final String title;
  final String content;
  final String folder;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ✅ NEW FIELDS
  final bool isPinned;
  final bool isFavorite;
  final int position;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.folder,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,

    // ✅ NEW
    this.isPinned = false,
    this.isFavorite = false,
    this.position = 0,
  });

  // =========================
  // FROM SUPABASE
  // =========================
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      folder: map['folder'] ?? 'General',
      category: map['category'] ?? 'General',
      tags: List<String>.from(map['tags'] ?? []),

      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),

      // ✅ NEW (SAFE DEFAULTS)
      isPinned: map['is_pinned'] ?? false,
      isFavorite: map['is_favorite'] ?? false,
      position: map['position'] ?? 0,
    );
  }

  // =========================
  // TO MAP (OPTIONAL)
  // =========================
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

      // ✅ NEW
      'is_pinned': isPinned,
      'is_favorite': isFavorite,
      'position': position,
    };
  }
}