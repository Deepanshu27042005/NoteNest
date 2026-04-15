import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../services/file_service.dart';

class SaveNoteScreen extends StatefulWidget {
  final File file;
  final String fileType;
  final String? initialSubject;
  final bool isFromScan; // New flag to handle scan flow navigation

  const SaveNoteScreen({
    super.key,
    required this.file,
    required this.fileType,
    this.initialSubject,
    this.isFromScan = false,
  });

  @override
  State<SaveNoteScreen> createState() => _SaveNoteScreenState();
}

class _SaveNoteScreenState extends State<SaveNoteScreen> {
  final _titleController = TextEditingController();
  late TextEditingController _subjectController;
  final _tagsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.initialSubject ?? '');
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();

    if (title.isEmpty || subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and subject')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fileService = FileService();
      final savedPath = await fileService.saveFile(widget.file);

      final newNote = Note(
        id: const Uuid().v4(),
        title: title,
        subject: subject,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        filePath: savedPath,
        fileType: widget.fileType,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        await context.read<NoteProvider>().addNote(newNote);
        
        // Navigation Logic:
        if (widget.isFromScan) {
          // If from scan: Pop SaveNoteScreen AND PreviewScanScreen
          Navigator.of(context).pop(); 
          Navigator.of(context).pop();
        } else {
          // If from simple import: Just pop SaveNoteScreen
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Save Your Note'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ARCHIVE ENTRY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Text('Curate Thought', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildTextField('Note Title', _titleController, 'e.g. Advanced Calculus Lec'),
            const SizedBox(height: 24),
            _buildTextField('Subject', _subjectController, 'e.g. Mathematics'),
            const SizedBox(height: 24),
            _buildTextField('Tags', _tagsController, 'Add tags...', hint: 'SEPARATED BY COMMAS'),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String placeholder, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (hint != null) Text(hint, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
