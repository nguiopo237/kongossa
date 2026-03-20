import 'dart:io';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../sevice/gallery_service/auto_import.dart';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with WidgetsBindingObserver {
  final AutoGalleryImportService _importService = AutoGalleryImportService();
  List<String> _images = [];
  bool _isLoading = true;
  bool _isMonitoring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGallery();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Rafraîchir quand l'app revient au premier plan
      _refreshImages();
    }
  }

  Future<void> _initializeGallery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Nettoyer d'abord les fichiers invalides
      await _importService.cleanupInvalidImages();

      // Charger les images existantes
      _images = _importService.getImportedImages();

      // Importer les nouvelles images en arrière-plan
      _importService.importNewValidImages().then((newImages) {
        if (mounted) {
          setState(() {
            _images.addAll(newImages);
          });

          if (newImages.isNotEmpty) {
            _showSnackBar('${newImages.length} nouvelles photos importées');
          }
        }
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> newImages = await _importService.importNewValidImages();

      setState(() {
        _images = _importService.getImportedImages();
        _isLoading = false;
      });

      if (newImages.isNotEmpty) {
        _showSnackBar('${newImages.length} nouvelles photos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _importAllImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> allImages = await _importService.importAllValidImages();

      setState(() {
        _images = allImages;
        _isLoading = false;
      });

      _showSnackBar('${allImages.length} photos importées');

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Copier vers le répertoire de l'app
        Directory appDir = await getApplicationDocumentsDirectory();
        String fileName = 'picked_${DateTime.now().millisecondsSinceEpoch}.jpg';
        String newPath = '${appDir.path}/imported_images/$fileName';

        await Directory('${appDir.path}/imported_images').create(recursive: true);

        File newImage = await File(image.path).copy(newPath);

        setState(() {
          _images.add(newImage.path);
        });

        _showSnackBar('✅ Image importée');
      }
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', isError: true);
    }
  }

  void _toggleMonitoring() {
    if (_isMonitoring) {
      _importService.stopMonitoring();
    } else {
      _importService.startMonitoring(onNewImages: (newImages) {
        if (mounted) {
          setState(() {
            _images.addAll(newImages);
          });
          _showSnackBar('${newImages.length} nouvelles photos détectées');
        }
      });
    }

    setState(() {
      _isMonitoring = !_isMonitoring;
    });
  }

  Future<void> _showImageDetails(String imagePath) async {
    File file = File(imagePath);
    if (!await file.exists()) {
      _showSnackBar('Image introuvable', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Image.file(file),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await _importService.deleteImage(imagePath);
                      setState(() {
                        _images.remove(imagePath);
                      });
                      Navigator.pop(context);
                      _showSnackBar('Image supprimée');
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.info),
                    label: Text('Infos'),
                    onPressed: () {
                      _showFileInfo(file);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileInfo(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${file.path.split('/').last}'),
            Text('Taille: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB'),
            Text('Modifié: ${file.lastModifiedSync()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quitter'),
        content: Text('Voulez-vous vraiment quitter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('NON'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('OUI'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _importService.stopMonitoring();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ma Galerie'),
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isMonitoring ? Icons.notifications_active : Icons.notifications_none),
              onPressed: _toggleMonitoring,
              tooltip: _isMonitoring ? 'Désactiver auto' : 'Activer auto',
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshImages,
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Tout importer'),
                    onTap: () {
                      Navigator.pop(context);
                      _importAllImages();
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.delete_sweep),
                    title: Text('Nettoyer'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _importService.cleanupInvalidImages();
                      setState(() {
                        _images = _importService.getImportedImages();
                      });
                      _showSnackBar('Nettoyage terminé');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.deepPurple, Colors.white],
            ),
          ),
          child: _isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text('Chargement...', style: TextStyle(color: Colors.white)),
              ],
            ),
          )
              : _errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 20),
                Text('Erreur', style: TextStyle(fontSize: 20, color: Colors.white)),
                SizedBox(height: 10),
                Text(_errorMessage!, textAlign: TextAlign.center),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _initializeGallery,
                  child: Text('Réessayer'),
                ),
              ],
            ),
          )
              : _images.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 100, color: Colors.white70),
                SizedBox(height: 20),
                Text(
                  'Aucune image',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  'Importez des photos depuis votre galerie',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: Icon(Icons.photo),
                  label: Text('Importer toutes les photos'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: _importAllImages,
                ),
                SizedBox(height: 10),
                TextButton.icon(
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('Choisir une photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _pickImage,
                ),
              ],
            ),
          )
              : GridView.builder(
            padding: EdgeInsets.all(4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageDetails(_images[index]),
                child: Hero(
                  tag: _images[index],
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(_images[index])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickImage,
          child: Icon(Icons.add_photo_alternate),
          backgroundColor: Colors.deepPurple,
        ),
      ),
    );
  }
}