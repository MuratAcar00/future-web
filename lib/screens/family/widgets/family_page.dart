import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// Scrollable, width-constrained column used by every family section.
class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < AppBreakpoints.mobile
        ? AppSpacing.lg
        : width < AppBreakpoints.desktop
        ? AppSpacing.xl
        : AppSpacing.xxl;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Page title style, slightly smaller on phones.
TextStyle familyTitleStyle(BuildContext context) =>
    MediaQuery.sizeOf(context).width < AppBreakpoints.mobile
    ? AppTextStyles.pageTitle.copyWith(fontSize: 28)
    : AppTextStyles.pageTitle;

/// Page title + subtitle used by the settings and profile sections.
class FamilyPageTitle extends StatelessWidget {
  const FamilyPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: familyTitleStyle(context)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.secondary),
      ],
    );
  }
}

/// Bordered group of rows separated by thin dividers.
class FamilyCard extends StatelessWidget {
  const FamilyCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerTheme.color!),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Section heading with optional trailing caption.
class FamilySectionHeader extends StatelessWidget {
  const FamilySectionHeader({super.key, required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppTextStyles.section),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(caption, style: AppTextStyles.secondary),
          ],
        ],
      ),
    );
  }
}
