import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/models/note.dart';

void main() {
  group('Note model tests', () {
    // =========================================================
    // TEST 1: Note stores all values correctly
    // =========================================================
    test('Note object stores values correctly', () {
      final now = DateTime(2026, 3, 2, 10, 0);

      final note = Note(
        id: '1',
        title: 'Test',
        content: 'Hello',
        folder: 'CSIT 112',
        category: 'Homework',
        tags: const ['week3', 'exam'],
        createdAt: now,
        updatedAt: now,
      );

      expect(note.id, '1');
      expect(note.title, 'Test');
      expect(note.content, 'Hello');
      expect(note.folder, 'CSIT 112');
      expect(note.category, 'Homework');

      // Better matchers for lists
      expect(note.tags, equals(['week3', 'exam']));
      expect(note.tags, contains('week3'));
      expect(note.tags, contains('exam'));
    });

    // =========================================================
    // TEST 2: Title can be empty (Untitled allowed)
    // =========================================================
    test('Note title can be empty (Untitled allowed)', () {
      final now = DateTime(2026, 3, 2, 10, 0);

      final note = Note(
        id: '2',
        title: '',
        content: 'Content only',
        folder: 'General',
        category: 'General',
        tags: const [],
        createdAt: now,
        updatedAt: now,
      );

      expect(note.title, '');
    });

    // =========================================================
    // TEST 3: Different notes must have different IDs
    // =========================================================
    test('Different notes have different IDs', () {
      final now = DateTime(2026, 3, 2, 10, 0);

      final note1 = Note(
        id: '1',
        title: 'A',
        content: 'One',
        folder: 'Work',
        category: 'Work',
        tags: const [],
        createdAt: now,
        updatedAt: now,
      );

      final note2 = Note(
        id: '2',
        title: 'B',
        content: 'Two',
        folder: 'Personal',
        category: 'Personal',
        tags: const [],
        createdAt: now,
        updatedAt: now,
      );

      expect(note1.id, isNot(note2.id));
    });

    // =========================================================
    // TEST 4: Note converts to Map and back correctly
    // =========================================================
    test('Note toMap and fromMap preserve data', () {
      final created = DateTime(2026, 2, 14, 9, 34);
      final updated = DateTime(2026, 2, 28, 18, 39);

      final original = Note(
        id: '123',
        title: 'Map Test',
        content: 'Testing serialization',
        folder: 'AMAT 240',
        category: 'Courses',
        tags: const ['lecture', 'matrix'],
        createdAt: created,
        updatedAt: updated,
      );

      final map = original.toMap();
      final recreated = Note.fromMap(map);

      expect(recreated.id, original.id);
      expect(recreated.title, original.title);
      expect(recreated.content, original.content);
      expect(recreated.folder, original.folder);
      expect(recreated.category, original.category);
      expect(recreated.tags, equals(original.tags));
      expect(
        recreated.createdAt.millisecondsSinceEpoch,
        original.createdAt.millisecondsSinceEpoch,
      );
      expect(
        recreated.updatedAt.millisecondsSinceEpoch,
        original.updatedAt.millisecondsSinceEpoch,
      );
    });

    // =========================================================
    // TEST 5: Backward compatibility (older notes without new fields)
    // =========================================================
    test('Note.fromMap works with old data (no folder/tags)', () {
      final oldMap = {
        'id': 'legacy',
        'title': 'Old Note',
        'content': 'This was created before folders',
        'updatedAt': DateTime(2026, 3, 1).millisecondsSinceEpoch,
      };

      final note = Note.fromMap(oldMap);

      expect(note.folder, 'General');
      expect(note.category, 'General');
      expect(note.tags, isEmpty);
    });

    // =========================================================
    // TEST 6: fromMap supports tags coming as a comma string
    // =========================================================
    test('Note.fromMap parses tags from comma-separated String', () {
      final map = {
        'id': 't6',
        'title': 'Tags String',
        'content': 'Should split tags',
        'folder': 'CSIT 415',
        'category': 'Homework',
        'tags': 'week3, exam ,  , review',
        'updatedAt': DateTime(2026, 3, 1).millisecondsSinceEpoch,
      };

      final note = Note.fromMap(map);

      expect(note.tags, equals(['week3', 'exam', 'review']));
    });

    // =========================================================
    // TEST 7: Invalid timestamps do not crash (robust parsing)
    // =========================================================
    test('Note.fromMap handles invalid time values safely', () {
      final badMap = {
        'id': 'bad',
        'title': 'Bad Time',
        'content': 'Invalid timestamps should not crash',
        'folder': 'General',
        'category': 'General',
        'tags': const [],
        'createdAt': 'not a number',
        'updatedAt': 'not a number',
      };

      final note = Note.fromMap(badMap);

      expect(note.id, 'bad');
      expect(note.title, 'Bad Time');
      expect(note.createdAt, isA<DateTime>());
      expect(note.updatedAt, isA<DateTime>());
    });
  });
}