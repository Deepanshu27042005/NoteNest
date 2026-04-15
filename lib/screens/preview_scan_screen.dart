import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'save_note_screen.dart';

class PreviewScanScreen extends StatefulWidget {
  final List<File> initialImages;
  final String? initialSubject;

  const PreviewScanScreen({
    super.key,
    required this.initialImages,
    this.initialSubject,
  });

  @override
  State<PreviewScanScreen> createState() => _PreviewScanScreenState();
}

class _PreviewScanScreenState extends State<PreviewScanScreen> {
  late List<File> _images;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _addMore() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  Future<void> _generatePdfAndSave() async {
    final pdf = pw.Document();

    for (var imageFile in _images) {
      final image = pw.MemoryImage(imageFile.readAsBytesSync());
      pdf.addPage(pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Image(image));
      }));
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/scanned_note_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SaveNoteScreen(
            file: file,
            fileType: 'pdf',
            initialSubject: widget.initialSubject,
            isFromScan: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: const Text('NoteNest', style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: Text('${_images.length} Pages Scanned', style: const TextStyle(color: Colors.grey))),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review Scans', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text('Ensure your notes are clear before finalizing the capture.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _images.length + 1,
              itemBuilder: (context, index) {
                if (index == _images.length) {
                  return GestureDetector(
                    onTap: _addMore,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.add_a_photo, color: Color(0xFF00695C)), SizedBox(height: 8), Text('Add more', style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold))],
                      ),
                    ),
                  );
                }
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_images[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text('PAGE ${index + 1}'.padLeft(2, '0'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Text('Retake All', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _images.isEmpty ? null : _generatePdfAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: Text('Save ${_images.length} Pages →', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
