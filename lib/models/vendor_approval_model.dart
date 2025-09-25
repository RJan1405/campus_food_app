import 'package:cloud_firestore/cloud_firestore.dart';

enum VendorApprovalStatus {
  pending,
  approved,
  rejected,
}

class VendorApprovalModel {
  final String id;
  final String vendorId;
  final String vendorEmail;
  final String vendorName;
  final String shopNumber;
  final double monthlyRent;
  final String document1Url; // Proof of identity
  final String document2Url; // Proof of business/rent agreement
  final String document1Name;
  final String document2Name;
  final VendorApprovalStatus status;
  final String? rejectionReason;
  final String? approvedBy; // Admin ID who approved/rejected
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final Map<String, dynamic> additionalDetails;

  VendorApprovalModel({
    required this.id,
    required this.vendorId,
    required this.vendorEmail,
    required this.vendorName,
    required this.shopNumber,
    required this.monthlyRent,
    required this.document1Url,
    required this.document2Url,
    required this.document1Name,
    required this.document2Name,
    required this.status,
    this.rejectionReason,
    this.approvedBy,
    required this.submittedAt,
    this.reviewedAt,
    this.additionalDetails = const {},
  });

  factory VendorApprovalModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return VendorApprovalModel(
      id: doc.id,
      vendorId: data['vendor_id'] ?? '',
      vendorEmail: data['vendor_email'] ?? '',
      vendorName: data['vendor_name'] ?? '',
      shopNumber: data['shop_number'] ?? '',
      monthlyRent: (data['monthly_rent'] ?? 0.0).toDouble(),
      document1Url: data['document1_url'] ?? '',
      document2Url: data['document2_url'] ?? '',
      document1Name: data['document1_name'] ?? '',
      document2Name: data['document2_name'] ?? '',
      status: VendorApprovalStatus.values.firstWhere(
        (e) => e.toString() == 'VendorApprovalStatus.${data['status']}',
        orElse: () => VendorApprovalStatus.pending,
      ),
      rejectionReason: data['rejection_reason'],
      approvedBy: data['approved_by'],
      submittedAt: (data['submitted_at'] as Timestamp).toDate(),
      reviewedAt: data['reviewed_at'] != null 
          ? (data['reviewed_at'] as Timestamp).toDate() 
          : null,
      additionalDetails: Map<String, dynamic>.from(data['additional_details'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vendor_id': vendorId,
      'vendor_email': vendorEmail,
      'vendor_name': vendorName,
      'shop_number': shopNumber,
      'monthly_rent': monthlyRent,
      'document1_url': document1Url,
      'document2_url': document2Url,
      'document1_name': document1Name,
      'document2_name': document2Name,
      'status': status.toString().split('.').last,
      'rejection_reason': rejectionReason,
      'approved_by': approvedBy,
      'submitted_at': Timestamp.fromDate(submittedAt),
      'reviewed_at': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'additional_details': additionalDetails,
    };
  }

  VendorApprovalModel copyWith({
    String? id,
    String? vendorId,
    String? vendorEmail,
    String? vendorName,
    String? shopNumber,
    double? monthlyRent,
    String? document1Url,
    String? document2Url,
    String? document1Name,
    String? document2Name,
    VendorApprovalStatus? status,
    String? rejectionReason,
    String? approvedBy,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    Map<String, dynamic>? additionalDetails,
  }) {
    return VendorApprovalModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      vendorName: vendorName ?? this.vendorName,
      shopNumber: shopNumber ?? this.shopNumber,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      document1Url: document1Url ?? this.document1Url,
      document2Url: document2Url ?? this.document2Url,
      document1Name: document1Name ?? this.document1Name,
      document2Name: document2Name ?? this.document2Name,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedBy: approvedBy ?? this.approvedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      additionalDetails: additionalDetails ?? this.additionalDetails,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case VendorApprovalStatus.pending:
        return 'Pending Approval';
      case VendorApprovalStatus.approved:
        return 'Approved';
      case VendorApprovalStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isPending => status == VendorApprovalStatus.pending;
  bool get isApproved => status == VendorApprovalStatus.approved;
  bool get isRejected => status == VendorApprovalStatus.rejected;
}
