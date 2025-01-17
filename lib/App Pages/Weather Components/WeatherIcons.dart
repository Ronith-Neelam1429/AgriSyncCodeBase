import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  final String weatherType;
  final bool isNight;
  final double size;
  final Color? color;

  const WeatherIcon({
    super.key,
    required this.weatherType,
    this.isNight = false,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    switch (weatherType.toLowerCase()) {
      case 'clear':
        return isNight
            ? MoonIcon(size: size, color: color ?? Colors.white)
            : SunIcon(size: size, color: const Color(0xFFFFD700));
      case 'cloudy':
        return StackedCloudsIcon(
          size: size,
          color: color ?? Colors.white,
          isNight: isNight,
        );
      case 'rainy':
        return RainyIcon(
          size: size,
          color: color ?? Colors.white,
          isNight: isNight,
        );
      case 'stormy':
        return StormyIcon(
          size: size,
          color: color ?? Colors.white,
          isNight: isNight,
        );
      default:
        return const SizedBox();
    }
  }
}

class SunIcon extends StatefulWidget {
  final double size;
  final Color color;

  const SunIcon({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  State<SunIcon> createState() => _SunIconState();
}

class _SunIconState extends State<SunIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            Icons.wb_sunny_rounded,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class MoonIcon extends StatefulWidget {
  final double size;
  final Color color;

  const MoonIcon({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  State<MoonIcon> createState() => _MoonIconState();
}

class _MoonIconState extends State<MoonIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            Icons.nightlight_round,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class StackedCloudsIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool isNight;

  const StackedCloudsIcon({
    super.key,
    required this.size,
    required this.color,
    this.isNight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cloudColor = isNight ? color.withOpacity(0.7) : color;
    
    return SizedBox(  // Add size constraints
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,  // Allow overflow if needed
        children: [
          if (isNight) 
            Positioned(
              right: size * 0.1,
              top: size * 0.1,
              child: Icon(
                Icons.nightlight_round,
                size: size * 0.7,
                color: color.withOpacity(0.3),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            child: Icon(
              Icons.cloud_rounded,
              size: size,
              color: cloudColor.withOpacity(0.9),
            ),
          ),
          Positioned(
            left: size * 0.1,
            top: size * 0.1,
            child: Icon(
              Icons.cloud_rounded,
              size: size,
              color: cloudColor,
            ),
          ),
          Positioned(
            left: size * 0.2,
            top: size * 0.2,
            child: Icon(
              Icons.cloud_rounded,
              size: size * 0.8,
              color: cloudColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
class RainyIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool isNight;

  const RainyIcon({
    super.key,
    required this.size,
    required this.color,
    this.isNight = false,
  });

  @override
  State<RainyIcon> createState() => _RainyIconState();
}

class _RainyIconState extends State<RainyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 10.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloudColor =
        widget.isNight ? widget.color.withOpacity(0.7) : widget.color;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          if (widget.isNight)
            Positioned(
              right: widget.size * 0.1,
              top: widget.size * 0.1,
              child: Icon(
                Icons.nightlight_round,
                size: widget.size * 0.7,
                color: widget.color.withOpacity(0.3),
              ),
            ),
          Icon(
            Icons.cloud_rounded,
            size: widget.size,
            color: cloudColor,
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: _animation.value,
                child: Icon(
                  Icons.water_drop_rounded,
                  size: widget.size * 0.5,
                  color: widget.color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class StormyIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool isNight;

  const StormyIcon({
    super.key,
    required this.size,
    required this.color,
    this.isNight = false,
  });

  @override
  State<StormyIcon> createState() => _StormyIconState();
}

class _StormyIconState extends State<StormyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloudColor =
        widget.isNight ? widget.color.withOpacity(0.7) : widget.color;

    return Stack(
      children: [
        if (widget.isNight)
          Positioned(
            right: widget.size * 0.1,
            top: widget.size * 0.1,
            child: Icon(
              Icons.nightlight_round,
              size: widget.size * 0.7,
              color: widget.color.withOpacity(0.3),
            ),
          ),
        Icon(
          Icons.cloud_rounded,
          size: widget.size,
          color: cloudColor,
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Icon(
                Icons.flash_on_rounded,
                size: widget.size * 0.6,
                color: const Color(0xFFFFD700),
              ),
            );
          },
        ),
      ],
    );
  }
}
