import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/domain/entity/desk_id_entiry.dart';
import 'package:fastfood/layers/domain/entity/order_entity.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  Future<void> _createOrderInFirebase(
      List<ProductEntity> selectedProducts, int deskId) async {
    final firestore = FirebaseFirestore.instance;

    final items = selectedProducts.map((product) {
      return OrderItem(name: product.name, quantity: product.price);
    }).toList();

    final order = OrderEntity(
      userId: deskId.toString(),
      items: items,
      status: false,
      date: DateTime.now(),
    );

    try {
      await firestore.collection('orders').add(order.toJson());
      debugPrint('Order Firestore ga yuborildi!');
    } catch (e) {
      debugPrint('Firebase yozishda xatolik: $e');
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

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = MediaQuery.of(context).size.width >= 600 ? 4 : 2;

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
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
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
                      setState(() {
                        shop = deskNumber;
                      });
                      await _createOrderInFirebase(widget.product, deskNumber);
                      await _createDeskFirebase(deskNumber);
                      widget.product.clear();
                      if (mounted) Navigator.pop(context);
                      ShowSnackBar.show(
                          context, "Buyurtma muvafaqqiyatli qo'shildi");
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
                    fontSize: 18.sp,
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
