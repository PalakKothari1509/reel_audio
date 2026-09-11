import 'package:flutter/material.dart';

// ── How the app looks ─────────────────────────────────────────────────────────
//
// One file, so a colour or a size is changed once rather than in forty places. The
// old screens set their own greys inline and drifted apart: three different card
// greys, four different text greys, and body text at 10px that nobody could read.
//
// Warm and light, because this app makes children's stories for parents. Near-black
// on cream reads in daylight on a phone, which white38 on black never did.

class AppColors {
  /// Page background. Cream rather than white — white is harsh at full brightness.
  static const bg = Color(0xFFFDF8F0);

  /// Cards and sheets sit on the background, so they are lighter than it.
  static const surface = Color(0xFFFFFFFF);

  /// A softer panel for things that sit inside a card.
  static const surfaceAlt = Color(0xFFF4EEE4);

  static const border = Color(0xFFE6DDCE);

  /// The brand colour. Actions, progress, anything selected.
  static const primary = Color(0xFF0F8A7E);
  static const primarySoft = Color(0xFFDCF0ED);

  /// Warm accent, for the hook and anything about attention.
  static const accent = Color(0xFFE07A3F);
  static const accentSoft = Color(0xFFFBEBE0);

  static const text = Color(0xFF2A2520);
  static const textSoft = Color(0xFF6B6259);

  /// Light enough to be secondary, dark enough to still be readable — the old
  /// white38 equivalent failed that second test.
  static const textFaint = Color(0xFF9A9088);

  static const warning = Color(0xFFB4690E);
  static const danger = Color(0xFFC0392B);
}

class AppText {
  static const screenTitle =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.25);
  static const section =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textSoft, letterSpacing: 0.8);
  static const body =
      TextStyle(fontSize: 15, color: AppColors.text, height: 1.45);
  static const hint =
      TextStyle(fontSize: 13, color: AppColors.textSoft, height: 1.4);
  static const small =
      TextStyle(fontSize: 12, color: AppColors.textFaint, height: 1.35);
}

/// Spacing steps. Everything is a multiple of these so nothing is nearly-aligned.
class Gap {
  static const xs = SizedBox(height: 4);
  static const s = SizedBox(height: 8);
  static const m = SizedBox(height: 16);
  static const l = SizedBox(height: 24);
  static const xl = SizedBox(height: 32);
  static const wS = SizedBox(width: 8);
  static const wM = SizedBox(width: 16);
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    // Dialogs and sheets used to keep their own dark grey and looked like a
    // different app the moment one opened.
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text, displayColor: AppColors.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
  );
}

// ── Pieces every screen uses ──────────────────────────────────────────────────

/// The step bar across the top. Says where you are, which the old app never did.
class StepBar extends StatelessWidget {
  final List<String> steps;
  final int current;
  /// Tapping a step you have already passed goes back to it. Steps ahead are not
  /// tappable, because the app cannot know you have done the ones in between.
  final void Function(int index)? onTap;

  const StepBar({super.key, required this.steps, required this.current, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i < current;
          final here = i == current;
          final colour = here
              ? AppColors.primary
              : done ? AppColors.primary.withOpacity(0.55) : AppColors.border;

          return Expanded(
            child: GestureDetector(
              onTap: (done && onTap != null) ? () => onTap!(i) : null,
              behavior: HitTestBehavior.opaque,
              child: Column(children: [
                Row(children: [
                  Expanded(child: Container(height: 3,
                    color: i == 0 ? Colors.transparent : colour)),
                  Container(
                    width: here ? 12 : 9, height: here ? 12 : 9,
                    decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
                  ),
                  Expanded(child: Container(height: 3,
                    color: i == steps.length - 1
                        ? Colors.transparent
                        : (i < current ? AppColors.primary.withOpacity(0.55) : AppColors.border))),
                ]),
                const SizedBox(height: 5),
                Text(steps[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: here ? FontWeight.w700 : FontWeight.w500,
                    color: here ? AppColors.primary
                        : done ? AppColors.textSoft : AppColors.textFaint,
                  )),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

/// The one thing this screen is for. Full width, big enough to hit, always last.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color colour;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.colour = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
            : Icon(icon ?? Icons.arrow_forward, size: 20),
        label: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colour,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textFaint,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Anything that is not the main action on the screen.
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color colour;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.colour = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: colour,
        backgroundColor: AppColors.surface,
        disabledForegroundColor: AppColors.textFaint,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// A white panel. Used for every grouped thing, so grouping is visible at a glance.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? colour;
  final Color? borderColour;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.colour,
    this.borderColour,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: colour ?? AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColour ?? AppColors.border),
        ),
        child: child,
      );
}

/// A small all-caps heading above a group.
class SectionTitle extends StatelessWidget {
  final String text;
  final String? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(text.toUpperCase(), style: AppText.section)),
          if (trailing != null)
            Text(trailing!, style: AppText.small),
        ]),
      );
}

/// One line of a settings list: icon, label, current value, chevron.
class SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColour;

  const SettingRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.valueColour,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.textSoft),
            const SizedBox(width: 12),
            Expanded(child: Text(label,
              style: const TextStyle(fontSize: 15, color: AppColors.text))),
            Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: valueColour ?? AppColors.primary)),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textFaint),
          ]),
        ),
      );
}

/// The message strip at the bottom of a working screen.
///
/// One place for it, because it used to be three slightly different grey boxes and
/// an error looked the same as "saved".
class StatusBar extends StatelessWidget {
  final String message;
  final VoidCallback? onCopy;
  const StatusBar({super.key, required this.message, this.onCopy});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    final bad = message.startsWith('❌');
    final good = message.startsWith('✅') || message.startsWith('🎉');
    final colour = bad ? AppColors.danger : good ? AppColors.primary : AppColors.warning;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colour.withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(bad ? Icons.error_outline : good ? Icons.check_circle_outline : Icons.info_outline,
          size: 17, color: colour),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
          style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.text))),
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: const Icon(Icons.copy, size: 16, color: AppColors.textFaint)),
      ]),
    );
  }
}
