import 'package:flutter/material.dart';

import '../../../firestore_service.dart';
import '../../../layouts/admin_layout.dart';
// Note: Assuming a helper for Cloudinary exists, if not I'll just use a direct image URL input or placeholder for now to avoid complexity without known helper.
// Searching the codebase earlier for "cloudinary" only yielded pubspec.
// I will implement a dialog that accepts an Image URL text field for simplicity,
// OR simpler yet, basic file picker and a mock upload if real one isn't readily available.
// Given "cloudinary_public" is in pubspec, I can try to use it if I key is available, but I don't see it.
// I will stick to "Image URL" input for MVP as user didn't provide keys.
// Wait, I can allow picking an image and assume we might store it or just ask for URL.
// Let's use URL input for stability.

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _imageController = TextEditingController();
  final _buttonTextController = TextEditingController();
  final _orderController = TextEditingController();

  bool _isUploading = false;
  String? _selectedCategory; // Defined here
  final ImagePicker _picker = ImagePicker();
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'drwoht0pd',
    'presets',
    cache: false,
  );

  void _showAddBannerDialog({Map<String, dynamic>? banner}) {
    if (banner != null) {
      _titleController.text = banner['title'] ?? '';
      _subtitleController.text = banner['subtitle'] ?? '';
      _imageController.text = banner['image'] ?? '';
      _buttonTextController.text = banner['buttonText'] ?? '';
      _orderController.text = (banner['order'] ?? 0).toString();
      _selectedCategory = banner['categoryId']; // Load existing category
    } else {
      _titleController.clear();
      _subtitleController.clear();
      _imageController.clear();
      _buttonTextController.clear();
      _orderController.text = '0';
      _selectedCategory = null; // Reset
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(banner == null ? 'Add Banner' : 'Edit Banner'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(labelText: 'Subtitle'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  // Dynamic Category Dropdown
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService.getAllCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final categories = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration:
                            const InputDecoration(labelText: 'Category (Link)'),
                        hint: const Text('Select a category to link'),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['id'],
                            child: Text(cat['name'] ?? 'Unnamed'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        // Optional: Allow null if they don't want to link?
                        // User asked "can we direct", implies optional or required. keeping optional for flexibility or required if user insists.
                        // For now, let's make it optional.
                      );
                    },
                  ),

                  const SizedBox(height: 16), // Add some spacing
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            hintText: 'https://example.com/image.jpg',
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      IconButton(
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        onPressed: _isUploading
                            ? null
                            : () async {
                                // We need to handle state inside the dialog
                                // But _pickAndUploadImage updates the main widget state
                                // We need to trigger rebuild here.
                                // Simplest way: await it and then setDialogState
                                // But _pickAndUploadImage uses main setState.
                                // Let's simplify: call method, pass callback?
                                // Or better: refactor _pickAndUploadImage to return URL or throw.
                                // For now, I'll inline the logic briefly or rely on the controller update + setDialogState.

                                // Actually, since the dialog might not rebuild if I setState on the parent,
                                // I should probably move the UI logic inside `StatefulBuilder`.

                                try {
                                  final XFile? pickedFile = await _picker
                                      .pickImage(source: ImageSource.gallery);
                                  if (pickedFile == null) return;

                                  setDialogState(() => _isUploading = true);

                                  final response = await _cloudinary.uploadFile(
                                    CloudinaryFile.fromFile(
                                      pickedFile.path,
                                      resourceType:
                                          CloudinaryResourceType.Image,
                                    ),
                                  );

                                  _imageController.text = response.secureUrl;
                                  setDialogState(() => _isUploading = false);
                                } catch (e) {
                                  setDialogState(() => _isUploading = false);
                                  print(e); // Simple log
                                }
                              },
                        tooltip: 'Upload from Gallery',
                      ),
                    ],
                  ),
                  if (_imageController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Image.network(
                        _imageController.text,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) =>
                            const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ],
                  TextFormField(
                    controller: _buttonTextController,
                    decoration: const InputDecoration(labelText: 'Button Text'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _orderController,
                    decoration:
                        const InputDecoration(labelText: 'Order (Sort)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        final data = {
                          'title': _titleController.text,
                          'subtitle': _subtitleController.text,
                          'image': _imageController.text,
                          'buttonText': _buttonTextController.text,
                          'order': int.tryParse(_orderController.text) ?? 0,
                          'isActive': true,
                          'categoryId':
                              _selectedCategory, // Save selected category
                        };

                        try {
                          Navigator.pop(context); // Close dialog first
                          if (banner == null) {
                            await FirestoreService.addBanner(data);
                          } else {
                            await FirestoreService.updateBanner(
                                banner['id'], data);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
              child: Text(banner == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Banners',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddBannerDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService.getBanners(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final banners = snapshot.data ?? [];

                  if (banners.isEmpty) {
                    return const Center(child: Text('No banners found.'));
                  }

                  return ListView.builder(
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(banner['image']),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(banner['title']),
                          subtitle: Text(
                              '${banner['subtitle']} (Order: ${banner['order']})'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showAddBannerDialog(banner: banner),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text(
                                          'Are you sure you want to delete this banner?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            FirestoreService.deleteBanner(
                                                banner['id']);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
