import 'package:flutter/material.dart';
import 'package:stitchcraft/services/auth_service.dart';
import '../widgets/main_layout.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'My Profile',
      actions: [],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                ]
              ),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(4),
                     decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                     child: const CircleAvatar(
                       radius: 32,
                       backgroundColor: Colors.grey,
                       child: Icon(Icons.person, size: 40, color: Colors.white),
                     ),
                   ),
                   const SizedBox(width: 24),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: const [
                       Text("Master Tailor", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                       Text("tailor@stitchcraft.com", style: TextStyle(color: Colors.white70)),
                     ],
                   )
                ],
              ),
            ),
           
            const SizedBox(height: 32),
            
            // Menu Items
            const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildActionTile(context, Icons.person_outline, "Edit Profile", Colors.blue),
            _buildActionTile(context, Icons.notifications_outlined, "Notifications", Colors.orange),
            _buildActionTile(context, Icons.language, "Language", Colors.purple),
            _buildActionTile(context, Icons.help_outline, "Help & Support", Colors.teal),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: () async {
                   await AuthService().logout();
                   if (context.mounted) {
                     Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                   }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 2))
         ]
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
             color: color.withOpacity(0.1),
             borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
