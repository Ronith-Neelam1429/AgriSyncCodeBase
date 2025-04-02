import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class PlantMaturityDetectorPage extends StatefulWidget {
  const PlantMaturityDetectorPage({Key? key}) : super(key: key);

  @override
  _PlantMaturityDetectorPageState createState() =>
      _PlantMaturityDetectorPageState();
}

class _PlantMaturityDetectorPageState extends State<PlantMaturityDetectorPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  // Labels from metadata.json
  final List<String> _labels = ["Mature", "Over Mature"];

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
        _predictionResult = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _selectFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _predictionResult = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
  if (_imageFile == null) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Read the image bytes
    final imageBytes = await _imageFile!.readAsBytes();
    
    // Use flutter_image_compress more efficiently by compressing to bytes directly
    final compressedBytes = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 224,
      minHeight: 224,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    
    // Split the image into chunks if it's still too large
    final base64Image = base64Encode(compressedBytes);
    
    // If the image is still large, consider splitting it into chunks
    if (base64Image.length > 500000) {
      // Use the chunk-based upload approach
      await _uploadInChunks(compressedBytes);
    } else {
      // Use the direct approach for smaller images
      final response = await http.post(
        Uri.parse('https://us-central1-agrisync-9f9e5.cloudfunctions.net/predictImage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 60)); // Increase timeout
      
      if (response.statusCode == 200) {
        setState(() {
          _predictionResult = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error analyzing image: $e';
      _isLoading = false;
    });
  }
}

// New function to handle larger images by splitting them into chunks
Future<void> _uploadInChunks(List<int> imageBytes) async {
  final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final chunkSize = 250000; // ~250KB chunks
  final totalChunks = (imageBytes.length / chunkSize).ceil();
  
  try {
    // Upload each chunk
    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (i + 1) * chunkSize > imageBytes.length 
          ? imageBytes.length 
          : (i + 1) * chunkSize;
      
      final chunk = imageBytes.sublist(start, end);
      final base64Chunk = base64Encode(chunk);
      
      // Send chunk
      final response = await http.post(
        Uri.parse('https://us-central1-agrisync-9f9e5.cloudfunctions.net/uploadImageChunk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'chunkIndex': i,
          'totalChunks': totalChunks,
          'chunk': base64Chunk
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to upload chunk $i');
      }
    }
    
    // Process the complete image once all chunks are uploaded
    final response = await http.post(
      Uri.parse('https://us-central1-agrisync-9f9e5.cloudfunctions.net/processSessionImage'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sessionId': sessionId}),
    );
    
    if (response.statusCode == 200) {
      setState(() {
        _predictionResult = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to process image: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error uploading image chunks: $e';
      _isLoading = false;
    });
  }
}
  Widget _buildPredictionResult() {
    if (_predictionResult == null) return const SizedBox.shrink();

    // Get prediction data
    List<double> predictions =
        List<double>.from(_predictionResult!['predictions']);

    // Find highest confidence prediction
    int maxIndex = 0;
    double maxValue = predictions[0];

    for (int i = 1; i < predictions.length; i++) {
      if (predictions[i] > maxValue) {
        maxValue = predictions[i];
        maxIndex = i;
      }
    }

    String result = _labels[maxIndex];
    double confidence = maxValue * 100;

    // Build result UI
    Color resultColor = result == "Mature" ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Analysis Result',
              style: Theme.of(context as BuildContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  result == "Mature" ? Icons.check_circle : Icons.warning,
                  color: resultColor,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: resultColor,
                        ),
                      ),
                      Text(
                        'Confidence: ${confidence.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              result == "Mature"
                  ? 'This fruit/vegetable appears to be at optimal maturity for harvest.'
                  : 'This fruit/vegetable appears to be over mature and may need immediate attention.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Maturity Detector'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            Container(
              height: 300,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),

            // Error message if any
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Analyze button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed:
                    _imageFile != null && !_isLoading ? _analyzeImage : null,
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Analyzing...' : 'Analyze Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            // Results
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildPredictionResult(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
