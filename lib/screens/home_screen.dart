import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/note_provider.dart';
import 'save_note_screen.dart';
import 'preview_scan_screen.dart';
import 'all_notes_screen.dart';
import 'note_options_screen.dart'; // Updated
import 'subject_notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
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
            ),
          ),
        );
      }
    }
  }

  Future<void> _importPDF(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaveNoteScreen(
              file: File(result.files.single.path!),
              fileType: 'pdf',
            ),
          ),
        );
      }
    }
  }

  Future<void> _importImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaveNoteScreen(
              file: File(image.path),
              fileType: 'image',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFB),
        drawer: _buildDrawer(context),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeBody(context),
            const AllNotesScreen(),
            const Center(child: Text('Settings Screen Coming Soon')),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF00695C),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Notes'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Consumer<NoteProvider>(
        builder: (context, provider, child) {
          final subjects = provider.notes.map((n) => n.subject).toSet().toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF00695C)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_copy, color: Colors.white, size: 40),
                      SizedBox(height: 12),
                      Text(
                        'My Library',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('SUBJECTS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Expanded(
                child: subjects.isEmpty
                    ? const Center(child: Text('No subjects yet'))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.folder_open, color: Color(0xFF00695C)),
                            title: Text(subjects[index]),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubjectNotesScreen(subject: subjects[index]),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NoteNest',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                    ),
                    Text(
                      'Organize your thoughts, locally.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            TextField(
              readOnly: true,
              onTap: () => setState(() => _selectedIndex = 1),
              decoration: InputDecoration(
                hintText: 'Search notes, subjects, tags...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildActionCard(
              title: 'Scan Document',
              subtitle: 'Use camera to scan notes',
              icon: Icons.qr_code_scanner,
              color: const Color(0xFF00695C),
              isPrimary: true,
              onTap: () => _scanNote(context),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'Import PDF',
              subtitle: 'Add PDF from storage',
              icon: Icons.picture_as_pdf,
              color: Colors.white,
              iconColor: const Color(0xFF00695C),
              onTap: () => _importPDF(context),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'Import Image',
              subtitle: 'Add from gallery',
              icon: Icons.image,
              color: Colors.white,
              iconColor: const Color(0xFF00695C),
              onTap: () => _importImage(context),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subjects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('See all', style: TextStyle(color: Color(0xFF00695C))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSubjectsList(),

            const SizedBox(height: 32),

            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRecentNotesList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isPrimary = false,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: isPrimary ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withOpacity(0.2) : const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isPrimary ? Colors.white : (iconColor ?? Colors.black)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPrimary ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    return Consumer<NoteProvider>(
      builder: (context, provider, child) {
        final subjectsMap = <String, int>{};
        for (var note in provider.notes) {
          subjectsMap[note.subject] = (subjectsMap[note.subject] ?? 0) + 1;
        }

        if (subjectsMap.isEmpty) {
          return const Text('Start by adding your first note!', style: TextStyle(color: Colors.grey, fontSize: 14));
        }

        final subjects = subjectsMap.entries.toList();
        final colors = [const Color(0xFFE0F2F1), const Color(0xFFF3E5F5), const Color(0xFFFFF3E0), const Color(0xFFE8EAF6)];

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectNotesScreen(subject: subject.key),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subject.key,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.value} ${subject.value == 1 ? 'Note' : 'Notes'}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentNotesList() {
    return Consumer<NoteProvider>(
      builder: (context, provider, child) {
        if (provider.notes.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Icon(Icons.note_add_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('No recent activity', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final recentNotes = provider.notes.reversed.take(5).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentNotes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final note = recentNotes[index];
            return Card(
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NoteOptionsScreen(note: note)), // Updated to NoteOptionsScreen
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    note.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                    color: const Color(0xFF00695C),
                  ),
                ),
                title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${note.subject} • ${note.createdAt.day}/${note.createdAt.month}'),
                trailing: const Icon(Icons.chevron_right, size: 18),
              ),
            );
          },
        );
      },
    );
  }
}
