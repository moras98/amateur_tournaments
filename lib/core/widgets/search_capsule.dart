import 'package:tande/core/utils/nav_geometry.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The app's search bar: a floating rounded capsule pinned under the status
/// bar — the bottom-nav capsule's recipe (12 margin, 64-tall stadium,
/// `surface` fill with a hairline `outlineVariant` border).
///
/// The SAME design on every screen that searches (design.md §7): Explore
/// (map *and* list view), Organizar and Mis inscripciones. No screen docks
/// it into an app bar — the pill is the identity of the search row.
class SearchCapsule extends StatelessWidget {
  const SearchCapsule({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    this.actions = const [],
  });

  final TextEditingController controller;

  final String hintText;

  final ValueChanged<String> onChanged;

  /// Runs on submit and on the suffix clear (with an empty query).
  final ValueChanged<String> onSubmitted;

  /// Trailing controls (filter, view toggle, sort…), same recipe as icons
  /// in the nav capsule: 48pt targets centered in the pill.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(kNavCapsuleBarHeight / 2));
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + kNavCapsuleMargin,
        left: kNavCapsuleMargin,
        right: kNavCapsuleMargin,
        bottom: kNavCapsuleMargin,
      ),
      child: DecoratedBox(
        // Hairline painted after the child: the field's Material would
        // cover it otherwise (same trick as the nav capsule).
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: radius,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: radius,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox(
              height: kNavCapsuleBarHeight,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(child: _buildField()),
                  ...actions,
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The input itself: NO fill of its own — the pill's `surface` is the
  /// field's background. The theme's grey rounded-rect fill would fight
  /// the stadium's curve (its corners are far squarer than the bar's).
  Widget _buildField() {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        filled: false,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.text.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: AppLocalizations.of(context)!.clearSearch,
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                onSubmitted('');
              },
            );
          },
        ),
      ),
    );
  }
}
