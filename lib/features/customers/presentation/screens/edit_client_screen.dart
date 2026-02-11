import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/models/customer_model.dart';

class EditClientScreen extends StatefulWidget {
  const EditClientScreen({super.key});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEditing = false;
  String? _customerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final customer = ModalRoute.of(context)?.settings.arguments as Customer?;
    if (customer != null && !_isEditing) {
      _isEditing = true;
      _customerId = customer.id;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
      // Notes field isn't in Customer model yet, assuming for now it's separate or will be added
    }
  }

  Future<void> _saveClient() async {
    if (_formKey.currentState!.validate()) {
      try {
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        final email = _emailController.text.trim();

        if (_isEditing) {
          final updatedCustomer = Customer(
            id: _customerId!,
            name: name,
            phone: phone,
            email: email,
            updatedAt: DateTime.now(),
          );
          await _dbService.updateCustomer(updatedCustomer);
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client updated successfully')));
        } else {
          final newCustomer = Customer(
            id: '',
            name: name,
            phone: phone,
            email: email,
            updatedAt: DateTime.now(),
          );
          await _dbService.addCustomer(newCustomer);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client added successfully')));
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Client' : 'Add Client')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Phone is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email (Optional)', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 24),
                
                const Align(alignment: Alignment.centerLeft, child: Text('Notes / Preferences')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Enter notes like measurements preferences, allergies, body posture etc.'),
                ),
                
                const SizedBox(height: 40),
                 SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveClient,
                      child: Text(_isEditing ? 'Update Client' : 'Save Client'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
