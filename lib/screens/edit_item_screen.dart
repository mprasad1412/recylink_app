import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditItemScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const EditItemScreen({
    super.key,
    required this.itemId,
    required this.itemData,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color surfaceColor = const Color(0xFFF5F9F6);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isUpdating = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadItemData();
  }

  void _loadItemData() {
    _titleController.text = widget.itemData['title'] ?? '';
    _descriptionController.text = widget.itemData['description'] ?? '';
    _contactController.text = widget.itemData['contact_info'] ?? '';
    _imageUrl = widget.itemData['images'] ?? '';

    final price = widget.itemData['price'];
    if (price != null && price > 0) {
      _priceController.text = price.toString();
    }
  }

  Future<void> _updateItem() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a product name');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter product information');
      return;
    }

    if (_contactController.text.trim().isEmpty) {
      _showError('Please enter contact information');
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      double price = 0;
      if (_priceController.text.trim().isNotEmpty) {
        price = double.tryParse(_priceController.text.trim()) ?? 0;
      }

      await _firestore.collection('items').doc(widget.itemId).update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'contact_info': _contactController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      debugPrint('Error updating item: $e');
      if (mounted) {
        _showError('Failed to update item. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          ),
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Item',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PHOTO PREVIEW (Non-editable)
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _imageUrl != null && _imageUrl!.isNotEmpty
                        ? Image.network(
                      _imageUrl!,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey[100],
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  // Info Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Photo cannot be changed',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. EDITABLE FIELDS
            _buildModernField(
              label: 'Product Name',
              controller: _titleController,
              hint: 'e.g. Recycled Glass Vase',
              enabled: !_isUpdating,
            ),

            const SizedBox(height: 20),

            _buildModernField(
              label: 'Price (RM)',
              controller: _priceController,
              hint: '0.00 (Leave empty for Free)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isUpdating,
            ),

            const SizedBox(height: 20),

            _buildModernField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'Describe the condition, material, and story of your item...',
              maxLines: 4,
              enabled: !_isUpdating,
            ),

            const SizedBox(height: 20),

            _buildModernField(
              label: 'Contact Info',
              controller: _contactController,
              hint: 'WhatsApp number or preferred contact method',
              keyboardType: TextInputType.phone,
              enabled: !_isUpdating,
            ),

            const SizedBox(height: 40),

            // 3. UPDATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 5,
                  shadowColor: primaryGreen.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isUpdating
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}