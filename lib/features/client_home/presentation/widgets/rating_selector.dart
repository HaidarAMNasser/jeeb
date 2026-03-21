import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';

class RatingSelector extends StatelessWidget {
  final int? selectedRating;
  final ValueChanged<int?> onRatingSelected;

  const RatingSelector({
    super.key,
    this.selectedRating,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = selectedRating != null && rating <= selectedRating!;

        return _SpinningStar(
          isSelected: isSelected,
          onTap: () =>
              onRatingSelected(selectedRating == rating ? null : rating),
        );
      }),
    );
  }
}

class _SpinningStar extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _SpinningStar({required this.isSelected, required this.onTap});

  @override
  State<_SpinningStar> createState() => _SpinningStarState();
}

class _SpinningStarState extends State<_SpinningStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_SpinningStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.p4),
          child: Icon(
            widget.isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 32,
            color: widget.isSelected
                ? ColorManager.primary
                : ColorManager.borderColor,
          ),
        ),
      ),
    );
  }
}
