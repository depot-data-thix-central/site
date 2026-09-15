import 'package:flutter/material.dart';

class VisionSection extends StatelessWidget {
  const VisionSection({
    super.key,
    required this.text,
    this.imageUrl,
    this.imageAsset,
    this.imagePosition = VisionImagePosition.start,
  });

  final String text;
  final String? imageUrl;
  final String? imageAsset;
  final VisionImagePosition imagePosition;

  @override
  Widget build(BuildContext context) {
    final safeText = _VisionSecurity.text(text, maxLength: 1600);
    if (safeText.isEmpty) return const SizedBox.shrink();

    final hasImage = imageUrl != null || imageAsset != null;
    final isSmall = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 56 : 84,
        horizontal: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: hasImage && !isSmall
              ? _buildWithImageRow(context, safeText)
              : _buildTextOnly(safeText),
        ),
      ),
    );
  }

  Widget _buildTextOnly(String safeText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _divider(),
        const SizedBox(height: 24),
        _textContent(safeText, TextAlign.center),
      ],
    );
  }

  Widget _buildWithImageRow(BuildContext context, String safeText) {
    final children = [
      Expanded(
        flex: 1,
        child: _textContent(
          safeText,
          imagePosition == VisionImagePosition.start
              ? TextAlign.right
              : TextAlign.left,
        ),
      ),
      const SizedBox(width: 48),
      Expanded(
        flex: 1,
        child: _imageWidget(),
      ),
    ];

    if (imagePosition == VisionImagePosition.start) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children.reversed.toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget _divider() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          width: 64 * value,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFD1D5DB),
                Color(0xFF111827),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _textContent(String safeText, TextAlign align) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : align == TextAlign.right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        _divider(),
        const SizedBox(height: 24),
        Text(
          safeText,
          textAlign: align,
          style: const TextStyle(
            fontSize: 24,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _imageWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: imageUrl != null && _VisionSecurity.isSafeImageUrl(imageUrl)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _placeholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _placeholder();
                },
              )
            : imageAsset != null
                ? Image.asset(
                    imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _placeholder();
                    },
                  )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Icon(
        Icons.image_outlined,
        size: 48,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

enum VisionImagePosition {
  start,
  end,
}

class _VisionSecurity {
  const _VisionSecurity._();

  static String text(String? value, {int maxLength = 1600}) {
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

  static bool isSafeImageUrl(String? value) {
    if (value == null || value.isEmpty) return false;

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return false;

    return uri.isScheme('https');
  }

  static String _truncateSafely(String value, int maxLength) {
    if (value.length <= maxLength) return value;

    final truncated = value.substring(0, maxLength);
    if (truncated.isEmpty) return '';

    final last = truncated.codeUnitAt(truncated.length - 1);

    if (last >= 0xD800 && last <= 0xDBFF) {
      return truncated.substring(0, truncated.length - 1);
    }

    return truncated;
  }
}
