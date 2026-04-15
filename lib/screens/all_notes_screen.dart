import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';
import 'note_options_screen.dart'; // Updated
import 'preview_scan_screen.dart';

class AllNotesScreen extends StatefulWidget {
  const AllNotesScreen({super.key});

  @override
  State<AllNotesScreen> createState() => _AllNotesScreenState();
}

class _AllNotesScreenState extends State<AllNotesScreen> {
  String _searchQuery = '';

  Future<void> _scanNote(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScanScreen(
              initialImages: [File(image.path)],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('NoteNest', style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Organized scan of your academic journey.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF80DEEA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sort, size: 18),
                          SizedBox(width: 4),
                          Text('Recent', style: TextStyle(fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<NoteProvider>(
              builder: (context, provider, child) {
                final notes = provider.searchNotes(_searchQuery);
                
                if (notes.isEmpty) {
                  return const Center(child: Text('No notes found in your library.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(context, note);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanNote(context),
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NoteOptionsScreen(note: note)), // Updated to NoteOptionsScreen
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Center(
                child: Icon(
                  note.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                  size: 48,
                  color: const Color(0xFF00695C),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            note.subject,
            style: const TextStyle(fontSize: 12, color: Color(0xFF00695C), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const Icon(Icons.more_vert, size: 16, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
