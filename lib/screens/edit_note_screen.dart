import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';

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

  final _noteService = NoteService();

  String _selectedCategory = 'General';
  bool _isSaving = false;

  String _noteId = '';

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');

    _selectedCategory = widget.note?.category ?? 'General';
    _folderCtrl.text = widget.note?.folder ?? 'General';
    _tagsCtrl.text = (widget.note?.tags ?? []).join(', ');

    _noteId = widget.note?.id ?? '';
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // =========================
  // SAVE (ONLY ONE CALL)
  // =========================
  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();

    final note = Note(
      id: _noteId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      folder: _folderCtrl.text.trim().isEmpty
          ? 'General'
          : _folderCtrl.text.trim(),
      category: _selectedCategory,
      tags: _parseTags(_tagsCtrl.text),
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    await _noteService.saveNote(note);

    if (_noteId.isEmpty) {
      _noteId = note.id;
    }

    if (!mounted) return;

    Navigator.pop(context); // 🔥 forces list refresh

    setState(() => _isSaving = false);
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _folderCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EAFE),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Note"),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: _input("Title"),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: TextField(
                controller: _contentController,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: _input("Start typing your note..."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}