import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../data/services/api_service.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  late Future<List<Post>> _postsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _postsFuture = _apiService.fetchPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = _apiService.fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softWhite,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('ડિજિટલ લેજર'), // Gujarati for Digital Ledger
            Text(
              'API Integration - Lab 9',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        toolbarHeight: 80,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: _refreshPosts,
              icon: const Icon(Icons.cloud_sync, size: 32),
              tooltip: 'Sync Data (બેકઅપ લો)',
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.deepBronze),
                  const SizedBox(height: 16),
                  Text(
                    'ડેટા લોડ થઈ રહ્યો છે...', // Data is loading...
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final posts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshPosts(),
            color: AppTheme.deepBronze,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostCard(post);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _buildSyncStatusBar(),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showPostDetails(context, post),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeuomorphic circle for ID
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.bronzeTint, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    post.id.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.deepBronze,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepBronze,
                            letterSpacing: 0.5,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.darkEarth.withValues(alpha: 0.8),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.bronzeTint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.lightGrey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.trustGreen, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'ડેટા સુરક્ષિત છે', // Data is secure
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.trustGreen,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _refreshPosts,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('રીફ્રેશ'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppTheme.deepBronze,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.safetyOrange, size: 80),
            const SizedBox(height: 24),
            Text(
              'ડેટા મેળવવામાં ભૂલ આવી છે!', // Error fetching data!
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.safetyOrange,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ERROR: $error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _refreshPosts,
                child: const Text('ફરી પ્રયાસ કરો (Retry)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, color: AppTheme.bronzeTint, size: 80),
          const SizedBox(height: 16),
          Text(
            'કોઈ ડેટા મળ્યો નથી.', // No data found.
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  void _showPostDetails(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          post.title.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.deepBronze),
        ),
        content: SingleChildScrollView(
          child: Text(
            post.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'બંધ કરો (Close)',
              style: TextStyle(color: AppTheme.deepBronze, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
