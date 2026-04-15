import 'dart:io';
import 'package:flutter/material.dart';
import '../models/note.dart';
import 'note_detail_screen.dart'; // This will be our "Read Full" viewer
import 'note_summary_screen.dart'; // We will create this next

class NoteOptionsScreen extends StatelessWidget {
  final Note note;

  const NoteOptionsScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(note.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How would you like to proceed?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose an option to interact with your note.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            // Option 1: Read Full Document
            _buildOptionCard(
              context,
              title: "Read Full Document",
              subtitle: "Open the complete PDF or Image in high resolution.",
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF00695C),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Option 2: Generate Summary
            _buildOptionCard(
              context,
              title: "AI Smart Summary",
              subtitle: "Extract key points, formulas, and context automatically.",
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF80DEEA),
              isDarkIcon: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NoteSummaryScreen(note: note)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDarkIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
