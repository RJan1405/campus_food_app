import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import '../../widgets/rating_widgets.dart';
import '../../providers/vendor_provider.dart';
import 'rating_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final String vendorId;
  final String? menuItemId;
  final String vendorName;
  final String? menuItemName;

  const ReviewsScreen({
    Key? key,
    required this.vendorId,
    this.menuItemId,
    required this.vendorName,
    this.menuItemName,
  }) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with TickerProviderStateMixin {
  final _reviewService = ReviewService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Stream<List<ReviewModel>> _getReviewsStream() {
    if (widget.menuItemId != null) {
      return _reviewService.getMenuItemReviews(widget.menuItemId!);
    } else {
      return _reviewService.getVendorReviews(widget.vendorId);
    }
  }

  Future<dynamic> _getRatingSummary() {
    if (widget.menuItemId != null) {
      return _reviewService.getMenuItemRatingSummary(widget.menuItemId!);
    } else {
      return _reviewService.getVendorRatingSummary(widget.vendorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMenuItem = widget.menuItemId != null;
    final itemName = isMenuItem ? widget.menuItemName : widget.vendorName;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Reviews',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star, color: Colors.white),
            onPressed: () => _navigateToRating(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header with item info
              _buildHeader(itemName!),
              
              // Rating summary
              _buildRatingSummary(),
              
              // Reviews list
              Expanded(
                child: _buildReviewsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRating,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.star, color: Colors.white),
        label: const Text(
          'Rate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(String itemName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            widget.menuItemId != null ? Icons.restaurant_menu : Icons.store,
            size: 40,
            color: Colors.deepPurple.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            itemName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.menuItemId != null) ...[
            const SizedBox(height: 4),
            Text(
              'from ${widget.vendorName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.deepPurple.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return FutureBuilder<dynamic>(
      future: _getRatingSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading rating summary: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final summary = snapshot.data;
        if (summary == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: RatingSummaryCard(
            averageRating: summary.averageRating,
            totalReviews: summary.totalReviews,
            ratingDistribution: summary.ratingDistribution,
            title: widget.menuItemId != null ? 'Menu Item Rating' : 'Vendor Rating',
          ),
        );
      },
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<List<ReviewModel>>(
      stream: _getReviewsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Check if it's an index error and show appropriate message
          final error = snapshot.error.toString();
          final isIndexError = error.contains('FAILED_PRECONDITION') || error.contains('index');
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIndexError ? Icons.info_outline : Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  isIndexError ? 'Reviews Loading...' : 'Error loading reviews',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isIndexError)
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'Setting up reviews system...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to review this ${widget.menuItemId != null ? 'menu item' : 'vendor'}!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToRating,
                  icon: const Icon(Icons.star),
                  label: const Text('Write Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: ReviewCard(
                      userName: review.userName,
                      rating: review.rating,
                      comment: review.comment,
                      timestamp: review.timestamp,
                      canDelete: _canDeleteReview(review),
                      onDelete: () => _deleteReview(review),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  bool _canDeleteReview(ReviewModel review) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == review.userId;
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reviewService.deleteReview(review.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting review: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToRating() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingScreen(
          vendorId: widget.vendorId,
          menuItemId: widget.menuItemId,
          vendorName: widget.vendorName,
          menuItemName: widget.menuItemName,
        ),
      ),
    );
    
    // Refresh vendor data when returning from rating screen
    try {
      Provider.of<VendorProvider>(context, listen: false).refreshVendorData();
    } catch (e) {
      print('Error refreshing vendor data: $e');
    }
  }
}
