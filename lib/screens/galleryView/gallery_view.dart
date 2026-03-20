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
  int _totalInGallery = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGallery();
    _loadGalleryStats();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshImages();
      _loadGalleryStats();
    }
  }

  Future<void> _loadGalleryStats() async {
    _totalInGallery = await _importService.countImagesInGallery();
    if (mounted) setState(() {});
  }

  Future<void> _initializeGallery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _importService.cleanupInvalidImages();
      _images = _importService.getImportedImages();

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
    setState(() => _isLoading = true);
    try {
      List<String> newImages = await _importService.importNewValidImages();
      setState(() {
        _images = _importService.getImportedImages();
        _isLoading = false;
      });
      if (newImages.isNotEmpty) {
        _showSnackBar('${newImages.length} nouvelles photos');
      }
      await _loadGalleryStats();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _importAllImages() async {
    // Afficher la boîte de dialogue de confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous importer TOUTES les images de votre galerie ?'),
            SizedBox(height: 10),
            Text('📊 Dans la galerie: $_totalInGallery images'),
            Text('✅ Déjà importées: ${_images.length} images'),
            Text('📦 À importer: ${_totalInGallery - _images.length} images'),
            SizedBox(height: 10),
            Text(
              'Cette opération peut prendre plusieurs minutes.',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('IMPORTER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher la boîte de progression
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Importation en cours...'),
              Text('Ne fermez pas l\'application'),
            ],
          ),
        ),
      ),
    );

    setState(() => _isLoading = true);

    try {
      List<String> allImages = await _importService.importAllValidImages();

      Navigator.pop(context); // Fermer la boîte de progression

      setState(() {
        _images = allImages;
        _isLoading = false;
      });

      await _loadGalleryStats();
      _showSnackBar('✅ ${allImages.length} photos importées');
    } catch (e) {
      Navigator.pop(context); // Fermer la boîte de progression
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: $e';
      });
      _showSnackBar('❌ Erreur: $e', isError: true);
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
        Directory appDir = await getApplicationDocumentsDirectory();
        String fileName = 'picked_${DateTime.now().millisecondsSinceEpoch}.jpg';
        String newPath = '${appDir.path}/imported_images/$fileName';

        await Directory('${appDir.path}/imported_images').create(recursive: true);
        File newImage = await File(image.path).copy(newPath);

        setState(() {
          _images.add(newImage.path);
        });

        _showSnackBar('✅ Image importée');
        await _loadGalleryStats();
      }
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', isError: true);
    }
  }

  void _toggleMonitoring() {
    if (_isMonitoring) {
      _importService.stopMonitoring();
      _showSnackBar('Surveillance désactivée');
    } else {
      _importService.startMonitoring(onNewImages: (newImages) {
        if (mounted) {
          setState(() {
            _images.addAll(newImages);
          });
          _showSnackBar('${newImages.length} nouvelles photos détectées');
          _loadGalleryStats();
        }
      });
      _showSnackBar('Surveillance activée');
    }
    setState(() {
      _isMonitoring = !_isMonitoring;
    });
  }

  Future<void> _showStats() async {
    int totalInGallery = await _importService.countImagesInGallery();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 Statistiques'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('📸 Dans la galerie:', '$totalInGallery images'),
            _buildStatRow('✅ Déjà importées:', '${_images.length} images'),
            _buildStatRow('📦 Restantes:', '${totalInGallery - _images.length} images'),
            _buildStatRow('📁 Surveillance:', _isMonitoring ? 'Active' : 'Inactive'),
            if (_images.isNotEmpty)
              _buildStatRow('💾 Espace utilisé:', _calculateTotalSize()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('FERMER'),
          ),
          if (_images.length < totalInGallery)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _importAllImages();
              },
              child: Text('IMPORTER TOUT'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  String _calculateTotalSize() {
    int totalBytes = 0;
    for (String path in _images) {
      try {
        totalBytes += File(path).lengthSync();
      } catch (e) {}
    }
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<void> _showImageDetails(String imagePath) async {
    File file = File(imagePath);
    if (!await file.exists()) {
      _showSnackBar('Image introuvable', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(file, height: 200, fit: BoxFit.cover),
            ),
            SizedBox(height: 10),
            Text(
              file.path.split('/').last,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: Icon(Icons.data_usage),
              title: Text('Taille: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB'),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Modifié: ${file.lastModifiedSync().toString().substring(0, 16)}'),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
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
                      await _loadGalleryStats();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Future<void> _cleanupImages() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🧹 Nettoyage'),
        content: Text('Voulez-vous supprimer les images corrompues ou invalides ?'),
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
    );

    if (confirm == true) {
      await _importService.cleanupInvalidImages();
      setState(() {
        _images = _importService.getImportedImages();
      });
      _showSnackBar('Nettoyage terminé');
      await _loadGalleryStats();
    }
  }

  @override
  void dispose() {
    _importService.stopMonitoring();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ma Galerie'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.stacked_bar_chart),
            onPressed: _showStats,
            tooltip: 'Statistiques',
          ),
          IconButton(
            icon: Icon(_isMonitoring ? Icons.notifications_active : Icons.notifications_none),
            onPressed: _toggleMonitoring,
            tooltip: _isMonitoring ? 'Désactiver auto' : 'Activer auto',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshImages,
            tooltip: 'Rafraîchir',
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
                  onTap: () {
                    Navigator.pop(context);
                    _cleanupImages();
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
    );
  }
}