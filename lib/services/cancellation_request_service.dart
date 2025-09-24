import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_food_app/models/cancellation_request_model.dart';

class CancellationRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new cancellation request
  Future<String> createCancellationRequest({
    required String orderId,
    required String vendorId,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final requestId = _firestore.collection('cancellation_requests').doc().id;
      
      final request = CancellationRequestModel(
        id: requestId,
        orderId: orderId,
        vendorId: vendorId,
        studentId: user.uid,
        reason: reason,
        status: CancellationRequestStatus.pending,
        requestedAt: DateTime.now(),
      );

      await _firestore
          .collection('cancellation_requests')
          .doc(requestId)
          .set(request.toMap());
      return requestId;
    } catch (e) {
      print('Error creating cancellation request: $e');
      throw Exception('Failed to create cancellation request: $e');
    }
  }

  // Get cancellation request for an order
  Future<CancellationRequestModel?> getCancellationRequest(String orderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection('cancellation_requests')
          .where('order_id', isEqualTo: orderId)
          .where('student_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return CancellationRequestModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to get cancellation request: $e');
    }
  }

  // Get all pending cancellation requests for a vendor
  Future<List<CancellationRequestModel>> getVendorPendingRequests(String vendorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('cancellation_requests')
          .where('vendor_id', isEqualTo: vendorId)
          .where('status', isEqualTo: 'pending')
          .orderBy('requested_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CancellationRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get vendor pending requests: $e');
    }
  }

  // Approve or reject a cancellation request
  Future<void> respondToCancellationRequest({
    required String requestId,
    required CancellationRequestStatus status,
    String? vendorResponse,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'responded_at': Timestamp.fromDate(DateTime.now()),
      };

      if (vendorResponse != null && vendorResponse.isNotEmpty) {
        updateData['vendor_response'] = vendorResponse;
      }

      await _firestore
          .collection('cancellation_requests')
          .doc(requestId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to respond to cancellation request: $e');
    }
  }

  // Get cancellation request by ID
  Future<CancellationRequestModel?> getCancellationRequestById(String requestId) async {
    try {
      final doc = await _firestore
          .collection('cancellation_requests')
          .doc(requestId)
          .get();

      if (!doc.exists) return null;

      return CancellationRequestModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get cancellation request: $e');
    }
  }

  // Stream of cancellation requests for a vendor
  Stream<List<CancellationRequestModel>> getVendorRequestsStream(String vendorId) {
    return _firestore
        .collection('cancellation_requests')
        .where('vendor_id', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
          List<CancellationRequestModel> requests = snapshot.docs
              .map((doc) => CancellationRequestModel.fromFirestore(doc))
              .toList();
          
          // Sort by requested_at in memory to avoid Firestore index requirement
          requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          
          return requests;
        });
  }

  // Get all cancellation requests for a vendor (for compatibility)
  Stream<List<CancellationRequestModel>> getVendorCancellationRequests(String vendorId) {
    return getVendorRequestsStream(vendorId);
  }
}
