import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  ImageProvider _resolveProvider(String path) {
    if (path.isEmpty) {
      return const AssetImage("assets/images/placeholder.png");
    }

    // URL full
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }

    // file lokal hasil kamera
    if (File(path).existsSync()) {
      return FileImage(File(path));
    }

    // fallback: anggap asset
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _resolveProvider(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text(
          "Evidence Detail",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag, // ✅ harus sama dengan di screen sebelumnya
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image(
              image: provider,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (_, __, ___) {
                return const Text(
                  "Gambar gagal dimuat",
                  style: TextStyle(color: Colors.white),
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
