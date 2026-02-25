import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatelessWidget {
  final String itemId;
  final String productName;
  final String productImage;
  final String description;
  final String userId;
  final double price;
  final bool isDemo; // Flag to identify demo items

  const ProductDetailScreen({
    super.key,
    required this.itemId,
    required this.productName,
    required this.productImage,
    required this.description,
    required this.userId,
    required this.price,
    this.isDemo = false,
  });

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color surfaceColor = Color(0xFFF5F9F6);

  Future<Map<String, dynamic>?> _getUserInfo() async {
    if (isDemo) {
      return {'username': 'Demo Seller'};
    }

    try {
      debugPrint('🔍 Fetching user info for userId: $userId');  // ← Add this

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      debugPrint('📄 Document exists: ${userDoc.exists}');  // ← Add this
      debugPrint('📄 Document data: ${userDoc.data()}');    // ← Add this

      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      debugPrint('❌ Error fetching user info: $e');
    }
    return null;
  }

  Future<String?> _getContactInfo() async {
    if (isDemo) {
      return null; // Demo items have no contact info
    }

    try {
      final itemDoc = await FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .get();

      if (itemDoc.exists) {
        final data = itemDoc.data();
        return data?['contact_info'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching contact info: $e');
    }
    return null;
  }

  Future<void> _contactSeller(BuildContext context) async {
    if (isDemo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is a demo item. Post your own items to enable contact!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final contactInfo = await _getContactInfo();

    if (contactInfo == null || contactInfo.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact information not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final phoneNumber = contactInfo.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phoneNumber.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          if (context.mounted) {
            _showContactDialog(context, contactInfo);
          }
        }
      } catch (e) {
        if (context.mounted) {
          _showContactDialog(context, contactInfo);
        }
      }
    } else {
      if (context.mounted) {
        _showContactDialog(context, contactInfo);
      }
    }
  }

  void _showContactDialog(BuildContext context, String contactInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Seller'),
        content: SelectableText(
          contactInfo,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic>? userData) {
    final profilePicUrl = userData?['profile_picture'] as String?;

    if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: primaryGreen.withOpacity(0.1),
        backgroundImage: NetworkImage(profilePicUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('❌ Error loading profile picture: $exception');
        },
        child: Container(), // Empty child so error fallback shows the background color
      );
    }

    // Default generic icon
    return CircleAvatar(
      radius: 25,
      backgroundColor: primaryGreen.withOpacity(0.1),
      child: const Icon(Icons.person, color: primaryGreen, size: 28),
    );
  }

  Widget _buildImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: isDemo
            ? Image.asset(
          productImage,
          width: double.infinity,
          height: 350, // Slightly taller
          fit: BoxFit.cover,
        )
            : (productImage.isNotEmpty
            ? Image.network(
          productImage,
          width: double.infinity,
          height: 350,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 350,
              color: Colors.grey[100],
              child: Icon(Icons.broken_image_rounded, size: 60, color: Colors.grey[400]),
            );
          },
        )
            : Container(
          height: 350,
          color: Colors.grey[100],
          child: Icon(Icons.recycling_rounded, size: 60, color: Colors.grey[400]),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor, // Mint background
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PRODUCT IMAGE
            _buildImage(),

            const SizedBox(height: 24),

            // 2. HEADER SECTION (Title & Price)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (price > 0)
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Free / Negotiable',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // 3. DESCRIPTION SECTION
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description.isNotEmpty ? description : 'No description provided.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),

            const SizedBox(height: 30),

            // 4. SELLER CARD
            FutureBuilder<Map<String, dynamic>?>(
              future: _getUserInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !isDemo) {
                  return const Center(child: CircularProgressIndicator(color: primaryGreen));
                }

                final username = snapshot.data?['username'] ?? 'Unknown Seller';

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildProfileAvatar(snapshot.data),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Listed by',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _contactSeller(context),
                          icon: Icon(isDemo ? Icons.info_outline : Icons.chat_bubble_outline, color: Colors.white),
                          label: Text(
                            isDemo ? 'Demo Mode' : 'Contact Seller',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDemo ? Colors.orange : primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}