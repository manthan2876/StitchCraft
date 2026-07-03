import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/features/posts/data/models/post_model.dart';
import 'package:stitchcraft/features/posts/data/services/api_service.dart';
import 'package:stitchcraft/features/posts/presentation/widgets/post_card.dart';
import 'package:stitchcraft/features/posts/presentation/widgets/sync_status_bar.dart';
import 'package:stitchcraft/features/posts/presentation/widgets/empty_state.dart';
import 'package:stitchcraft/features/posts/presentation/widgets/error_state.dart';

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
            const Text('ડિજિટલ લેજર'),
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
                    'ડેટા લોડ થઈ રહ્યો છે...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return ErrorState(error: snapshot.error.toString(), onRetry: _refreshPosts);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState();
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
                return PostCard(
                  post: post,
                  onTap: () => _showPostDetails(context, post),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: SyncStatusBar(onRefresh: _refreshPosts),
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
