import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/review.dart';
import '../../models/bus_timetable.dart';
import 'review_form_screen.dart';

class BusReviewsScreen extends StatefulWidget {
  final String busId;
  final BusTimeTable? busInfo;

  const BusReviewsScreen({
    super.key,
    required this.busId,
    this.busInfo,
  });

  @override
  State<BusReviewsScreen> createState() => _BusReviewsScreenState();
}

class _BusReviewsScreenState extends State<BusReviewsScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadReviews();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final userJson = jsonDecode(userData);
      setState(() {
        _currentUserId = userJson['_id'] ?? userJson['id'];
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getReviewsByBus(widget.busId);
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

  bool _isMyReview(Review review) {
    return _currentUserId != null && review.passengerId == _currentUserId;
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

  Future<void> _editReview(Review review) async {
    final bus = BusTimeTable(
      id: review.busId,
      from: review.busInfo?.from ?? widget.busInfo?.from ?? 'Unknown',
      to: review.busInfo?.to ?? widget.busInfo?.to ?? 'Unknown',
      startTime: review.busInfo?.startTime ?? widget.busInfo?.startTime ?? '',
      endTime: review.busInfo?.endTime ?? widget.busInfo?.endTime ?? '',
      busType: review.busInfo?.busType ?? widget.busInfo?.busType ?? 'Normal',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewFormScreen(
          bus: bus,
          existingReview: {
            'id': review.id,
            'rating': review.rating,
            'comment': review.comment,
          },
        ),
      ),
    );

    if (result == true) {
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        title: const Text('Bus Reviews'),
        backgroundColor: const Color(0xFF1A1B3A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(
                  child: Text(
                    'No reviews yet. Be the first to review!',
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
                      final isMyReview = _isMyReview(review);
                      
                      return Card(
                        color: isMyReview 
                            ? const Color(0xFF2A2B4A) 
                            : const Color(0xFF1F2937),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isMyReview 
                              ? const BorderSide(color: Color(0xFFF97316), width: 2)
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with passenger name and "Your Review" badge
                              Row(
                                children: [
                                  const Icon(Icons.person, 
                                    color: Colors.white54, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    review.passengerName ?? 'Anonymous',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isMyReview) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF97316),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Your Review',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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
                              
                              // Action Buttons (Only for user's own reviews)
                              if (isMyReview) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _editReview(review),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Edit'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFF97316),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _deleteReview(review.id),
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
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