import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../storage/preferences_service.dart';
import 'api_endpoints.dart';

/// Data class representing any real-time event received or sent via Socket.IO.
class SocketEventData {
  final String event;
  final dynamic data;
  final DateTime timestamp;

  SocketEventData({
    required this.event,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'SocketEventData(event: $event, data: $data, time: $timestamp)';
}

/// Centralized catalog of all MYPGPMS Socket.IO event names.
class SocketEvents {
  SocketEvents._();

  // Visitors module
  static const String visitorNew = 'visitor:new';
  static const String visitorStatusUpdated = 'visitor:status_updated';
  static const String visitorEntry = 'visitor:entry';
  static const String visitorStatsUpdated = 'visitor:stats_updated';

  // Maintenance & Complaints module
  static const String complaintNew = 'complaint:new';
  static const String complaintStatusUpdated = 'complaint:status_updated';
  static const String complaintActivity = 'complaint:activity';
  static const String complaintStatsUpdated = 'complaint:stats_updated';

  // Notices & Broadcasts module
  static const String noticeNew = 'notice:new';
  static const String noticeStatsUpdated = 'notice:stats_updated';

  // Payments module
  static const String paymentNew = 'payment:new';
  static const String paymentStatusUpdated = 'payment:status_updated';
  static const String paymentStatsUpdated = 'payment:stats_updated';

  // Room & Shifts module
  static const String roomShiftNew = 'room_shift:new';
  static const String roomShiftStatusUpdated = 'room_shift:status_updated';
  static const String roomNew = 'room:new';
  static const String roomUpdated = 'room:updated';
  static const String roomDeleted = 'room:deleted';
  static const String roomStatsUpdated = 'room:stats_updated';

  // Stay Clearance & Checkout module
  static const String checkoutNew = 'checkout:new';
  static const String checkoutStatusUpdated = 'checkout:status_updated';

  // Community Feed & Social Hub module
  static const String communityPostNew = 'community:post_new';
  static const String communityPostLiked = 'community:post_liked';
  static const String communityCommentNew = 'community:comment_new';
  static const String notificationNew = 'notification:new';
  static const String subscribePost = 'subscribe:post';
  static const String unsubscribePost = 'unsubscribe:post';

  // User & Staff module
  static const String userNew = 'user:new';
  static const String userUpdated = 'user:updated';
  static const String residentStatsUpdated = 'resident:stats_updated';
  static const String staffStatsUpdated = 'staff:stats_updated';
  static const String branchStatsUpdated = 'branch:stats_updated';
  static const String buildingStatsUpdated = 'building:stats_updated';

  // Dashboard & Global Stats
  static const String dashboardStatsUpdated = 'dashboard:stats_updated';
}

/// Robust, production-grade Socket.IO client manager for MYPGPMS.
/// Handles JWT authentication handshake, auto-reconnection, multi-tenant room subscriptions,
/// and bidirectional event dispatching across all feature APIs.
class SocketService {
  final PreferencesService preferencesService;
  final String serverUrl;

  io.Socket? _socket;
  bool _isConnected = false;

  final Map<String, List<Function(dynamic)>> _listeners = {};
  final List<Function(String, dynamic)> _anyListeners = [];

  // Stream Controllers for Reactive Architecture
  final _connectionStateController = StreamController<bool>.broadcast();
  final _allEventsController = StreamController<SocketEventData>.broadcast();
  final _visitorEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _complaintEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _noticeEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _paymentEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _roomShiftEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _checkoutEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _dashboardEventController = StreamController<Map<String, dynamic>>.broadcast();

  SocketService({
    required this.preferencesService,
    this.serverUrl = ApiEndpoints.socketBaseUrl,
  });

  /// Current connection status.
  bool get isConnected => _isConnected && (_socket?.connected ?? false);

  /// Reactive stream of connection state (true: connected, false: disconnected).
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Reactive stream of all received socket events.
  Stream<SocketEventData> get allEventsStream => _allEventsController.stream;

  /// Reactive stream for real-time visitor events.
  Stream<Map<String, dynamic>> get visitorEventStream => _visitorEventController.stream;

  /// Reactive stream for real-time complaint events.
  Stream<Map<String, dynamic>> get complaintEventStream => _complaintEventController.stream;

  /// Reactive stream for real-time notice events.
  Stream<Map<String, dynamic>> get noticeEventStream => _noticeEventController.stream;

  /// Reactive stream for real-time payment events.
  Stream<Map<String, dynamic>> get paymentEventStream => _paymentEventController.stream;

  /// Reactive stream for real-time room shift events.
  Stream<Map<String, dynamic>> get roomShiftEventStream => _roomShiftEventController.stream;

  /// Reactive stream for real-time stay checkout events.
  Stream<Map<String, dynamic>> get checkoutEventStream => _checkoutEventController.stream;

  /// Reactive stream for dashboard stats events.
  Stream<Map<String, dynamic>> get dashboardEventStream => _dashboardEventController.stream;

  /// Direct socket instance if low-level control is needed.
  io.Socket? get socket => _socket;

  /// Connect to the Socket.IO server with the user's JWT access token.
  void connect({String? customToken}) {
    final token = customToken ?? preferencesService.accessToken;

    if (token == null || token.isEmpty) {
      debugPrint('[SocketService] Cannot connect: No access token found in storage.');
      return;
    }

    if (_socket != null) {
      if (_socket!.connected) {
        debugPrint('[SocketService] Already connected with ID: ${_socket!.id}');
        return;
      }
      debugPrint('[SocketService] Reconnecting existing socket instance...');
      _socket!.connect();
      return;
    }

    try {
      debugPrint('[SocketService] Initializing WebSocket connection to $serverUrl ...');

      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setQuery({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(9999)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(25000)
            .build(),
      );

      _setupInternalListeners();
      _socket?.connect();
    } catch (e) {
      debugPrint('[SocketService] Exception during socket initialization: $e');
    }
  }

  void _setupInternalListeners() {
    final s = _socket;
    if (s == null) return;

    s.onConnect((_) {
      _isConnected = true;
      _connectionStateController.add(true);
      debugPrint('🟢 [SocketService] Connected successfully with ID: ${s.id}');
    });

    s.onDisconnect((reason) {
      _isConnected = false;
      _connectionStateController.add(false);
      debugPrint('🟡 [SocketService] Disconnected. Reason: $reason');
    });

    s.onConnectError((err) {
      _isConnected = false;
      _connectionStateController.add(false);
      debugPrint('🔴 [SocketService] Connection error: $err');
    });

    s.onError((err) {
      debugPrint('🔴 [SocketService] General error: $err');
    });

    // Global catch-all event listener: dispatches to streams, generic listeners, and event-specific callbacks
    s.onAny((event, [data]) {
      _dispatchIncomingEvent(event.toString(), data);
    });
  }

  void _dispatchIncomingEvent(String event, dynamic data) {
    debugPrint('⚡ [SocketService] Incoming event: "$event" | data: $data');

    // Add to global event stream
    if (!_allEventsController.isClosed) {
      _allEventsController.add(SocketEventData(event: event, data: data));
    }

    // Route to typed stream controllers
    final lower = event.toLowerCase();
    if (lower.contains('visitor')) {
      _routeMapData(_visitorEventController, data);
    }
    if (lower.contains('complaint')) {
      _routeMapData(_complaintEventController, data);
    }
    if (lower.contains('notice')) {
      _routeMapData(_noticeEventController, data);
    }
    if (lower.contains('payment')) {
      _routeMapData(_paymentEventController, data);
    }
    if (lower.contains('room_shift') || (lower.contains('room') && lower.contains('shift'))) {
      _routeMapData(_roomShiftEventController, data);
    }
    if (lower.contains('checkout')) {
      _routeMapData(_checkoutEventController, data);
    }
    if (lower.contains('dashboard') || lower.contains('stats')) {
      _routeMapData(_dashboardEventController, data);
    }

    // 1. Dispatch to global catch-all listeners
    for (final handler in List<Function(String, dynamic)>.from(_anyListeners)) {
      try {
        handler(event, data);
      } catch (e) {
        debugPrint('[SocketService] Error in anyListener for "$event": $e');
      }
    }

    // 2. Dispatch to specific event listeners
    final handlers = _listeners[event];
    if (handlers != null && handlers.isNotEmpty) {
      for (final handler in List<Function(dynamic)>.from(handlers)) {
        try {
          handler(data);
        } catch (e) {
          debugPrint('[SocketService] Error in handler for "$event": $e');
        }
      }
    }
  }

  void _routeMapData(StreamController<Map<String, dynamic>> controller, dynamic data) {
    if (controller.isClosed) return;
    if (data is Map<String, dynamic>) {
      controller.add(data);
    } else if (data is Map) {
      controller.add(Map<String, dynamic>.from(data));
    }
  }

  /// Listen for an event dispatched from the server.
  /// Listeners remain active across reconnections.
  void on(String event, Function(dynamic) handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
    if (_socket == null || !_socket!.connected) {
      connect();
    }
  }

  /// Stop listening for a specific event.
  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _listeners[event]?.remove(handler);
    } else {
      _listeners.remove(event);
    }
  }

  /// Catch-all listener: called whenever ANY event is emitted by the server.
  void onAny(Function(String event, dynamic data) handler) {
    _anyListeners.add(handler);
    if (_socket == null || !_socket!.connected) {
      connect();
    }
  }

  /// Stop listening to catch-all events.
  void offAny([Function(String event, dynamic data)? handler]) {
    if (handler != null) {
      _anyListeners.remove(handler);
    } else {
      _anyListeners.clear();
    }
  }

  /// Generic emit an event to the server.
  void emit(String event, [dynamic data]) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[SocketService] Notice: Socket is connecting, queuing/emitting "$event"...');
      connect();
    }
    _socket?.emit(event, data);
  }

  // =========================================================================
  // Dedicated API Client Emitters (Call socket whenever an API mutates data)
  // =========================================================================

  /// Notify socket when a visitor is created via API.
  void notifyVisitorCreated(Map<String, dynamic> data) {
    debugPrint('[SocketService] Calling socket: ${SocketEvents.visitorNew}');
    emit(SocketEvents.visitorNew, data);
    emit(SocketEvents.visitorStatsUpdated, data);
    emit(SocketEvents.dashboardStatsUpdated, data);
  }

  /// Notify socket when a visitor is updated or pass is changed via API.
  void notifyVisitorUpdated(Map<String, dynamic> data) {
    debugPrint('[SocketService] Calling socket: ${SocketEvents.visitorStatusUpdated}');
    emit(SocketEvents.visitorStatusUpdated, data);
    emit(SocketEvents.visitorStatsUpdated, data);
    emit(SocketEvents.dashboardStatsUpdated, data);
  }

  /// Notify socket when a complaint is registered via API.
  void notifyComplaintCreated(Map<String, dynamic> data) {
    debugPrint('[SocketService] Calling socket: ${SocketEvents.complaintNew}');
    emit(SocketEvents.complaintNew, data);
    emit(SocketEvents.complaintStatsUpdated, data);
    emit(SocketEvents.dashboardStatsUpdated, data);
  }

  /// Notify socket when a payment transaction is initiated or completed.
  void notifyPaymentUpdated(Map<String, dynamic> data) {
    debugPrint('[SocketService] Calling socket: ${SocketEvents.paymentStatusUpdated}');
    emit(SocketEvents.paymentStatusUpdated, data);
    emit(SocketEvents.paymentStatsUpdated, data);
    emit(SocketEvents.dashboardStatsUpdated, data);
  }

  /// Notify socket when a room shift request is submitted via API.
  void notifyRoomShiftCreated(Map<String, dynamic> data) {
    debugPrint('[SocketService] Calling socket: ${SocketEvents.roomShiftNew}');
    emit(SocketEvents.roomShiftNew, data);
    emit(SocketEvents.roomStatsUpdated, data);
    emit(SocketEvents.dashboardStatsUpdated, data);
  }

  /// Notify socket when a checkout/vacate request is submitted via API.
  void notifyCheckoutCreated(Map<String, dynamic> data) {
    debugPrint('[SocketService] Calling socket: ${SocketEvents.checkoutNew}');
    emit(SocketEvents.checkoutNew, data);
    emit(SocketEvents.dashboardStatsUpdated, data);
  }

  /// Notify socket of general dashboard metric changes.
  void notifyDashboardStatsChanged([Map<String, dynamic>? data]) {
    debugPrint('[SocketService] Calling socket: ${SocketEvents.dashboardStatsUpdated}');
    emit(SocketEvents.dashboardStatsUpdated, data ?? {});
  }

  /// Subscribe to dynamic topic room for a specific community post thread.
  void subscribeToPost(dynamic postId) {
    debugPrint('[SocketService] Subscribing to post thread: $postId');
    emit(SocketEvents.subscribePost, postId);
  }

  /// Unsubscribe from a community post thread.
  void unsubscribeFromPost(dynamic postId) {
    debugPrint('[SocketService] Unsubscribing from post thread: $postId');
    emit(SocketEvents.unsubscribePost, postId);
  }

  /// Disconnect socket connection cleanly.
  void disconnect() {
    if (_socket != null) {
      debugPrint('[SocketService] Disconnecting socket...');
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _connectionStateController.add(false);
    }
  }

  /// Dispose of all streams and close socket connection.
  void dispose() {
    disconnect();
    _listeners.clear();
    _anyListeners.clear();
    _connectionStateController.close();
    _allEventsController.close();
    _visitorEventController.close();
    _complaintEventController.close();
    _noticeEventController.close();
    _paymentEventController.close();
    _roomShiftEventController.close();
    _checkoutEventController.close();
    _dashboardEventController.close();
  }
}
