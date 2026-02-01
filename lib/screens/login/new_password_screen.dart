import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _submit() {
    // Reset Logic
    Navigator.pushNamed(context, '/password_success');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
               Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
              
              Text(
                'Set New Password',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter new strong password, password at least 6 characters.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('New Password*', style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPassController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                   suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Confirm New Password*', style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPassController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                   suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
