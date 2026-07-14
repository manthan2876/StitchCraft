import 'package:flutter/material.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';

class ProfileTab extends StatelessWidget {
  final TextEditingController nameController;
  final String email;
  final String role;
  final bool isSaving;
  final VoidCallback onSave;

  const ProfileTab({
    super.key,
    required this.nameController,
    required this.email,
    required this.role,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Profile details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Display Name (Editable)
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Display Name'),
          ),
          const SizedBox(height: 16),

          // Email Address (Read-only)
          TextField(
            controller: TextEditingController(text: email),
            decoration: const InputDecoration(
              labelText: 'Email Address',
            ),
            enabled: false,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),

          // Role (Read-only)
          TextField(
            controller: TextEditingController(text: role),
            decoration: const InputDecoration(
              labelText: 'Account Role',
            ),
            enabled: false,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          
          PrimaryButton(
            text: 'Save Details',
            isLoading: isSaving,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}
