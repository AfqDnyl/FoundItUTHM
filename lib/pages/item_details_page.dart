import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ItemDetailsPage extends StatelessWidget {
  final String itemName;
  final String description;
  final String imageUrl;
  final String itemId;
  final String contactInfo;

  ItemDetailsPage({
    required this.itemName,
    required this.description,
    required this.imageUrl,
    required this.itemId,
    required this.contactInfo,
  });

  Future<void> _saveQrCodeToGallery(BuildContext context) async {
    try {
      if (await Permission.storage.request().isGranted) {
        // Create a QR code painter
        final qrPainter = QrPainter(
          data: itemId,
          version: QrVersions.auto,
          gapless: false,
          color: Color(0xFF000000),
          emptyColor: Color(0xFFFFFFFF),
        );

        // Render the QR code to an image
        final pictureRecorder = ui.PictureRecorder();
        final canvas = Canvas(pictureRecorder);
        final size = Size(300, 300);
        qrPainter.paint(canvas, size);
        final image = await pictureRecorder.endRecording().toImage(300, 300);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        // Save the image to the gallery
        final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(pngBytes),
          quality: 100,
          name: itemName,
        );

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('QR code saved to gallery successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save QR code to gallery.')),
          );
        }
      } else if (await Permission.manageExternalStorage.request().isGranted) {
        // Handle MANAGE_EXTERNAL_STORAGE permission
        // This permission allows more extensive access to external storage
        // Ensure you handle this correctly and update the logic as needed.
        final qrPainter = QrPainter(
          data: itemId,
          version: QrVersions.auto,
          gapless: false,
          color: Color(0xFF000000),
          emptyColor: Color(0xFFFFFFFF),
        );

        // Render the QR code to an image
        final pictureRecorder = ui.PictureRecorder();
        final canvas = Canvas(pictureRecorder);
        final size = Size(300, 300);
        qrPainter.paint(canvas, size);
        final image = await pictureRecorder.endRecording().toImage(300, 300);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        // Save the image to the gallery
        final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(pngBytes),
          quality: 100,
          name: itemName,
        );

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('QR code saved to gallery successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save QR code to gallery.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission is required to save QR code.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(
                      imageUrl,
                      width: MediaQuery.of(context).size.width * 0.8,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    itemName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Contact Info: $contactInfo',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: QrImageView(
                      data: itemId,
                      version: QrVersions.auto,
                      size: 300.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _saveQrCodeToGallery(context),
                      child: Text('Save QR Code to Gallery'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}