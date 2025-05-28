import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/domain/entity/order_entity.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        // elevation: 4,
        leading: IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => SplashPage()));
            },
            icon: Icon(Icons.arrow_back_ios)),
        title: Text(
          'Buyurtmalar',
          style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black),
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
                      Text(
                        'Stol raqami: $userId',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ...items.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '${item.quantity} so\'m',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      Divider(height: 20.h, color: Colors.grey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jami:',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$total so\'m',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Gap(8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status:',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          IconButton(
                            onPressed: () {
                              _saveChanges(order);
                            },
                            icon: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? CircularProgressIndicator()
                                : Icon(
                                    status
                                        ? Icons.check_circle
                                        : Icons.hourglass_empty,
                                    color:
                                        status ? Colors.green : Colors.orange,
                                  ),
                          ),
                        ],
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
