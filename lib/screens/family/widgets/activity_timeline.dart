import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../../models/sensor_event.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/sensor_provider.dart';
import 'event_empty_state.dart';
import 'family_page.dart';
import 'timeline_item.dart';

/// Vertical event timeline backed by an [AnimatedList].
///
/// The list mirrors [SensorProvider.events]: added events fade/slide in,
/// removed events (e.g. after a demo reset) animate out.
class ActivityTimeline extends StatefulWidget {
  const ActivityTimeline({super.key});

  @override
  State<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends State<ActivityTimeline> {
  final _listKey = GlobalKey<AnimatedListState>();
  SensorProvider? _provider;
  List<SensorEvent> _items = const [];
  Duration _duration = AppDurations.timeline;
  DateTime _now = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<SensorProvider>();
    if (!identical(provider, _provider)) {
      _provider?.removeListener(_sync);
      _provider = provider..addListener(_sync);
      _items = List.of(provider.events);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_sync);
    super.dispose();
  }

  /// Diffs the provider list against the displayed list. Both are sorted
  /// newest-first with immutable sort keys, so removing missing ids and then
  /// inserting new ids at their target index reproduces the provider order.
  void _sync() {
    if (!mounted) return;
    final next = _provider!.events;
    final nextIds = {for (final e in next) e.id};
    final list = _listKey.currentState;

    for (var i = _items.length - 1; i >= 0; i--) {
      if (nextIds.contains(_items[i].id)) continue;
      final removed = _items.removeAt(i);
      final wasFirst = i == 0;
      final wasLast = i == _items.length;
      list?.removeItem(
        i,
        (context, animation) =>
            _animated(removed, animation, isFirst: wasFirst, isLast: wasLast),
        duration: _duration,
      );
    }

    final shownIds = {for (final e in _items) e.id};
    for (var j = 0; j < next.length; j++) {
      if (shownIds.contains(next[j].id)) continue;
      _items.insert(j, next[j]);
      list?.insertItem(j, duration: _duration);
    }

    setState(() {});
  }

  Widget _animated(
    SensorEvent event,
    Animation<double> animation, {
    required bool isFirst,
    required bool isLast,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.15),
            end: Offset.zero,
          ).animate(curved),
          child: TimelineItem(
            event: event,
            now: _now,
            isFirst: isFirst,
            isLast: isLast,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _duration = context.motion(AppDurations.timeline);
    _now = context.select<ClockProvider, DateTime>((c) => c.currentTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FamilySectionHeader(
          title: 'Etkinlik Akışı',
          caption: '${_items.length} olay · simüle',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_items.isEmpty) const EventEmptyState(),
        AnimatedList(
          key: _listKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) => _animated(
            _items[index],
            animation,
            isFirst: index == 0,
            isLast: index == _items.length - 1,
          ),
        ),
      ],
    );
  }
}
