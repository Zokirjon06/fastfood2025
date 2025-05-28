import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/application/cubit/get_product_cubit.dart';
import 'package:fastfood/layers/domain/entity/order_entity.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/presentation/pages/screens/add_desk_id.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ProductEntity> selectedProducts = [];
  List<OrderEntity>? order;
  bool send = false;
  int shop = 0;
  double money = 0;

  void _createOrderInFirebase(List<ProductEntity> selectedProducts) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final String randomUserId =
        (100 * (DateTime.now().millisecondsSinceEpoch % 100) / 100)
            .round()
            .toString();

    final List<OrderItem> items = selectedProducts.map((product) {
      return OrderItem(
        name: product.name,
        quantity: product.price,
      );
    }).toList();

    final OrderEntity order = OrderEntity(
        userId: randomUserId,
        items: items,
        status: false,
        date: DateTime.now());
    try {
      await firestore.collection('orders').add(order.toJson());

      debugPrint('Order Firestore ga yuborildi!');
    } catch (e) {
      debugPrint('Firebase yozishda xatolik: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => SplashPage()));
            },
            icon: Icon(Icons.arrow_back_ios)),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.add, size: MediaQuery.of(context).size.width * 0.08)
              ),
            ],
      ),
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      //   floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.of(context).push(
      //         MaterialPageRoute(builder: (context) => MobileAdminPanel()));
      //   },
      //   backgroundColor: Colors.amber,
      //   foregroundColor: Colors.white,
      //   child: Icon(Icons.add),
      // ),
      floatingActionButton: send
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width >= 600
                        ? MediaQuery.of(context).size.width * 0.88
                        : MediaQuery.of(context).size.width * 0.74,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buyurtma: $shop ta',
                          style:
                              TextStyle(fontSize: 18.sp, color: Colors.purple),
                        ),
                      ],
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      if (selectedProducts.isNotEmpty) {
                        // _createOrderInFirebase(selectedProducts);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AddDeskId(
                                  product: selectedProducts,
                                  // order: order,
                                )));
                        setState(() {
                          // selectedProducts.clear();
                          shop = 0;
                          money = 0;
                          send = false;
                        });
                      }
                    },
                    backgroundColor: Colors.amber,
                    child: Icon(
                      Icons.send,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  context.read<ProductCubit>().getProducts(value.trim());
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  hintText: 'Qidiruv...',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              Gap(20.h),
              // TextButton(
              //     onPressed: () {
              //       Navigator.of(context).push(MaterialPageRoute(
              //           builder: (context) => OrderListPage()));
              //     },
              //     child: Text(
              //       'Buyutmalar',
              //       style:
              //           TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              //     )),
              // Gap(10.h),
              Expanded(
                child: BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, state) {
                    if (state.status == ProductStatus.loading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state.status == ProductStatus.failed) {
                      return Center(
                        child: Text(
                          "Ma'lumotni yuklashda xatolik yuz berdi",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final products = state.products;
                    if (products.isEmpty) {
                      return Center(
                        child: Text(
                          "Ma'lumot yo'q",
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }

                    return MasonryGridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width >= 1025
                          ? 6
                          : MediaQuery.of(context).size.width >= 600
                              ? 4
                              : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10.h),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final isSelected = selectedProducts.contains(product);

                        return Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedProducts.add(product);
                                  money += product.price;
                                  shop++;

                                  send = selectedProducts.isNotEmpty;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.only(bottom: 20.h),
                                decoration: BoxDecoration(
                                  color: isSelected && send
                                      ? Colors.yellow.shade100
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(15.r),
                                  border: Border.all(
                                      color: Colors.grey.shade300, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(15.r)),
                                      child: Image.network(
                                        product.imageUrl,
                                        height: 130.h,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(10.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18.sp),
                                          ),
                                          Gap(6.h),
                                          Text(
                                            "${product.price.toStringAsFixed(2)} so'm",
                                            style: TextStyle(
                                                fontSize: 16.sp,
                                                color: Colors.deepOrange),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // IconButton yuqoriga joylashgan
                                  ],
                                ),
                              ),
                            ),
                            if (isSelected && send)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  // style: IconButton.styleFrom(backgroundColor: Colors.blue),
                                  icon: Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedProducts.remove(product);
                                        money -= product.price;
                                        shop--;
                                      }
                                      send = selectedProducts.isNotEmpty;
                                    });
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Gap(20.h),
            ],
          ),
        ),
      ),
    );
  }
}
















// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final List<Map<String, String>> foodItems = [
//     {
//       'name': 'Cheeseburger',
//       'image':
//           'https://www.foodandwine.com/thmb/DI29Houjc_ccAtFKly0BbVsusHc=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/crispy-comte-cheesburgers-FT-RECIPE0921-6166c6552b7148e8a8561f7765ddf20b.jpg',
//       'price': '\$5.99',
//     },
//     {
//       'name': 'Pizza',
//       'image':
//           'https://www.foodandwine.com/thmb/Wd4lBRZz3X_8qBr69UOu2m7I2iw=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/classic-cheese-pizza-FT-RECIPE0422-31a2c938fc2546c9a07b7011658cfd05.jpg',
//       'price': '\$7.99',
//     },
//     {
//       'name': 'Sandwich',
//       'image':
//           'https://www.southernliving.com/thmb/TW2iJ6-7F-BAy35Q_EYW5wnIHGI=/750x0/filters:no_upscale():max_bytes(150000):strip_icc():format(webp)/Ham_Sandwich_011-1-49227336bc074513aaf8fdbde440eafe.jpg',
//       'price': '\$3.49',
//     },
//     {
//       'name': 'Chicken pitas',
//       'image':
//           'https://www.fromvalerieskitchen.com/wordpress/wp-content/uploads/2020/07/Greek-Chicken-Pita-Recipe-32.jpg',
//       'price': '\$4.50',
//     },
//     {
//       'name': 'Hot Dog',
//       'image':
//           'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQW4JtaURhXq3qwFupbZlDemafsA_A6pDqA8g&s',
//       'price': '\$4.50',
//     },
//     {
//       'name': 'French fries',
//       'image':
//           'https://images.immediate.co.uk/production/volatile/sites/30/2021/03/French-fries-b9e3e0c.jpg',
//       'price': '\$3.49',
//     },
//     {
//       'name': 'Gril',
//       'image': 'https://bioshop.kz/files/uploads/4_gr1.JPG',
//       'price': '\$3.99',
//     },
//     {
//       'name': 'Shovrma',
//       'image':
//           'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSnqAKmqHpNu1FRY8vfMV6z-TIaHTeIpkFqlQ&s',
//       'price': '\$7.99',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.of(context).push(
      //         MaterialPageRoute(builder: (context) => MobileAdminPanel()));
      //   },
      //   backgroundColor: Colors.amber,
      //   foregroundColor: Colors.white,
      //   child: Icon(Icons.add),
      // ),
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             expandedHeight: 210.h,
//             pinned: true,
//             backgroundColor: Colors.orange[600],
//             flexibleSpace: FlexibleSpaceBar(
//               titlePadding:
//                   EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
//               title: Text('FastFood',
//                   style: TextStyle(
//                       color: Colors.white, fontWeight: FontWeight.bold)),
//               background: Image.network(
//                 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSa3T4s-5hJUa9KH6u4dXgBb9wJN_dAyDuDTg559bomk6Jgnh0dtDCHMqAq1-C9BfWwgkI&usqp=CAU',
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ),
//           BlocBuilder<ProductCubit, ProductState>(
//             builder: (context, state) {
//               if (state.status == ProductStatus.loading) {
//                 return const SliverToBoxAdapter(
//                   child: Center(child: CircularProgressIndicator()),
//                 );
//               } else if (state.status == ProductStatus.failed) {
//                 return const SliverToBoxAdapter(
//                   child: Center(
//                     child: Text(
//                       "Ma'lumotni yuklashda xatolik yuz berdi",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 );
//               }

//               final products = state.products;
//               if (products.isEmpty) {
//                 return const SliverToBoxAdapter(
//                   child: Center(
//                     child: Text(
//                       "Ma'lumot yo'q",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 );
//               }

//               return SliverPadding(
//                 padding: const EdgeInsets.all(16.0),
//                 sliver: SliverGrid(
//                   delegate: SliverChildBuilderDelegate(
//                     (context, index) {
//                       final product = products[index];
//                       return Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(15.r),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.2),
//                               blurRadius: 6,
//                               offset: Offset(0, 4),
//                             ),
//                           ],
//                           border:
//                               Border.all(color: Colors.grey.shade300, width: 1),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             ClipRRect(
//                               borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(15.r),
//                                 topRight: Radius.circular(15.r),
//                               ),
//                               child: Image.network(
//                                 product.imageUrl,
//                                 height: 130.h,
//                                 width: double.infinity,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 12.w, vertical: 10.h),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     product.name,
//                                     style: TextStyle(
//                                       fontSize: 20.sp,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black,
//                                     ),
//                                   ),
//                                   SizedBox(height: 4.h),
//                                   Text(
//                                     'Barcha retseptlar',
//                                     style: TextStyle(
//                                       fontSize: 16.sp,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.grey[700],
//                                     ),
//                                   ),
//                                   SizedBox(height: 10.h),
//                                   Text(
//                                     product.price.toString(),
//                                     style: TextStyle(
//                                       fontSize: 16.sp,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.deepOrange,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     childCount: products.length,
//                   ),
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     mainAxisSpacing: 16,
//                     crossAxisSpacing: 16,
//                     childAspectRatio: 0.75,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }











