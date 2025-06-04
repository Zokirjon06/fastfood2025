import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/domain/entity/desk_id_entiry.dart';
import 'package:fastfood/layers/domain/entity/order_entity.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/presentation/extension/extensions.dart';
import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/utils/responsive_utils.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:math' as math;

/// Utility class for handling price calculations with 8% service charge
class PriceCalculator {
  static const double serviceChargeRate = 0.08; // 8% service charge
  static const int decimalPlaces = 2; // Precision for currency calculations

  /// Calculates the total price including 8% service charge
  /// Returns null if the input is invalid
  static double? calculateTotalWithServiceCharge(double? basePrice) {
    try {
      // Validate input
      if (basePrice == null || basePrice < 0 || !basePrice.isFinite) {
        return null;
      }

      // Check for potential overflow
      if (basePrice > double.maxFinite / 1.08) {
        return null;
      }

      // Calculate total with service charge: price * 1.08
      final total = basePrice * (1 + serviceChargeRate);

      // Round to specified decimal places to avoid floating-point precision issues
      return _roundToDecimalPlaces(total, decimalPlaces);
    } catch (e) {
      // Handle any unexpected errors
      return null;
    }
  }

  /// Calculates the service charge amount only
  static double? calculateServiceCharge(double? basePrice) {
    try {
      if (basePrice == null || basePrice < 0 || !basePrice.isFinite) {
        return null;
      }

      final serviceCharge = basePrice * serviceChargeRate;
      return _roundToDecimalPlaces(serviceCharge, decimalPlaces);
    } catch (e) {
      return null;
    }
  }

  /// Calculates total for a list of products with service charge
  static CalculationResult calculateOrderTotal(List<ProductEntity> products) {
    try {
      if (products.isEmpty) {
        return CalculationResult(
          isValid: false,
          errorMessage: 'No products in the order',
        );
      }

      double subtotal = 0.0;
      List<String> invalidProducts = [];

      for (final product in products) {
        if (product.price < 0 || !product.price.isFinite) {
          invalidProducts.add(product.name);
          continue;
        }
        subtotal += product.price;
      }

      if (invalidProducts.isNotEmpty) {
        return CalculationResult(
          isValid: false,
          errorMessage: 'Invalid prices for: ${invalidProducts.join(', ')}',
        );
      }

      final serviceCharge = calculateServiceCharge(subtotal);
      final total = calculateTotalWithServiceCharge(subtotal);

      if (serviceCharge == null || total == null) {
        return CalculationResult(
          isValid: false,
          errorMessage: 'Calculation overflow or invalid values',
        );
      }

      return CalculationResult(
        isValid: true,
        subtotal: subtotal,
        serviceCharge: serviceCharge,
        total: total,
        breakdown: 'Subtotal: ${subtotal.toMoney()} so\'m\n'
                  'Service Charge (8%): ${serviceCharge.toMoney()} so\'m\n'
                  'Total: ${total.toMoney()} so\'m',
      );
    } catch (e) {
      return CalculationResult(
        isValid: false,
        errorMessage: 'Unexpected calculation error: ${e.toString()}',
      );
    }
  }

  /// Rounds a double to specified decimal places
  static double _roundToDecimalPlaces(double value, int places) {
    if (value == 0.0) return 0.0;

    final factor = math.pow(10, places);
    final rounded = (value * factor).round() / factor;

    // For very small values, preserve some precision
    if (rounded == 0.0 && value > 0.0) {
      return value; // Return original value if rounding would make it 0
    }

    return rounded;
  }
}

/// Result class for calculation operations
class CalculationResult {
  final bool isValid;
  final double? subtotal;
  final double? serviceCharge;
  final double? total;
  final String? breakdown;
  final String? errorMessage;

  CalculationResult({
    required this.isValid,
    this.subtotal,
    this.serviceCharge,
    this.total,
    this.breakdown,
    this.errorMessage,
  });
}

/// Result class for order creation operations
class OrderCreationResult {
  final bool success;
  final String? message;
  final String? errorMessage;
  final CalculationResult? calculationResult;

  OrderCreationResult({
    required this.success,
    this.message,
    this.errorMessage,
    this.calculationResult,
  });
}

class AddDeskId extends StatefulWidget {
  final List<ProductEntity> product;
  const AddDeskId({super.key, required this.product});

  @override
  State<AddDeskId> createState() => _AddDeskIdState();
}

class _AddDeskIdState extends State<AddDeskId> {
  Set<int> takenDeskIds = {}; // band qilingan stol id'lari
  int shop = 1;

  @override
  void initState() {
    super.initState();
    fetchTakenDeskIds();
  }

  @override
  void dispose() {
    widget.product.clear();
    super.dispose();
  }

  Future<void> fetchTakenDeskIds() async {
    final firestore = FirebaseFirestore.instance;

    final deskSnapshot = await firestore.collection('deskId').get();
    final orderSnapshot = await firestore.collection('orders').get();

    final deskIds = deskSnapshot.docs
        .map((doc) => int.tryParse(doc.data()['id'] ?? '') ?? -1)
        .where((id) => id != -1)
        .toSet();

    final orderIds = orderSnapshot.docs
        .map((doc) => int.tryParse(doc.data()['userId'] ?? '') ?? -1)
        .where((id) => id != -1)
        .toSet();

    final combined =
        deskIds.intersection(orderIds); // faqat ikkala joyda borlar

    setState(() {
      takenDeskIds = combined;
    });
  }

