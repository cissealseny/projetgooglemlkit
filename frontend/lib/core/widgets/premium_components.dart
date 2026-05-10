import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_colors.dart';
import '../theme/design_tokens.dart';

/// ══════════════════════════════════════════════════════════════
/// PREMIUM CARD COMPONENT
/// Clean, minimal card with subtle shadow and optional gradient
/// ══════════════════════════════════════════════════════════════

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool hasBorder;
  final bool hasShadow;
  final BorderRadius? borderRadius;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.hasBorder = true,
    this.hasShadow = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? DesignColors.cardDark : DesignColors.cardLight);
    final borderColor =
        isDark ? DesignColors.borderDark : DesignColors.borderLight;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? bgColor : null,
        gradient: gradient,
        borderRadius: borderRadius ?? DesignRadius.radiusLg,
        border: hasBorder ? Border.all(color: borderColor, width: 1) : null,
        boxShadow: hasShadow ? DesignColors.shadowSm : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? DesignRadius.radiusLg,
          child: Padding(
            padding: padding ?? DesignSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ══════════════════════════════════════════════════════════════
/// FEATURE CARD - For feature highlights
/// ══════════════════════════════════════════════════════════════

class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isCompact;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accentColor,
    this.onTap,
    this.isCompact = false,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignDurations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.isCompact
              ? const EdgeInsets.all(12)
              : DesignSpacing.cardPadding,
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: DesignRadius.radiusLg,
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: widget.isCompact
              ? _buildCompactContent(isDark)
              : _buildFullContent(isDark),
        ),
      ),
    );
  }

  Widget _buildCompactContent(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.15),
            borderRadius: DesignRadius.radiusMd,
          ),
          child: Icon(
            widget.icon,
            color: widget.accentColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.title,
          style: DesignTypography.labelLarge(
            isDark
                ? DesignColors.textPrimaryDark
                : DesignColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFullContent(bool isDark) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accentColor,
                widget.accentColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: DesignRadius.radiusMd,
            boxShadow: DesignColors.shadowColored(widget.accentColor),
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: DesignTypography.titleMedium(
                  isDark
                      ? DesignColors.textPrimaryDark
                      : DesignColors.textPrimaryLight,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: DesignTypography.bodySmall(
                    isDark
                        ? DesignColors.textSecondaryDark
                        : DesignColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: widget.accentColor,
        ),
      ],
    );
  }
}

/// ══════════════════════════════════════════════════════════════
/// STAT CARD - For displaying metrics
/// ══════════════════════════════════════════════════════════════

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? accentColor;
  final String? trend;
  final bool isTrendPositive;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accentColor,
    this.trend,
    this.isTrendPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? DesignColors.primary;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: DesignRadius.radiusSm,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTrendPositive
                        ? DesignColors.successLight
                        : DesignColors.errorLight,
                    borderRadius: DesignRadius.radiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrendPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: isTrendPositive
                            ? DesignColors.success
                            : DesignColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: DesignTypography.labelSmall(
                          isTrendPositive
                              ? DesignColors.success
                              : DesignColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: DesignTypography.headlineLarge(
              isDark
                  ? DesignColors.textPrimaryDark
                  : DesignColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: DesignTypography.bodySmall(
              isDark
                  ? DesignColors.textSecondaryDark
                  : DesignColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// ══════════════════════════════════════════════════════════════
/// PREMIUM INPUT FIELD
/// ══════════════════════════════════════════════════════════════

class PremiumInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int maxLines;
  final bool autofocus;

  const PremiumInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLines: maxLines,
          autofocus: autofocus,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// ══════════════════════════════════════════════════════════════
/// PREMIUM BUTTON
/// ══════════════════════════════════════════════════════════════

enum PremiumButtonVariant { primary, secondary, outline, ghost, accent }

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets? padding;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PremiumButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  });

  const PremiumButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = PremiumButtonVariant.primary;

  const PremiumButton.accent({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = PremiumButtonVariant.accent;

  const PremiumButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = PremiumButtonVariant.outline;

  const PremiumButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = PremiumButtonVariant.ghost;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignDurations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildButton(isDark),
      ),
    );
  }

  Widget _buildButton(bool isDark) {
    final child = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getForegroundColor(isDark),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(widget.label),
      ],
    );

    switch (widget.variant) {
      case PremiumButtonVariant.primary:
        return SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              padding: widget.padding,
              backgroundColor: DesignColors.primary,
              foregroundColor: Colors.white,
            ),
            child: child,
          ),
        );

      case PremiumButtonVariant.secondary:
        return SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              padding: widget.padding,
              backgroundColor: DesignColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: child,
          ),
        );

      case PremiumButtonVariant.accent:
        return SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              padding: widget.padding,
              backgroundColor: DesignColors.accent,
              foregroundColor: DesignColors.primary,
            ),
            child: child,
          ),
        );

      case PremiumButtonVariant.outline:
        return SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(padding: widget.padding),
            child: child,
          ),
        );

      case PremiumButtonVariant.ghost:
        return SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: TextButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: TextButton.styleFrom(padding: widget.padding),
            child: child,
          ),
        );
    }
  }

  Color _getForegroundColor(bool isDark) {
    switch (widget.variant) {
      case PremiumButtonVariant.primary:
      case PremiumButtonVariant.secondary:
        return Colors.white;
      case PremiumButtonVariant.accent:
        return DesignColors.primary;
      case PremiumButtonVariant.outline:
      case PremiumButtonVariant.ghost:
        return isDark ? DesignColors.accent : DesignColors.primary;
    }
  }
}

/// ══════════════════════════════════════════════════════════════
/// SECTION HEADER
/// ══════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTypography.titleLarge(
                    isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: DesignTypography.bodySmall(
                      isDark
                          ? DesignColors.textSecondaryDark
                          : DesignColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// ══════════════════════════════════════════════════════════════
/// EMPTY STATE
/// ══════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: DesignSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDark
                        ? DesignColors.borderDark
                        : DesignColors.borderLight)
                    .withValues(alpha: 0.5),
                borderRadius: DesignRadius.radiusXl,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark
                    ? DesignColors.textTertiaryDark
                    : DesignColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: DesignTypography.titleLarge(
                isDark
                    ? DesignColors.textPrimaryDark
                    : DesignColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: DesignTypography.bodyMedium(
                  isDark
                      ? DesignColors.textSecondaryDark
                      : DesignColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ══════════════════════════════════════════════════════════════
/// LOADING INDICATOR
/// ══════════════════════════════════════════════════════════════

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indicatorColor =
        color ?? (isDark ? DesignColors.accent : DesignColors.primary);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: DesignTypography.bodyMedium(
                isDark
                    ? DesignColors.textSecondaryDark
                    : DesignColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ══════════════════════════════════════════════════════════════
/// AVATAR
/// ══════════════════════════════════════════════════════════════

class PremiumAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? backgroundColor;

  const PremiumAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .take(2)
            .map((s) => s.isNotEmpty ? s[0] : '')
            .join()
            .toUpperCase()
        : '?';

    final bgColor = backgroundColor ?? _generateColorFromName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 2),
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials,
                style: DesignTypography.labelLarge(Colors.white).copyWith(
                  fontSize: size * 0.4,
                ),
              ),
            )
          : null,
    );
  }

  Color _generateColorFromName(String name) {
    final colors = [
      DesignColors.vision,
      DesignColors.nlp,
      DesignColors.generative,
      DesignColors.secondary,
      DesignColors.primary,
    ];

    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }
}
