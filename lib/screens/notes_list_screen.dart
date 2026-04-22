import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'edit_note_screen.dart';
import 'account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final NoteService _noteService = NoteService();
  final _client = Supabase.instance.client;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  // =========================
  // FILTER LOGIC
  // =========================
  List<Note> _applyFilters(List<Note> notes) {
    List<Note> temp = notes;

    // CATEGORY FILTER
    if (_selectedCategory != 'All') {
      temp = temp.where((note) => note.category == _selectedCategory).toList();
    }

    // SEARCH FILTER
    temp = temp.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // PIN FIRST
    temp.sort((a, b) {
      if (a.isPinned == b.isPinned) return 0;
      return a.isPinned ? -1 : 1;
    });

    // NEWEST FIRST
    temp.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return temp;
  }

  // =========================
  // DELETE
  // =========================
  Future<void> _deleteNote(String id) async {
    try {
      await _noteService.deleteNote(id);

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Note deleted"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  // =========================
  // OPEN EDIT
  // =========================
  Future<void> _openEditor(Note? note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(note: note),
      ),
    );

    setState(() {});
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> _logout() async {
    await _client.auth.signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  String formatDate(DateTime d) {
    return "${d.month}/${d.day}/${d.year}";
  }

  // =========================
  // LIST UI
  // =========================
  Widget _buildList(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return Dismissible(
          key: ValueKey(note.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteNote(note.id),
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: GestureDetector(
            onTap: () => _openEditor(note),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? "Untitled" : note.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (note.isPinned)
                        const Icon(Icons.push_pin,
                            size: 18, color: Colors.deepPurple),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        formatDate(note.updatedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EAFE),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Notes',
          style: TextStyle(
            color: Color(0xFF5B2C83),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFF5B2C83)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AccountScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF5B2C83)),
            onPressed: _logout,
          ),
        ],
      ),

      body: StreamBuilder<List<Note>>(
        stream: _noteService.listenToNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawNotes = snapshot.data ?? [];

          // BUILD CATEGORIES (NO setState)
          final categorySet = <String>{};
          for (var note in rawNotes) {
            categorySet.add(note.category);
          }
          final availableCategories = ['All', ...categorySet];

          final notes = _applyFilters(rawNotes);

          return Column(
            children: [
              // CATEGORY FILTER BAR
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: availableCategories.length,
                  itemBuilder: (context, index) {
                    final cat = availableCategories[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategory == cat
                              ? const Color(0xFF5B2C83)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: _selectedCategory == cat
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // SEARCH
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                  },
                ),
              ),

              // LIST
              Expanded(
                child: notes.isEmpty
                    ? const Center(child: Text("No notes yet"))
                    : _buildList(notes),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5B2C83),
        child: const Icon(Icons.add),
        onPressed: () => _openEditor(null),
      ),
    );
  }
}