  /// Creates an order in Firebase with proper price calculations including 8% service charge
  Future<OrderCreationResult> _createOrderInFirebase(
      List<ProductEntity> selectedProducts, int deskId) async {
    try {
      // Validate inputs
      if (selectedProducts.isEmpty) {
        return OrderCreationResult(
          success: false,
          errorMessage: 'No products selected for the order',
        );
      }

      if (deskId <= 0) {
        return OrderCreationResult(
          success: false,
          errorMessage: 'Invalid desk ID',
        );
      }

      // Calculate order total with service charge
      final calculationResult = PriceCalculator.calculateOrderTotal(selectedProducts);

      if (!calculationResult.isValid) {
        return OrderCreationResult(
          success: false,
          errorMessage: calculationResult.errorMessage ?? 'Calculation failed',
        );
      }

      final firestore = FirebaseFirestore.instance;

      // Create order items with calculated prices including service charge
      final items = selectedProducts.map((product) {
        final totalPrice = PriceCalculator.calculateTotalWithServiceCharge(product.price);
        if (totalPrice == null) {
          throw Exception('Failed to calculate price for ${product.name}');
        }
        return OrderItem(
          name: product.name,
          quantity: totalPrice, // Using quantity field to store total price with service charge
        );
      }).toList();

      final order = OrderEntity(
        userId: deskId.toString(),
        items: items,
        status: false,
        date: DateTime.now(),
      );

      await firestore.collection('orders').add(order.toJson());

      return OrderCreationResult(
        success: true,
        calculationResult: calculationResult,
        message: 'Order created successfully',
      );

    } catch (e) {
      debugPrint('Firebase order creation error: $e');
      return OrderCreationResult(
        success: false,
        errorMessage: 'Failed to create order: ${e.toString()}',
      );
    }
  }

  Future<void> _createDeskFirebase(int deskId) async {
    final firestore = FirebaseFirestore.instance;

    final desk = DeskIdEntiry(id: deskId.toString());

    try {
      await firestore.collection('deskId').add(desk.toJson());
      debugPrint('Desk Firestore ga yuborildi!');
    } catch (e) {
      debugPrint('Firebase yozishda xatolik: $e');
    }
  }

  /// Shows desk selection confirmation dialog
  Future<bool> _showDeskSelectionConfirmation(int deskNumber) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.rBorderRadius(16)),
          ),
          title: Row(
            children: [
              Icon(
                Icons.table_restaurant,
                color: Colors.amber.shade700,
                size: context.rIconSize(28),
              ),
              Gap(context.rSpacing(12)),
              Text(
                'Stol tanlashni tasdiqlash',
                style: TextStyle(
                  fontSize: context.rFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(context.rSpacing(12)),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(context.rBorderRadius(8)),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      color: Colors.amber.shade700,
                      size: context.rIconSize(24),
                    ),
                    Gap(context.rSpacing(8)),
                    Text(
                      'Desk #$deskNumber',
                      style: TextStyle(
                        fontSize: context.rFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(context.rSpacing(16)),
              Text(
                'Ishonchingiz komilmi?',
                style: TextStyle(
                  fontSize: context.rFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Gap(context.rSpacing(8)),
              Text(
                'Ushbu stol uchun buyurtmalarni qabul qilmoqchimisiz?',
                style: TextStyle(
                  fontSize: context.rFontSize(16),
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Bekor qilish',
                style: TextStyle(
                  fontSize: context.rFontSize(16),
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.rBorderRadius(8)),
                ),
                padding: EdgeInsets.symmetric(horizontal: context.rSpacing(20), vertical: context.rSpacing(10)),
              ),
              child: Text(
                'Qabul qilish',
                style: TextStyle(
                  fontSize: context.rFontSize(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }



  /// Handles desk selection with proper calculation display and error handling
  Future<void> _handleDeskSelection(int deskNumber) async {
    try {
      // Show desk selection confirmation
      final shouldSelectDesk = await _showDeskSelectionConfirmation(deskNumber);
      if (!shouldSelectDesk) return;

      // Calculate and validate the order
      final calculationResult = PriceCalculator.calculateOrderTotal(widget.product);

      if (!calculationResult.isValid) {
        if (mounted) {
          ShowSnackBar.show(context, calculationResult.errorMessage ?? 'Calculation error');
        }
        return;
      }

      setState(() {
        shop = deskNumber;
      });

      // Create order with proper error handling
      final orderResult = await _createOrderInFirebase(widget.product, deskNumber);

      if (!orderResult.success) {
        if (mounted) {
          ShowSnackBar.show(context, orderResult.errorMessage ?? 'Failed to create order');
        }
        return;
      }

      // Create desk entry
      await _createDeskFirebase(deskNumber);

      // Clear products and navigate
      widget.product.clear();

      if (mounted) {
        Navigator.pop(context);
        ShowSnackBar.show(context, 'Order created successfully!\n${calculationResult.breakdown}');
      }

    } catch (e) {
      debugPrint('Error in desk selection: $e');
      if (mounted) {
        ShowSnackBar.show(context, 'An unexpected error occurred. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => HomePage()));
              widget.product.clear();
            },
            icon: Icon(Icons.arrow_back_ios)),
        centerTitle: true,
        title: Text(
          "Bo'sh joyni tanlang",
          style: TextStyle(fontSize: context.rFontSize(22), fontWeight: FontWeight.bold),
        ),
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: 20,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, index) {
            final deskNumber = index + 1;
            final isTaken = takenDeskIds.contains(deskNumber);

            return ElevatedButton(
              onPressed: isTaken
                  ? () {
                      ShowSnackBar.show(context, "Bu joy band.");
                    }
                  : () async {
                      await _handleDeskSelection(deskNumber);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isTaken ? Colors.amber : Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Stol $deskNumber',
                style: TextStyle(
                    fontSize: context.rFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}
