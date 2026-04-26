import 'package:flutter/material.dart';
import 'package:mynote/models/note.dart';
import 'package:mynote/services/note_service.dart';
import 'package:mynote/services/gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

class EditNoteScreen extends StatefulWidget {
  final Note? note;

  const EditNoteScreen({super.key, this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final TextEditingController _tagsCtrl = TextEditingController();

  final _noteService = NoteService();

  String _selectedCategory = 'General';
  final List<String> _categories = [
    'General',
    'School',
    'Work',
    'Personal',
    'Ideas',
    'Other'
  ];

  List<String> _tagList = [];

  bool _isSaving = false;
  bool _isSummarizing = false;

  String _noteId = '';

  Color _selectedColor = Colors.white;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _contentBeforeListening = '';

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');

    _selectedCategory = widget.note?.category ?? 'General';
    _tagList = widget.note?.tags ?? [];
    _tagsCtrl.text = _tagList.join(', ');
    _noteId = widget.note?.id ?? '';

    _selectedColor = widget.note?.color != null
        ? Color(widget.note!.color!)
        : Colors.white;

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _startListening() async {
    _contentBeforeListening = _contentController.text;

    await _speechToText.listen(onResult: (result) {
      setState(() {
        _contentController.text =
            '$_contentBeforeListening ${result.recognizedWords}';
      });
    });

    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _addTag() {
    final tag = _tagsCtrl.text.trim();
    if (tag.isEmpty) return;

    if (!_tagList.contains(tag)) {
      setState(() => _tagList.add(tag));
    }

    _tagsCtrl.clear();
  }

  Future<void> _pickColor() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pick color"),
        content: Wrap(
          spacing: 10,
          children: [
            _colorDot(Colors.white),
            _colorDot(Colors.yellow.shade200),
            _colorDot(Colors.blue.shade200),
            _colorDot(Colors.green.shade200),
            _colorDot(Colors.pink.shade200),
            _colorDot(Colors.orange.shade200),
            _colorDot(Colors.purple.shade200),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedColor = picked);
    }
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, color),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

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
      folder: widget.note?.folder ?? 'General',
      category: _selectedCategory,
      tags: _tagList,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      color: _selectedColor.toARGB32(),
    );

    await _noteService.saveNote(note);

    if (!mounted) return;
    Navigator.pop(context);
  }

  // AI SUMMARY
  Future<void> _summarizeNote() async {
    final text = _contentController.text;

    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nothing to summarize")),
      );
      return;
    }

    setState(() => _isSummarizing = true);

    try {
      final summary = await GeminiService().summarize(text);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Summary"),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("AI ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSummarizing = false);
      }
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'School':
        return Icons.school;
      case 'Work':
        return Icons.work;
      case 'Personal':
        return Icons.person;
      case 'Ideas':
        return Icons.lightbulb;
      default:
        return Icons.notes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedColor.withValues(alpha: 0.25),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Note"),
        actions: [
          IconButton(icon: const Icon(Icons.palette), onPressed: _pickColor),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.black,
            ),
            onPressed: !_speechEnabled
                ? _initSpeech
                : (_isListening ? _stopListening : _startListening),
          ),
          IconButton(
            icon: _isSummarizing
                ? const CircularProgressIndicator()
                : const Icon(Icons.auto_awesome),
            onPressed: _isSummarizing ? null : _summarizeNote,
          ),
          IconButton(
            icon: _isSaving
                ? const CircularProgressIndicator()
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 12),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                decoration: _input("Title"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _input("Category"),
                items: _categories.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(_getCategoryIcon(c), size: 18),
                        const SizedBox(width: 6),
                        Text(c),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagsCtrl,
                      decoration: _input("Add tag"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: _tagList.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.purple.shade100,
                    avatar: const Icon(Icons.tag, size: 16),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: _input("Start typing your note...").copyWith(
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}