import 'package:flutter/material.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import '../../../firestore_service.dart';
import '../../../layouts/admin_layout.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;
  bool _isUploading = false;

  // Modern Green Theme Colors
  final Color _primaryColor = const Color(0xFF2C8610);
  final Color _primaryLight = const Color(0xFFF0F9EE);
  final Color _accentColor = const Color(0xFF4CAF50);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = Colors.black87;
  final Color _textSecondary = Colors.grey.shade600;
  final Color _borderColor = Colors.grey.shade200;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _imageController = TextEditingController();
  final _buttonTextController = TextEditingController();
  final _orderController = TextEditingController();
  String? _selectedCategory;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'drwoht0pd',
    'presets',
    cache: false,
  );

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _imageController.dispose();
    _buttonTextController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilterSearchPagination(
      List<Map<String, dynamic>> banners) {
    // FILTER
    List<Map<String, dynamic>> filtered = banners.where((banner) {
      final isActive = banner['isActive'] ?? true;
      if (_filterStatus == 'active') return isActive;
      if (_filterStatus == 'inactive') return !isActive;
      return true;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((banner) =>
              (banner['title'] ?? '')
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              (banner['subtitle'] ?? '')
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    // Sort by order
    filtered.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

    // PAGINATION
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= filtered.length) return [];
    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  void _nextPage(int totalItems) {
    if (_currentPage * _itemsPerPage < totalItems) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  void _showAddBannerDialog({Map<String, dynamic>? banner}) {
    if (banner != null) {
      _titleController.text = banner['title'] ?? '';
      _subtitleController.text = banner['subtitle'] ?? '';
      _imageController.text = banner['image'] ?? '';
      _buttonTextController.text = banner['buttonText'] ?? '';
      _orderController.text = (banner['order'] ?? 0).toString();
      _selectedCategory = banner['categoryId'];
    } else {
      _titleController.clear();
      _subtitleController.clear();
      _imageController.clear();
      _buttonTextController.clear();
      _orderController.text = '0';
      _selectedCategory = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          banner == null
                              ? Icons.add_photo_alternate
                              : Icons.edit_rounded,
                          color: _primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        banner == null ? 'Add Banner' : 'Edit Banner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: _primaryLight.withOpacity(0.3),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _subtitleController,
                            decoration: InputDecoration(
                              labelText: 'Subtitle',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: _primaryLight.withOpacity(0.3),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: FirestoreService.getAllCategories(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const LinearProgressIndicator();
                              }
                              final categories = snapshot.data!;
                              return DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Category Link (Optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: _primaryLight.withOpacity(0.3),
                                ),
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
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _imageController,
                                  decoration: InputDecoration(
                                    labelText: 'Image URL',
                                    hintText: 'https://example.com/image.jpg',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: _primaryLight.withOpacity(0.3),
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: _isUploading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _primaryColor),
                                        ),
                                      )
                                    : Icon(Icons.upload_file_rounded,
                                        color: _primaryColor),
                                onPressed: _isUploading
                                    ? null
                                    : () async {
                                        try {
                                          final XFile? pickedFile =
                                              await _picker.pickImage(
                                                  source: ImageSource.gallery);
                                          if (pickedFile == null) return;

                                          setDialogState(
                                              () => _isUploading = true);

                                          final response =
                                              await _cloudinary.uploadFile(
                                            CloudinaryFile.fromFile(
                                              pickedFile.path,
                                              resourceType:
                                                  CloudinaryResourceType.Image,
                                            ),
                                          );

                                          _imageController.text =
                                              response.secureUrl;
                                          setDialogState(
                                              () => _isUploading = false);
                                        } catch (e) {
                                          setDialogState(
                                              () => _isUploading = false);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      },
                                tooltip: 'Upload from Gallery',
                              ),
                            ],
                          ),
                          if (_imageController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _borderColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _imageController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        size: 40, color: Colors.grey.shade400),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _buttonTextController,
                            decoration: InputDecoration(
                              labelText: 'Button Text',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: _primaryLight.withOpacity(0.3),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _orderController,
                            decoration: InputDecoration(
                              labelText: 'Order (Sort)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: _primaryLight.withOpacity(0.3),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                    'order':
                                        int.tryParse(_orderController.text) ??
                                            0,
                                    'isActive': true,
                                    'categoryId': _selectedCategory,
                                  };

                                  try {
                                    Navigator.pop(context);
                                    if (banner == null) {
                                      await FirestoreService.addBanner(data);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Banner added successfully'),
                                            backgroundColor: _accentColor,
                                          ),
                                        );
                                      }
                                    } else {
                                      await FirestoreService.updateBanner(
                                          banner['id'], data);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Banner updated successfully'),
                                            backgroundColor: _accentColor,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(banner == null ? 'ADD' : 'SAVE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Container(
        color: _primaryLight.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.photo_library_rounded,
                              color: _primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Banner Management',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage homepage banners and promotions',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddBannerDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Banner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        shadowColor: _primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search and Filter Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search banners by title or subtitle...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon:
                            Icon(Icons.search_rounded, color: _primaryColor),
                        filled: true,
                        fillColor: _primaryLight.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _currentPage = 1;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Status Filter Chips
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: ['active', 'inactive', 'all'].length,
                        itemBuilder: (context, index) {
                          final status = ['active', 'inactive', 'all'][index];
                          final label =
                              status[0].toUpperCase() + status.substring(1);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _filterStatus == status
                                      ? Colors.white
                                      : _primaryColor,
                                ),
                              ),
                              selected: _filterStatus == status,
                              selectedColor: _primaryColor,
                              backgroundColor: _primaryLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _filterStatus == status
                                      ? _primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _filterStatus = status;
                                  _currentPage = 1;
                                });
                              },
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Banners List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService.getBanners(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_primaryColor),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading banners',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final allBanners = snapshot.data ?? [];
                    final paginatedBanners =
                        _applyFilterSearchPagination(allBanners);

                    if (paginatedBanners.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No banners found',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filter',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: paginatedBanners.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final banner = paginatedBanners[index];
                              final isActive = banner['isActive'] ?? true;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  elevation: 0,
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isActive
                                            ? _accentColor.withOpacity(0.3)
                                            : Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Container(
                                        width: 80,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                                banner['image'] ?? ''),
                                            fit: BoxFit.cover,
                                          ),
                                          border: Border.all(
                                              color: _borderColor, width: 1),
                                        ),
                                      ),
                                      title: Text(
                                        banner['title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isActive
                                              ? _textPrimary
                                              : Colors.grey,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            banner['subtitle'] ?? 'No Subtitle',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isActive
                                                  ? _textSecondary
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? _accentColor
                                                          .withOpacity(0.1)
                                                      : Colors.grey
                                                          .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isActive
                                                      ? 'Active'
                                                      : 'Inactive',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isActive
                                                        ? _accentColor
                                                        : Colors.grey[600],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Order: ${banner['order'] ?? 0}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue[600],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Material(
                                        elevation: 2,
                                        shadowColor:
                                            Colors.black.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[50],
                                        child: PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: Colors.grey[700],
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 8,
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              _showAddBannerDialog(
                                                  banner: banner);
                                            } else if (value == 'toggle') {
                                              final action = isActive
                                                  ? 'deactivate'
                                                  : 'activate';
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  title:
                                                      Text('Confirm $action'),
                                                  content: Text(
                                                    'Are you sure you want to $action this banner?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            _primaryColor,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                      child: Text(
                                                        '${action[0].toUpperCase()}${action.substring(1)}',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                await FirestoreService
                                                    .updateBanner(
                                                  banner['id'],
                                                  {'isActive': !isActive},
                                                );
                                              }
                                            } else if (value == 'delete') {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  title: const Text(
                                                      'Confirm Delete'),
                                                  content: const Text(
                                                      'Are you sure you want to delete this banner?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                      child:
                                                          const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                await FirestoreService
                                                    .deleteBanner(banner['id']);
                                              }
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'toggle',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isActive
                                                        ? Icons.toggle_off
                                                        : Icons.toggle_on,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(isActive
                                                      ? 'Deactivate'
                                                      : 'Activate'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      size: 20,
                                                      color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Pagination Controls
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _prevPage,
                                icon: Icon(Icons.arrow_back_ios_rounded,
                                    size: 16, color: _primaryColor),
                                style: IconButton.styleFrom(
                                  backgroundColor: _primaryLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Page $_currentPage',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () => _nextPage(allBanners.length),
                                icon: Icon(Icons.arrow_forward_ios_rounded,
                                    size: 16, color: _primaryColor),
                                style: IconButton.styleFrom(
                                  backgroundColor: _primaryLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
