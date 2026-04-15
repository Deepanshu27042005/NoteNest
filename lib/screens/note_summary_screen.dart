import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../services/text_extraction_service.dart';
import '../services/ai_service.dart';

class NoteSummaryScreen extends StatefulWidget {
  final Note note;

  const NoteSummaryScreen({super.key, required this.note});

  @override
  State<NoteSummaryScreen> createState() => _NoteSummaryScreenState();
}

class _NoteSummaryScreenState extends State<NoteSummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGenerating = false;
  final TextExtractionService _extractionService = TextExtractionService();
  final AiService _aiService = AiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _extractionService.dispose();
    super.dispose();
  }

  Future<void> _generateSmartRevision() async {
    setState(() => _isGenerating = true);

    try {
      final file = File(widget.note.filePath);
      final text = await _extractionService.extractText(file, widget.note.fileType);

      if (text.isEmpty || text == "SCANNED_PDF_DETECTED") {
        throw "Could not extract text. Please ensure the document is clear.";
      }

      final revision = await _aiService.getSmartRevision(text);

      if (revision != null) {
        final note = widget.note;
        note.aiSummary = revision['summary'];
        note.aiKeyPoints = List<String>.from(revision['keyPoints'] ?? []);
        note.aiFormulas = List<String>.from(revision['formulas'] ?? []);
        note.aiKeywords = List<String>.from(revision['keywords'] ?? []);
        note.aiDefinitions = List<String>.from(revision['definitions'] ?? []);
        note.aiGeneratedAt = DateTime.now();

        await context.read<NoteProvider>().updateNote(note);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Smart Revision Generated!')),
          );
          _tabController.animateTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _editSection(String title, String? currentText, Function(String) onSave) {
    final controller = TextEditingController(text: currentText);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Edit $title", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  onSave(controller.text);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), foregroundColor: Colors.white),
                child: const Text("Save Changes"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final hasAiData = note.aiSummary != null;

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
          if (hasAiData)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF00695C)),
              onPressed: _isGenerating ? null : _generateSmartRevision,
            ),
          const SizedBox(width: 8),
        ],
        bottom: hasAiData && !_isGenerating
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF00695C),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF00695C),
                tabs: const [
                  Tab(text: 'Summary'),
                  Tab(text: 'Key Points'),
                  Tab(text: 'Formulas'),
                  Tab(text: 'Keywords'),
                  Tab(text: 'Definitions'),
                ],
              )
            : null,
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00695C)),
                  SizedBox(height: 16),
                  Text("Building your textbook guide...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : !hasAiData
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 24),
                      const Text(
                        "No smart revision yet.",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Transform your notes into a\ndetailed topic-wise guide.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _generateSmartRevision,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Generate Smart Revision"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00695C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Summary with Pictures
                    _buildSummaryTab(note),

                    // Tab 2: Key Points
                    _buildAiListTab(
                      title: 'Detailed Takeaways',
                      items: note.aiKeyPoints,
                      icon: Icons.tips_and_updates_outlined,
                      onEdit: () => _editSection("Key Points", note.aiKeyPoints?.join("\n"), (val) async {
                        note.aiKeyPoints = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
                        await context.read<NoteProvider>().updateNote(note);
                        setState(() {});
                      }),
                    ),

                    // Tab 3: Formulas
                    _buildAiFormulaTab(
                      title: 'Key Formulas & Logic',
                      items: note.aiFormulas,
                      onEdit: () => _editSection("Formulas", note.aiFormulas?.join("\n"), (val) async {
                        note.aiFormulas = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
                        await context.read<NoteProvider>().updateNote(note);
                        setState(() {});
                      }),
                    ),

                    // Tab 4: Keywords
                    _buildAiChipTab(
                      title: 'Core Concepts',
                      items: note.aiKeywords,
                      onEdit: () => _editSection("Keywords", note.aiKeywords?.join("\n"), (val) async {
                        note.aiKeywords = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
                        await context.read<NoteProvider>().updateNote(note);
                        setState(() {});
                      }),
                    ),

                    // Tab 5: Definitions
                    _buildAiListTab(
                      title: 'Academic Glossary',
                      items: note.aiDefinitions,
                      icon: Icons.book_outlined,
                      onEdit: () => _editSection("Definitions", note.aiDefinitions?.join("\n"), (val) async {
                        note.aiDefinitions = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
                        await context.read<NoteProvider>().updateNote(note);
                        setState(() {});
                      }),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryTab(Note note) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Topic Header Image (Dynamic from Unsplash based on Subject)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              'https://source.unsplash.com/featured/?${note.subject},education,study',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.teal.shade50,
                child: const Icon(Icons.menu_book, size: 50, color: Color(0xFF00695C)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Topic-Wise Analysis', onEdit: () => _editSection("Summary", note.aiSummary, (val) async {
            note.aiSummary = val;
            await context.read<NoteProvider>().updateNote(note);
            setState(() {});
          })),
          const SizedBox(height: 16),
          
          // 2. The Detailed AI Summary
          Text(
            note.aiSummary ?? '',
            style: const TextStyle(fontSize: 16, height: 1.7, color: Colors.black87),
          ),
          const SizedBox(height: 32),

          // 3. Visual Context (The original Scan)
          const Text('Original Scan Context', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          if (note.fileType == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(note.filePath), height: 300, width: double.infinity, fit: BoxFit.contain),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 12),
                  Text('View PDF context in Document tab'),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAiListTab({required String title, List<String>? items, IconData icon = Icons.check_circle_outline, VoidCallback? onEdit}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, onEdit: onEdit),
          const SizedBox(height: 16),
          if (items != null)
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 20, color: const Color(0xFF00695C)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item, style: const TextStyle(fontSize: 16, height: 1.4))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildAiFormulaTab({required String title, List<String>? items, VoidCallback? onEdit}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, onEdit: onEdit),
          const SizedBox(height: 16),
          if (items != null && items.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF5F7F8), borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: items
                    .map((f) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.functions, color: Colors.blue, size: 22),
                              const SizedBox(width: 12),
                              Expanded(child: Text(f, style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            )
          else
            const Center(child: Text('No formulas detected.', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildAiChipTab({required String title, List<String>? items, VoidCallback? onEdit}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, onEdit: onEdit),
          const SizedBox(height: 16),
          if (items != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((tag) => _buildChip(tag)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        if (onEdit != null) IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey), onPressed: onEdit),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Text("#$label", style: const TextStyle(fontSize: 13, color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
    );
  }
}
