import 'package:cloud_firestore/cloud_firestore.dart';

enum CancellationRequestStatus {
  pending,
  approved,
  rejected,
}

class CancellationRequestModel {
  final String id;
  final String orderId;
  final String studentId;
  final String vendorId;
  final String reason;
  final CancellationRequestStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? vendorResponse;

  CancellationRequestModel({
    required this.id,
    required this.orderId,
    required this.studentId,
    required this.vendorId,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
    this.vendorResponse,
  });

  factory CancellationRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CancellationRequestModel(
      id: doc.id,
      orderId: data['order_id'] ?? '',
      studentId: data['student_id'] ?? '',
      vendorId: data['vendor_id'] ?? '',
      reason: data['reason'] ?? '',
      status: _parseStatus(data['status']),
      requestedAt: (data['requested_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['responded_at'] as Timestamp?)?.toDate(),
      vendorResponse: data['vendor_response'],
    );
  }

  static CancellationRequestStatus _parseStatus(dynamic status) {
    if (status == null) return CancellationRequestStatus.pending;
    switch (status.toString().toLowerCase()) {
      case 'pending':
        return CancellationRequestStatus.pending;
      case 'approved':
        return CancellationRequestStatus.approved;
      case 'rejected':
        return CancellationRequestStatus.rejected;
      default:
        return CancellationRequestStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'student_id': studentId,
      'vendor_id': vendorId,
      'reason': reason,
      'status': status.toString().split('.').last,
      'requested_at': Timestamp.fromDate(requestedAt),
      'responded_at': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'vendor_response': vendorResponse,
    };
  }

  CancellationRequestModel copyWith({
    String? id,
    String? orderId,
    String? studentId,
    String? vendorId,
    String? reason,
    CancellationRequestStatus? status,
    DateTime? requestedAt,
    DateTime? respondedAt,
    String? vendorResponse,
  }) {
    return CancellationRequestModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      studentId: studentId ?? this.studentId,
      vendorId: vendorId ?? this.vendorId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      vendorResponse: vendorResponse ?? this.vendorResponse,
    );
  }
}
