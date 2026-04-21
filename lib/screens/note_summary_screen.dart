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
    _tabController = TabController(length: 6, vsync: this);
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
        note.aiShortQuestions = List<String>.from(revision['shortQuestions'] ?? []);
        note.aiLongQuestions = List<String>.from(revision['longQuestions'] ?? []);
        note.aiGeneratedAt = DateTime.now();

        await context.read<NoteProvider>().updateNote(note);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assessment & Guide Generated!')),
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
              maxLines: 8,
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
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D1D1D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          note.title,
          style: const TextStyle(color: Color(0xFF1D1D1D), fontSize: 18, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (hasAiData)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00695C)),
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
                indicatorWeight: 4,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Summary'),
                  Tab(text: 'Key Points'),
                  Tab(text: 'Formulas'),
                  Tab(text: 'Questions'),
                  Tab(text: 'Keywords'),
                  Tab(text: 'Definitions'),
                ],
              )
            : null,
      ),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00695C)),
                  const SizedBox(height: 24),
                  Text(
                    "Building your study guide...",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : !hasAiData
              ? _buildGenerateView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(note),
                    _buildAiListTab(
                      title: 'Key Takeaways',
                      items: note.aiKeyPoints,
                      icon: Icons.lightbulb_outline_rounded,
                      onEdit: () => _editSection("Key Points", note.aiKeyPoints?.join("\n"), (val) async {
                        note.aiKeyPoints = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
                        await context.read<NoteProvider>().updateNote(note);
                        setState(() {});
                      }),
                    ),
                    _buildAiFormulaTab(
                      title: 'Formulas & Logic',
                      items: note.aiFormulas,
                      onEdit: () => _editSection("Formulas", note.aiFormulas?.join("\n"), (val) async {
                        note.aiFormulas = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
                        await context.read<NoteProvider>().updateNote(note);
                        setState(() {});
                      }),
                    ),
                    _buildQuestionsTab(note),
                    _buildAiChipTab(
                      title: 'Core Concepts',
                      items: note.aiKeywords,
                      onEdit: () => _editSection("Keywords", note.aiKeywords?.join("\n"), (val) async {
                        note.aiKeywords = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
                        await context.read<NoteProvider>().updateNote(note);
                        setState(() {});
                      }),
                    ),
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

  Widget _buildGenerateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, size: 64, color: Color(0xFF00695C)),
            ),
            const SizedBox(height: 32),
            const Text("Transform Your Notes", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "Let NoteNest AI analyze your notes to generate topic-wise summaries, formulas, and test questions.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: _generateSmartRevision,
                icon: const Icon(Icons.auto_awesome),
                label: const Text("Generate Smart Revision", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(Note note) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header Card (Replaced unstable image with modern gradient card)
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00695C), Color(0xFF004D40)],
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 10))],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30, top: -30,
                  child: Icon(Icons.auto_awesome, size: 180, color: Colors.white.withOpacity(0.08)),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text(note.subject.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 12),
                      const Text("In-Depth Study Guide", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          _buildSectionHeader('Topic-Wise Analysis', onEdit: () => _editSection("Summary", note.aiSummary, (val) async {
            note.aiSummary = val;
            await context.read<NoteProvider>().updateNote(note);
            setState(() {});
          })),
          const SizedBox(height: 24),

          // High-Quality Summary Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _parseSummary(note.aiSummary ?? ''),
            ),
          ),
          
          const SizedBox(height: 40),
          const Text('Reference Metadata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D1D1D))),
          const SizedBox(height: 16),
          _buildSourceContext(note),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _parseSummary(String text) {
    List<Widget> widgets = [];
    final lines = text.split('\n');
    for (var line in lines) {
      String trimmed = line.trim();
      if (trimmed.startsWith('##')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 12),
          child: Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF00695C), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: Text(trimmed.replaceAll('##', '').trim(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF00695C)))),
            ],
          ),
        ));
      } else if (trimmed.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(trimmed, style: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF37474F), letterSpacing: 0.1)),
        ));
      }
    }
    return widgets;
  }

  Widget _buildSourceContext(Note note) {
    if (note.fileType == 'image') {
      return ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(note.filePath), width: double.infinity, fit: BoxFit.fitWidth));
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: const Row(children: [Icon(Icons.description_rounded, color: Color(0xFF00695C), size: 36), SizedBox(width: 16), Text("Source: Academic PDF Document", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 15))]),
    );
  }

  Widget _buildQuestionsTab(Note note) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Practice Questions', onEdit: () => _editSection("Short Questions", note.aiShortQuestions?.join("\n"), (val) async {
            note.aiShortQuestions = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
            await context.read<NoteProvider>().updateNote(note);
            setState(() {});
          })),
          const SizedBox(height: 24),
          if (note.aiShortQuestions != null)
            ...note.aiShortQuestions!.asMap().entries.map((entry) => _buildQuestionCard(entry.key + 1, entry.value, const Color(0xFFE0F2F1), 'SHORT')),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Descriptive Study', onEdit: () => _editSection("Long Questions", note.aiLongQuestions?.join("\n"), (val) async {
            note.aiLongQuestions = val.split("\n").where((e) => e.trim().isNotEmpty).toList();
            await context.read<NoteProvider>().updateNote(note);
            setState(() {});
          })),
          const SizedBox(height: 24),
          if (note.aiLongQuestions != null)
            ...note.aiLongQuestions!.asMap().entries.map((entry) => _buildQuestionCard(entry.key + 1, entry.value, const Color(0xFFFFF3E0), 'LONG')),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, String question, Color color, String tag) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Text(index.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF004D40)))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)), child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5))),
            ],
          ),
          const SizedBox(height: 14),
          Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5, color: Color(0xFF263238))),
        ],
      ),
    );
  }

  Widget _buildAiListTab({required String title, List<String>? items, IconData icon = Icons.check_circle_outline, VoidCallback? onEdit}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, onEdit: onEdit),
          const SizedBox(height: 24),
          if (items != null)
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 22, color: const Color(0xFF00695C)),
                  const SizedBox(width: 18),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF455A64)))),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildAiFormulaTab({required String title, List<String>? items, VoidCallback? onEdit}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, onEdit: onEdit),
          const SizedBox(height: 24),
          if (items != null && items.isNotEmpty)
            ...items.map((f) => Container(
              width: double.infinity, margin: const EdgeInsets.only(bottom: 18), padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))]),
              child: Row(children: [const Icon(Icons.functions_rounded, color: Color(0xFF80DEEA), size: 30), const SizedBox(width: 20), Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8)))]),
            )).toList()
          else
            const Center(child: Text('No formulas detected.', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildAiChipTab({required String title, List<String>? items, VoidCallback? onEdit}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, onEdit: onEdit),
          const SizedBox(height: 24),
          if (items != null) Wrap(spacing: 14, runSpacing: 14, children: items.map((tag) => _buildChip(tag)).toList()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [Container(width: 6, height: 30, decoration: BoxDecoration(color: const Color(0xFF00695C), borderRadius: BorderRadius.circular(4))), const SizedBox(width: 16), Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1D1D1D), letterSpacing: -0.5))]),
        if (onEdit != null) IconButton(icon: const Icon(Icons.edit_rounded, size: 24, color: Colors.grey), onPressed: onEdit),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00695C).withOpacity(0.4)), boxShadow: [BoxShadow(color: const Color(0xFF00695C).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Text("#$label", style: const TextStyle(fontSize: 15, color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
    );
  }
}
