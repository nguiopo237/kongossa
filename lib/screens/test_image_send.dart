

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kongossa/screens/testsend.dart';

import '../presentation/component/widget/cloudinaryvideoplayer.dart';
import '../sevice/upload/upload_cloud.dart';
import '../sevice/upload/upload_compress_image.dart';
import 'package:path/path.dart' as path;

class CloudinaryExample extends StatefulWidget {
  @override
  _CloudinaryExampleState createState() => _CloudinaryExampleState();
}

class _CloudinaryExampleState extends State<CloudinaryExample> {
  final CloudinaryService _service = CloudinaryService();
  // final CloudinaryServices _services= CloudinaryServices();
   UniversalCloudinaryUploader _serviceall= UniversalCloudinaryUploader();
  final ImagePicker _picker = ImagePicker();

  List<String> _imageUrls = [];
  List<UploadResult> _uploadResults = [];
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _selectedFolder = 'flutter-tests';

  // Test de connexion à Cloudinary
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      final connected = await _service.testConnection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(connected
              ? '✅ Connecté à Cloudinary!'
              : '❌ Échec de connexion'),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );

      if (connected) {
        // Récupérer les images déjà uploadées
        await _fetchUploadedImages();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Récupérer les images déjà uploadées
  Future<void> _fetchUploadedImages() async {
    setState(() => _isLoading = true);

    try {
      final images = await _service.listImagesInFolder(folder: _selectedFolder!);
      setState(() {
        _imageUrls = images.map((img) => img.secureUrl).toList();
      });

      if (images.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${images.length} images trouvées'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Erreur récupération images: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Sélectionner une image depuis la galerie
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickMedia(

       // source: ImageSource.gallery,
      // // imageQuality: 85,
    );

    if (pickedFile != null) {
      print("special on");
      File file = File(pickedFile.path);
   final link  =   path.dirname(pickedFile.path);
   String originalName = path.basename(pickedFile.path);
   String originalNames = file.parent.path;

      print(link);
      print(originalName);
      print(originalNames);
      print(pickedFile.path);
    //  await _services.uploadImageSigned(imageFile: File(pickedFile.path));
      await _serviceall.uploadAnyFile(filePath: pickedFile.path, folder: "kogossa_app/secure",fileName:originalName );
      // await _uploadImage(File(pickedFile.path));
    }
  }

  // Prendre une photo avec la caméra
  Future<void> _takeAndUploadPhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path));
    }
  }

  // Uploader l'image vers Cloudinary
  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      print('📤 Début upload: ${imageFile.path}');

      // Upload avec progression
      final result = await _service.uploadImageFromFile(
        filePath: imageFile.path,
        folder: _selectedFolder!,
        fileName: 'flutter-${DateTime.now().millisecondsSinceEpoch}',
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      // Ajouter le résultat
      setState(() {
        _uploadResults.add(result);
        if (result.secureUrl != null) {
          _imageUrls.add(result.secureUrl!);
        }
      });

      // Afficher le résultat
      _showUploadResult(result);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('❌ Erreur upload: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // Afficher le résultat de l'upload
  void _showUploadResult(UploadResult result) {
    final title = result.success ? '✅ Upload réussi!' : '❌ Échec upload';
    final message = result.success
        ? 'Image uploadée avec succès\nTaille: ${(result.bytes! / 1024).toStringAsFixed(1)} KB\nDimensions: ${result.width}×${result.height}'
        : 'Erreur: ${result.errorMessage}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (result.publicId != null) ...[
              SizedBox(height: 10),
              Text('PublicId:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(result.publicId!),
            ],
            if (result.secureUrl != null) ...[
              SizedBox(height: 10),
              Text('URL:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(
                result.secureUrl!,
                style: TextStyle(fontSize: 10),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          if (result.secureUrl != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _copyToClipboard(result.secureUrl!);
              },
              child: Text('Copier URL'),
            ),
        ],
      ),
    );
  }

  // Copier dans le presse-papier
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('URL copiée!')),
    );
  }

  // Supprimer une image
  Future<void> _deleteImage(int index) async {
    if (index >= _uploadResults.length) return;

    final result = _uploadResults[index];
    if (result.publicId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'image?'),
        content: Text('Voulez-vous supprimer cette image de Cloudinary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              print(result.secureUrl.toString());
              //_services.deleteImage("https://res.cloudinary.com/dlzkp9dix/image/upload/v1770509900/kogossa_app/secure/signed_1770509896205.jpg.jpg");
            },
            child: Text('tester', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        final deleted = await _service.deleteImage(result.publicId!);

        if (deleted) {
          setState(() {
            _uploadResults.removeAt(index);
            if (index < _imageUrls.length) {
              _imageUrls.removeAt(index);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Upload multiple d'images
  Future<void> _uploadMultipleImages() async {
    final pickedFiles = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2000,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
      });

      int successCount = 0;
      int totalCount = pickedFiles.length;

      for (int i = 0; i < pickedFiles.length; i++) {
        final file = File(pickedFiles[i].path);
        // _services.uploadImageSigned(imageFile: file);
        setState(() {
          _uploadProgress = (i + 1) / totalCount;
        });

        try {
          final result = await _service.uploadImageFromFile(
            filePath: file.path,
            folder: '${_selectedFolder}/batch-${DateTime.now().millisecondsSinceEpoch}',
          );

          if (result.success) {
            successCount++;
            setState(() {
              _uploadResults.add(result);
              if (result.secureUrl != null) {
                _imageUrls.add(result.secureUrl!);
              }
            });
          }
        } catch (e) {
          print('Erreur upload ${file.path}: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $successCount/$totalCount images uploadées'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cloudinary 25 Go Gratuit'),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Contrôles principaux
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Sélecteur de dossier
                  Row(
                    children: [
                      Icon(Icons.folder, size: 20, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedFolder,
                          isExpanded: true,
                          items: [
                            'flutter-tests',
                            'produits',
                            'utilisateurs',
                            'bannières',
                            'temporaire',
                          ].map((folder) {
                            return DropdownMenuItem(
                              value: folder,
                              child: Text('Dossier: $folder'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedFolder = value);
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Boutons d'action
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Test connexion
                      ActionChip(
                        avatar: Icon(Icons.wifi, size: 18),
                        label: Text('Test Connexion'),
                        onPressed: _isLoading ? null : _testConnection,
                      ),

                      // Galerie
                      ActionChip(
                        avatar: Icon(Icons.photo_library, size: 18),
                        label: Text('Galerie'),
                        onPressed: _isLoading ? null : _pickAndUploadImage,
                      ),

                      // Caméra
                      ActionChip(
                        avatar: Icon(Icons.camera_alt, size: 18),
                        label: Text('Caméra'),
                        onPressed: _isLoading ? null : _takeAndUploadPhoto,
                      ),

                      // Multiple
                      ActionChip(
                        avatar: Icon(Icons.collections, size: 18),
                        label: Text('Multiple'),
                        onPressed: _isLoading ? null : _uploadMultipleImages,
                      ),

                      // Récupérer
                      ActionChip(
                        avatar: Icon(Icons.refresh, size: 18),
                        label: Text('Récupérer'),
                        onPressed: _isLoading ? null : _fetchUploadedImages,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Indicateur de progression
          if (_isLoading && _uploadProgress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),

          // Liste des images
          Expanded(
            child: _imageUrls.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  // Text(
                  //   'Aucune image uploadée',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     color: Colors.grey[600],
                  //     fontWeight: FontWeight.w300,
                  //   ),
                  // ),
                  Videoplayerpost(videoUrl: 'https://res.cloudinary.com/dlzkp9dix/video/upload/v1770597562/kogossa_app/secure/signed_1770597533667..mp4.mp4',),
                  SizedBox(height: 10),
                  Text(
                    'Utilisez les boutons ci-dessus pour uploader',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                final url = _imageUrls[index];
                final result = index < _uploadResults.length
                    ? _uploadResults[index]
                    : null;

                return Card(
                  elevation: 2,
                  child: Stack(
                    children: [
                      // Image
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                              imageUrl: ''
                            "https://res.cloudinary.com/dlzkp9dix/image/upload/v1770511431/kogossa_app/secure/signed_1770511429819.jpg.jpg",
                            fit: BoxFit.cover,

                          ),
                        ),
                      ),

                      // Overlay info
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (result != null && result.publicId != null)
                                Text(
                                  result.publicId!.split('/').last,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (result != null && result.bytes != null)
                                Text(
                                  '${(result.bytes! / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Bouton suppression
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, size: 18, color: Colors.white),
                            onPressed: () => _deleteImage(index),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),

                      // Badge succès/échec
                      if (result != null)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: result.success ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              result.success ? Icons.check : Icons.error,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Info Cloudinary gratuit
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(top: BorderSide(color: Colors.blue[100]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue, size: 40),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLOUDINARY GRATUIT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.green),
                          SizedBox(width: 5),
                          Text('25 Go stockage', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.green),
                          SizedBox(width: 5),
                          Text('25 Go bande passante/mois', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.green),
                          SizedBox(width: 5),
                          Text('CDN global', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text('${_imageUrls.length} images'),
                  backgroundColor: Colors.blue[100],
                ),
              ],
            ),
          ),
        ],
      ),

      // Bouton upload rapide
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickAndUploadImage,
        icon: Icon(Icons.cloud_upload),
        label: Text('Upload media'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}