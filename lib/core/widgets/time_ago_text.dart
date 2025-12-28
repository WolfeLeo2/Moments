import 'dart:async';
import 'package:flutter/material.dart';

class TimeAgoText extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const TimeAgoText({
    super.key,
    required this.dateTime,
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<TimeAgoText> createState() => _TimeAgoTextState();
}

class _TimeAgoTextState extends State<TimeAgoText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(TimeAgoText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateTime != widget.dateTime) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final now = DateTime.now();
    final difference = now.difference(widget.dateTime);

    // Determine update interval based on age
    Duration interval;
    if (difference.inMinutes < 1) {
      interval = const Duration(seconds: 10); // Update every 10s for "just now"
    } else if (difference.inHours < 1) {
      interval = const Duration(minutes: 1); // Update every minute
    } else {
      interval = const Duration(minutes: 15); // Update less frequently
    }

    _timer = Timer.periodic(interval, (timer) {
      if (mounted) setState(() {});
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 30) {
      return 'just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix}${_formatTimeAgo(widget.dateTime)}${widget.suffix}',
      style: widget.style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
