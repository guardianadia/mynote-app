import 'package:flutter/material.dart';
import '../models/note.dart';

class EditNoteScreen extends StatefulWidget {
  final Note? note;

  const EditNoteScreen({super.key, this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  final TextEditingController _folderCtrl = TextEditingController();
  final TextEditingController _tagsCtrl = TextEditingController();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  static const List<String> _categories = [
    'General',
    'Homework',
    'Courses',
    'Chores',
    'Work',
    'Personal',
  ];

  String _selectedCategory = 'General';

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );

    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _selectedCategory = widget.note?.category ?? 'General';
    _folderCtrl.text = widget.note?.folder ?? 'General';
    _tagsCtrl.text = (widget.note?.tags ?? []).join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _folderCtrl.dispose();
    _tagsCtrl.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  // =========================
  // TAG PARSER
  // =========================
  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // =========================
  // SAVE NOTE
  // =========================
  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    final folder = _folderCtrl.text.trim().isEmpty
        ? 'General'
        : _folderCtrl.text.trim();

    final tags = _parseTags(_tagsCtrl.text);

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title or note content.'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    final note = Note(
      id: widget.note?.id ?? now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      folder: folder,
      category: _selectedCategory,
      tags: tags,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,

      // ✅ KEEP EXISTING VALUES
      isPinned: widget.note?.isPinned ?? false,
      isFavorite: widget.note?.isFavorite ?? false,
      position: widget.note?.position ?? 0,
    );

    Navigator.pop(context, note);
  }

  // =========================
  // INPUT STYLE
  // =========================
  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withAlpha(230),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EAFE),

      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        backgroundColor: const Color(0xFF5B2C83),

        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                // TITLE
                TextField(
                  focusNode: _titleFocus,
                  controller: _titleController,
                  decoration: _fieldDecoration('Title'),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _contentFocus.requestFocus(),
                ),

                const SizedBox(height: 12),

                // FOLDER
                TextField(
                  controller: _folderCtrl,
                  decoration: _fieldDecoration('Folder'),
                ),

                const SizedBox(height: 12),

                // CATEGORY
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: _fieldDecoration('Category'),
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'General';
                    });
                  },
                ),

                const SizedBox(height: 12),

                // TAGS
                TextField(
                  controller: _tagsCtrl,
                  decoration: _fieldDecoration('Tags (comma separated)'),
                ),

                const SizedBox(height: 12),

                // CONTENT
                Expanded(
                  child: TextField(
                    focusNode: _contentFocus,
                    controller: _contentController,
                    decoration: _fieldDecoration('Note'),
                    maxLines: null,
                    expands: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}