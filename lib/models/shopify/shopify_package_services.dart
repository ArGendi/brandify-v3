import 'package:flutter/material.dart';
import 'package:shopify_flutter/shopify_flutter.dart';
import 'package:shopify_flutter/shopify_config.dart';
import 'package:shopify_flutter/shopify/src/shopify_store.dart';
import 'package:brandify/models/local/cache.dart';

class ShopifyPackageServices {
  static ShopifyStore? _shopifyStore;
  static bool _isInitialized = false;

  /// Initialize Shopify configuration
  static Future<bool> initializeShopify({
    required String storeUrl,
    required String storefrontAccessToken,
    String? adminAccessToken,
    String? apiKey,
    String? apiSecretKey,
  }) async {
    try {
      debugPrint('Initializing Shopify with domain: $storeUrl');
      // Configure Shopify
      ShopifyConfig.setConfig(
        storeUrl: storeUrl,
        storefrontAccessToken: storefrontAccessToken,
      );

      // Initialize the store
      _shopifyStore = ShopifyStore.instance;
      _isInitialized = true;
      
      debugPrint('Shopify initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing Shopify: $e');
      return false;
    }
  }

  /// Check if Shopify is initialized
  static bool get isInitialized => _isInitialized && _shopifyStore != null;

  /// Get Shopify store instance
  static ShopifyStore? get store => _isInitialized ? _shopifyStore : null;


  /// Get all products using shopify_flutter package
  static Future<List<Product>> getAllProducts({
    int? limit,
    String? after,
    String? before,
    String? query,
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching all products from Shopify...');
      
      final products = await _shopifyStore!.getAllProducts();

      debugPrint('Successfully fetched ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  /// Get product by ID
  static Future<Product?> getProductById(String productId) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching product by ID: $productId');
      
      final product = await _shopifyStore!.getProductsByIds([productId]);
      return product?.first;
    } catch (e) {
      debugPrint('Error fetching product by ID: $e');
      return null;
    }
  }

  /// Get product by handle
  static Future<Product?> getProductByHandle(String handle) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching product by handle: $handle');
      
      final product = await _shopifyStore!.getProductByHandle(handle);
      return product;
    } catch (e) {
      debugPrint('Error fetching product by handle: $e');
      return null;
    }
  }

  /// Get all collections
  static Future<List<Collection>> getAllCollections({
    int? limit,
    String? after,
    String? before,
    String? query,
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching all collections from Shopify...');
      
      final collections = await _shopifyStore!.getAllCollections();

      debugPrint('Successfully fetched ${collections.length} collections');
      return collections;
    } catch (e) {
      debugPrint('Error fetching collections: $e');
      return [];
    }
  }

  /// Get collection by ID
  static Future<Collection?> getCollectionById(String collectionId) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching collection by ID: $collectionId');
      
      final collection = await _shopifyStore!.getCollectionById(collectionId);
      return collection;
    } catch (e) {
      debugPrint('Error fetching collection by ID: $e');
      return null;
    }
  }

  /// Get collection by handle
  static Future<Collection?> getCollectionByHandle(String handle) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching collection by handle: $handle');
      
      final collection = await _shopifyStore!.getCollectionByHandle(handle);
      return collection;
    } catch (e) {
      debugPrint('Error fetching collection by handle: $e');
      return null;
    }
  }

  /// Get all store orders using shopify_flutter package
  static Future<List<Order>> getAllStoreOrders({
    int? limit,
    String? after,
    String? before,
    String? sortKey,
    bool reverse = false,
    String? query,
    String? status,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching all store orders from Shopify...');
      
      // Note: The shopify_flutter package might not have getAllOrders method
      // This is a placeholder implementation - you may need to use the Admin API directly
      // or check the package documentation for the correct method name
      
      debugPrint('Warning: getAllOrders method may not be available in shopify_flutter package');
      debugPrint('Consider using the Admin API directly for order management');
      
      return [];
    } catch (e) {
      debugPrint('Error fetching store orders: $e');
      return [];
    }
  }

  /// Get orders by status
  static Future<List<Order>> getOrdersByStatus({
    required String status,
    int? limit,
    String? after,
    String? before,
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching orders with status: $status');
      debugPrint('Warning: getAllOrders method may not be available in shopify_flutter package');
      
      return [];
    } catch (e) {
      debugPrint('Error fetching orders by status: $e');
      return [];
    }
  }

  /// Get orders by date range
  static Future<List<Order>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    String? after,
    String? before,
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching orders from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      debugPrint('Warning: getAllOrders method may not be available in shopify_flutter package');
      
      return [];
    } catch (e) {
      debugPrint('Error fetching orders by date range: $e');
      return [];
    }
  }

  /// Get order by ID
  static Future<Order?> getOrderById(String orderId) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching order by ID: $orderId');
      debugPrint('Warning: getAllOrders method may not be available in shopify_flutter package');
      
      return null;
    } catch (e) {
      debugPrint('Error fetching order by ID: $e');
      return null;
    }
  }

  /// Get orders by customer ID
  static Future<List<Order>> getOrdersByCustomerId({
    required String customerId,
    int? limit,
    String? after,
    String? before,
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching orders for customer: $customerId');
      debugPrint('Warning: getAllOrders method may not be available in shopify_flutter package');
      
      return [];
    } catch (e) {
      debugPrint('Error fetching orders by customer ID: $e');
      return [];
    }
  }

  /// Get paid orders
  static Future<List<Order>> getPaidOrders({
    int? limit,
    String? after,
    String? before,
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching paid orders...');
      debugPrint('Warning: getAllOrders method may not be available in shopify_flutter package');
      
      return [];
    } catch (e) {
      debugPrint('Error fetching paid orders: $e');
      return [];
    }
  }

  /// Get fulfilled orders
  static Future<List<Order>> getFulfilledOrders({
    int? limit,
    String? after,
    String? before,
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching fulfilled orders...');
      debugPrint('Warning: getAllOrders method may not be available in shopify_flutter package');
      
      return [];
    } catch (e) {
      debugPrint('Error fetching fulfilled orders: $e');
      return [];
    }
  }

  /// Get cancelled orders
  static Future<List<Order>> getCancelledOrders({
    int? limit,
    String? after,
    String? before,
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching cancelled orders...');
      debugPrint('Warning: getAllOrders method may not be available in shopify_flutter package');
      
      return [];
    } catch (e) {
      debugPrint('Error fetching cancelled orders: $e');
      return [];
    }
  }

  /// Get orders summary statistics
  static Future<Map<String, dynamic>> getOrdersSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Shopify not initialized');
      }

      debugPrint('Fetching orders summary...');
      debugPrint('Warning: Order management methods may not be available in shopify_flutter package');
      
      // Placeholder implementation since order methods are not available
      return {
        'total_orders': 0,
        'total_revenue': 0.0,
        'paid_orders': 0,
        'fulfilled_orders': 0,
        'cancelled_orders': 0,
        'pending_orders': 0,
        'average_order_value': 0.0,
        'top_products': [],
        'note': 'Order management requires Admin API access. Use ShopifyServices class for order operations.',
        'date_range': startDate != null && endDate != null ? {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        } : null,
      };
    } catch (e) {
      debugPrint('Error getting orders summary: $e');
      return {
        'error': 'Failed to get summary: $e',
        'total_orders': 0,
        'total_revenue': 0.0,
        'paid_orders': 0,
        'fulfilled_orders': 0,
        'cancelled_orders': 0,
        'pending_orders': 0,
        'average_order_value': 0.0,
        'top_products': [],
      };
    }
  }
}