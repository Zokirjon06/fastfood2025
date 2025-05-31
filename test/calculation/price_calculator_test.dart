import 'package:flutter_test/flutter_test.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/presentation/pages/screens/add_desk_id.dart';

// Helper function to create test products with all required fields
ProductEntity createTestProduct({
  required String id,
  required String name,
  required double price,
  String? localImagePath = '/test/image/path.jpg',
  String? uploadedImageUrl,
}) {
  return ProductEntity(
    id: id,
    name: name,
    price: price,
    localImagePath: localImagePath,
    uploadedImageUrl: uploadedImageUrl,
    date: DateTime.now(),
  );
}

void main() {
  group('PriceCalculator Tests', () {
    group('calculateTotalWithServiceCharge', () {
      test('should calculate correct total with 8% service charge', () {
        // Test basic calculation
        expect(PriceCalculator.calculateTotalWithServiceCharge(100.0), 108.0);
        expect(PriceCalculator.calculateTotalWithServiceCharge(50.0), 54.0);
        expect(PriceCalculator.calculateTotalWithServiceCharge(25.0), 27.0);
      });

      test('should handle decimal precision correctly', () {
        // Test floating-point precision
        final result = PriceCalculator.calculateTotalWithServiceCharge(33.33);
        expect(result, closeTo(35.9964, 0.01)); // 33.33 * 1.08 = 35.9964

        // Test rounding to 2 decimal places
        final rounded = PriceCalculator.calculateTotalWithServiceCharge(10.555);
        expect(rounded, 11.4); // Should round properly
      });

      test('should return null for invalid inputs', () {
        expect(PriceCalculator.calculateTotalWithServiceCharge(null), isNull);
        expect(PriceCalculator.calculateTotalWithServiceCharge(-10.0), isNull);
        expect(PriceCalculator.calculateTotalWithServiceCharge(double.infinity), isNull);
        expect(PriceCalculator.calculateTotalWithServiceCharge(double.nan), isNull);
      });

      test('should handle zero correctly', () {
        expect(PriceCalculator.calculateTotalWithServiceCharge(0.0), 0.0);
      });

      test('should handle very large numbers without overflow', () {
        // Test near overflow conditions
        const largeNumber = 1e15; // Very large but manageable
        final result = PriceCalculator.calculateTotalWithServiceCharge(largeNumber);
        expect(result, isNotNull);
        expect(result, largeNumber * 1.08);

        // Test overflow protection
        const overflowNumber = double.maxFinite / 1.07; // Would cause overflow
        final overflowResult = PriceCalculator.calculateTotalWithServiceCharge(overflowNumber);
        expect(overflowResult, isNull);
      });
    });

    group('calculateServiceCharge', () {
      test('should calculate correct service charge amount', () {
        expect(PriceCalculator.calculateServiceCharge(100.0), 8.0);
        expect(PriceCalculator.calculateServiceCharge(50.0), 4.0);
        expect(PriceCalculator.calculateServiceCharge(25.0), 2.0);
      });

      test('should handle decimal precision correctly', () {
        final result = PriceCalculator.calculateServiceCharge(33.33);
        expect(result, closeTo(2.6664, 0.01)); // 33.33 * 0.08 = 2.6664
      });

      test('should return null for invalid inputs', () {
        expect(PriceCalculator.calculateServiceCharge(null), isNull);
        expect(PriceCalculator.calculateServiceCharge(-10.0), isNull);
        expect(PriceCalculator.calculateServiceCharge(double.infinity), isNull);
        expect(PriceCalculator.calculateServiceCharge(double.nan), isNull);
      });

      test('should handle zero correctly', () {
        expect(PriceCalculator.calculateServiceCharge(0.0), 0.0);
      });
    });

    group('calculateOrderTotal', () {
      test('should calculate correct order total for multiple products', () {
        final products = [
          createTestProduct(id: '1', name: 'Product 1', price: 100.0),
          createTestProduct(id: '2', name: 'Product 2', price: 50.0),
          createTestProduct(id: '3', name: 'Product 3', price: 25.0),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isTrue);
        expect(result.subtotal, 175.0); // 100 + 50 + 25
        expect(result.serviceCharge, 14.0); // 175 * 0.08
        expect(result.total, 189.0); // 175 * 1.08
        expect(result.breakdown, isNotNull);
        expect(result.breakdown, contains('Subtotal: 175.00 so\'m'));
        expect(result.breakdown, contains('Service Charge (8%): 14.00 so\'m'));
        expect(result.breakdown, contains('Total: 189.00 so\'m'));
      });

      test('should handle empty product list', () {
        final result = PriceCalculator.calculateOrderTotal([]);

        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'No products in the order');
      });

      test('should handle products with invalid prices', () {
        final products = [
          createTestProduct(id: '1', name: 'Valid Product', price: 100.0),
          createTestProduct(id: '2', name: 'Invalid Product', price: -50.0),
          createTestProduct(id: '3', name: 'Another Invalid', price: double.infinity),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Invalid prices for:'));
        expect(result.errorMessage, contains('Invalid Product'));
        expect(result.errorMessage, contains('Another Invalid'));
      });

      test('should handle single product correctly', () {
        final products = [
          createTestProduct(id: '1', name: 'Single Product', price: 50.0),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isTrue);
        expect(result.subtotal, 50.0);
        expect(result.serviceCharge, 4.0); // 50 * 0.08
        expect(result.total, 54.0); // 50 * 1.08
      });

      test('should handle products with zero prices', () {
        final products = [
          createTestProduct(id: '1', name: 'Free Product', price: 0.0),
          createTestProduct(id: '2', name: 'Paid Product', price: 100.0),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isTrue);
        expect(result.subtotal, 100.0);
        expect(result.serviceCharge, 8.0);
        expect(result.total, 108.0);
      });

      test('should handle very large order totals', () {
        final products = [
          createTestProduct(id: '1', name: 'Expensive Product', price: 1e10),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isTrue);
        expect(result.subtotal, 1e10);
        expect(result.serviceCharge, 1e10 * 0.08);
        expect(result.total, 1e10 * 1.08);
      });

      test('should handle potential overflow scenarios', () {
        final products = [
          createTestProduct(id: '1', name: 'Overflow Product', price: double.maxFinite / 1.07),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Calculation overflow'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle mixed valid and invalid products', () {
        final products = [
          createTestProduct(id: '1', name: 'Valid 1', price: 100.0),
          createTestProduct(id: '2', name: 'Invalid', price: -50.0),
          createTestProduct(id: '3', name: 'Valid 2', price: 25.0),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Invalid prices for: Invalid'));
      });

      test('should handle products with very small prices', () {
        final products = [
          createTestProduct(id: '1', name: 'Tiny Price', price: 0.01),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isTrue);
        expect(result.subtotal, 0.01);
        expect(result.serviceCharge, closeTo(0.0008, 0.0001)); // 0.01 * 0.08
        expect(result.total, closeTo(0.0108, 0.0001)); // 0.01 * 1.08
      });

      test('should maintain precision with many decimal places', () {
        final products = [
          createTestProduct(id: '1', name: 'Precise Price', price: 33.333333),
        ];

        final result = PriceCalculator.calculateOrderTotal(products);

        expect(result.isValid, isTrue);
        expect(result.subtotal, 33.333333);
        // Check that calculations maintain reasonable precision
        expect(result.serviceCharge, closeTo(2.67, 0.01));
        expect(result.total, closeTo(36.0, 0.01));
      });
    });

    group('Calculation Consistency', () {
      test('should produce consistent results for same inputs', () {
        final products = [
          createTestProduct(id: '1', name: 'Product', price: 123.45),
        ];

        final result1 = PriceCalculator.calculateOrderTotal(products);
        final result2 = PriceCalculator.calculateOrderTotal(products);

        expect(result1.isValid, result2.isValid);
        expect(result1.subtotal, result2.subtotal);
        expect(result1.serviceCharge, result2.serviceCharge);
        expect(result1.total, result2.total);
      });

      test('should match individual and batch calculations', () {
        final price = 100.0;

        // Individual calculation
        final individualTotal = PriceCalculator.calculateTotalWithServiceCharge(price);
        final individualCharge = PriceCalculator.calculateServiceCharge(price);

        // Batch calculation
        final products = [
          createTestProduct(id: '1', name: 'Product', price: price),
        ];
        final batchResult = PriceCalculator.calculateOrderTotal(products);

        expect(batchResult.isValid, isTrue);
        expect(batchResult.total, individualTotal);
        expect(batchResult.serviceCharge, individualCharge);
        expect(batchResult.subtotal, price);
      });
    });
  });

  group('CalculationResult Tests', () {
    test('should create valid calculation result', () {
      final result = CalculationResult(
        isValid: true,
        subtotal: 100.0,
        serviceCharge: 8.0,
        total: 108.0,
        breakdown: 'Test breakdown',
      );

      expect(result.isValid, isTrue);
      expect(result.subtotal, 100.0);
      expect(result.serviceCharge, 8.0);
      expect(result.total, 108.0);
      expect(result.breakdown, 'Test breakdown');
      expect(result.errorMessage, isNull);
    });

    test('should create invalid calculation result', () {
      final result = CalculationResult(
        isValid: false,
        errorMessage: 'Test error',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, 'Test error');
      expect(result.subtotal, isNull);
      expect(result.serviceCharge, isNull);
      expect(result.total, isNull);
      expect(result.breakdown, isNull);
    });
  });

  group('OrderCreationResult Tests', () {
    test('should create successful order creation result', () {
      final calculationResult = CalculationResult(
        isValid: true,
        subtotal: 100.0,
        serviceCharge: 8.0,
        total: 108.0,
      );

      final result = OrderCreationResult(
        success: true,
        message: 'Order created',
        calculationResult: calculationResult,
      );

      expect(result.success, isTrue);
      expect(result.message, 'Order created');
      expect(result.calculationResult, calculationResult);
      expect(result.errorMessage, isNull);
    });

    test('should create failed order creation result', () {
      final result = OrderCreationResult(
        success: false,
        errorMessage: 'Creation failed',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Creation failed');
      expect(result.message, isNull);
      expect(result.calculationResult, isNull);
    });
  });
}
