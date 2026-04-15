import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class NoteProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  Future<void> init() async {
    await _dbService.init();
    _loadNotes();
  }

  void _loadNotes() {
    _notes = _dbService.getAllNotes();
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    await _dbService.addNote(note);
    _loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _dbService.updateNote(note);
    _loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _dbService.deleteNote(id);
    _loadNotes();
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;
    return _notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(query.toLowerCase());
      final subjectMatch = note.subject.toLowerCase().contains(query.toLowerCase());
      final tagMatch = note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      return titleMatch || subjectMatch || tagMatch;
    }).toList();
  }
}
