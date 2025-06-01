import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/application/cubit/get_product_cubit.dart';
import 'package:fastfood/layers/domain/entity/order_entity.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/presentation/extension/extensions.dart';
import 'package:fastfood/layers/presentation/pages/screens/add_desk_id.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';
import 'package:fastfood/layers/presentation/pages/order_edit_or_delete_page.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';
import 'package:fastfood/layers/data/service/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Controllers and focus nodes
  late final TabController _tabController;
  late final PageController _pageController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  // State variables
  List<ProductEntity> selectedProducts = [];
  List<OrderEntity>? order;
  bool _isSearchMode = false;
  int _currentPage = 0;
  bool send = false;
  int shop = 0;
  double money = 0;

  // Constants for better performance
  static const int _itemsPerPage = 6; // 6 products per page (2x3 grid)

  @override
  void initState() {
    super.initState();

    // Initialize all controllers
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Listen to search controller changes to update clear button
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Enters search mode and shows search overlay
  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
    // Focus the search field after the UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  /// Exits search mode and returns to normal view
  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
    });
    // Clear search results
    context.read<ProductCubit>().getProducts('');
    _searchFocusNode.unfocus();
  }

  /// Calculates total number of pages based on products count
  int _getTotalPages(int totalProducts) {
    return (totalProducts / _itemsPerPage).ceil();
  }

  /// Gets products for current page
  List<ProductEntity> _getProductsForPage(List<ProductEntity> allProducts, int page) {
    final startIndex = page * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, allProducts.length);

    if (startIndex >= allProducts.length) return [];
    return allProducts.sublist(startIndex, endIndex);
  }

  /// Navigates to next page
  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigates to previous page
  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigates to specific page
  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Shows the add product modal
  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductModal(
        onProductAdded: () {
          // Refresh products after adding
          context.read<ProductCubit>().getProducts('');
        },
      ),
    );
  }

  /// Creates delivery order directly without desk selection
  Future<void> _createDeliveryOrder() async {
    if (selectedProducts.isEmpty) return;

    try {
      // Generate random userId between 1-100
      final random = math.Random();
      final randomUserId = random.nextInt(100) + 1;

      // Calculate total with 8% service charge
      final firestore = FirebaseFirestore.instance;

      final items = selectedProducts.map((product) {
        final totalWithServiceCharge = product.price; // Add 8%
        return OrderItem(
          name: product.name,
          quantity: totalWithServiceCharge,
        );
      }).toList();

      final order = OrderEntity(
        userId: randomUserId.toString(),
        items: items,
        status: false,
        date: DateTime.now(),
      );

      await firestore.collection('orders').add(order.toJson());

      // Clear selection and show success
      setState(() {
        selectedProducts.clear();
        shop = 0;
        money = 0;
        send = false;
      });

      if (mounted) {
        ShowSnackBar.show(context, 'Delivery order created successfully!');
      }
    } catch (e) {
      if (mounted) {
        ShowSnackBar.show(context, 'Failed to create delivery order: ${e.toString()}');
      }
    }
  }

  /// Builds the normal AppBar with title and actions
  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'FastFood Admin',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
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
      actions: [
        // Search Button
        IconButton(
          onPressed: _enterSearchMode,
          icon: Icon(
            Icons.search,
            size: MediaQuery.sizeOf(context).width * 0.08,
            color: Colors.grey.shade700,
          ),
          tooltip: 'Search',
        ),
        // Add Product Button
        IconButton(
          onPressed: () {
            _showAddProductModal();
          },
          icon: Icon(
            Icons.add,
            size: MediaQuery.sizeOf(context).width * 0.08,
            color: Colors.black,
          ),
          tooltip: 'Add Product',
        ),
        Gap(8.w),
      ],
    );
  }

  /// Builds the search AppBar with search input and back button
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: IconButton(
        onPressed: _exitSearchMode,
        icon: Icon(
          Icons.arrow_back,
          color: Colors.grey.shade700,
        ),
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        onChanged: (value) {
          context.read<ProductCubit>().getProducts(value.trim());
        },
        decoration: InputDecoration(
          hintText: 'Qidiruv...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8.h),
        ),
        style: TextStyle(
          fontSize: 16.sp,
          color: Colors.black87,
        ),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            onPressed: () {
              _searchController.clear();
              context.read<ProductCubit>().getProducts('');
            },
            icon: Icon(
              Icons.clear,
              color: Colors.grey.shade700,
            ),
          ),
        Gap(8.w),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearchMode ? _buildSearchAppBar() : _buildNormalAppBar(),
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                              TextStyle(fontSize: 18.sp, color: Colors.blue[900]),
                        ),
                      ],
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      if (selectedProducts.isNotEmpty) {
                        // Check current tab
                        if (_tabController.index == 0) {
                          // Hall tab - navigate to AddDeskId
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AddDeskId(
                                    product: selectedProducts,
                                  )));
                          setState(() {
                            shop = 0;
                            money = 0;
                            send = false;
                          });
                        } else {
                          // Delivery tab - create order directly
                          _createDeliveryOrder();
                        }
                      }
                    },
                    backgroundColor: Colors.amber,
                    child: Icon(
                      _tabController.index == 0 ? Icons.send : Icons.delivery_dining,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: _isSearchMode ? _buildSearchView() : _buildNormalView(),
    );
  }

  /// Builds the normal view with TabBar and TabBarView
  Widget _buildNormalView() {
    return Column(
      children: [
        // TabBar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.amber.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.amber.shade700,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Zal',),
              Tab(text: 'Dostavka'),
            ],
          ),
        ),
        // TabBarView content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Hall Tab
              _buildProductView(),
              // Delivery Tab
              _buildProductView(),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the search view with pagination
  Widget _buildSearchView() {
    // Reset to first page when entering search mode
    if (_currentPage != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentPage = 0;
        });
        _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      });
    }
    return _buildProductView();
  }

  /// Builds the product view that's shared between both tabs
  Widget _buildProductView() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(20.h),
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

                  final allProducts = state.products;
                  if (allProducts.isEmpty) {
                    return Center(
                      child: Text(
                        "Ma'lumot yo'q",
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }

                  // Calculate pagination
                  final totalPages = _getTotalPages(allProducts.length);

                  // Reset current page if it exceeds total pages
                  if (_currentPage >= totalPages) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _currentPage = 0;
                      });
                    });
                  }

                  return Column(
                    children: [
                      // Page indicator and info
                      if (totalPages > 1) _buildPageHeader(allProducts.length, totalPages),

                      // Products grid with pagination
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          itemCount: totalPages,
                          itemBuilder: (context, pageIndex) {
                            final pageProducts = _getProductsForPage(allProducts, pageIndex);
                            return _buildProductGrid(pageProducts);
                          },
                        ),
                      ),

                      // Page navigation controls
                      if (totalPages > 1) _buildPageNavigation(totalPages),
                    ],
                  );
                },
              ),
            ),
            Gap(20.h),
          ],
        ),
      ),
    );
  }

  /// Builds the page header with current page info
  Widget _buildPageHeader(int totalProducts, int totalPages) {
    final startItem = (_currentPage * _itemsPerPage) + 1;
    final endItem = ((_currentPage + 1) * _itemsPerPage).clamp(1, totalProducts);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mahsulotlar: $startItem-$endItem / $totalProducts',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade800,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Sahifa ${_currentPage + 1}/$totalPages',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the product grid for a specific page
  Widget _buildProductGrid(List<ProductEntity> products) {
    return MasonryGridView.count(
      crossAxisCount: MediaQuery.of(context).size.width >= 1025
          ? 6
          : MediaQuery.of(context).size.width >= 600
              ? 4
              : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
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
              onLongPress: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OrderEditOrDeletePage(product: product),
                  ),
                );

                // If changes were made, refresh the products list
                if (result == true && mounted && context.mounted) {
                  context.read<ProductCubit>().getProducts('');
                }
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
                      color: Colors.grey.withValues(alpha: 0.2),
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
                      child: product.hasLocalImage
                          ? Image.file(
                              File(product.localImagePath!),
                              height: 130.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return product.hasUploadedImage
                                    ? Image.network(
                                        product.imageUrl!,
                                        height: 130.h,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 130.h,
                                            width: double.infinity,
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        height: 130.h,
                                        width: double.infinity,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                        ),
                                      );
                              },
                            )
                          : product.hasUploadedImage
                              ? Image.network(
                                  product.imageUrl!,
                                  height: 130.h,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 130.h,
                                      width: double.infinity,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  height: 130.h,
                                  width: double.infinity,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                  ),
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
                            "${product.price.toMoney()} so'm",
                            style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.deepOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected && send)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
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
  }

  /// Builds the page navigation controls
  Widget _buildPageNavigation(int totalPages) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: Icon(
              Icons.chevron_left,
              size: 32.sp,
              color: _currentPage > 0 ? Colors.amber.shade700 : Colors.grey.shade400,
            ),
          ),

          Gap(16.w),

          // Page indicators
          Row(
            children: List.generate(totalPages, (index) {
              final isCurrentPage = index == _currentPage;
              return GestureDetector(
                onTap: () => _goToPage(index),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: isCurrentPage ? 32.w : 24.w,
                  height: isCurrentPage ? 32.h : 24.h,
                  decoration: BoxDecoration(
                    color: isCurrentPage ? Colors.amber.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16.r),
                    border: isCurrentPage
                        ? Border.all(color: Colors.amber.shade900, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: isCurrentPage ? 14.sp : 12.sp,
                        fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentPage ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          Gap(16.w),

          // Next button
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () => _nextPage(totalPages) : null,
            icon: Icon(
              Icons.chevron_right,
              size: 32.sp,
              color: _currentPage < totalPages - 1 ? Colors.amber.shade700 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal widget for adding new products
class AddProductModal extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductModal({
    super.key,
    required this.onProductAdded,
  });

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Picks an image from device gallery
  Future<void> _pickImage() async {
    try {
      // Request permission for accessing photos
      var status = await Permission.photos.status;

      if (status.isDenied) {
        status = await Permission.photos.request();
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          ShowSnackBar.show(context, "Ruxsat rad etilgan. Iltimos, sozlamalarga o'ting va ruxsatlarni yoqing");
        }
        await openAppSettings();
        return;
      }

      if (status.isGranted) {
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final File imageFile = File(pickedFile.path);

          // Validate image file
          if (!ImageUploadService.isValidImageFile(imageFile)) {
            if (mounted) {
              ShowSnackBar.show(context, "Noto'g'ri fayl formati. Iltimos, rasm faylini tanlang.");
            }
            return;
          }

          // Check file size (max 5MB)
          if (!ImageUploadService.isValidFileSize(imageFile)) {
            if (mounted) {
              ShowSnackBar.show(context, "Fayl hajmi juda katta. Maksimal 5MB ruxsat etilgan.");
            }
            return;
          }

          setState(() {
            _selectedImage = imageFile;
          });

          if (mounted) {
            ShowSnackBar.show(context, "Rasm tanlandi");
          }
        }
      } else {
        if (mounted) {
          ShowSnackBar.show(context, "Rasmlarni tanlash uchun ruxsat berilmagan");
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ShowSnackBar.show(context, "Rasm tanlashda xatolik yuz berdi");
      }
    }
  }

  /// Removes the selected image
  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  /// Submits the product to Firebase
  Future<void> _submitProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    // Validation
    if (name.isEmpty) {
      ShowSnackBar.show(context, "Mahsulot nomini kiriting");
      return;
    }

    if (price <= 0) {
      ShowSnackBar.show(context, "To'g'ri narx kiriting");
      return;
    }

    if (_selectedImage == null) {
      ShowSnackBar.show(context, "Rasm tanlang");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final db = FirebaseFirestore.instance;

      // Show upload progress
      if (mounted) {
        ShowSnackBar.show(context, "Rasm saqlanmoqda...");
      }

      // Upload image to Firebase Storage with retry mechanism
      final uploadedImageUrl = await ImageUploadService.uploadProductImageWithRetry(
        imageFile: _selectedImage!,
        fileName: 'product_${name.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
        maxRetries: 3,
      );

      ProductEntity product = ProductEntity(
        name: name,
        date: DateTime.now(),
        localImagePath: _selectedImage!.path,
        imageUrl: uploadedImageUrl,
        price: price,
      );

      var myTask = await db.collection('products').add(product.toJson());
      await db
          .collection("products")
          .doc(myTask.id)
          .update({"id": myTask.id});

      if (mounted) {
        ShowSnackBar.show(context, "Mahsulot muvaffaqiyatli qo'shildi!");
        Navigator.of(context).pop(); // Close modal
        widget.onProductAdded(); // Refresh products
      }

    } catch (e) {
      debugPrint('Error submitting product: $e');
      if (mounted) {
        String errorMessage = "Mahsulot qo'shishda xatolik yuz berdi";

        // Provide specific error messages
        if (e.toString().contains('Storage bucket not found')) {
          errorMessage = "Firebase Storage sozlanmagan. Mahsulot mahalliy saqlanadi.";
        } else if (e.toString().contains('Unauthorized access')) {
          errorMessage = "Rasm yuklash uchun ruxsat yo'q. Mahsulot mahalliy saqlanadi.";
        } else if (e.toString().contains('User not authenticated')) {
          errorMessage = "Foydalanuvchi autentifikatsiya qilinmagan. Qayta login qiling.";
        } else if (e.toString().contains('File size too large')) {
          errorMessage = "Fayl hajmi juda katta. Maksimal 10MB ruxsat etilgan.";
        } else if (e.toString().contains('Both Firebase Storage and local storage failed')) {
          errorMessage = "Rasm saqlashda xatolik. Qaytadan urinib ko'ring.";
        } else if (e.toString().contains('Firebase Storage') && e.toString().contains('local storage')) {
          errorMessage = "Mahsulot muvaffaqiyatli qo'shildi (mahalliy saqlandi).";
        }

        ShowSnackBar.show(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yangi mahsulot qo\'shish',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    'Mahsulot nomi',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Gap(8.h),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Mahsulot nomini kiriting',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.amber, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  Gap(20.h),

                  // Product Price
                  Text(
                    'Mahsulot narxi',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Gap(8.h),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Narxni kiriting',
                      suffixText: 'so\'m',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.amber, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  Gap(20.h),

                  // Product Image
                  Text(
                    'Mahsulot rasmi',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Gap(8.h),

                  Container(
                    width: double.infinity,
                    height: 200.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: _selectedImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8.h,
                                right: 8.w,
                                child: GestureDetector(
                                  onTap: _removeSelectedImage,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: _isUploading ? null : _pickImage,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48.sp,
                                  color: Colors.grey.shade400,
                                ),
                                Gap(8.h),
                                Text(
                                  'Rasm tanlash uchun bosing',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  Gap(30.h),
                ],
              ),
            ),
          ),

          // Add Button
          Container(
            padding: EdgeInsets.all(20.w),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Gap(12.w),
                          Text(
                            'Yuklanmoqda...',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Mahsulot qo\'shish',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
