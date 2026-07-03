import 'package:flutter/widgets.dart';
import 'package:stitchcraft/core/localization/generated/app_localizations.dart';

export 'package:stitchcraft/core/localization/generated/app_localizations.dart';

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}
