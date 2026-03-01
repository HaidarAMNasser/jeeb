import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/theme/values_manager.dart';

class FloatingIcons extends StatefulWidget {
  final int pageIndex;
  final int iconCount;

  const FloatingIcons({super.key, required this.pageIndex, this.iconCount = 5});

  @override
  State<FloatingIcons> createState() => _FloatingIconsState();
}

class _FloatingIconsState extends State<FloatingIcons>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<IconData> _icons;
  late List<Offset> _positions;

  // Food-related icons
  final List<IconData> _foodIcons = [
    // Utensils
    Icons.restaurant,
    Icons.restaurant_menu,
    Icons.local_dining,
    Icons.ramen_dining,
    Icons.lunch_dining,
    // Fast food & burgers
    Icons.fastfood,
    Icons.local_pizza,
    // Desserts
    Icons.cake,
    Icons.icecream,
    Icons.local_cafe,
    Icons.emoji_food_beverage,
    // Kitchen & service
    Icons.room_service,
    // Shopping
    Icons.shopping_bag,
    Icons.shopping_cart,
    // More food items
    Icons.soup_kitchen,
    Icons.dining,
  ];

  @override
  void initState() {
    super.initState();
    _setupIcons();
    _setupAnimations();
  }

  void _setupIcons() {
    // Use pageIndex as seed for consistent randomness per page
    final random = math.Random(widget.pageIndex);
    final iconCount =
        widget.iconCount + random.nextInt(6); // 5-11 icons (more foody icons)

    _icons = [];
    _positions = [];

    for (int i = 0; i < iconCount; i++) {
      // Pick random icon
      _icons.add(_foodIcons[random.nextInt(_foodIcons.length)]);

      // Random position starting from top of screen and going upward
      final startY =
          0.05 + (random.nextDouble() * 0.35); // 5-40% from top (higher reach)
      
      // For page index 1, distribute icons more on left and right sides
      double x;
      if (widget.pageIndex == 1) {
        // Distribute icons on left and right sides, avoiding center (0.35-0.65)
        if (i % 2 == 0) {
          // Left side: 0.0 to 0.35
          x = random.nextDouble() * 0.35;
        } else {
          // Right side: 0.65 to 1.0
          x = 0.65 + (random.nextDouble() * 0.35);
        }
      } else {
        // For other pages, distribute evenly across the entire width
        x = (i / iconCount) * 0.9 + (random.nextDouble() * 0.1);
      }
      
      _positions.add(Offset(x, startY));
    }
  }

  void _setupAnimations() {
    _controllers = [];
    _animations = [];
    final random = math.Random(widget.pageIndex);

    for (int i = 0; i < _icons.length; i++) {
      final controller = AnimationController(
        duration: Duration(
          milliseconds: 3000 + random.nextInt(2000), // 3-5 seconds
        ),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: _positions[i].dy,
        end:
            _positions[i].dy -
            (0.30 +
                random.nextDouble() *
                    0.20), // Move upward more (30-50% of screen) - higher reach
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _controllers.add(controller);
      _animations.add(animation);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = math.Random(widget.pageIndex);

    return Stack(
      children: List.generate(_icons.length, (index) {
        // More varied opacity - some very low, some medium
        final opacity = index % 4 == 0
            ? 0.08 +
                  random.nextDouble() *
                      0.12 // 0.08-0.2 for some icons (very low)
            : index % 3 == 0
            ? 0.15 +
                  random.nextDouble() *
                      0.2 // 0.15-0.35 for others (low-medium)
            : 0.3 + random.nextDouble() * 0.3; // 0.3-0.6 for rest (medium-high)

        final iconSize =
            AppSize.s20 + random.nextDouble() * AppSize.s16; // 20-36 size

        // Vibrant colors for some icons
        final useVibrantColor = index % 5 == 0 || index % 5 == 2;
        final iconColor = useVibrantColor
            ? (index % 3 == 0
                  ? ColorManager.accent
                  : index % 3 == 1
                  ? ColorManager.secondary
                  : ColorManager.success)
            : ColorManager.primary;

        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Positioned(
              left: _positions[index].dx * size.width,
              top: _animations[index].value * size.height,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  _icons[index],
                  size: iconSize,
                  color: iconColor.withOpacity(useVibrantColor ? 0.8 : 0.6),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
