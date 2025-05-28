import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';
import 'package:flutter/material.dart';

class MobileAdminPanel extends StatefulWidget {
  const MobileAdminPanel({super.key});

  @override
  State<MobileAdminPanel> createState() => _MobileAdminPanelState();
}

class _MobileAdminPanelState extends State<MobileAdminPanel> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final imageController = TextEditingController();
  String category = 'Main Course';
  bool available = true;

 
  Future<void> _submit() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
    final image = imageController.text.trim();
    try {
      final db = FirebaseFirestore.instance;
      ProductEntity product = ProductEntity(
          // id: id,
          name: name,
          date: DateTime.now(),
          category: category,
          imageUrl: image,
          price: price,
          isAvailable: available);

      var myTask = await db.collection('products').add(product.toJson());
      await db
          .collection("products")
          .doc(myTask.id)
          .update({"id": myTask.id});
      ShowSnackBar.show(context, "Ma'lumot saqlandi!");
      nameController.clear();
      priceController.clear();
      imageController.clear();
      
    } catch (e) {
     ShowSnackBar.show(context, "Xato: ${e.toString()}");
      debugPrint( ' xato${e.toString()}');
    }

  }

   Stream<List<ProductEntity>> getProductsStream() {
  final db = FirebaseFirestore.instance;
  return db.collection('products').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final product = ProductEntity.fromJson(data);
      product.id = doc.id;
      return product;
    }).toList();
  });
}


  Widget buildProductItem(ProductEntity data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ListTile(
        leading: Image.network(
          data.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
        title: Text(data.name),
        subtitle: Text('${data.category} • \$${data.price}'),
        trailing: Icon(
          data.isAvailable ? Icons.check_circle : Icons.cancel,
          color: data.isAvailable ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [IconButton(onPressed: (){
          setState(() {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomePage()), (route) => false);
          });
        }, icon: Icon(Icons.check_sharp))],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Yangi mahsulot qo‘shish',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Mahsulot nomi'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Narxi'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: 'Rasm URL'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              items: const [
                DropdownMenuItem(
                    value: 'Main Course', child: Text('Main Course')),
                DropdownMenuItem(value: 'Salad', child: Text('Salad')),
                DropdownMenuItem(value: 'Side Dish', child: Text('Side Dish')),
              ],
              onChanged: (value) => setState(() => category = value!),
              decoration: const InputDecoration(labelText: 'Kategoriya'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mavjudmi?'),
                Switch(
                  value: available,
                  onChanged: (val) => setState(() => available = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text("Qo‘shish"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
            const Divider(height: 40),
            const Text(
              'Mahsulotlar ro‘yxati',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ProductEntity>>(
    stream: getProductsStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Xato: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text("Ma'lumot yo‘q"));
      }
      List<ProductEntity> products = List.from(snapshot.data!);
      
      products.sort((b, a) => a.date!.compareTo(b.date!));
     
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];
          return buildProductItem(item);
        },
      );
    },
  ),
          ],
        ),
      ),
    );
  }
}
