import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/domain/entity/order_entity.dart';
import 'package:fastfood/layers/presentation/extension/extensions.dart';
import 'package:fastfood/layers/presentation/pages/auth/login_page.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';
import 'package:fastfood/layers/presentation/utils/responsive_utils.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  //
  //  Set<int> takenDeskIds = {};
  Set<int> deskId = {};
  Set<int> orderId = {};

  //
  @override
  void initState() {
    super.initState();
    fetchTakenDeskIds();
  }

  //
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

    final bool hasCommonIds = deskIds.intersection(orderIds).isNotEmpty;

    setState(() {
      deskId = deskIds;
      orderId = orderIds;
      // Istasangiz bu yerda `hasCommonIds` ni saqlash uchun boshqa o'zgaruvchiga ham o'rnating
    });

    print("Common ID bor: $hasCommonIds");
  }

  //
  Stream<List<OrderEntity>> getAllOrdersStream() {
    final db = FirebaseFirestore.instance;
    return db.collection('orders').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderEntity.fromJson(doc.data())..id = doc.id)
          .toList();
    });
  }

  /// Shows order ready confirmation dialog
  Future<void> _showOrderReadyConfirmation(OrderEntity order) async {
    final bool? shouldMarkReady = await showDialog<bool>(
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
                Icons.restaurant_menu,
                color: Colors.amber.shade700,
                size: context.rIconSize(28),
              ),
              Gap(context.rSpacing(12)),
              Text(
                'Buyurtma tayyormi?',
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
                      Icons.table_restaurant,
                      color: Colors.amber.shade700,
                      size: context.rIconSize(24),
                    ),
                    Gap(context.rSpacing(8)),
                    Text(
                      'Stol #${order.userId}',
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
                'Bu buyurtma tayyormi?',
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
                'Buyurtma tayyor',
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

    if (shouldMarkReady == true) {
      _saveChanges(order);
    }
  }

  void _saveChanges(OrderEntity order) async {
    final db = FirebaseFirestore.instance;

    try {
      await db.collection('orders').doc(order.id).update({'status': true});

      if (!mounted) return;
      ShowSnackBar.show(context, "Status muvaffaqiyatli yangilandi.");
    } catch (e) {
      debugPrint("Statusni yangilashda xatolik: $e");

      if (!mounted) return;
      ShowSnackBar.show(context, "Status yangilanishida xatolik yuz berdi.");
    }
  }

  /// Builds a single order item widget with improved styling
  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: context.rSpacing(8)),
      padding: EdgeInsets.symmetric(horizontal: context.rSpacing(12), vertical: context.rSpacing(10)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.rBorderRadius(8)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Item icon
          Container(
            padding: EdgeInsets.all(context.rSpacing(6)),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(context.rBorderRadius(6)),
            ),
            child: Icon(
              Icons.restaurant,
              size: context.rIconSize(20),
              color: Colors.orange.shade700,
            ),
          ),
          Gap(context.rSpacing(12)),

          // Item name
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: context.rFontSize(16),
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Item price
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.rSpacing(8), vertical: context.rSpacing(4)),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(context.rBorderRadius(6)),
            ),
            child: Text(
              '${item.quantity.toMoney()} so\'m',
              style: TextStyle(
                fontSize: context.rFontSize(16),
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => SplashPage()));
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.grey.shade700,
          ),
        ),
        title: Text(
          'Buyurtmalar',
          style: TextStyle(
            fontSize: context.rFontSize(20),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),(route) => false
                );
              },
              icon: Icon(Icons.logout_outlined))
        ],
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<List<OrderEntity>>(
        stream: getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text(
                "Xatolik yuz berdi!",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          List<OrderEntity> orders = snapshot.data!;

          if (orders.isEmpty) {
            return const Center(
              child: Text("Buyurtmalar topilmadi"),
            );
          }

          orders.sort((a, b) => b.date.compareTo(a.date));

          return MasonryGridView.count(
            crossAxisCount: context.isMobile ? 1 : 2,
            mainAxisSpacing: context.rSpacing(16),
            crossAxisSpacing: context.rSpacing(16),
            padding: EdgeInsets.symmetric(horizontal: context.rSpacing(16), vertical: context.rSpacing(10)),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // final userId = order.userId;
              final status = order.status;
              final items = order.items;
              // final deskNumber = index + 1;
              // final isTaken = deskId == orderId;
              final userId = int.tryParse(order.userId.toString()) ?? -1;
              final isTaken = deskId.contains(userId);

              double total = 0;
              for (var item in items) {
                total += double.tryParse(item.quantity.toString()) ?? 0;
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.rBorderRadius(15)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(context.rSpacing(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with table number and order info
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rSpacing(12), vertical: context.rSpacing(8)),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(context.rBorderRadius(8)),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              color: Colors.deepPurple,
                              size: context.rIconSize(25),
                            ),
                            Gap(context.rSpacing(8)),
                            Text(
                              isTaken
                                  ? 'Stol raqami: $userId'
                                  : 'Dostavka: $userId',
                              style: TextStyle(
                                fontSize: context.rFontSize(18),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Spacer(),
                            // Container(
                            //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            //   decoration: BoxDecoration(
                            //     color: Colors.grey.shade100,
                            //     borderRadius: BorderRadius.circular(5.r),
                            //   ),
                            //   child: Text(
                            //     '${items.length} buyurtma',
                            //     style: TextStyle(
                            //       fontSize: 16.sp,
                            //       color: Colors.grey.shade600,
                            //       fontWeight: FontWeight.w500,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      Gap(context.rSpacing(12)),

                      // Items list with better layout
                      Column(
                        children:
                            items.map((item) => _buildOrderItem(item)).toList(),
                      ),
                      Divider(height: context.rSpacing(20), color: Colors.grey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jami:',
                            style: TextStyle(
                              fontSize: context.rFontSize(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${total.toMoney()} so\'m',
                            style: TextStyle(
                              fontSize: context.rFontSize(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Gap(context.rSpacing(12)),

                      // Status and action section
                      Container(
                        padding: EdgeInsets.all(context.rSpacing(10)),
                        decoration: BoxDecoration(
                          color: status
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(context.rBorderRadius(8)),
                          border: Border.all(
                            color: status
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status ? Icons.check_circle : Icons.access_time,
                              color: status
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              size: context.rIconSize(20),
                            ),
                            Gap(context.rSpacing(8)),
                            Text(
                              'Holati:',
                              style: TextStyle(
                                fontSize: context.rFontSize(18),
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Gap(context.rSpacing(8)),
                            Expanded(
                              child: Text(
                                status ? 'Bajarildi' : '',
                                style: TextStyle(
                                  fontSize: context.rFontSize(18),
                                  fontWeight: FontWeight.bold,
                                  color: status
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                            if (!status)
                              ElevatedButton(
                                onPressed: () =>
                                    _showOrderReadyConfirmation(order),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(context.rBorderRadius(8)),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: context.rSpacing(16), vertical: context.rSpacing(8)),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: context.rIconSize(16)),
                                    Gap(context.rSpacing(4)),
                                    Text(
                                      'Tayyorlanmoqda',
                                      style: TextStyle(
                                        fontSize: context.rFontSize(18),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Gap(context.rSpacing(8)),
                      // ElevatedButton(
                      //     onPressed: () {},
                      //     style: ElevatedButton.styleFrom(
                      //         backgroundColor: Colors.amber,
                      //         foregroundColor: Colors.white),
                      //     child: Text("Bajarildi"))
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
