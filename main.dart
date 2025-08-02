import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() {
  runApp(const PhotoSenderApp());
}

class PhotoSenderApp extends StatelessWidget {
  const PhotoSenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Sender',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const PhotoSenderHomePage(),
    );
  }
}

class PhotoSenderHomePage extends StatefulWidget {
  const PhotoSenderHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PhotoSenderHomePageState createState() => _PhotoSenderHomePageState();
}

class _PhotoSenderHomePageState extends State<PhotoSenderHomePage> {
  final TextEditingController _ipController = TextEditingController();
  List<File>? _images;
  String? _statusMessage;
  bool _isSending = false;
  final String _currentTime = DateTime.now()
      .toUtc()
      .add(const Duration(hours: 5, minutes: 45))
      .toString()
      .split('.')[0];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images =
            pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
        _statusMessage = 'Selected ${pickedFiles.length} images';
      });
    } else {
      setState(() {
        _statusMessage = 'No images selected';
      });
    }
  }

  Future<void> _sendImages() async {
    if (_images == null || _images!.isEmpty) {
      setState(() {
        _statusMessage = 'Please select at least one image';
      });
      return;
    }

    if (_ipController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter the laptop IP address';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = 'Sending images...';
    });

    final uri = Uri.parse('http://${_ipController.text}:5000/upload');
    final request = http.MultipartRequest('POST', uri);
    for (var image in _images!) {
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          _isSending = false;
          _statusMessage =
              'Images sent! Access at http://${_ipController.text}:5000/download';
        });
      } else {
        setState(() {
          _isSending = false;
          _statusMessage = 'Failed to send: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Photo to Laptop'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'Laptop IP Address (e.g., 192.168.1.9)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.computer),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_images != null && _images!.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images!.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.file(
                                _images![index],
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('No images selected'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Images'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current Time: $_currentTime (UTC+5:45)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendImages,
              icon: _isSending
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.send),
              label: const Text('Send Images'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(fontSize: 18),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage != null)
              Card(
                color: _statusMessage!.contains('Error') ||
                        _statusMessage!.contains('Failed') ||
                        _statusMessage!.contains('Please')
                    ? Colors.red[100]
                    : Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _statusMessage!.contains('Error') ||
                                _statusMessage!.contains('Failed') ||
                                _statusMessage!.contains('Please')
                            ? Icons.error
                            : Icons.check_circle,
                        color: _statusMessage!.contains('Error') ||
                                _statusMessage!.contains('Failed') ||
                                _statusMessage!.contains('Please')
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _statusMessage!.contains('Error') ||
                                    _statusMessage!.contains('Failed') ||
                                    _statusMessage!.contains('Please')
                                ? Colors.red
                                : Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
