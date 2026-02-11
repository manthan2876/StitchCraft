import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'dart:io';

class FabricPhotoCaptureWidget extends StatefulWidget {
  final String? existingPhotoUrl;
  final Function(File? photo) onPhotoChanged;
  final bool isRequired;

  const FabricPhotoCaptureWidget({
    super.key,
    this.existingPhotoUrl,
    required this.onPhotoChanged,
    this.isRequired = true,
  });

  @override
  State<FabricPhotoCaptureWidget> createState() => _FabricPhotoCaptureWidgetState();
}

class _FabricPhotoCaptureWidgetState extends State<FabricPhotoCaptureWidget> {
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhoto = File(image.path);
        });
        widget.onPhotoChanged(_selectedPhoto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhoto = null;
    });
    widget.onPhotoChanged(null);
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _capturePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.accentColor),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _capturePhoto(ImageSource.gallery);
                },
              ),
              if (_selectedPhoto != null || widget.existingPhotoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppTheme.error),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _selectedPhoto != null || widget.existingPhotoUrl != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isRequired && !hasPhoto
            ? AppTheme.warning.withValues(alpha: 0.05)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isRequired && !hasPhoto
              ? AppTheme.warning
              : Colors.grey.shade300,
          width: widget.isRequired && !hasPhoto ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: widget.isRequired && !hasPhoto
                    ? AppTheme.warning
                    : AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fabric Photo Evidence',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (widget.isRequired) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capture client fabric for dispute resolution',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (hasPhoto) ...[
            // Photo Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _selectedPhoto != null
                  ? Image.file(
                      _selectedPhoto!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : widget.existingPhotoUrl != null
                      ? Image.network(
                          widget.existingPhotoUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.error, size: 48),
                              ),
                            );
                          },
                        )
                      : const SizedBox(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showPhotoOptions,
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _removePhoto,
                  icon: const Icon(Icons.delete),
                  color: AppTheme.error,
                  tooltip: 'Remove Photo',
                ),
              ],
            ),
          ] else ...[
            // Capture Button
            InkWell(
              onTap: _showPhotoOptions,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to capture fabric photo',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.isRequired) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'REQUIRED',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          if (widget.isRequired && !hasPhoto) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Photo evidence helps resolve disputes about fabric quality',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
