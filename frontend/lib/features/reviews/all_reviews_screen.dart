import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/review.dart';

class AllReviewsScreen extends StatefulWidget {
  final bool isAdmin;
  
  const AllReviewsScreen({super.key, this.isAdmin = false});

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAllReviews();
      setState(() {
        _reviews = data.map((json) => Review.fromJson(json)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2B4A),
        title: const Text('Delete Review', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this review?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteReview(reviewId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReviews();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        title: const Text('All Reviews'),
        backgroundColor: const Color(0xFF1A1B3A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return Card(
                        color: const Color(0xFF2A2B4A),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Passenger Name
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.white54, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    review.passengerName ?? 'Anonymous',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Bus Route
                              Text(
                                '${review.busInfo?.from ?? 'Unknown'} → ${review.busInfo?.to ?? 'Unknown'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                review.busInfo?.busType ?? 'Bus',
                                style: const TextStyle(
                                  color: Color(0xFFF97316),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Rating
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < review.rating ? Icons.star : Icons.star_border,
                                    color: const Color(0xFFF97316),
                                    size: 20,
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),
                              
                              // Comment
                              Text(
                                review.comment,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Date
                              Text(
                                'Posted on ${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              
                              // Delete Button (Only for Admin)
                              if (widget.isAdmin) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _deleteReview(review.id),
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text('Delete'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}