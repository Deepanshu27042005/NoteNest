import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';
import 'note_options_screen.dart'; // Updated
import 'preview_scan_screen.dart';
import 'save_note_screen.dart';

class SubjectNotesScreen extends StatefulWidget {
  final String subject;

  const SubjectNotesScreen({super.key, required this.subject});

  @override
  State<SubjectNotesScreen> createState() => _SubjectNotesScreenState();
}

class _SubjectNotesScreenState extends State<SubjectNotesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
              initialSubject: widget.subject,
            ),
          ),
        );
      }
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00695C)),
              title: const Text('Scan with Camera'),
              onTap: () {
                Navigator.pop(context);
                _scanNote(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF00695C)),
              title: const Text('Import PDF'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                if (result != null && result.files.single.path != null && context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SaveNoteScreen(file: File(result.files.single.path!), fileType: 'pdf', initialSubject: widget.subject)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF00695C)),
              title: const Text('Import Image'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null && context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SaveNoteScreen(file: File(image.path), fileType: 'image', initialSubject: widget.subject)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareSubject(List<Note> notes) async {
    if (notes.isEmpty) return;
    final files = notes.map((n) => XFile(n.filePath)).toList();
    await Share.shareXFiles(files, text: 'Notes for ${widget.subject}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('NoteNest', style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        child: Consumer<NoteProvider>(
          builder: (context, provider, child) {
            final subjects = provider.notes.map((n) => n.subject).toSet().toList();
            return Column(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Color(0xFF00695C)),
                  child: Center(child: Text('Subject Library', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.folder_open, color: Color(0xFF00695C)),
                        title: Text(subjects[index]),
                        onTap: () {
                          Navigator.pop(context);
                          if (subjects[index] != widget.subject) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SubjectNotesScreen(subject: subjects[index])));
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Subjects', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Icon(Icons.chevron_right, size: 12, color: Colors.grey),
                Text(widget.subject, style: const TextStyle(fontSize: 12, color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.subject, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Consumer<NoteProvider>(
              builder: (context, provider, child) {
                final notes = provider.notes.where((n) => n.subject == widget.subject).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text('📄 ${notes.length} Notes Total', style: const TextStyle(color: Colors.grey)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _shareSubject(notes),
                                  icon: const Icon(Icons.share_outlined, size: 16),
                                  label: const Text('Share'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade100,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _scanNote(context),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('New Scan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00695C),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: notes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == notes.length) {
                          return GestureDetector(
                            onTap: () => _showAddOptions(context),
                            child: _buildAddMoreCard(widget.subject),
                          );
                        }
                        return _buildNoteCard(context, notes[index]);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NoteOptionsScreen(note: note)), // Updated to NoteOptionsScreen
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(note.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image, size: 32, color: const Color(0xFF00695C)),
              ),
            ),
            const SizedBox(height: 12),
            Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text('${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMoreCard(String subject) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Add more notes to', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          Text(subject, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
