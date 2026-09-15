import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class ConsentBanner extends StatefulWidget {
  const ConsentBanner({
    super.key,
    required this.text,
    required this.onAccept,
    required this.onRefuse,
  });

  final String text;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  @override
  State<ConsentBanner> createState() => _ConsentBannerState();
}

class _ConsentBannerState extends State<ConsentBanner> {
  bool _processing = false;
  bool _hovering = false;

  Future<void> _submit({required bool accepted}) async {
    if (_processing) return;

    setState(() {
      _processing = true;
    });

    await HapticFeedback.selectionClick();

    if (!mounted) return;

    if (accepted) {
      widget.onAccept();
    } else {
      widget.onRefuse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeText = _ConsentSecurity.text(widget.text, maxLength: 1000);

    if (safeText.isEmpty) {
      return const SizedBox.shrink();
    }

    final acceptBackground = AppColors.gold;

    final acceptForeground =
        ThemeData.estimateBrightnessForColor(acceptBackground) ==
                Brightness.dark
            ? Colors.white
            : const Color(0xFF111827);

    final iconColor =
        ThemeData.estimateBrightnessForColor(AppColors.gold) == Brightness.dark
            ? AppColors.gold
            : const Color(0xFFB45309);

    return Semantics(
      container: true,
      label: 'Bannière de consentement',
      child: MouseRegion(
        onEnter: (_) {
          if (mounted) {
            setState(() => _hovering = true);
          }
        },
        onExit: (_) {
          if (mounted) {
            setState(() => _hovering = false);
          }
        },
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(
                    15,
                    23,
                    42,
                    _hovering ? 0.16 : 0.10,
                  ),
                  blurRadius: _hovering ? 36 : 28,
                  offset: Offset(0, _hovering ? 16 : 12),
                ),
              ],
            ),
            child: AnimatedOpacity(
              opacity: _processing ? 0.78 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 460;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _message(safeText, iconColor),
                        const SizedBox(height: 16),
                        _actions(
                          compact: compact,
                          acceptBackground: acceptBackground,
                          acceptForeground: acceptForeground,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(String safeText, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedScale(
          scale: _hovering ? 1.05 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF3E7C3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.privacy_tip_rounded,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            safeText,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actions({
    required bool compact,
    required Color acceptBackground,
    required Color acceptForeground,
  }) {
    final refuseButton = _refuseButton(expanded: compact);
    final acceptButton = _acceptButton(
      expanded: compact,
      background: acceptBackground,
      foreground: acceptForeground,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          refuseButton,
          const SizedBox(height: 10),
          acceptButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        refuseButton,
        const SizedBox(width: 10),
        acceptButton,
      ],
    );
  }

  Widget _refuseButton({required bool expanded}) {
    final button = OutlinedButton(
      onPressed: _processing ? null : () => _submit(accepted: false),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const Text('Refuser'),
    );

    if (!expanded) return button;

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  Widget _acceptButton({
    required bool expanded,
    required Color background,
    required Color foreground,
  }) {
    final button = FilledButton(
      onPressed: _processing ? null : () => _submit(accepted: true),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: const Text('Accepter'),
    );

    if (!expanded) return button;

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}

class _ConsentSecurity {
  const _ConsentSecurity._();

  static String text(String? value, {int maxLength = 1000}) {
    if (value == null || value.isEmpty) return '';

    final cleaned = value
        .replaceAll(
          RegExp(
            r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFEFF\u202A-\u202E\u2066-\u2069]',
          ),
          '',
        )
        .trim();

    return _truncateSafely(cleaned, maxLength);
  }

  static String _truncateSafely(String value, int maxLength) {
    if (value.length <= maxLength) return value;

    final truncated = value.substring(0, maxLength);

    if (truncated.isEmpty) return '';

    final lastCodeUnit = truncated.codeUnitAt(truncated.length - 1);

    // Avoid cutting in the middle of a UTF-16 surrogate pair.
    if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
      return truncated.substring(0, truncated.length - 1);
    }

    return truncated;
  }
}
