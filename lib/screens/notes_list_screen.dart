import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../models/note.dart';
import 'edit_note_screen.dart';

import '../services/auth_service.dart';
import '../auth/login_screen.dart';

class ScrollUpIntent extends Intent {
  const ScrollUpIntent();
}

class ScrollDownIntent extends Intent {
  const ScrollDownIntent();
}

class PageUpIntent extends Intent {
  const PageUpIntent();
}

class PageDownIntent extends Intent {
  const PageDownIntent();
}

String _folderEmoji(String folder) {
  final f = folder.toLowerCase();
  if (f.contains('csit') || f.contains('course') || f.contains('class')) return '🎓';
  if (f.contains('math') || f.contains('amat')) return '📐';
  if (f.contains('homework')) return '📚';
  if (f.contains('chore') || f.contains('home')) return '🏠';
  if (f.contains('work') || f.contains('job')) return '💼';
  return '📁';
}

Color _folderColor(String folder) {
  int hash = 0;
  for (final codeUnit in folder.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }

  const palette = <Color>[
    Color(0xFF2563EB), // blue
    Color(0xFF7C3AED), // purple
    Color(0xFF16A34A), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF0EA5E9), // sky
    Color(0xFFEA580C), // orange
    Color(0xFF059669), // emerald
    Color(0xFF6B7280), // gray
  ];

  return palette[hash % palette.length];
}

