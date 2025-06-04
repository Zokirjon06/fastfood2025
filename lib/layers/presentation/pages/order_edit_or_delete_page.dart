import 'dart:io';
import 'package:fastfood/layers/presentation/extension/extensions.dart';
import 'package:fastfood/layers/presentation/helpers/input_formatter.dart';
import 'package:fastfood/layers/presentation/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/product_entity.dart';
import '../../data/service/image_upload_service.dart';
import '../widgets/show_snack_bar_widget.dart';

class OrderEditOrDeletePage extends StatefulWidget {
  final ProductEntity product;

  const OrderEditOrDeletePage({
    super.key,
    required this.product,
  });

  @override
  State<OrderEditOrDeletePage> createState() => _OrderEditOrDeletePageState();
}

class _OrderEditOrDeletePageState extends State<OrderEditOrDeletePage> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toMoney().toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ShowSnackBar.show(context, "Rasm tanlashda xatolik: ${e.toString()}");
      }
    }
  }
Future<void> _saveChanges(ProductEntity product) async {
  final String name = _nameController.text.trim();
  final String rawPrice = _priceController.text.trim();

  setState(() {
    _isLoading = true;
  });

  try {
    final db = FirebaseFirestore.instance;

    String? imageUrl = product.imageUrl;
    String? localImagePath = product.localImagePath;

    // Yangi rasm tanlangan bo‘lsa, uni yuklash
    if (_selectedImage != null) {
      ShowSnackBar.show(context, "Rasm saqlanmoqda...");

      final uploadedImageUrl = await ImageUploadService.uploadProductImageWithRetry(
        imageFile: _selectedImage!,
        fileName: 'product_${name.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
        maxRetries: 3,
      );

      if (uploadedImageUrl.startsWith('http')) {
        imageUrl = uploadedImageUrl;
        localImagePath = null;
      } else {
        localImagePath = uploadedImageUrl;
        imageUrl = null;
      }
    }

    // Raqamlarni faqat son sifatida olish
    final cleanedPrice = rawPrice.replaceAll(RegExp(r'[^0-9]'), '');
    final int? price = int.tryParse(cleanedPrice);

    if (price == null) {
      ShowSnackBar.show(context, "Iltimos, narxni to‘g‘ri kiriting");
      return;
    }

    // Ma’lumotlarni yangilash
    product.name = name;
    product.price = price.toDouble();
    product.imageUrl = imageUrl;
    product.localImagePath = localImagePath;

    await db.collection('products').doc(product.id).update(product.toJson());

    if (mounted) {
      ShowSnackBar.show(context, "Mahsulot muvaffaqiyatli yangilandi");
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      ShowSnackBar.show(context, "Xatolik: ${e.toString()}");
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  // Future<void> _saveChanges() async {
  //   final String name = _nameController.text.trim();
  //   final String priceText = _priceController.text.trim();

  //   if (name.isEmpty) {
  //     ShowSnackBar.show(context, "Mahsulot nomini kiriting");
  //     return;
  //   }

  //   if (priceText.isEmpty) {
  //     ShowSnackBar.show(context, "Narxni kiriting");
  //     return;
  //   }

  //   final double? price = double.tryParse(priceText);
  //   if (price == null || price <= 0) {
  //     ShowSnackBar.show(context, "To'g'ri narx kiriting");
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     final db = FirebaseFirestore.instance;
      
  //     String? imageUrl = widget.product.imageUrl;
  //     String? localImagePath = widget.product.localImagePath;

  //     // If new image is selected, upload it
  //     if (_selectedImage != null) {
  //       ShowSnackBar.show(context, "Rasm saqlanmoqda...");
        
  //       final uploadedImageUrl = await ImageUploadService.uploadProductImageWithRetry(
  //         imageFile: _selectedImage!,
  //         fileName: 'product_${name.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
  //         maxRetries: 3,
  //       );

  //       // Check if it's a local path or URL
  //       if (uploadedImageUrl.startsWith('http')) {
  //         imageUrl = uploadedImageUrl;
  //         localImagePath = null;
  //       } else {
  //         localImagePath = uploadedImageUrl;
  //         imageUrl = null;
  //       }
  //     }

  //     // Update product in Firestore
  //     await db.collection('products').doc(widget.product.id).update({
  //       'name': name,
  //       'price': price,
  //       if (imageUrl != null) 'imageUrl': imageUrl,
  //       if (localImagePath != null) 'localImagePath': localImagePath,
  //     });

  //     if (mounted) {
  //       ShowSnackBar.show(context, "Mahsulot muvaffaqiyatli yangilandi");
  //       Navigator.pop(context, true); // Return true to indicate changes were made
  //     }

  //   } catch (e) {
  //     if (mounted) {
  //       ShowSnackBar.show(context, "Xatolik: ${e.toString()}");
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _deleteProduct() async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('products').doc(widget.product.id).delete();
      
      if (mounted) {
        ShowSnackBar.show(context, "Mahsulot o'chirildi");
        Navigator.pop(context, true); // Return true to indicate product was deleted
      }
    } catch (e) {
      if (mounted) {
        ShowSnackBar.show(context, "O'chirishda xatolik: ${e.toString()}");
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ishonchingiz komilmi"),
          content: const Text("Bu maxsulotni o'chirmoqchimisiz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Bekor qilish"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteProduct();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text("O'chirish"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rasm",
          style: TextStyle(
            fontSize: context.rFontSize(16),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.rSpacing(8)),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: context.rHeight(25),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : widget.product.hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                        child: widget.product.hasLocalImage
                            ? Image.file(
                                File(widget.product.localImagePath!),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                widget.product.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: context.rIconSize(48),
                            color: Colors.grey,
                          ),
                          SizedBox(height: context.rSpacing(8)),
                          Text(
                            "Rasm tanlang",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: context.rFontSize(14),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete),
            color: Colors.red,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(context.rSpacing(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name input
            Text(
              "Mahsulot nomi",
              style: TextStyle(
                fontSize: context.rFontSize(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: context.rSpacing(8)),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Mahsulot nomini kiriting",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                ),
              ),
            ),
            SizedBox(height: context.rSpacing(20)),

            // Price input
            Text(
              "Narx",
              style: TextStyle(
                fontSize: context.rFontSize(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: context.rSpacing(8)),
            TextField(
              controller: _priceController  ,
              keyboardType: TextInputType.number,
              inputFormatters: [InputFormatters.moneyFormatter],
              decoration: InputDecoration(
                hintText: "Narxni kiriting",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                ),
              ),
            ),
            SizedBox(height: context.rSpacing(20)),

            // Image section
            _buildImageSection(),
          ],
        ),
      ),
      floatingActionButton: _isLoading
          ? const CircularProgressIndicator()
          : FloatingActionButton(
              onPressed: (){
                _saveChanges(widget.product);
              },
              child: const Icon(Icons.check),
            ),
    );
  }
}
