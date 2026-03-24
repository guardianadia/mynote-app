import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import 'edit_note_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _client = Supabase.instance.client;

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];

  String _searchQuery = '';
  String _sortType = 'date';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // =========================
  // LOAD NOTES
  // =========================
  Future<void> _loadNotes() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final data = await _client
        .from('notes')
        .select()
        .eq('user_id', user.id);

    _notes = (data as List).map((e) => Note.fromMap(e)).toList();

    _applyFilters();
  }

  // =========================
  // FILTER + SORT
  // =========================
  void _applyFilters() {
    List<Note> temp = _notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // 📌 PIN FIRST
    temp.sort((a, b) {
      if (a.isPinned == b.isPinned) return 0;
      return a.isPinned ? -1 : 1;
    });

    // 📊 SORT
    if (_sortType == 'title') {
      temp.sort((a, b) => a.title.compareTo(b.title));
    } else {
      temp.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    setState(() {
      _filteredNotes = temp;
    });
  }

  // =========================
  // PIN / FAVORITE
  // =========================
  Future<void> _togglePin(Note note) async {
    await _client
        .from('notes')
        .update({'is_pinned': !note.isPinned}).eq('id', note.id);

    _loadNotes();
  }

  Future<void> _toggleFavorite(Note note) async {
    await _client
        .from('notes')
        .update({'is_favorite': !note.isFavorite}).eq('id', note.id);

    _loadNotes();
  }

  // =========================
  // DELETE
  // =========================
  Future<void> _deleteNote(String id) async {
    await _client.from('notes').delete().eq('id', id);
    _loadNotes();
  }

  // =========================
  // EDIT
  // =========================
  void _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(note: note),
      ),
    );

    if (result != null && result is Note) {
      await _client.from('notes').update({
        'title': result.title,
        'content': result.content,
        'folder': result.folder,
        'category': result.category,
        'tags': result.tags,
        'updated_at': result.updatedAt.toIso8601String(),
      }).eq('id', result.id);

      _loadNotes();
    }
  }

  // =========================
  // REORDER
  // =========================
  void _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final item = _filteredNotes.removeAt(oldIndex);
    _filteredNotes.insert(newIndex, item);

    setState(() {});

    for (int i = 0; i < _filteredNotes.length; i++) {
      await _client
          .from('notes')
          .update({'position': i}).eq('id', _filteredNotes[i].id);
    }
  }

  // =========================
  // DATE FORMAT
  // =========================
  String formatDate(DateTime d) {
    return "${d.month}/${d.day}/${d.year}";
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EAFE),

      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: const Color(0xFF5B2C83),

        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              _sortType = value;
              _applyFilters();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              PopupMenuItem(value: 'title', child: Text('Sort by Title')),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
            ),
          ),

          // 📋 LIST
          Expanded(
            child: ReorderableListView.builder(
              onReorder: _reorder,
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];

                return Dismissible(
                  key: ValueKey(note.id),
                  onDismissed: (_) => _deleteNote(note.id),
                  background: Container(color: Colors.red),

                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(note.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note.content),

                          const SizedBox(height: 6),

                          Text(
                            "Updated: ${formatDate(note.updatedAt)}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              note.isFavorite
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () => _toggleFavorite(note),
                          ),
                          IconButton(
                            icon: Icon(
                              note.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                            ),
                            onPressed: () => _togglePin(note),
                          ),
                        ],
                      ),

                      onTap: () => _editNote(note),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5B2C83),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditNoteScreen()),
          );

          if (result != null && result is Note) {
            final user = _client.auth.currentUser;
            if (user == null) return;

            await _client.from('notes').insert({
              'id': result.id,
              'user_id': user.id,
              'title': result.title,
              'content': result.content,
              'folder': result.folder,
              'category': result.category,
              'tags': result.tags,
              'created_at': result.createdAt.toIso8601String(),
              'updated_at': result.updatedAt.toIso8601String(),
              'is_pinned': result.isPinned,
              'is_favorite': result.isFavorite,
              'position': result.position,
            });

            _loadNotes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}