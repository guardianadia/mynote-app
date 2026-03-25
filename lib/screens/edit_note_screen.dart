import 'dart:async';
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
  bool _autoSaving = false;

  Timer? _debounce;

  static const List<String> _categories = [
    'General',
    'Homework',
    'Courses',
    'Chores',
    'Work',
    'Personal',
  ];

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

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () {
      _autoSave();
    });
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // =========================
  // AUTO SAVE
  // =========================
  Future<void> _autoSave() async {
    if (!mounted) return;

    setState(() => _autoSaving = true);

    try {
      final now = DateTime.now();

      final note = Note(
        id: widget.note?.id ?? '',
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

      //  FIX: ONLY saveNote (no updateNote)
      await _noteService.saveNote(note);

    } catch (_) {}

    if (mounted) setState(() => _autoSaving = false);
  }

  // =========================
  // MANUAL SAVE BUTTON
  // =========================
  Future<void> _save() async {
    setState(() => _isSaving = true);

    await _autoSave();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved ✔")),
    );

    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _folderCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: true, // 🔥 fixes label overlap
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EAFE),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5B2C83)),
        title: const Text(
          "Note",
          style: TextStyle(color: Color(0xFF5B2C83)),
        ),
        actions: [
          if (_autoSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.sync, color: Colors.grey),
            ),

          Tooltip(
            message: "Save",
            child: IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, color: Color(0xFF5B2C83)),
              onPressed: _isSaving ? null : _save,
            ),
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

            TextField(
              controller: _folderCtrl,
              decoration: _input("Folder"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: _input("Category"),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedCategory = v);
                }
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _tagsCtrl,
              decoration: _input("Tags"),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: TextField(
                controller: _contentController,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top, // 🔥 FIXED
                decoration: _input("Start typing your note..."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}