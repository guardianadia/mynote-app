import 'package:flutter/material.dart';
import 'package:mynote/models/note.dart';
import 'package:mynote/services/note_service.dart';
import 'package:mynote/services/gemini_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
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
  String _saveStatus = '';

  // Speech to text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _speechError = '';
  String _contentBeforeListening = '';

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedCategory = widget.note?.category ?? 'General';
    _tagList = widget.note?.tags ?? [];
    _tagsCtrl.text = _tagList.join(', ');
    _noteId = widget.note?.id ?? '';

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _speechError = error.errorMsg;
          _isListening = false;
        });
      },
    );

    if (!mounted) return;
    setState(() {});
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    setState(() {
      _isListening = _speechToText.isListening;
    });
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available.')),
      );
      return;
    }

    _speechError = '';
    _contentBeforeListening = _contentController.text;

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(minutes: 4),
      pauseFor: const Duration(seconds: 25),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
    );

    if (!mounted) return;
    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final spokenText = result.recognizedWords;
    setState(() {
      final hasExistingText = _contentBeforeListening.trim().isNotEmpty;
      final separator = hasExistingText ? '\n' : '';
      _contentController.text = '$_contentBeforeListening$separator$spokenText';
      _contentController.selection =
          TextSelection.fromPosition(TextPosition(offset: _contentController.text.length));
    });
  }

  void _addTag() {
    final tag = _tagsCtrl.text.trim();
    if (tag.isEmpty) return;
    if (!_tagList.contains(tag)) {
      setState(() {
        _tagList.add(tag);
      });
    }
    _tagsCtrl.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tagList.remove(tag);
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) return;

    setState(() {
      _isSaving = true;
      _saveStatus = 'Saving...';
    });

    final now = DateTime.now();

    final note = Note(
      id: _noteId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      folder: widget.note?.folder ?? 'General', // KEEP folder
      category: _selectedCategory,
      tags: _tagList,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _noteService.saveNote(note);

      if (_noteId.isEmpty) _noteId = note.id;

      if (!mounted) return;
      setState(() => _saveStatus = 'Saved ✔');

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _saveStatus = '');
      });

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _summarizeNote() async {
    final text = _contentController.text;
    if (text.trim().isEmpty) return;

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
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
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
          if (_saveStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _saveStatus,
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              ),
            ),

          IconButton(
            tooltip: _isListening ? 'Stop voice input' : 'Start voice input',
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : null,
            ),
            onPressed: !_speechEnabled
                ? _initSpeech
                : (_isListening ? _stopListening : _startListening),
          ),

          IconButton(
            icon: _isSummarizing
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            onPressed: _isSummarizing ? null : _summarizeNote,
          ),

          IconButton(
            icon: _isSaving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: _input("Title")),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: _input("Category"),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(controller: _tagsCtrl, decoration: _input("Add tag")),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addTag),
              ],
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              children: _tagList.map((tag) {
                return Chip(label: Text(tag), onDeleted: () => _removeTag(tag));
              }).toList(),
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