Color _categoryColor(String category) {
  switch (category) {
    case 'Homework':
      return const Color(0xFF2563EB);
    case 'Courses':
      return const Color(0xFF7C3AED);
    case 'Chores':
      return const Color(0xFF16A34A);
    case 'Work':
      return const Color(0xFFF59E0B);
    case 'Personal':
      return const Color(0xFFEC4899);
    default:
      return const Color(0xFF6B7280);
  }
}

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  static const String _boxName = 'notesBox';

  final List<Note> _notes = [];
  final ScrollController _scroll = ScrollController();
  final FocusNode _screenFocus = FocusNode();

  final AuthService _auth = AuthService();

  // Folder filter
  String _filterFolder = 'All';

  Box get _box => Hive.box(_boxName);

  @override
  void initState() {
    super.initState();
    _loadFromHive();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _screenFocus.dispose();
    super.dispose();
  }

  void _loadFromHive() {
    final List<Note> loaded = [];

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        loaded.add(Note.fromMap(Map<dynamic, dynamic>.from(raw)));
      }
    }

    loaded.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    setState(() {
      _notes
        ..clear()
        ..addAll(loaded);
    });
  }

  Future<void> _saveNoteToHive(Note note) async {
    await _box.put(note.id, note.toMap());
  }

  Future<void> _deleteNoteFromHive(String id) async {
    await _box.delete(id);
  }

  Future<void> _addNewNote() async {
    final created = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => const EditNoteScreen()),
    );

    if (created != null) {
      await _saveNoteToHive(created);
      setState(() => _notes.insert(0, created));

      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _editExistingNote(Note note) async {
    final updated = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => EditNoteScreen(existing: note)),
    );

    if (updated != null) {
      await _saveNoteToHive(updated);

      setState(() {
        final index = _notes.indexWhere((n) => n.id == updated.id);
        if (index != -1) _notes[index] = updated;
        _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      });
    }
  }

  Future<void> _deleteNote(String id) async {
    await _deleteNoteFromHive(id);
    setState(() => _notes.removeWhere((n) => n.id == id));
  }

  void _scrollBy(double delta) {
    if (!_scroll.hasClients) return;

    final target = (_scroll.offset + delta).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );

    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  // LOGOUT
  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // OPTIONAL: RESET ACCOUNT (for demo)
  Future<void> _resetAccount() async {
    await _auth.clearAccount();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _fmtDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');

    final mm = two(dt.month);
    final dd = two(dt.day);
    final yyyy = dt.year;

    int h = dt.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;

    final min = two(dt.minute);
    return '$mm/$dd/$yyyy $h:$min $ampm';
  }

  List<String> get _allFolders {
    final set = <String>{};
    for (final n in _notes) {
      final f = n.folder.trim().isEmpty ? 'General' : n.folder.trim();
      set.add(f);
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!list.contains('General')) list.insert(0, 'General');
    return list;
  }

  List<Note> get _filteredNotes {
    if (_filterFolder == 'All') return List<Note>.from(_notes);
    return _notes.where((n) => n.folder == _filterFolder).toList();
  }

  Map<String, List<Note>> _groupByFolder(List<Note> notes) {
    final Map<String, List<Note>> groups = {};
    for (final n in notes) {
      groups.putIfAbsent(n.folder, () => []);
      groups[n.folder]!.add(n);
    }
    for (final k in groups.keys) {
      groups[k]!.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return groups;
  }

  Widget _filterBar() {
    final folders = ['All', ..._allFolders];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          for (final f in folders) ...[
            ChoiceChip(
              label: Text(f),
              selected: _filterFolder == f,
              onSelected: (_) => setState(() => _filterFolder = f),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _categoryBadge(String category) {
    final c = _categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }

  Widget _folderBadge(String folder) {
    final c = _folderColor(folder);
    final emoji = _folderEmoji(folder);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$emoji $folder',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }

  Widget _tagsRow(List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: -6,
      children: tags.take(6).map((t) {
        return Chip(
          label: Text(t, style: const TextStyle(fontSize: 12)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _folderHeader(String folder, int count) {
    final emoji = _folderEmoji(folder);
    final c = _folderColor(folder);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Row(
        children: [
          Text(
            '$emoji $folder',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Text('($count)'),
          const Spacer(),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _noteCard(Note note) {
    return Dismissible(
      key: ValueKey(note.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNote(note.id),
      child: Card(
        child: ListTile(
          title: Text(
            note.title.isEmpty ? '(Untitled)' : note.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _categoryBadge(note.category),
                    const SizedBox(width: 8),
                    _folderBadge(note.folder),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  note.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 6),
                _tagsRow(note.tags),
                const SizedBox(height: 6),
                Text(
                  'Created: ${_fmtDate(note.createdAt)}  •  Updated: ${_fmtDate(note.updatedAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          onTap: () => _editExistingNote(note),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _filteredNotes;
    final groups = _groupByFolder(notes);

    final folderOrder =
        _filterFolder == 'All' ? _allFolders : <String>[_filterFolder];

    final List<Widget> listChildren = [];

    for (final folder in folderOrder) {
      final group = groups[folder];
      if (group == null || group.isEmpty) continue;

      listChildren.add(_folderHeader(folder, group.length));

      for (final n in group) {
        listChildren.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _noteCard(n),
          ),
        );
      }
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): ScrollUpIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): ScrollDownIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): PageUpIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): PageDownIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ScrollUpIntent: CallbackAction<ScrollUpIntent>(
            onInvoke: (_) => _scrollBy(-80),
          ),
          ScrollDownIntent: CallbackAction<ScrollDownIntent>(
            onInvoke: (_) => _scrollBy(80),
          ),
          PageUpIntent: CallbackAction<PageUpIntent>(
            onInvoke: (_) => _scrollBy(-350),
          ),
          PageDownIntent: CallbackAction<PageDownIntent>(
            onInvoke: (_) => _scrollBy(350),
          ),
        },
        child: Focus(
          autofocus: true,
          focusNode: _screenFocus,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('MyNote'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: _logout,
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove),
                  tooltip: 'Reset Account',
                  onPressed: _resetAccount,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _addNewNote,
              child: const Icon(Icons.add),
            ),

            // iPad polish: limit max width
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  children: [
                    _filterBar(),
                    Expanded(
                      child: notes.isEmpty
                          ? const Center(
                              child: Text('No notes yet. Tap + to add one.'),
                            )
                          : ListView(
                              controller: _scroll,
                              children: listChildren,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}