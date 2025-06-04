import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastfood/layers/application/cubit/get_product_cubit.dart';
import 'package:fastfood/layers/domain/entity/order_entity.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/presentation/extension/extensions.dart';
import 'package:fastfood/layers/presentation/helpers/input_formatter.dart';
import 'package:fastfood/layers/presentation/pages/screens/add_desk_id.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';
import 'package:fastfood/layers/presentation/pages/order_edit_or_delete_page.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';
import 'package:fastfood/layers/presentation/utils/responsive_utils.dart';
import 'package:fastfood/layers/data/service/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final ScrollController _scrollController = ScrollController();

  // State variables
  List<ProductEntity> selectedProducts = [];
  List<OrderEntity>? order;
  bool _isSearchMode = false;
  int _currentPage = 0;
  bool send = false;
  int shop = 0;
  double money = 0;

  // Enhanced lazy loading and memory management variables
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentBatchIndex = 0;
  late final int _batchSize; // Items per batch (responsive)
  final List<ProductEntity> _loadedProducts = []; // Cache for loaded products
  final Set<int> _visibleIndices = <int>{}; // Track visible items for memory management

  // Memory management constants (responsive)
  late final int _maxCachedItems; // Maximum items to keep in memory
  late final int _preloadThreshold; // Items before end to trigger loading
  static const double _scrollThreshold = 0.8; // 80% scroll to trigger loading

  // Device-specific pagination constants
  static const int _mobileItemsPerPage = 6; // 6 products per page for mobile only
  bool _wasMobileLastFrame = false; // Track device type changes for state reset


  // Get items per page based on screen size (only used for mobile pagination)
  int get _itemsPerPage {
    // Only mobile uses pagination, larger screens use continuous scrolling
    return _mobileItemsPerPage;
  }

  
  @override
  void initState() {
    super.initState();

    // Initialize all controllers
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Add scroll listener for lazy loading
    _scrollController.addListener(_scrollListener);

    // Listen to search controller changes to update clear button
    _searchController.addListener(() {
      setState(() {});
    });

    // Initialize lazy loading state
    _currentBatchIndex = 0;
    _hasMoreData = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize responsive constants after context is available
    _batchSize = ResponsiveUtils.getBatchSize(context);
    _maxCachedItems = ResponsiveUtils.getOptimalCacheSize(context);
    _preloadThreshold = ResponsiveUtils.getPreloadThreshold(context);

    // Check for device type changes and reset state if needed
    _handleDeviceTypeChange();
  }

  /// Handles device type changes (e.g., rotation, window resize)
  void _handleDeviceTypeChange() {
    final isMobileNow = ResponsiveUtils.isMobile(context);

    // If device type changed, reset pagination/lazy loading state
    if (_wasMobileLastFrame != isMobileNow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentPage = 0;
            _resetLazyLoading();
          });

          // Reset page controller for mobile pagination
          if (isMobileNow && _pageController.hasClients) {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
      _wasMobileLastFrame = isMobileNow;
    }
  }

  @override
    void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Enhanced scroll listener for memory-efficient lazy loading
  void _scrollListener() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreData) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Check if we need to load more items
    if (currentScroll >= maxScroll * _scrollThreshold) {
      _loadMoreItems();
    }

    // Memory management: track visible items
    _updateVisibleIndices();
  }

  /// Load more items with memory management
  void _loadMoreItems() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay for loading more products
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _currentBatchIndex++;
          _isLoadingMore = false;

          // Check if we've reached the end of available data
          // This would be determined by your actual data source
          // For now, we'll simulate having more data for the first few batches
          if (_currentBatchIndex >= 10) { // Simulate max 10 batches
            _hasMoreData = false;
          }

          // Memory management: clean up old items if cache is too large
          _manageMemoryCache();
        });
      }
    });
  }

  /// Update visible indices for memory management
  void _updateVisibleIndices() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final viewportHeight = position.viewportDimension;
    final scrollOffset = position.pixels;

    // Calculate visible range with some buffer
    final startOffset = (scrollOffset - viewportHeight * 0.5).clamp(0.0, double.infinity);
    final endOffset = scrollOffset + viewportHeight * 1.5;

    // This is a simplified calculation - in a real implementation,
    // you'd calculate based on actual item heights and positions
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(context);
    final estimatedItemHeight = ResponsiveUtils.getCardHeight(context) + 16; // Card height + spacing

    final startIndex = ((startOffset / estimatedItemHeight).floor() * crossAxisCount).clamp(0, _loadedProducts.length - 1);
    final endIndex = ((endOffset / estimatedItemHeight).ceil() * crossAxisCount).clamp(0, _loadedProducts.length);

    _visibleIndices.clear();
    for (int i = startIndex; i < endIndex; i++) {
      _visibleIndices.add(i);
    }
  }

  /// Manage memory cache by removing items far from viewport
  void _manageMemoryCache() {
    if (_loadedProducts.length <= _maxCachedItems) return;

    // Keep only items that are visible or near visible
    final itemsToKeep = <ProductEntity>[];
    final sortedIndices = _visibleIndices.toList()..sort();

    if (sortedIndices.isNotEmpty) {
      final bufferSize = _preloadThreshold * 2;
      final startKeep = (sortedIndices.first - bufferSize).clamp(0, _loadedProducts.length);
      final endKeep = (sortedIndices.last + bufferSize).clamp(0, _loadedProducts.length);

      for (int i = startKeep; i < endKeep; i++) {
        if (i < _loadedProducts.length) {
          itemsToKeep.add(_loadedProducts[i]);
        }
      }

      _loadedProducts.clear();
      _loadedProducts.addAll(itemsToKeep);

      // Force garbage collection to free up memory
      if (_loadedProducts.length < _maxCachedItems * 0.5) {
        // Trigger garbage collection when cache is significantly reduced
        Future.delayed(Duration.zero, () {
          // This helps with memory cleanup
        });
      }
    }
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



  /// Reset lazy loading state (useful when search changes or data refreshes)
  void _resetLazyLoading() {
    setState(() {
      _currentBatchIndex = 0;
      _hasMoreData = true;
      _isLoadingMore = false;
      _loadedProducts.clear();
      _visibleIndices.clear();
    });
  }



  /// Exits search mode and returns to normal view
  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
    });
    // Reset lazy loading state and clear search results
    _resetLazyLoading();
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
          fontSize: context.rFontSize(22),
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
            size: context.rIconSize(30),
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
            size: context.rIconSize(30),
            color: Colors.black,
          ),
          tooltip: 'Add Product',
        ),
        Gap(context.rSpacing(8)),
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
            fontSize: context.rFontSize(16),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: context.rSpacing(8)),
        ),
        style: TextStyle(
          fontSize: context.rFontSize(16),
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
        Gap(context.rSpacing(8)),
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
              padding: EdgeInsets.symmetric(horizontal: context.rSpacing(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width >= 600
                        ? MediaQuery.of(context).size.width * 0.88
                        : MediaQuery.of(context).size.width * 0.74,
                    padding:
                        EdgeInsets.symmetric(horizontal: context.rSpacing(16), vertical: context.rSpacing(12)),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(context.rBorderRadius(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buyurtma: $shop ta',
                          style:
                              TextStyle(fontSize: context.rFontSize(18), color: Colors.blue[900]),
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
              fontSize: context.rFontSize(18),
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: context.rFontSize(18),
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

  /// Builds the product view with device-specific pagination behavior
  Widget _buildProductView() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rSpacing(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(context.rSpacing(20)),
            Expanded(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  if (state.status == ProductStatus.loading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.amber.shade700,
                      ),
                    );
                  } else if (state.status == ProductStatus.failed) {
                    return Center(
                      child: Text(
                        "Ma'lumotni yuklashda xatolik yuz berdi",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: context.rFontSize(16),
                        ),
                      ),
                    );
                  }

                  final allProducts = state.products;
                  if (allProducts.isEmpty) {
                    return Center(
                      child: Text(
                        "Ma'lumot yo'q",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: context.rFontSize(16),
                        ),
                      ),
                    );
                  }

                  // Device-specific behavior
                  if (ResponsiveUtils.isMobile(context)) {
                    // Mobile: Use pagination with 6 items per page
                    return _buildMobilePaginatedView(allProducts);
                  } else {
                    // Tablet, Desktop, TV: Use continuous scrolling with lazy loading
                    return _buildContinuousScrollView(allProducts);
                  }
                },
              ),
            ),
            Gap(context.rSpacing(20)),
          ],
        ),
      ),
    );
  }

  /// Builds mobile view with pagination (6 items per page)
  Widget _buildMobilePaginatedView(List<ProductEntity> allProducts) {
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
        if (totalPages > 1) _buildMobilePageHeader(allProducts.length, totalPages),

        // Products grid with pagination
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
              // Preload next page for smoother experience
              _preloadMobilePageData(allProducts, page);
            },
            itemCount: totalPages,
            itemBuilder: (context, pageIndex) {
              final pageProducts = _getProductsForPage(allProducts, pageIndex);
              return _buildMobileGrid(pageProducts);
            },
          ),
        ),

        // Page navigation controls
        if (totalPages > 1) _buildMobilePageNavigation(totalPages),
      ],
    );
  }

  /// Builds continuous scroll view for tablet, desktop, and TV
  Widget _buildContinuousScrollView(List<ProductEntity> allProducts) {
    final displayProducts = _getProductsForContinuousScroll(allProducts);

    return Column(
      children: [
        // Product count indicator for larger screens
        if (displayProducts.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.rSpacing(16), vertical: context.rSpacing(8)),
            margin: EdgeInsets.only(bottom: context.rSpacing(8)),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(context.rBorderRadius(8)),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ko\'rsatilgan: ${displayProducts.length} / ${allProducts.length}',
                  style: TextStyle(
                    fontSize: context.rFontSize(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
                if (_hasMoreData)
                  Text(
                    'Scroll down for more',
                    style: TextStyle(
                      fontSize: context.rFontSize(12),
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

        // Scrollable product grid with lazy loading
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(context.rSpacing(16)),
              child: _buildContinuousGrid(displayProducts),
            ),
          ),
        ),

        // Loading indicator at bottom
        if (_isLoadingMore)
          Container(
            padding: EdgeInsets.all(context.rSpacing(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: context.rSpacing(20),
                  height: context.rSpacing(20),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                Gap(context.rSpacing(12)),
                Text(
                  'Loading more products...',
                  style: TextStyle(
                    fontSize: context.rFontSize(14),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

        // End of data indicator
        if (!_hasMoreData && displayProducts.isNotEmpty)
          Container(
            padding: EdgeInsets.all(context.rSpacing(16)),
            child: Text(
              'All products loaded',
              style: TextStyle(
                fontSize: context.rFontSize(14),
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the page header with current page info for mobile
  Widget _buildMobilePageHeader(int totalProducts, int totalPages) {
    final startItem = (_currentPage * _itemsPerPage) + 1;
    final endItem = ((_currentPage + 1) * _itemsPerPage).clamp(1, totalProducts);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.rSpacing(16), vertical: context.rSpacing(12)),
      margin: EdgeInsets.only(bottom: context.rSpacing(16)),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mahsulotlar: $startItem-$endItem / $totalProducts',
            style: TextStyle(
              fontSize: context.rFontSize(14),
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade800,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.rSpacing(12), vertical: context.rSpacing(6)),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(context.rBorderRadius(20)),
            ),
            child: Text(
              'Sahifa ${_currentPage + 1}/$totalPages',
              style: TextStyle(
                fontSize: context.rFontSize(12),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get products for continuous scroll with lazy loading
  List<ProductEntity> _getProductsForContinuousScroll(List<ProductEntity> allProducts) {
    // Calculate how many items to show based on current batch
    final itemsToShow = (_currentBatchIndex + 1) * _batchSize;
    final endIndex = itemsToShow.clamp(0, allProducts.length);

    // Update loaded products cache
    if (_loadedProducts.length < endIndex) {
      _loadedProducts.clear();
      _loadedProducts.addAll(allProducts.sublist(0, endIndex));
    }

    // Update hasMoreData flag
    _hasMoreData = endIndex < allProducts.length;

    return _loadedProducts;
  }

  /// Preload data for smoother mobile page transitions
  void _preloadMobilePageData(List<ProductEntity> allProducts, int currentPage) {
    // Preload next page data if available
    if (currentPage + 1 < _getTotalPages(allProducts.length)) {
      final nextPageProducts = _getProductsForPage(allProducts, currentPage + 1);
      // Cache images for next page products
      for (final product in nextPageProducts) {
        if (product.hasUploadedImage) {
          // Preload network images
          precacheImage(NetworkImage(product.imageUrl!), context);
        }
      }
    }
  }

  /// Builds mobile grid with 2 columns
  Widget _buildMobileGrid(List<ProductEntity> products) {
    return MasonryGridView.count(
      crossAxisCount: 2, // Always 2 columns for mobile
      mainAxisSpacing: context.rSpacing(16),
      crossAxisSpacing: context.rSpacing(16),
      itemCount: products.length,
      shrinkWrap: false,
      physics: null, // Default scrolling for mobile
      itemBuilder: (context, index) {
        final product = products[index];
        final isSelected = selectedProducts.contains(product);
        return _buildMemoryEfficientProductCard(product, isSelected, index);
      },
    );
  }

  /// Builds continuous grid for larger screens
  Widget _buildContinuousGrid(List<ProductEntity> products) {
    return MasonryGridView.count(
      crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(context),
      mainAxisSpacing: context.rSpacing(16),
      crossAxisSpacing: context.rSpacing(16),
      itemCount: products.length,
      shrinkWrap: true, // Allow parent to control scrolling
      physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
      itemBuilder: (context, index) {
        final product = products[index];
        final isSelected = selectedProducts.contains(product);
        return _buildMemoryEfficientProductCard(product, isSelected, index);
      },
    );
  }

  /// Builds mobile page navigation controls
  Widget _buildMobilePageNavigation(int totalPages) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.rSpacing(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: Icon(
              Icons.chevron_left,
              size: context.rIconSize(32),
              color: _currentPage > 0 ? Colors.amber.shade700 : Colors.grey.shade400,
            ),
          ),

          Gap(context.rSpacing(16)),

          // Page indicators (limit to 5 for mobile)
          Row(
            children: _buildMobilePageIndicators(totalPages),
          ),

          Gap(context.rSpacing(16)),

          // Next button
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () => _nextPage(totalPages) : null,
            icon: Icon(
              Icons.chevron_right,
              size: context.rIconSize(32),
              color: _currentPage < totalPages - 1 ? Colors.amber.shade700 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds mobile page indicators with smart pagination
  List<Widget> _buildMobilePageIndicators(int totalPages) {
    const maxIndicators = 5;
    List<Widget> indicators = [];

    if (totalPages <= maxIndicators) {
      // Show all pages if total is small
      for (int i = 0; i < totalPages; i++) {
        indicators.add(_buildPageIndicator(i, i == _currentPage));
      }
    } else {
      // Smart pagination for many pages
      int start = (_currentPage - 2).clamp(0, totalPages - maxIndicators);
      int end = (start + maxIndicators).clamp(maxIndicators, totalPages);

      for (int i = start; i < end; i++) {
        indicators.add(_buildPageIndicator(i, i == _currentPage));
      }
    }

    return indicators;
  }

  /// Builds a single page indicator
  Widget _buildPageIndicator(int index, bool isCurrentPage) {
    return GestureDetector(
      onTap: () => _goToPage(index),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: context.rSpacing(4)),
        width: isCurrentPage ? context.rSpacing(32) : context.rSpacing(24),
        height: isCurrentPage ? context.rSpacing(32) : context.rSpacing(24),
        decoration: BoxDecoration(
          color: isCurrentPage ? Colors.amber.shade700 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(context.rBorderRadius(16)),
          border: isCurrentPage
              ? Border.all(color: Colors.amber.shade900, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: isCurrentPage ? context.rFontSize(14) : context.rFontSize(12),
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              color: isCurrentPage ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }







  /// Builds a memory-efficient product card with optimized image loading
  Widget _buildMemoryEfficientProductCard(ProductEntity product, bool isSelected, int index) {
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
              // Reset lazy loading to refresh the cache
              _resetLazyLoading();
            }
          },
              child: Container(
                padding: EdgeInsets.only(bottom: context.rSpacing(20)),
                decoration: BoxDecoration(
                  color: isSelected && send
                      ? Colors.yellow.shade100
                      : Colors.white,
                  borderRadius: BorderRadius.circular(context.rBorderRadius(15)),
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
                          top: Radius.circular(context.rBorderRadius(15))),
                      child: _buildOptimizedProductImage(product),
                    ),
                    Padding(
                      padding: EdgeInsets.all(context.rSpacing(10)),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: context.rFontSize(18)),
                          ),
                          Gap(context.rSpacing(6)),
                          Text(
                            "${product.price.toMoney()} so'm",
                            style: TextStyle(
                                fontSize: context.rFontSize(16),
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
                    size: context.rIconSize(28),
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
      }

  /// Builds optimized product image with memory management
  Widget _buildOptimizedProductImage(ProductEntity product) {
    return SizedBox(
      height: ResponsiveUtils.getCardHeight(context) * 0.6,
      width: double.infinity,
      child: _buildImageWidget(product),
    );
  }

  /// Builds the appropriate image widget based on product image type
  Widget _buildImageWidget(ProductEntity product) {
    // First, try to display local image if available
    if (product.hasActualLocalImage) {
      return Image.file(
        File(product.actualLocalImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder('Mahalliy rasm yuklanmadi');
        },
        // Memory optimization for local images
        cacheHeight: (ResponsiveUtils.getCardHeight(context) * 0.6 *
                     MediaQuery.of(context).devicePixelRatio).round(),
      );
    }

    // Then, try to display network image if it's a valid URL
    if (product.hasUploadedImage) {
      return Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: Colors.amber.shade700,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder('Rasm yuklanmadi');
        },
        // Memory optimization: cache images with appropriate size
        cacheHeight: (ResponsiveUtils.getCardHeight(context) * 0.6 *
                     MediaQuery.of(context).devicePixelRatio).round(),
      );
    }

    // If no valid image, show placeholder
    return _buildImagePlaceholder('Rasm yo\'q');
  }

  /// Builds a placeholder widget for missing or failed images
  Widget _buildImagePlaceholder(String message) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: context.rIconSize(40),
            color: Colors.grey.shade400,
          ),
          Gap(context.rSpacing(8)),
          Text(
            message,
            style: TextStyle(
              fontSize: context.rFontSize(12),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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
    final String prices = _priceController.text.trim();

    // Validation
    if (name.isEmpty) {
      ShowSnackBar.show(context, "Mahsulot nomini kiriting");
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

      // Check if uploadedImageUrl is a local path or URL
      String? imageUrl;
      String? localImagePath;

      if (uploadedImageUrl.startsWith('http')) {
        imageUrl = uploadedImageUrl;
        localImagePath = null;
      } else {
        localImagePath = uploadedImageUrl;
        imageUrl = null;
      }
    final cleanedPrice = prices.replaceAll(RegExp(r'[^0-9]'), '');
    final int? price = int.tryParse(cleanedPrice);

    if (price == null) {
      ShowSnackBar.show(context, "Iltimos, narxni to‘g‘ri kiriting");
      return;
    }

      ProductEntity product = ProductEntity(
        name: name,
        date: DateTime.now(),
        localImagePath: localImagePath,
        imageUrl: imageUrl,
        price: price.toDouble(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.rBorderRadius(20))),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: context.rSpacing(8)),
            width: context.rSpacing(40),
            height: context.rSpacing(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(context.rBorderRadius(2)),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(context.rSpacing(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yangi mahsulot qo\'shish',
                  style: TextStyle(
                    fontSize: context.rFontSize(20),
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
              padding: EdgeInsets.symmetric(horizontal: context.rSpacing(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    'Mahsulot nomi',
                    style: TextStyle(
                      fontSize: context.rFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Gap(context.rSpacing(8)),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Mahsulot nomini kiriting',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                        borderSide: BorderSide(color: Colors.amber, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  Gap(context.rSpacing(20)),

                  // Product Price
                  Text(
                    'Mahsulot narxi',
                    style: TextStyle(
                      fontSize: context.rFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Gap(context.rSpacing(8)),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [InputFormatters.moneyFormatter],
                    decoration: InputDecoration(
                      hintText: 'Narxni kiriting',
                      suffixText: 'so\'m',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                        borderSide: BorderSide(color: Colors.amber, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  Gap(context.rSpacing(20)),

                  // Product Image
                  Text(
                    'Mahsulot rasmi',
                    style: TextStyle(
                      fontSize: context.rFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Gap(context.rSpacing(8)),

                  Container(
                    width: double.infinity,
                    height: context.rHeight(25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: _selectedImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                                child: Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: context.rSpacing(8),
                                right: context.rSpacing(8),
                                child: GestureDetector(
                                  onTap: _removeSelectedImage,
                                  child: Container(
                                    padding: EdgeInsets.all(context.rSpacing(4)),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: context.rIconSize(16),
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
                                  size: context.rIconSize(48),
                                  color: Colors.grey.shade400,
                                ),
                                Gap(context.rSpacing(8)),
                                Text(
                                  'Rasm tanlash uchun bosing',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: context.rFontSize(14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  Gap(context.rSpacing(30)),
                ],
              ),
            ),
          ),

          // Add Button
          Container(
            padding: EdgeInsets.all(context.rSpacing(20)),
            child: SizedBox(
              width: double.infinity,
              height: context.rSpacing(50),
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.rBorderRadius(12)),
                  ),
                  elevation: 2,
                ),
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: context.rSpacing(20),
                            height: context.rSpacing(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Gap(context.rSpacing(12)),
                          Text(
                            'Yuklanmoqda...',
                            style: TextStyle(
                              fontSize: context.rFontSize(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Mahsulot qo\'shish',
                        style: TextStyle(
                          fontSize: context.rFontSize(16),
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

