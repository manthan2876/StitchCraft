import 'package:flutter/material.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/features/profile/widgets/shop_manage_tab.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class ShopHubScreen extends StatelessWidget {
  final bool isTab;
  const ShopHubScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.loc.shop_hub,
        showDrawerButton: !isTab,
      ),
      body: const ShopManageTab(),
    );
  }
}
