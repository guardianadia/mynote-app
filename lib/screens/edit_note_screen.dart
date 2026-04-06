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
  final TextEditingController _folderCtrl = TextEditingController();
  final TextEditingController _tagsCtrl = TextEditingController();

  final _noteService = NoteService();

  String _selectedCategory = 'General';
  bool _isSaving = false;
  bool _isSummarizing = false;

  String _noteId = '';
  String _saveStatus = '';

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
    _folderCtrl.text = widget.note?.folder ?? 'General';
    _tagsCtrl.text = (widget.note?.tags ?? []).join(', ');

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
        const SnackBar(
          content: Text('Speech recognition is not available on this device.'),
        ),
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
    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();

    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final spokenText = result.recognizedWords;

    setState(() {
      final hasExistingText = _contentBeforeListening.trim().isNotEmpty;
      final separator = hasExistingText ? '\n' : '';

      _contentController.text =
          '$_contentBeforeListening$separator$spokenText';

      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _contentController.text.length),
      );
    });
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveStatus = 'Saving...';
    });

    final now = DateTime.now();

    final note = Note(
      id: _noteId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      folder: _folderCtrl.text.trim().isEmpty
          ? 'General'
          : _folderCtrl.text.trim(),
      category: _selectedCategory,
      tags: _parseTags(_tagsCtrl.text.trim()),
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _noteService.saveNote(note);

      if (_noteId.isEmpty) _noteId = note.id;

      if (!mounted) return;

      setState(() {
        _saveStatus = 'Saved ✔';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _saveStatus = '');
      });

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note: $e')),
      );
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
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Failed to summarize note: $e"),
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
          if (_saveStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _saveStatus,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                  ),
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
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _isSummarizing ? null : _summarizeNote,
          ),

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
            if (_isListening)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Listening... speak now',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            if (_speechError.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Voice input error: $_speechError',
                  style: const TextStyle(fontSize: 13),
                ),
              ),

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