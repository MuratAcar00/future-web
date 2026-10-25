import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../models/routine_status.dart';
import '../../../models/sensor_event.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/sensor_provider.dart';
import '../widgets/family_page.dart';

/// Profile of the monitored person, filled from live provider state.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = context.select<ClockProvider, DateTime>((c) => c.currentTime);
    final sensorCount = context.select<SensorProvider, int>(
      (p) => p.sensors.length,
    );
    final todayCount = context.select<SensorProvider, int>(
      (p) => p.eventCountOn(now),
    );
    final lastActivity = context.select<SensorProvider, SensorEvent?>(
      (p) => p.events.where((e) => e.kind.isSensorActivity).firstOrNull,
    );
    final status = context.select<RoutineProvider, RoutineStatus>(
      (r) => r.status,
    );

    return FamilyPage(
      children: [
        const FamilyPageTitle(
          title: 'Profil',
          subtitle: 'Takip edilen kişi ve aile hesabı bilgileri.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                border: Border.all(color: AppColors.border),
                shape: BoxShape.circle,
              ),
              child: const Text(
                AppStrings.residentInitials,
                style: AppTextStyles.bodyStrong,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.residentName, style: AppTextStyles.section),
                  Text('Takip edilen kişi', style: AppTextStyles.secondary),
                ],
              ),
            ),
            const TagChip(
              label: 'Demo profil',
              background: AppColors.simulator,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const FamilySectionHeader(title: 'Ev özeti'),
        FamilyCard(
          children: [
            const _ProfileRow(label: 'Ev', value: AppStrings.homeName),
            _ProfileRow(
              label: 'Sensörler',
              value: '$sensorCount simüle sensör',
            ),
            _ProfileRow(label: 'Bugünkü olaylar', value: '$todayCount'),
            _ProfileRow(
              label: 'Son hareket',
              value: lastActivity == null
                  ? 'Henüz yok'
                  : '${lastActivity.tag} · '
                        '${TurkishDateFormat.relative(lastActivity.timestamp, now)}',
            ),
            _ProfileRow(label: 'Rutin durumu', value: status.label),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const FamilySectionHeader(title: 'Aile hesabı'),
        const FamilyCard(
          children: [
            _ProfileRow(label: 'Kullanıcı', value: 'Siz (demo aile üyesi)'),
            _ProfileRow(
              label: 'Bildirimler',
              value: 'Bu demoda gerçek bildirim gönderilmez; uyarılar yalnızca bu panelde görünür.',
            ),
            _ProfileRow(
              label: 'Mahremiyet',
              value: 'Kamera veya mikrofon yok; yalnızca simüle edilen sensör olayları.',
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label, style: AppTextStyles.secondary),
            ),
            Expanded(child: Text(value, style: AppTextStyles.body)),
          ],
        ),
      ),
    );
  }
}
