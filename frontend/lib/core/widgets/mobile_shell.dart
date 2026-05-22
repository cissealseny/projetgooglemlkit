import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_colors.dart';
import '../theme/design_tokens.dart';
import '../../features/generative/pages/chat_page.dart';

/// Premium mobile-first shell with bottom navigation
/// Features elegant floating tab bar with subtle animations
class MobileShell extends StatefulWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onNavigate;

  const MobileShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onNavigate,
  });

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<_NavItem> _navItems = const [
    _NavItem(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'Accueil'),
    _NavItem(
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on_rounded,
      label: 'Centres'),

    _NavItem(
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome_rounded,
        label: 'IA'),
    _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: DesignDurations.normal,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showEcoAssistantBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final screenHeight = MediaQuery.of(context).size.height;
        // Total available height excluding keyboard and status bar
        final availableHeight = screenHeight - keyboardHeight - MediaQuery.of(context).viewPadding.top;
        final sheetHeight = (screenHeight * 0.82).clamp(0.0, availableHeight);

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignRadius.xl),
              topRight: Radius.circular(DesignRadius.xl),
            ),
            child: SizedBox(
              height: sheetHeight,
              child: const ChatPage(isBottomSheet: true),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            widget.child,
            if (widget.currentIndex != 2)
              _DraggableChatButton(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showEcoAssistantBottomSheet(context);
                },
              ),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: DesignSpacing.md,
            right: DesignSpacing.md,
            bottom: bottomPadding + DesignSpacing.sm,
          ),
          child: _PremiumNavBar(
            items: _navItems,
            currentIndex: widget.currentIndex,
            onTap: widget.onNavigate,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Premium floating navigation bar
class _PremiumNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final void Function(int) onTap;
  final bool isDark;

  const _PremiumNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? DesignColors.cardDark : DesignColors.surfaceLight,
        borderRadius: DesignRadius.radiusXl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark
              ? DesignColors.borderDark.withValues(alpha: 0.5)
              : DesignColors.borderLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          return _NavBarItem(
            item: items[index],
            isSelected: currentIndex == index,
            onTap: () => onTap(index),
            isDark: isDark,
          );
        }),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) => _controller.forward();
  void _handleTapUp(_) => _controller.reverse();
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isDark ? DesignColors.accent : DesignColors.primary;
    final inactiveColor = widget.isDark
        ? DesignColors.textTertiaryDark
        : DesignColors.textTertiaryLight;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: DesignDurations.fast,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: DesignRadius.radiusMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: DesignDurations.fast,
                child: Icon(
                  widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                  key: ValueKey(widget.isSelected),
                  size: 24,
                  color: widget.isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: DesignDurations.fast,
                style: DesignTypography.caption(
                  widget.isSelected ? activeColor : inactiveColor,
                ).copyWith(
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page transition for mobile navigation
class MobilePageTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const MobilePageTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: child,
      ),
    );
  }
}

class _DraggableChatButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DraggableChatButton({required this.onTap});

  @override
  State<_DraggableChatButton> createState() => _DraggableChatButtonState();
}

class _DraggableChatButtonState extends State<_DraggableChatButton>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(-1.0, -1.0);
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    // Default position: bottom right, above the navigation bar
    if (_position.dx == -1.0 && _position.dy == -1.0) {
      _position = Offset(
        size.width - 76.0, // 56 button width + 20 margin
        size.height - 156.0 - bottomPadding, 
      );
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
          HapticFeedback.selectionClick();
        },
        onPanUpdate: (details) {
          setState(() {
            double newX = _position.dx + details.delta.dx;
            double newY = _position.dy + details.delta.dy;

            // Constrain within screen boundaries
            newX = newX.clamp(16.0, size.width - 72.0);
            newY = newY.clamp(
              MediaQuery.of(context).viewPadding.top + 16.0,
              size.height - 100.0 - bottomPadding,
            );

            _position = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        onTap: () {
          if (!_isDragging) {
            widget.onTap();
          }
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragging ? 0.95 : _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: DesignColors.generativeGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DesignColors.generative.withValues(alpha: 0.4),
                  blurRadius: _isDragging ? 8 : 16,
                  spreadRadius: _isDragging ? 1 : 2,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
