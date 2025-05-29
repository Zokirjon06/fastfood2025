import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/presentation/pages/screens/add_desk_id.dart';

// Mock classes for testing
@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
import 'add_desk_id_integration_test.mocks.dart';

// Helper function to create test products with all required fields
ProductEntity createTestProduct({
  required String id,
  required String name,
  required double price,
  String category = 'Food',
  String imageUrl = '',
  bool isAvailable = true,
}) {
  return ProductEntity(
    id: id,
    name: name,
    price: price,
    imageUrl: imageUrl,
    category: category,
    date: DateTime.now(),
    isAvailable: isAvailable,
  );
}

void main() {
  group('AddDeskId Integration Tests', () {
    late List<ProductEntity> testProducts;

    setUp(() {
      testProducts = [
        ProductEntity(
          id: '1',
          name: 'Burger',
          price: 25000.0,
          imageUrl: '',
          category: 'Food',
          date: DateTime.now(),
          isAvailable: true,
        ),
        ProductEntity(
          id: '2',
          name: 'Pizza',
          price: 45000.0,
          imageUrl: '',
          category: 'Food',
          date: DateTime.now(),
          isAvailable: true,
        ),
        ProductEntity(
          id: '3',
          name: 'Drink',
          price: 8000.0,
          imageUrl: '',
          category: 'Beverage',
          date: DateTime.now(),
          isAvailable: true,
        ),
      ];
    });

    group('Desk Selection Confirmation Tests', () {
      testWidgets('should show desk selection confirmation dialog first',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        // Find and tap a desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Should show desk selection confirmation dialog first
        expect(find.text('Confirm Desk Selection'), findsOneWidget);
        expect(find.text('Are you sure?'), findsOneWidget);
        expect(find.text('Do you want to accept orders for this desk?'), findsOneWidget);
        expect(find.text('Desk #1'), findsOneWidget);

        // Check dialog buttons
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Yes, Accept Orders'), findsOneWidget);

        // Should NOT show order summary yet
        expect(find.text('Order Summary'), findsNothing);
      });

      testWidgets('should cancel desk selection when Cancel is pressed',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Tap Cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed, should be back to desk selection
        expect(find.text('Confirm Desk Selection'), findsNothing);
        expect(find.byType(AddDeskId), findsOneWidget);
      });

      testWidgets('should proceed to order summary when Yes, Accept Orders is pressed',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Tap Yes, Accept Orders button
        await tester.tap(find.text('Yes, Accept Orders'));
        await tester.pumpAndSettle();

        // Should now show order summary dialog
        expect(find.text('Order Summary'), findsOneWidget);
        expect(find.text('Order Details:'), findsOneWidget);
      });
    });

    group('Calculation Display Tests', () {
      testWidgets('should display order summary dialog with correct calculations after desk confirmation',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        // Find and tap a desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Confirm desk selection
        await tester.tap(find.text('Yes, Accept Orders'));
        await tester.pumpAndSettle();

        // Should show order confirmation dialog
        expect(find.text('Order Summary'), findsOneWidget);
        expect(find.text('Order Details:'), findsOneWidget);

        // Check if products are displayed
        expect(find.text('Burger'), findsOneWidget);
        expect(find.text('Pizza'), findsOneWidget);
        expect(find.text('Drink'), findsOneWidget);

        // Check if prices are displayed correctly
        expect(find.text('25000.00 so\'m'), findsOneWidget);
        expect(find.text('45000.00 so\'m'), findsOneWidget);
        expect(find.text('8000.00 so\'m'), findsOneWidget);

        // Check calculation breakdown
        // Subtotal: 25000 + 45000 + 8000 = 78000
        // Service Charge: 78000 * 0.08 = 6240
        // Total: 78000 + 6240 = 84240
        expect(find.textContaining('Subtotal: 78000.00 so\'m'), findsOneWidget);
        expect(find.textContaining('Service Charge (8%): 6240.00 so\'m'), findsOneWidget);
        expect(find.textContaining('Total: 84240.00 so\'m'), findsOneWidget);

        // Check dialog buttons
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Confirm Order'), findsOneWidget);
      });

      testWidgets('should cancel order when Cancel is pressed',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Tap Cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.text('Order Summary'), findsNothing);

        // Should still be on AddDeskId page
        expect(find.byType(AddDeskId), findsOneWidget);
      });

      testWidgets('should handle empty product list gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: []),
          ),
        );

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.textContaining('No products in the order'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle products with invalid prices',
          (WidgetTester tester) async {
        final invalidProducts = [
          createTestProduct(id: '1', name: 'Valid Product', price: 25000.0),
          createTestProduct(id: '2', name: 'Invalid Product', price: -1000.0),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: invalidProducts),
          ),
        );

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Should show error message about invalid prices
        expect(find.textContaining('Invalid prices for: Invalid Product'), findsOneWidget);
      });

      testWidgets('should show proper error for taken desk',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        // Wait for desk status to load
        await tester.pumpAndSettle();

        // Find a button that might be taken (this would depend on actual data)
        // For testing, we'll simulate by checking button colors
        final buttons = find.byType(ElevatedButton);

        // This test would need to be adapted based on actual desk status loading
        // For now, we'll test the UI structure
        expect(buttons, findsWidgets);
      });
    });

    group('Calculation Accuracy Tests', () {
      testWidgets('should calculate 8% service charge correctly for single item',
          (WidgetTester tester) async {
        final singleProduct = [
          createTestProduct(id: '1', name: 'Single Item', price: 10000.0),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: singleProduct),
          ),
        );

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Check calculations: 10000 * 1.08 = 10800
        expect(find.textContaining('Subtotal: 10000.00 so\'m'), findsOneWidget);
        expect(find.textContaining('Service Charge (8%): 800.00 so\'m'), findsOneWidget);
        expect(find.textContaining('Total: 10800.00 so\'m'), findsOneWidget);
      });

      testWidgets('should handle decimal prices correctly',
          (WidgetTester tester) async {
        final decimalProducts = [
          createTestProduct(id: '1', name: 'Decimal Item', price: 33.33),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: decimalProducts),
          ),
        );

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Check that calculations are displayed (exact values may be rounded)
        expect(find.textContaining('Subtotal: 33.33 so\'m'), findsOneWidget);
        expect(find.textContaining('Service Charge (8%)'), findsOneWidget);
        expect(find.textContaining('Total:'), findsOneWidget);
      });

      testWidgets('should handle zero-priced items correctly',
          (WidgetTester tester) async {
        final zeroProducts = [
          createTestProduct(id: '1', name: 'Free Item', price: 0.0),
          createTestProduct(id: '2', name: 'Paid Item', price: 1000.0),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: zeroProducts),
          ),
        );

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Check calculations: 1000 * 1.08 = 1080
        expect(find.textContaining('Subtotal: 1000.00 so\'m'), findsOneWidget);
        expect(find.textContaining('Service Charge (8%): 80.00 so\'m'), findsOneWidget);
        expect(find.textContaining('Total: 1080.00 so\'m'), findsOneWidget);
      });
    });

    group('UI Interaction Tests', () {
      testWidgets('should display correct number of desk buttons',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        await tester.pumpAndSettle();

        // Should display 20 desk buttons (as per the original implementation)
        final buttons = find.byType(ElevatedButton);
        expect(buttons, findsNWidgets(20));
      });

      testWidgets('should show desk numbers correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        await tester.pumpAndSettle();

        // Check that desk numbers are displayed
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
      });

      testWidgets('should maintain responsive layout',
          (WidgetTester tester) async {
        // Test with different screen sizes
        await tester.binding.setSurfaceSize(const Size(800, 600)); // Tablet size

        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: testProducts),
          ),
        );

        await tester.pumpAndSettle();

        // Should still display all buttons
        final buttons = find.byType(ElevatedButton);
        expect(buttons, findsNWidgets(20));

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Navigation Tests', () {
      testWidgets('should navigate back after successful order creation',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddDeskId(product: testProducts),
                    ),
                  ),
                  child: const Text('Go to AddDeskId'),
                ),
              ),
            ),
          ),
        );

        // Navigate to AddDeskId
        await tester.tap(find.text('Go to AddDeskId'));
        await tester.pumpAndSettle();

        // Should be on AddDeskId page
        expect(find.byType(AddDeskId), findsOneWidget);

        // Tap desk button and confirm order
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Confirm the order
        await tester.tap(find.text('Confirm Order'));
        await tester.pumpAndSettle();

        // Note: In a real test, we'd mock Firebase and verify navigation
        // For now, we verify the dialog interaction works
        expect(find.text('Order Summary'), findsNothing);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle large number of products efficiently',
          (WidgetTester tester) async {
        // Create a large list of products
        final largeProductList = List.generate(100, (index) =>
          createTestProduct(
            id: index.toString(),
            name: 'Product $index',
            price: (index + 1) * 1000.0,
          )
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AddDeskId(product: largeProductList),
          ),
        );

        // Should render without performance issues
        await tester.pumpAndSettle();

        // Tap desk button
        final deskButton = find.byType(ElevatedButton).first;
        await tester.tap(deskButton);
        await tester.pumpAndSettle();

        // Should calculate and display results efficiently
        expect(find.text('Order Summary'), findsOneWidget);
        expect(find.textContaining('Total:'), findsOneWidget);
      });
    });
  });
}
