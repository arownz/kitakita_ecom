import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../../../shared/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../providers/marketplace_providers.dart';
import '../../domain/models/product.dart';
import '../../../../shared/providers/auth_provider.dart';

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedCondition = 'Good';
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imagePreviews = [];
  bool _isLoading = false;

  final List<String> _conditions = [
    'Brand New',
    'Like New',
    'Excellent',
    'Good',
    'Fair',
    'Poor',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildForm(categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load categories: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(categoriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<Category> categories) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: ResponsiveUtils.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.spaceM),

            // Image Upload Section
            _buildImageSection(),
            const SizedBox(height: AppSizes.spaceL),

            // Product Title
            _buildTextField(
              controller: _titleController,
              label: 'Product Title',
              icon: Icons.shopping_bag,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product title is required';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spaceM),

            // Category Dropdown
            _buildCategoryDropdown(categories),
            const SizedBox(height: AppSizes.spaceM),

            // Price
            _buildTextField(
              controller: _priceController,
              label: 'Price (₱)',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Price is required';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spaceM),

            // Condition Dropdown
            _buildConditionDropdown(),
            const SizedBox(height: AppSizes.spaceM),

            // Location
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              icon: Icons.location_on,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spaceM),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spaceXL),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Post Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSizes.spaceXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Images',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: AppSizes.spaceS),
        Text(
          'Add up to 5 photos to showcase your product',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
        ),
        const SizedBox(height: AppSizes.spaceM),

        // Image Grid
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddImageButton();
              }
              return _buildImageItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    if (_selectedImages.length >= 5) return const SizedBox.shrink();

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: AppSizes.spaceS),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: AppColors.primaryBlue,
            ),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: AppSizes.spaceS),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.lightGray,
              child: _imagePreviews.length > index
                  ? Image.memory(_imagePreviews[index], fit: BoxFit.cover)
                  : const Icon(
                      Icons.image,
                      size: 32,
                      color: AppColors.primaryBlue,
                    ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: AppColors.primaryBlue,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: AppColors.primaryBlue,
        ),
        prefixIcon: const Icon(Icons.category, color: AppColors.primaryBlue),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      items: categories.map((category) {
        return DropdownMenuItem(value: category.id, child: Text(category.name));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCondition,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue),
      decoration: InputDecoration(
        labelText: 'Condition',
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: AppColors.primaryBlue,
        ),
        prefixIcon: const Icon(Icons.star, color: AppColors.primaryBlue),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      items: _conditions.map((condition) {
        return DropdownMenuItem(value: condition, child: Text(condition));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCondition = value!;
        });
      },
    );
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImages.add(image);
        _imagePreviews.add(bytes);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_imagePreviews.length > index) {
        _imagePreviews.removeAt(index);
      }
    });
  }

  ProductCondition _getProductCondition(String condition) {
    switch (condition) {
      case 'Brand New':
        return ProductCondition.new_;
      case 'Like New':
        return ProductCondition.likeNew;
      case 'Excellent':
        return ProductCondition.likeNew;
      case 'Good':
        return ProductCondition.good;
      case 'Fair':
        return ProductCondition.fair;
      case 'Poor':
        return ProductCondition.poor;
      default:
        return ProductCondition.good;
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1) Upload images to Supabase Storage
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        final bucket = SupabaseService.storage.from('product_images');
        final uuid = const Uuid();
        for (int i = 0; i < _selectedImages.length; i++) {
          final imageBytes = await _selectedImages[i].readAsBytes();
          final String path = 'users/$userId/${uuid.v4()}.jpg';
          await bucket.uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
          final publicUrl = bucket.getPublicUrl(path);
          uploadedUrls.add(publicUrl);
        }
      }

      // 2) Create product with Supabase including uploaded image URLs
      final product = Product(
        id: '', // Will be generated by Supabase
        sellerId: userId,
        categoryId: _selectedCategoryId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        condition: _getProductCondition(_selectedCondition),
        location: _locationController.text.trim(),
        images: uploadedUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(productCreationProvider.notifier)
          .createProduct(product);

      if (success) {
        // Refresh products list
        ref.read(productsProvider.notifier).refreshProducts();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product posted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post product: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
