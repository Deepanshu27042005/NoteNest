import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class TextExtractionService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Unified method to extract text based on file type
  Future<String> extractText(File file, String fileType) async {
    if (fileType == 'pdf') {
      return await _extractTextFromPdf(file);
    } else if (fileType == 'image') {
      return await _extractTextFromImage(file);
    }
    return '';
  }

  /// Extracts text from Image using Google ML Kit OCR
  Future<String> _extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    String text = recognizedText.text;
    return text.trim();
  }

  /// Extracts text from PDF using Syncfusion PDF
  Future<String> _extractTextFromPdf(File pdfFile) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      
      // If the PDF is scanned (empty text extraction), we return a placeholder 
      // or implement PDF-to-Image OCR in a later step.
      if (text.trim().isEmpty) {
        return "SCANNED_PDF_DETECTED"; 
      }
      
      return text.trim();
    } catch (e) {
      print("Error extracting text from PDF: $e");
      return '';
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
