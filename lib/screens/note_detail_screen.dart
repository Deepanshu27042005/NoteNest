import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../services/file_service.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final file = File(note.filePath);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00695C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          note.title,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black54),
            onPressed: () => Share.shareXFiles([XFile(note.filePath)], text: note.title),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deleteNote(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: note.fileType == 'pdf'
              ? SfPdfViewer.file(file)
              : InteractiveViewer(
                  child: Image.file(file, fit: BoxFit.contain),
                ),
        ),
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<NoteProvider>();
      final fileService = FileService();
      await fileService.deleteFile(note.filePath);
      await provider.deleteNote(note.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
