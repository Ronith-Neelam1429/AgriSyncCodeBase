import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PlantMaturityDetectorPage extends StatefulWidget {
  const PlantMaturityDetectorPage({Key? key}) : super(key: key);

  @override
  _PlantMaturityDetectorPageState createState() => _PlantMaturityDetectorPageState();
}

class _PlantMaturityDetectorPageState extends State<PlantMaturityDetectorPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  // Labels (from metadata.json)
  final List<String> _labels = ["Mature", "Over Mature"];

  // Pick an image from camera
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

  // Pick an image from gallery
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

  // Analyze image by compressing and sending it to your prediction API
  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Read and compress the image
      final imageBytes = await _imageFile!.readAsBytes();
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 224,
        minHeight: 224,
        quality: 60,
        format: CompressFormat.jpeg,
      );
      final base64Image = base64Encode(compressedBytes);
      final response = await http.post(
        Uri.parse('https://predictimage-k3urlognnq-uc.a.run.app?key=YOUR_API_KEY_HERE'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _predictionResult = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // Build the prediction result card with modern styling
  Widget _buildPredictionResult() {
    if (_predictionResult == null) return const SizedBox.shrink();

    // Convert predictions safely to double
    List<dynamic> rawPredictions = _predictionResult!['predictions'];
    List<double> predictions = rawPredictions.map((value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    }).toList();

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
    Color resultColor = result == "Mature" ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: resultColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(result == "Mature" ? Icons.check_circle : Icons.warning, color: resultColor, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: resultColor)),
                      Text('Confidence: ${confidence.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              result == "Mature"
                  ? 'This produce appears to be at optimal maturity for harvest.'
                  : 'This produce appears to be over mature and may need immediate attention.',
              style: const TextStyle(fontSize: 16),
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
        title: const Text('Plant Maturity Detector', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview container with modern card design.
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color.fromARGB(255,66,192,201), width: 2),
                  color: Colors.grey[50],
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          'No image selected',
                          style: TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
                      ),
              ),
            ),
            // Display error message if exists.
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            // Action buttons row.
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
                        
                        backgroundColor: const Color.fromARGB(255,66,192,201),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        backgroundColor: const Color.fromARGB(255,66,192,201),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Analyze Image button.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _imageFile != null && !_isLoading ? _analyzeImage : null,
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
                  backgroundColor: const Color.fromARGB(255,66,192,201),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // Display prediction result.
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
