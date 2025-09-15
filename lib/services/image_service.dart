import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageService {
  static Future<File> addWatermark(File imageFile, String watermarkText) async {
    try {
      // Read the image file
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) throw Exception('Could not decode image');

      // Create a copy of the image
      final img.Image watermarkedImage = img.Image.from(originalImage);
      
      // Add watermark text
      img.drawString(
        watermarkedImage,
        watermarkText,
        font: img.arial24,
        x: 10,
        y: watermarkedImage.height - 30,
        color: img.ColorRgba8(255, 255, 255, 180), // Semi-transparent white
      );

      // Add a semi-transparent overlay watermark in the center
      final centerX = (watermarkedImage.width / 2).round();
      final centerY = (watermarkedImage.height / 2).round();
      
      img.drawString(
        watermarkedImage,
        'Modern Trade Market',
        font: img.arial48,
        x: centerX - 150,
        y: centerY,
        color: img.ColorRgba8(255, 255, 255, 100), // More transparent
      );

      // Encode the watermarked image
      final List<int> watermarkedBytes = img.encodePng(watermarkedImage);
      
      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'watermarked_${DateTime.now().millisecondsSinceEpoch}.png';
      final File watermarkedFile = File('${tempDir.path}/$fileName');
      
      await watermarkedFile.writeAsBytes(watermarkedBytes);
      return watermarkedFile;
    } catch (e) {
      print('Error adding watermark: $e');
      return imageFile; // Return original if watermarking fails
    }
  }

  static Future<List<File>> addWatermarkToMultiple(List<File> imageFiles) async {
    List<File> watermarkedFiles = [];
    
    for (File imageFile in imageFiles) {
      final watermarkedFile = await addWatermark(imageFile, 'MTM');
      watermarkedFiles.add(watermarkedFile);
    }
    
    return watermarkedFiles;
  }
}