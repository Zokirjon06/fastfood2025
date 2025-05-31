import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/domain/entity/order_entity.dart';
import 'package:fastfood/layers/presentation/extension/extensions.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
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
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Colors.amber.shade700,
                size: 28.sp,
              ),
              Gap(12.w),
              Text(
                'Buyurtma tayyormi?',
                style: TextStyle(
                  fontSize: 20.sp,
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
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.table_restaurant,
                      color: Colors.amber.shade700,
                      size: 24.sp,
                    ),
                    Gap(8.w),
                    Text(
                      'Stol #${order.userId}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(16.h),
              Text(
                'Ishonchingiz komilmi?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Gap(8.h),
              Text(
                'Bu buyurtma tayyormi?',
                style: TextStyle(
                  fontSize: 16.sp,
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
                  fontSize: 16.sp,
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
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
              child: Text(
                'Buyurtma tayyor',
                style: TextStyle(
                  fontSize: 16.sp,
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
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Item icon
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              Icons.restaurant,
              size: 20.sp,
              color: Colors.orange.shade700,
            ),
          ),
          Gap(12.w),

          // Item name
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Item price
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              '${item.quantity.toMoney()} so\'m',
              style: TextStyle(
                fontSize: 16.sp,
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
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
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
            crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 2 : 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10.h),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final userId = order.userId;
              final status = order.status;
              final items = order.items;

              double total = 0;
              for (var item in items) {
                total += double.tryParse(item.quantity.toString()) ?? 0;
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with table number and order info
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              color: Colors.deepPurple,
                              size: 25.sp,
                            ),
                            Gap(8.w),
                            Text(
                              'Stol raqami: $userId',
                              style: TextStyle(
                                fontSize: 18.sp,
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
                      Gap(12.h),

                      // Items list with better layout
                      Column(
                        children: items.map((item) => _buildOrderItem(item)).toList(),
                      ),
                      Divider(height: 20.h, color: Colors.grey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jami:',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${total.toMoney()} so\'m',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Gap(12.h),

                      // Status and action section
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: status ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: status ? Colors.green.shade200 : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status ? Icons.check_circle : Icons.access_time,
                              color: status ? Colors.green.shade700 : Colors.orange.shade700,
                              size: 20.sp,
                            ),
                            Gap(8.w),
                            Text(
                              'Holati:',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Gap(8.w),
                            Expanded(
                              child: Text(
                                status ? 'Bajarildi' : '',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: status ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ),
                            if (!status)
                              ElevatedButton(
                                onPressed: () => _showOrderReadyConfirmation(order),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 16.sp),
                                    Gap(4.w),
                                    Text(
                                      'Tayyorlanmoqda',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Gap(8.h),
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
