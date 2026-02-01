import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              children: [
                TextSpan(text: 'Tailor'),
                TextSpan(text: 'Book', style: TextStyle(fontWeight: FontWeight.normal)),
                TextSpan(text: '.', style: TextStyle(color: AppTheme.primaryColor)),
              ],
            ),
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Past Due'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersList(status: 'Active'), // Populated
            _OrdersList(status: 'Past Due'), // Empty Logic Test
            _OrdersList(status: 'Upcoming'),
            _OrdersList(status: 'Completed'),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final String status;
  const _OrdersList({required this.status});

  @override
  Widget build(BuildContext context) {
    // For demo purposes, "Active" has items, others are empty
    final bool isEmpty = status != 'Active';

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(
               Icons.checkroom_outlined, // Fallback illustration
               size: 120, 
               color: Colors.grey.shade200,
             ).animate().scale(duration: 600.ms),
            const SizedBox(height: 24),
            Text(
              'Welcome To Tailor Book!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No clients added yet get started\nby adding a client.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return const _OrderCard();
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zakir Ullah',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Salwar Kameez #1',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Received',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rs 600 (1 Item)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due On May, 20, 2022',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // View Button and Spacer
          Column(
             mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), // Light Blue bg
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
