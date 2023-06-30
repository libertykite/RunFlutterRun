import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../domain/entities/activity.dart';
import '../view_model/activity_details_view_model.dart';

class RemoveActivityAlert extends HookConsumerWidget {
  final Activity activity;

  const RemoveActivityAlert({Key? key, required this.activity})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(activityDetailsViewModelProvider.notifier);

    return AlertDialog(
      title: Text(AppLocalizations.of(context).ask_activity_removal),
      actions: [
        TextButton(
          onPressed: () {
            provider.removeActivity(activity);
          },
          child: Text(AppLocalizations.of(context).delete),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ],
    );
  }
}