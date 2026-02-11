import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Setup Your Shop'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor),
                        ),
                        child: const Icon(Icons.store, size: 50, color: Colors.grey),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Text('Shop Name', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(hintText: 'e.g. Elegant Tailors'),
                ),
                const SizedBox(height: 20),
                
                Text('Phone Number', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(hintText: '+91 98765 43210'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                Text('Address', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                TextFormField(
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Shop No. 12, Main Market...'),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Role Selection or Dashboard
                      Navigator.pushReplacementNamed(context, '/role_selection');
                    },
                    child: const Text('Create Shop Profile'),
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
