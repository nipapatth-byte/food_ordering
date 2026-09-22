import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationOverlay extends StatefulWidget {
  final String? userId;
  final Widget child;

  const NotificationOverlay({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _subscribedUserId;
  final Set<String> _knownIds = {};
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribedUserId != widget.userId) {
      _subscription?.cancel();
      _subscribedUserId = widget.userId;
      _knownIds.clear();
      _ready = false;
      final userId = widget.userId;
      if (userId != null) {
        _subscription = NotificationService()
            .streamForUser(userId)
            .listen(_onNotifications);
      }
    }
  }

  void _onNotifications(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final newDocs = snapshot.docs
        .where((doc) => !_knownIds.contains(doc.id))
        .toList();
    _knownIds.addAll(snapshot.docs.map((doc) => doc.id));
    if (!_ready) {
      _ready = true;
      return;
    }
    if (newDocs.isEmpty || !mounted) return;
    final data = newDocs.first.data();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${data['title'] ?? 'การแจ้งเตือน'}: ${data['message'] ?? ''}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
