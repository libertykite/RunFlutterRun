import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../domain/entities/activity.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'activity_item.dart';

/// The screen that displays a list of activities.
class ActivityList extends HookConsumerWidget {
  /// The activities to display.
  final List<Activity> activities;

  /// display username ?
  final bool displayUserName;

  /// can open activity ?
  final bool canOpenActivity;

  /// Creates a [ActivityList] widget.
  ///
  /// The [activities] is the activities to display.
  const ActivityList(
      {Key? key,
      this.displayUserName = false,
      this.canOpenActivity = true,
      required this.activities})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: activities.isEmpty
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.info, size: 48),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    AppLocalizations.of(context)!.no_data,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return ActivityItem(
                  index: index,
                  activity: activities[index],
                  displayUserName: displayUserName,
                  canOpenActivity: canOpenActivity,
                );
              },
            ),
    );
  }
}