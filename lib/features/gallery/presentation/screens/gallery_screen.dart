import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/gallery_item_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedFabricFilter = 'ALL';
  String _selectedGarmentFilter = 'ALL';

  final List<String> _fabricTypes = [
    'ALL',
    'COTTON',
    'SILK',
    'CHIFFON',
    'GEORGETTE',
    'CREPE',
    'SATIN',
  ];

  final List<String> _garmentTypes = [
    'ALL',
    'BLOUSE',
    'SAREE_FALL',
    'KURTA',
    'DRESS',
    'LEHENGA',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _addGalleryItem,
            tooltip: 'Add Design',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Fabric',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _fabricTypes.map((fabric) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(fabric),
                          selected: _selectedFabricFilter == fabric,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFabricFilter = fabric;
                            });
                          },
                          selectedColor: AppTheme.accentColor.withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Filter by Garment',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _garmentTypes.map((garment) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(garment),
                          selected: _selectedGarmentFilter == garment,
                          onSelected: (selected) {
                            setState(() {
                              _selectedGarmentFilter = garment;
                            });
                          },
                          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Gallery Grid
          Expanded(
            child: StreamBuilder<List<GalleryItem>>(
              stream: _dbService.getGalleryItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var items = snapshot.data ?? [];

                // Apply filters
                if (_selectedFabricFilter != 'ALL') {
                  items = items.where((item) {
                    return item.fabricTags.contains(_selectedFabricFilter);
                  }).toList();
                }

                if (_selectedGarmentFilter != 'ALL') {
                  items = items.where((item) {
                    return item.garmentTags.contains(_selectedGarmentFilter);
                  }).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No designs found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add designs to build your portfolio',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildGalleryCard(items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard(GalleryItem item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: () => _viewGalleryItem(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                      item.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                        );
                      },
                    )
                  : Image.file(
                      File(item.imageUrl),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                        );
                      },
                    ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.title.isNotEmpty)
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...item.fabricTags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGalleryItem() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    // Show dialog to add tags
    if (mounted) {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _AddGalleryItemDialog(imagePath: image.path),
      );

      if (result != null) {
        final galleryItem = GalleryItem(
          id: '',
          imageUrl: image.path,
          fabricTags: result['fabricTags'] as List<String>,
          garmentTags: result['garmentTags'] as List<String>,
          title: result['title'] as String,
          description: result['description'] as String,
          source: 'USER_UPLOAD',
          syncStatus: 1,
          updatedAt: DateTime.now(),
        );

        await _dbService.addGalleryItem(galleryItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Design added to gallery!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    }
  }

  void _viewGalleryItem(GalleryItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            item.imageUrl.startsWith('http')
                ? Image.network(item.imageUrl)
                : Image.file(File(item.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.title.isNotEmpty)
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(item.description),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...item.fabricTags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
                        );
                      }),
                      ...item.garmentTags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _dbService.deleteGalleryItem(item.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Design removed from gallery'),
                        ),
                      );
                    }
                  },
                  child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGalleryItemDialog extends StatefulWidget {
  final String imagePath;

  const _AddGalleryItemDialog({required this.imagePath});

  @override
  State<_AddGalleryItemDialog> createState() => _AddGalleryItemDialogState();
}

class _AddGalleryItemDialogState extends State<_AddGalleryItemDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedFabrics = [];
  final List<String> _selectedGarments = [];

  final List<String> _fabricOptions = [
    'COTTON',
    'SILK',
    'CHIFFON',
    'GEORGETTE',
    'CREPE',
    'SATIN',
  ];

  final List<String> _garmentOptions = [
    'BLOUSE',
    'SAREE_FALL',
    'KURTA',
    'DRESS',
    'LEHENGA',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Design to Gallery'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(
              File(widget.imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'Fabric Types',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _fabricOptions.map((fabric) {
                return FilterChip(
                  label: Text(fabric),
                  selected: _selectedFabrics.contains(fabric),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFabrics.add(fabric);
                      } else {
                        _selectedFabrics.remove(fabric);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Garment Types',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _garmentOptions.map((garment) {
                return FilterChip(
                  label: Text(garment),
                  selected: _selectedGarments.contains(garment),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGarments.add(garment);
                      } else {
                        _selectedGarments.remove(garment);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': _titleController.text,
              'description': _descriptionController.text,
              'fabricTags': _selectedFabrics,
              'garmentTags': _selectedGarments,
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
