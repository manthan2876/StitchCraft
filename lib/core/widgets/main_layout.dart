import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showAppBar;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool useSafeArea;

  const MainLayout({
    super.key,
    required this.child,
    this.title,
    this.showAppBar = true,
    this.centerTitle = true,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              centerTitle: centerTitle,
              actions: actions,
              elevation: 0,
              backgroundColor: Theme.of(context).cardColor, // Clean look
              foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
            )
          : null,
      body: useSafeArea ? SafeArea(child: child) : child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
