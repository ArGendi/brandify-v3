import 'package:flutter/material.dart';
import 'package:shopify_flutter/shopify/src/shopify_store.dart';
import 'package:shopify_flutter/shopify_config.dart';
import 'package:shopify_flutter/shopify_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:brandify/models/local/cache.dart';
import 'dart:convert';
import 'dart:async';
import 'package:brandify/models/product.dart' as p;

class ShopifyServices {
  static String? adminAPIAcessToken;
  //static String? storeFrontAPIAcessToken;
  static String? locationId;
  static String? storeId;
  // static String? apiKey;
  // static String? apiSecretKey;
  //static late ShopifyStore shopifyStore;

  static void setParamters(
    {
      String? newAdminAcessToken,
      String? newStoreId,
      String? newLocationId
    }
  ){
    adminAPIAcessToken = newAdminAcessToken;
    storeId = newStoreId;
    locationId = newLocationId;
  }

  static void clearValues(){
    adminAPIAcessToken = null;
    locationId = null;
    storeId = null;
  }

  // Future<List<Product>> getProducts() async {
  //   try {
  //     final products = await shopifyStore.getAllProducts();
  //     return products;
  //   } catch (e) {
  //     print('Error fetching Shopify products: $e');
  //     return [];
  //   }
  // }

  Future<List<dynamic>> getProductsFromAdmin() async {
    try {
      final response = await http.get( 
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/products.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['products'];
      } else {
        print('Error fetching products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching Shopify products from admin: $e');
      return [];
    }
  }

 Future<List<dynamic>> getAllProducts() async {
  final List<dynamic> allProducts = [];
  String? nextPageToken;
  int attemptCount = 0;
  const int maxAttempts = 100; // Increased safety net for large product catalogs
  bool hasMorePages = true;

  debugPrint('Starting to fetch all products from Shopify...');

  while (hasMorePages && attemptCount < maxAttempts) {
    attemptCount++;
    debugPrint('Fetching products page $attemptCount');

    try {
      final Map<String, String> params = {
        'limit': '250',
      };

      // Add pagination token if available
      if (nextPageToken != null && nextPageToken.isNotEmpty) {
        params['page_info'] = nextPageToken;
      }

      final url = Uri.https(
        '$storeId.myshopify.com',
        '/admin/api/2024-07/products.json',
        params,
      );

      debugPrint('Request URL: $url');

      final response = await http.get(
        url,
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 45));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List? ?? [];
        allProducts.addAll(products);

        debugPrint('Fetched ${products.length} products on page $attemptCount');
        debugPrint('Total products so far: ${allProducts.length}');

        // Check if there are more pages using Link header
        final linkHeader = response.headers['link'] ?? '';
        debugPrint('Link header: $linkHeader');
        
        hasMorePages = linkHeader.contains('rel="next"');
        
        if (hasMorePages) {
          nextPageToken = _extractNextPageToken(linkHeader);
          debugPrint('Next page token: $nextPageToken');
          
          if (nextPageToken == null || nextPageToken.isEmpty) {
            debugPrint('Warning: Found next page marker but no valid token');
            hasMorePages = false;
          } else {
            // Rate limiting - wait between requests
            await Future.delayed(const Duration(milliseconds: 800));
          }
        } else {
          debugPrint('No more pages detected');
          nextPageToken = null;
        }
      } else if (response.statusCode == 429) {
        // Rate limit hit, wait longer
        debugPrint('Rate limit hit, waiting 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
        continue; // Retry the same page
      } else {
        debugPrint('Error fetching products: ${response.statusCode} - ${response.body}');
        // Don't break on error, try to continue with next page
        hasMorePages = false;
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      // Don't break on error, try to continue
      hasMorePages = false;
    }
  }

  if (attemptCount >= maxAttempts) {
    debugPrint('Warning: Reached maximum attempts ($maxAttempts) but may have more data');
  }

  debugPrint('Total products fetched: ${allProducts.length}');
  debugPrint('Total pages processed: $attemptCount');
  
  return allProducts;
}

String? _extractNextPageToken(String linkHeader) {
  try {
    debugPrint('Extracting next page token from: $linkHeader');
    
    // Handle both comma-separated links and single links
    final links = linkHeader.split(',');
    for (final link in links) {
      debugPrint('Processing link: $link');
      if (link.contains('rel="next"')) {
        // Try multiple regex patterns to extract the page_info parameter
        final patterns = [
          RegExp(r'page_info=([^&>]+)'),
          RegExp(r'page_info=([^&>\s]+)'),
          RegExp(r'[?&]page_info=([^&>]+)'),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(link);
          if (match != null) {
            final token = match.group(1);
            debugPrint('Found next page token: $token');
            return token;
          }
        }
      }
    }
    
    debugPrint('No next page token found in link header');
    return null;
  } catch (e) {
    debugPrint('Error parsing link header: $e');
    return null;
  }
}

  Future<List<dynamic>> getOrders() async {
    try {
      final response = await http.get( 
        Uri.parse('https://$storeId.myshopify.com/admin/api/2024-07/orders.json?limit=250'), // ?status=completed
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("++++++++++++++++++++++++++++++++++++++++++");
        print("ordeeeeeeeeeeeeeeeeeeeeeeeeeers: ${data['orders'].length}");
        print("++++++++++++++++++++++++++++++++++++++++++");
        return data['orders'];
      } else {
        print('Error fetching orders: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching Shopify orders: $e');
      return [];
    }
  }

  Future<bool> updateInventory(p.Product product) async {
      try {
        // First update the product details
        final productResponse = await http.put(
          Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/products/${product.shopifyId}.json'),
          headers: {
            'X-Shopify-Access-Token': adminAPIAcessToken!,
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'product': {
              'id': product.shopifyId,
              'title': product.name,
              'status': 'active',
              'variants': product.sizes.map((size) => {
                'id': size.id,
                'price': product.shopifyPrice,
                'inventory_management': 'shopify'
              }).toList(),
            }
          }),
        );

        if (productResponse.statusCode != 200) {
          debugPrint('Failed to update product: ${productResponse.statusCode} ${productResponse.body}');
          return false;
        }

        // Update inventory for each size
        for (var size in product.sizes) {
          // Get variant details to get inventory_item_id
          final variantResponse = await http.get(
            Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/variants/${size.id}.json'),
            headers: {
              'X-Shopify-Access-Token': adminAPIAcessToken!,
              'Content-Type': 'application/json',
            },
          );

          if (variantResponse.statusCode != 200) {
            debugPrint('Failed to get variant details: ${variantResponse.statusCode}');
            continue;
          }

          final variantData = json.decode(variantResponse.body)['variant'];
          final inventoryItemId = variantData['inventory_item_id'];

          // Update inventory level for this variant
          final inventoryResponse = await http.post(
            Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/inventory_levels/set.json'),
            headers: {
              'X-Shopify-Access-Token': adminAPIAcessToken!,
              'Content-Type': 'application/json',
            },
            body: json.encode({ 
              'location_id': locationId!,
              'inventory_item_id': inventoryItemId,
              'available': size.quantity
            }),
          );

          if (inventoryResponse.statusCode != 200) {
            debugPrint('Failed to update inventory for size ${size.name}: ${inventoryResponse.statusCode} ${inventoryResponse.body}');
          }
        }

        debugPrint('Product, prices and inventory updated successfully');
        return true;
      } catch (e) {
        debugPrint('Error updating product and inventory: $e');
        return false;
      }
    }  

    Future<bool> deleteProduct(String shopifyId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/products/$shopifyId.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Product deleted successfully from Shopify');
        return true;
      } else {
        debugPrint('Failed to delete product: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting product from Shopify: $e');
      return false;
    }
  }
   
  Future<int?> createProduct(p.Product product) async {
    try {
      final response = await http.post(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/products.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'product': {
            'title': product.name,
            'status': 'active',
            'vendor': Cache.getName() ?? 'Default Vendor',
            'product_type': product.category ?? 'Default Category',
            'body_html': product.description ?? '',
            'images': product.image != null ? [
              {
                'src': product.image,
                'position': 1
              }
            ] : [],
            'variants': product.sizes.map((size) => {
              'option1': size.name,
              'price': product.shopifyPrice.toString(),
              'inventory_management': 'shopify',
              'inventory_quantity': size.quantity,
              'sku': '${product.name}-${size.name}'.replaceAll(' ', '-').toLowerCase(),
            }).toList(),
            'options': [{
              'name': 'Size',
              'values': product.sizes.map((size) => size.name).toList(),
            }],
          }
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        int shopifyId = data['product']['id'];
        debugPrint('Product created successfully in Shopify with ID: $shopifyId');
        return shopifyId;
      } else {
        debugPrint('Failed to create product: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating product in Shopify: $e');
      return null;
    }
  }

  Future<bool> updateProductQuantity(int variantId, int quantityChange) async {
      try {
        // First get the variant details to get inventory_item_id
        final variantResponse = await http.get(
          Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/variants/$variantId.json'),
          headers: {
            'X-Shopify-Access-Token': adminAPIAcessToken!,
            'Content-Type': 'application/json',
          },
        );
  
        if (variantResponse.statusCode != 200) {
          debugPrint('Failed to get variant details: ${variantResponse.statusCode}');
          return false;
        }
  
        final variantData = json.decode(variantResponse.body)['variant'];
        final inventoryItemId = variantData['inventory_item_id'];
        final currentQuantity = variantData['inventory_quantity'] ?? 0;
        final newQuantity = currentQuantity + quantityChange;
  
        // Update inventory level
        final inventoryResponse = await http.post(
          Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/inventory_levels/set.json'),
          headers: {
            'X-Shopify-Access-Token': adminAPIAcessToken!,
            'Content-Type': 'application/json',
          },
          body: json.encode({ 
            'location_id': locationId!,
            'inventory_item_id': inventoryItemId,
            'available': newQuantity
          }),
        );
  
        if (inventoryResponse.statusCode == 200) {
          debugPrint('Inventory updated successfully. New quantity: $newQuantity');
          return true;
        } else {
          debugPrint('Failed to update inventory: ${inventoryResponse.statusCode} ${inventoryResponse.body}');
          return false;
        }
      } catch (e) {
        debugPrint('Error updating product quantity: $e');
        return false;
      }
    }

  /// Refund a Shopify order using their API
  Future<bool> refundOrder(int orderId, {double? refundAmount, String? reason}) async {
    try {
      debugPrint('Processing refund for Shopify order: $orderId');
      
      // Get order details first
      final orderResponse = await http.get(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (orderResponse.statusCode != 200) {
        debugPrint('Failed to get order details: ${orderResponse.statusCode} - ${orderResponse.body}');
        return false;
      }

      final orderData = json.decode(orderResponse.body)['order'];
      debugPrint('Order financial status: ${orderData['financial_status']}');
      
      // Check if order is already refunded
      if (orderData['financial_status'] == 'refunded' || 
          orderData['financial_status'] == 'partially_refunded') {
        debugPrint('Order is already refunded or partially refunded');
        return false;
      }
      
      // Check if order is paid
      if (orderData['financial_status'] != 'paid') {
        debugPrint('Order is not paid, cannot refund. Status: ${orderData['financial_status']}');
        return false;
      }

      final lineItems = orderData['line_items'] as List? ?? [];
      if (lineItems.isEmpty) {
        debugPrint('No line items found in order');
        return false;
      }

      final totalAmount = double.parse(orderData['total_price'] ?? '0');
      final refundAmountToUse = refundAmount ?? totalAmount;

      debugPrint('Creating refund for order $orderId, amount: $refundAmountToUse');

      // Create a simple refund without complex transaction handling
      final refundPayload = {
        'refund': {
          'shipping': {
            'full_refund': true
          },
          'refund_line_items': lineItems.map<Map<String, dynamic>>((item) => {
            'id': item['id'],
            'quantity': item['quantity'],
            'restock_type': 'return'
          }).toList(),
          'note': reason ?? 'Refund processed via API'
        }
      };

      debugPrint('Refund payload: ${json.encode(refundPayload)}');

      // Create the refund
      final refundResponse = await http.post(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId/refunds.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
        body: json.encode(refundPayload),
      ).timeout(const Duration(seconds: 60));

      debugPrint('Refund response status: ${refundResponse.statusCode}');
      debugPrint('Refund response body: ${refundResponse.body}');

      if (refundResponse.statusCode == 201) {
        final refundData = json.decode(refundResponse.body);
        debugPrint('Refund created successfully: ${refundData['refund']['id']}');
        
        // Verify the refund was processed by checking order status again
        await Future.delayed(const Duration(seconds: 2));
        final verifyResponse = await http.get(
          Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId.json'),
          headers: {
            'X-Shopify-Access-Token': adminAPIAcessToken!,
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));
        
        if (verifyResponse.statusCode == 200) {
          final updatedOrderData = json.decode(verifyResponse.body)['order'];
          debugPrint('Order status after refund: ${updatedOrderData['financial_status']}');
          
          if (updatedOrderData['financial_status'] == 'refunded' || 
              updatedOrderData['financial_status'] == 'partially_refunded') {
            debugPrint('Refund verification successful');
            return true;
          } else {
            debugPrint('Refund verification failed - order still shows as paid');
            return false;
          }
        }
        
        return true;
      } else {
        debugPrint('Failed to create refund: ${refundResponse.statusCode} - ${refundResponse.body}');
        return false;
      }
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('Timeout error processing Shopify refund: $e');
      } else {
        debugPrint('Error processing Shopify refund: $e');
      }
      return false;
    }
  }

  /// Get refunds for a specific order
  Future<List<Map<String, dynamic>>> getOrderRefunds(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId/refunds.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['refunds'] ?? []);
      } else {
        debugPrint('Failed to get refunds: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('Timeout error getting order refunds: $e');
      } else {
        debugPrint('Error getting order refunds: $e');
      }
      return [];
    }
  }

  /// Check if an order can be refunded
  Future<bool> canRefundOrder(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final orderData = json.decode(response.body)['order'];
        final financialStatus = orderData['financial_status'];
        final fulfillmentStatus = orderData['fulfillment_status'];
        
        debugPrint('Order $orderId - Financial status: $financialStatus, Fulfillment status: $fulfillmentStatus');
        
        // Order can be refunded if it's paid and not already refunded
        return financialStatus == 'paid' && 
               financialStatus != 'refunded' && 
               financialStatus != 'partially_refunded';
      } else {
        debugPrint('Failed to check refund status: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('Timeout error checking if order can be refunded: $e');
      } else {
        debugPrint('Error checking if order can be refunded: $e');
      }
      return false;
    }
  }

  /// Get order details including financial status
  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body)['order'];
      } else {
        debugPrint('Failed to get order details: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('Timeout error getting order details: $e');
      } else {
        debugPrint('Error getting order details: $e');
      }
      return null;
    }
  }
   
  /// Test function to debug order refund process
  Future<Map<String, dynamic>> debugOrderRefund(int orderId) async {
    try {
      debugPrint('Debugging order $orderId for refund...');
      
      final orderDetails = await getOrderDetails(orderId);
      if (orderDetails == null) {
        return {'error': 'Could not fetch order details'};
      }
      
      final canRefund = await canRefundOrder(orderId);
      final existingRefunds = await getOrderRefunds(orderId);
      
      return {
        'order_id': orderId,
        'financial_status': orderDetails['financial_status'],
        'fulfillment_status': orderDetails['fulfillment_status'],
        'total_price': orderDetails['total_price'],
        'can_refund': canRefund,
        'existing_refunds_count': existingRefunds.length,
        'transactions_count': (orderDetails['transactions'] as List?)?.length ?? 0,
        'line_items_count': (orderDetails['line_items'] as List?)?.length ?? 0,
      };
    } catch (e) {
      return {'error': 'Debug failed: $e'};
    }
  }

  /// Test function to check if we can fetch orders and compare methods
  Future<Map<String, dynamic>> testOrderFetching(DateTime startDate, DateTime endDate) async {
    try {
      debugPrint('=== TESTING ORDER FETCHING ===');
      debugPrint('Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      
      // Test the main method
      debugPrint('Testing main method...');
      final mainStart = DateTime.now();
      final mainOrders = await _getPaidOrdersInDateRange(startDate, endDate);
      final mainDuration = DateTime.now().difference(mainStart);
      
      // Test alternative method
      debugPrint('Testing alternative method...');
      final altStart = DateTime.now();
      final altOrders = await getAllPaidOrdersAlternative(startDate, endDate);
      final altDuration = DateTime.now().difference(altStart);
      
      // Test simple method without pagination
      debugPrint('Testing simple method...');
      final simpleStart = DateTime.now();
      final simpleOrders = await _getSimpleOrders(startDate, endDate);
      final simpleDuration = DateTime.now().difference(simpleStart);
      
      return {
        'main_method': {
          'orders_count': mainOrders.length,
          'duration_ms': mainDuration.inMilliseconds,
          'success': true,
        },
        'alternative_method': {
          'orders_count': altOrders.length,
          'duration_ms': altDuration.inMilliseconds,
          'success': true,
        },
        'simple_method': {
          'orders_count': simpleOrders.length,
          'duration_ms': simpleDuration.inMilliseconds,
          'success': true,
        },
        'comparison': {
          'main_vs_alt': mainOrders.length == altOrders.length ? 'Match' : 'Different',
          'main_vs_simple': mainOrders.length == simpleOrders.length ? 'Match' : 'Different',
          'alt_vs_simple': altOrders.length == simpleOrders.length ? 'Match' : 'Different',
        }
      };
    } catch (e) {
      return {
        'error': 'Test failed: $e',
        'main_method': {'success': false, 'error': '$e'},
        'alternative_method': {'success': false, 'error': '$e'},
        'simple_method': {'success': false, 'error': '$e'},
      };
    }
  }

  /// Simple method to get products without complex pagination
  Future<List<dynamic>> _getSimpleProducts() async {
    try {
      final url = Uri.https(
        '$storeId.myshopify.com',
        '/admin/api/2023-10/products.json',
        {
          'limit': '250',
        },
      );
      
      final response = await http.get(
        url,
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List? ?? [];
        debugPrint('Simple method: Fetched ${products.length} products');
        return products;
      } else {
        debugPrint('Simple method: Error ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Simple method: Error $e');
      return [];
    }
  }

  /// Test function to check if we can fetch products and compare methods
  Future<Map<String, dynamic>> testProductFetching() async {
    try {
      debugPrint('=== TESTING PRODUCT FETCHING ===');
      
      // Test the main method
      debugPrint('Testing main method...');
      final mainStart = DateTime.now();
      final mainProducts = await getAllProducts();
      final mainDuration = DateTime.now().difference(mainStart);
      
      // Test alternative method
      debugPrint('Testing alternative method...');
      final altStart = DateTime.now();
      final altProducts = await getAllProductsAlternative();
      final altDuration = DateTime.now().difference(altStart);
      
      // Test simple method without pagination
      debugPrint('Testing simple method...');
      final simpleStart = DateTime.now();
      final simpleProducts = await _getSimpleProducts();
      final simpleDuration = DateTime.now().difference(simpleStart);
      
      // Test new comprehensive method
      debugPrint('Testing comprehensive method...');
      final compStart = DateTime.now();
      final compProducts = await getAllProductsComprehensive();
      final compDuration = DateTime.now().difference(compStart);
      
      return {
        'main_method': {
          'products_count': mainProducts.length,
          'duration_ms': mainDuration.inMilliseconds,
          'success': true,
        },
        'alternative_method': {
          'products_count': altProducts.length,
          'duration_ms': altDuration.inMilliseconds,
          'success': true,
        },
        'simple_method': {
          'products_count': simpleProducts.length,
          'duration_ms': simpleDuration.inMilliseconds,
          'success': true,
        },
        'comprehensive_method': {
          'products_count': compProducts.length,
          'duration_ms': compDuration.inMilliseconds,
          'success': true,
        },
        'comparison': {
          'main_vs_alt': mainProducts.length == altProducts.length ? 'Match' : 'Different',
          'main_vs_simple': mainProducts.length == simpleProducts.length ? 'Match' : 'Different',
          'alt_vs_simple': altProducts.length == simpleProducts.length ? 'Match' : 'Different',
          'comp_vs_main': compProducts.length == mainProducts.length ? 'Match' : 'Different',
          'comp_vs_alt': compProducts.length == altProducts.length ? 'Match' : 'Different',
        }
      };
    } catch (e) {
      return {
        'error': 'Test failed: $e',
        'main_method': {'success': false, 'error': '$e'},
        'alternative_method': {'success': false, 'error': '$e'},
        'simple_method': {'success': false, 'error': '$e'},
        'comprehensive_method': {'success': false, 'error': '$e'},
      };
    }
  }

  /// Comprehensive method to get all products using page-based pagination
  Future<List<dynamic>> getAllProductsComprehensive() async {
    final List<dynamic> allProducts = [];
    int page = 1;
    const int maxPages = 500; // Very high limit
    bool hasMoreData = true;

    debugPrint('Comprehensive method: Starting to fetch all products...');

    while (hasMoreData && page <= maxPages) {
      debugPrint('Comprehensive method: Fetching page $page');

      try {
        // Use page-based pagination instead of cursor-based
        final Map<String, String> params = {
          'limit': '250',
          'page': page.toString(),
        };

        final url = Uri.https(
          '$storeId.myshopify.com',
          '/admin/api/2023-10/products.json',
          params,
        );

        debugPrint('Comprehensive method: Request URL: $url');

        final response = await http.get(
          url,
          headers: {
            'X-Shopify-Access-Token': adminAPIAcessToken!,
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 60));

        debugPrint('Comprehensive method: Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final products = data['products'] as List? ?? [];
          
          if (products.isEmpty) {
            debugPrint('Comprehensive method: No more products found on page $page');
            hasMoreData = false;
            break;
          }
          
          allProducts.addAll(products);
          debugPrint('Comprehensive method: Fetched [32m${products.length}[0m products on page $page');
          debugPrint('Comprehensive method: Total products so far: ${allProducts.length}');

          // Check if we got less than the limit (indicates last page)
          if (products.length < 250) {
            debugPrint('Comprehensive method: Got less than 250 products, likely last page');
            hasMoreData = false;
          }

          page++;
          await Future.delayed(const Duration(milliseconds: 1000)); // Longer delay
        } else if (response.statusCode == 429) {
          debugPrint('Comprehensive method: Rate limit hit, waiting 3 seconds...');
          await Future.delayed(const Duration(seconds: 3));
          continue; // Retry the same page
        } else {
          debugPrint('Comprehensive method: Error ${response.statusCode} - ${response.body}');
          hasMoreData = false;
        }
      } catch (e) {
        debugPrint('Comprehensive method: Error on page $page: $e');
        hasMoreData = false;
      }
    }

    debugPrint('Comprehensive method: Total products fetched: ${allProducts.length}');
    debugPrint('Comprehensive method: Total pages processed: ${page - 1}');
    
    return allProducts;
  }

  /// Get products count to verify we're getting all products
  Future<int> getProductsCount() async {
    try {
      final url = Uri.https(
        '$storeId.myshopify.com',
        '/admin/api/2023-10/products/count.json',
      );

      final response = await http.get(
        url,
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] as int? ?? 0;
        debugPrint('Total products count from API: $count');
        return count;
      } else {
        debugPrint('Error getting products count: ${response.statusCode} - ${response.body}');
        return 0;
      }
    } catch (e) {
      debugPrint('Error getting products count: $e');
      return 0;
    }
  }

  /// Debug function to analyze pagination headers
  Future<Map<String, dynamic>> debugPagination() async {
    try {
      debugPrint('=== DEBUGGING PAGINATION ===');
      
      final url = Uri.https(
        '$storeId.myshopify.com',
        '/admin/api/2023-10/products.json',
        {'limit': '10'}, // Small limit to see pagination clearly
      );

      final response = await http.get(
        url,
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('All headers: ${response.headers}');
      
      final linkHeader = response.headers['link'] ?? '';
      debugPrint('Link header: $linkHeader');
      
      final data = json.decode(response.body);
      final products = data['products'] as List? ?? [];
      
      return {
        'status_code': response.statusCode,
        'products_count': products.length,
        'link_header': linkHeader,
        'has_next': linkHeader.contains('rel="next"'),
        'has_prev': linkHeader.contains('rel="prev"'),
        'all_headers': response.headers.toString(),
      };
    } catch (e) {
      return {
        'error': 'Debug failed: $e',
      };
    }
  }

  /// Simple method to get orders without complex pagination
  Future<List<dynamic>> _getSimpleOrders(DateTime startDate, DateTime endDate) async {
    try {
      final startDateStr = startDate.toUtc().toIso8601String();
      final endDateStr = endDate.toUtc().toIso8601String();
      
      final url = Uri.https(
        '$storeId.myshopify.com',
        '/admin/api/2023-10/orders.json',
        {
          'limit': '250',
          'financial_status': 'paid',
          'created_at_min': startDateStr,
          'created_at_max': endDateStr,
        },
      );
      
      final response = await http.get(
        url,
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = data['orders'] as List? ?? [];
        debugPrint('Simple method: Fetched ${orders.length} orders');
        return orders;
      } else {
        debugPrint('Simple method: Error ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Simple method: Error $e');
      return [];
    }
  }

  /// Test refund process without actually creating a refund
  Future<Map<String, dynamic>> testRefundProcess(int orderId) async {
    try {
      debugPrint('Testing refund process for order: $orderId');
      
      // Get order details
      final orderDetails = await getOrderDetails(orderId);
      if (orderDetails == null) {
        return {
          'success': false,
          'error': 'Could not fetch order details',
          'order_id': orderId
        };
      }
      
      final financialStatus = orderDetails['financial_status'];
      final fulfillmentStatus = orderDetails['fulfillment_status'];
      final totalPrice = orderDetails['total_price'];
      final lineItems = orderDetails['line_items'] as List? ?? [];
      final transactions = orderDetails['transactions'] as List? ?? [];
      
      debugPrint('Order analysis:');
      debugPrint('- Financial status: $financialStatus');
      debugPrint('- Fulfillment status: $fulfillmentStatus');
      debugPrint('- Total price: $totalPrice');
      debugPrint('- Line items count: ${lineItems.length}');
      debugPrint('- Transactions count: ${transactions.length}');
      
      // Check if order can be refunded
      bool canRefund = false;
      String refundReason = '';
      
      if (financialStatus == 'refunded' || financialStatus == 'partially_refunded') {
        refundReason = 'Order is already refunded';
      } else if (financialStatus != 'paid') {
        refundReason = 'Order is not paid (status: $financialStatus)';
      } else if (lineItems.isEmpty) {
        refundReason = 'No line items found in order';
      } else {
        canRefund = true;
        refundReason = 'Order can be refunded';
      }
      
      // Analyze transactions
      List<Map<String, dynamic>> successfulTransactions = [];
      for (final transaction in transactions) {
        if (transaction['status'] == 'success' && transaction['kind'] == 'sale') {
          successfulTransactions.add({
            'id': transaction['id'],
            'amount': transaction['amount'],
            'gateway': transaction['gateway'],
            'created_at': transaction['created_at'],
          });
        }
      }
      
      return {
        'success': canRefund,
        'order_id': orderId,
        'financial_status': financialStatus,
        'fulfillment_status': fulfillmentStatus,
        'total_price': totalPrice,
        'line_items_count': lineItems.length,
        'transactions_count': transactions.length,
        'successful_transactions': successfulTransactions,
        'can_refund': canRefund,
        'refund_reason': refundReason,
        'message': canRefund ? 'Order is ready for refund' : 'Order cannot be refunded: $refundReason'
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Test failed: $e',
        'order_id': orderId
      };
    }
  }

  /// Manual refund function with detailed logging for debugging
  Future<Map<String, dynamic>> manualRefundOrder(int orderId, {String? reason}) async {
    try {
      debugPrint('=== MANUAL REFUND PROCESS START ===');
      debugPrint('Order ID: $orderId');
      debugPrint('Reason: $reason');
      
      // Step 1: Get order details
      debugPrint('Step 1: Getting order details...');
      final orderResponse = await http.get(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (orderResponse.statusCode != 200) {
        return {
          'success': false,
          'error': 'Failed to get order details: ${orderResponse.statusCode}',
          'response_body': orderResponse.body
        };
      }

      final orderData = json.decode(orderResponse.body)['order'];
      debugPrint('Order financial status: ${orderData['financial_status']}');
      debugPrint('Order fulfillment status: ${orderData['fulfillment_status']}');
      debugPrint('Order total price: ${orderData['total_price']}');
      
      // Step 2: Validate order can be refunded
      debugPrint('Step 2: Validating order can be refunded...');
      if (orderData['financial_status'] != 'paid') {
        return {
          'success': false,
          'error': 'Order is not paid. Current status: ${orderData['financial_status']}'
        };
      }
      
      final lineItems = orderData['line_items'] as List? ?? [];
      debugPrint('Line items count: ${lineItems.length}');
      
      if (lineItems.isEmpty) {
        return {
          'success': false,
          'error': 'No line items found in order'
        };
      }
      
      // Step 3: Prepare refund payload
      debugPrint('Step 3: Preparing refund payload...');
      final refundPayload = {
        'refund': {
          'shipping': {
            'full_refund': true
          },
          'refund_line_items': lineItems.map<Map<String, dynamic>>((item) => {
            'id': item['id'],
            'quantity': item['quantity'],
            'restock_type': 'return'
          }).toList(),
          'note': reason ?? 'Manual refund via API'
        }
      };
      
      debugPrint('Refund payload: ${json.encode(refundPayload)}');
      
      // Step 4: Create refund
      debugPrint('Step 4: Creating refund...');
      final refundResponse = await http.post(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId/refunds.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
        body: json.encode(refundPayload),
      ).timeout(const Duration(seconds: 60));
      
      debugPrint('Refund response status: ${refundResponse.statusCode}');
      debugPrint('Refund response body: ${refundResponse.body}');
      
      if (refundResponse.statusCode != 201) {
        return {
          'success': false,
          'error': 'Failed to create refund: ${refundResponse.statusCode}',
          'response_body': refundResponse.body
        };
      }
      
      final refundData = json.decode(refundResponse.body);
      debugPrint('Refund created with ID: ${refundData['refund']['id']}');
      
      // Step 5: Verify refund
      debugPrint('Step 5: Verifying refund...');
      await Future.delayed(const Duration(seconds: 3));
      
      final verifyResponse = await http.get(
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders/$orderId.json'),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (verifyResponse.statusCode == 200) {
        final updatedOrderData = json.decode(verifyResponse.body)['order'];
        final newStatus = updatedOrderData['financial_status'];
        debugPrint('Order status after refund: $newStatus');
        
        return {
          'success': true,
          'refund_id': refundData['refund']['id'],
          'order_status_before': orderData['financial_status'],
          'order_status_after': newStatus,
          'message': 'Refund processed successfully'
        };
      } else {
        return {
          'success': true,
          'refund_id': refundData['refund']['id'],
          'warning': 'Refund created but could not verify order status',
          'verification_error': '${verifyResponse.statusCode}: ${verifyResponse.body}'
        };
      }
      
    } catch (e) {
      debugPrint('=== MANUAL REFUND PROCESS ERROR ===');
      debugPrint('Error: $e');
      return {
        'success': false,
        'error': 'Manual refund failed: $e'
      };
    }
  }

  /// Simple test function to debug refund on a specific order
  Future<Map<String, dynamic>> testRefundOnOrder(int orderId) async {
    try {
      debugPrint('=== TESTING REFUND ON ORDER $orderId ===');
      
      // Step 1: Test the order
      final testResult = await testRefundProcess(orderId);
      debugPrint('Test result: $testResult');
      
      if (testResult['success'] == false) {
        return {
          'success': false,
          'error': testResult['error'] ?? 'Test failed',
          'test_result': testResult
        };
      }
      
      // Step 2: Try manual refund
      debugPrint('Attempting manual refund...');
      final refundResult = await manualRefundOrder(orderId, reason: 'Test refund');
      debugPrint('Refund result: $refundResult');
      
      return {
        'success': refundResult['success'],
        'test_result': testResult,
        'refund_result': refundResult,
        'message': refundResult['success'] == true 
          ? 'Refund test successful' 
          : 'Refund test failed: ${refundResult['error']}'
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Test refund failed: $e'
      };
    }
  }

  /// Get all paid orders for today
  Future<List<dynamic>> getPaidOrdersToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      
      return await getPaidOrdersInDateRange(startOfDay, endOfDay);
    } catch (e) {
      debugPrint('Error fetching today\'s paid orders: $e');
      return [];
    }
  }

  /// Get all paid orders for this week (Monday to Sunday)
  Future<List<dynamic>> getPaidOrdersThisWeek() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfWeek = startOfWeekDay.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
      
      return await getPaidOrdersInDateRange(startOfWeekDay, endOfWeek);
    } catch (e) {
      debugPrint('Error fetching this week\'s paid orders: $e');
      return [];
    }
  }

  /// Get all paid orders for this month
  Future<List<dynamic>> getPaidOrdersThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
      

      return await getPaidOrdersInDateRange(startOfMonth, endOfMonth);
    } catch (e) {
      debugPrint('Error fetching this month\'s paid orders: $e');
      return [];
    }
  }

  /// Get all paid orders for the last 3 months
  Future<List<dynamic>> getPaidOrdersLastThreeMonths() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 3, 1);
      final endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
      
      return await getPaidOrdersInDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('Error fetching last 3 months\' paid orders: $e');
      return [];
    }
  }

  /// Get all paid orders within a custom date range
  Future<List<dynamic>> getPaidOrdersInCustomRange(DateTime startDate, DateTime endDate) async {
    try {
      // Normalize dates to start and end of day
      final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      
      return await getPaidOrdersInDateRange(normalizedStartDate, normalizedEndDate);
    } catch (e) {
      debugPrint('Error fetching paid orders in custom range: $e');
      return [];
    }
  }

  /// Alternative method to get all products using cursor-based pagination
  Future<List<dynamic>> getAllProductsAlternative() async {
    final List<dynamic> allProducts = [];
    String? cursor;
    int pageCount = 0;
    const int maxPages = 200; // Safety limit

    debugPrint('Alternative method: Starting to fetch all products from Shopify...');

    while (pageCount < maxPages) {
      pageCount++;
      debugPrint('Alternative method: Fetching products page $pageCount');

      try {
        final Map<String, String> params = {
          'limit': '250',
        };

        if (cursor != null && cursor.isNotEmpty) {
          params['cursor'] = cursor;
        }

        final url = Uri.https(
          '$storeId.myshopify.com',
          '/admin/api/2023-10/products.json',
          params,
        );

        final response = await http.get(
          url,
          headers: {
            'X-Shopify-Access-Token': adminAPIAcessToken!,
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final products = data['products'] as List? ?? [];
          
          if (products.isEmpty) {
            debugPrint('Alternative method: No more products found');
            break;
          }
          
          allProducts.addAll(products);
          debugPrint('Alternative method: Fetched ${products.length} products on page $pageCount');
          debugPrint('Alternative method: Total products so far: ${allProducts.length}');

          // Check for next page cursor
          final linkHeader = response.headers['link'] ?? '';
          if (linkHeader.contains('rel="next"')) {
            final nextMatch = RegExp(r'cursor=([^&>]+)').firstMatch(linkHeader);
            cursor = nextMatch?.group(1);
            debugPrint('Alternative method: Next cursor: $cursor');
            
            if (cursor == null || cursor.isEmpty) {
              debugPrint('Alternative method: No valid cursor found, stopping');
              break;
            }
            
            await Future.delayed(const Duration(milliseconds: 800));
          } else {
            debugPrint('Alternative method: No more pages detected');
            break;
          }
        } else if (response.statusCode == 429) {
          debugPrint('Alternative method: Rate limit hit, waiting...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          debugPrint('Alternative method: Error ${response.statusCode} - ${response.body}');
          break;
        }
      } catch (e) {
        debugPrint('Alternative method: Error $e');
        break;
      }
    }

    debugPrint('Alternative method: Total products fetched: ${allProducts.length}');
    return allProducts;
  }

  /// Alternative method to get all paid orders using cursor-based pagination
  Future<List<dynamic>> getAllPaidOrdersAlternative(DateTime startDate, DateTime endDate) async {
    final List<dynamic> allOrders = [];
    String? cursor;
    int pageCount = 0;
    const int maxPages = 200; // Safety limit

    // Format dates for Shopify API
    final startDateStr = startDate.toUtc().toIso8601String();
    final endDateStr = endDate.toUtc().toIso8601String();

    debugPrint('Alternative method: Fetching paid orders from $startDateStr to $endDateStr');

    while (pageCount < maxPages) {
      pageCount++;
      debugPrint('Alternative method: Fetching page $pageCount');

      try {
        final Map<String, String> params = {
          'limit': '250',
          'financial_status': 'paid',
          'created_at_min': startDateStr,
          'created_at_max': endDateStr,
        };

        if (cursor != null && cursor.isNotEmpty) {
          params['cursor'] = cursor;
        }

        final url = Uri.https(
          '$storeId.myshopify.com',
          '/admin/api/2023-10/orders.json',
          params,
        );

        final response = await http.get(
          url,
          headers: {
            'X-Shopify-Access-Token': adminAPIAcessToken!,
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final orders = data['orders'] as List? ?? [];
          
          if (orders.isEmpty) {
            debugPrint('Alternative method: No more orders found');
            break;
          }
          
          allOrders.addAll(orders);
          debugPrint('Alternative method: Fetched ${orders.length} orders on page $pageCount');
          debugPrint('Alternative method: Total orders so far: ${allOrders.length}');

          // Check for next page cursor
          final linkHeader = response.headers['link'] ?? '';
          if (linkHeader.contains('rel="next"')) {
            final nextMatch = RegExp(r'cursor=([^&>]+)').firstMatch(linkHeader);
            cursor = nextMatch?.group(1);
            debugPrint('Alternative method: Next cursor: $cursor');
            
            if (cursor == null || cursor.isEmpty) {
              debugPrint('Alternative method: No valid cursor found, stopping');
              break;
            }
            
            await Future.delayed(const Duration(milliseconds: 800));
          } else {
            debugPrint('Alternative method: No more pages detected');
            break;
          }
        } else if (response.statusCode == 429) {
          debugPrint('Alternative method: Rate limit hit, waiting...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          debugPrint('Alternative method: Error ${response.statusCode} - ${response.body}');
          break;
        }
      } catch (e) {
        debugPrint('Alternative method: Error $e');
        break;
      }
    }

    debugPrint('Alternative method: Total orders fetched: ${allOrders.length}');
    return allOrders;
  }

  /// Helper function to get paid orders within a date range with pagination
  Future<List<dynamic>> _getPaidOrdersInDateRange(DateTime startDate, DateTime endDate) async {
    final List<dynamic> allOrders = [];
    String? nextPageToken;
    int attemptCount = 0;
    const int maxAttempts = 100; // Increased safety net for large date ranges
    bool hasMorePages = true;

    // Format dates for Shopify API (ISO 8601 format with timezone)
    final startDateStr = startDate.toUtc().toIso8601String();
    final endDateStr = endDate.toUtc().toIso8601String();

    debugPrint('Fetching paid orders from $startDateStr to $endDateStr');

    while (hasMorePages && attemptCount < maxAttempts) {
      attemptCount++;
      debugPrint('Fetching page $attemptCount');

      try {
        final Map<String, String> params = {
          'limit': '250',
          //'financial_status': 'paid', // Only paid orders
          'created_at_min': startDateStr,
          'created_at_max': endDateStr,
        };

        // Add pagination token if available
        if (nextPageToken != null && nextPageToken.isNotEmpty) {
          params['page_info'] = nextPageToken;
        }

        final url = Uri.https(
          '$storeId.myshopify.com',
          '/admin/api/2023-10/orders.json',
          params,
        );

        debugPrint('Request URL: $url');

        final response = await http.get(
          url,
          headers: {
            'X-Shopify-Access-Token': adminAPIAcessToken!,
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 45));

        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response headers: ${response.headers}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final orders = data['orders'] as List? ?? [];
          allOrders.addAll(orders);

          debugPrint('Fetched ${orders.length} orders on page $attemptCount');
          debugPrint('Total orders so far: ${allOrders.length}');

          // Check if there are more pages using Link header
          final linkHeader = response.headers['link'] ?? '';
          debugPrint('Link header: $linkHeader');
          
          hasMorePages = linkHeader.contains('rel="next"');
          
          if (hasMorePages) {
            nextPageToken = _extractNextPageToken(linkHeader);
            debugPrint('Next page token: $nextPageToken');
            
            if (nextPageToken == null || nextPageToken.isEmpty) {
              debugPrint('Warning: Found next page marker but no valid token');
              hasMorePages = false;
            } else {
              // Rate limiting - wait between requests
              await Future.delayed(const Duration(milliseconds: 800));
            }
          } else {
            debugPrint('No more pages detected');
            nextPageToken = null;
          }
        } else if (response.statusCode == 429) {
          // Rate limit hit, wait longer
          debugPrint('Rate limit hit, waiting 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
          continue; // Retry the same page
        } else {
          debugPrint('Error fetching orders: ${response.statusCode} - ${response.body}');
          // Don't break on error, try to continue with next page
          hasMorePages = false;
        }
      } catch (e) {
        debugPrint('Error fetching orders in date range: $e');
        // Don't break on error, try to continue
        hasMorePages = false;
      }
    }

    if (attemptCount >= maxAttempts) {
      debugPrint('Warning: Reached maximum attempts ($maxAttempts) but may have more data');
    }

    debugPrint('Total orders fetched: ${allOrders.length}');
    debugPrint('Total pages processed: $attemptCount');

    print("++++++++++++++++++++++++++++++++++++++++++");
    print("all ordeeeeeeeeeeeeeeeeeeeeeeeeeers: ${allOrders.length}");
    print("++++++++++++++++++++++++++++++++++++++++++");
    
    return allOrders;
  }

  Future<List> getPaidOrdersInDateRange(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    print("startttttttttttttttttttttttttttOfMonth: $fromDate");
    print("enddddddddddddddddddddddddddddOfMonth: $toDate");
    String isoFrom = fromDate.toUtc().toIso8601String();
    String isoTo = toDate.toUtc().toIso8601String();

    String baseUrl =
        'https://$storeId.myshopify.com/admin/api/2024-07/orders.json'
        '?status=closed'
        '&created_at_min=$isoFrom'
        '&created_at_max=$isoTo'
        '&limit=250';

    List<Map<String, dynamic>> allOrders = [];
    String? nextPageUrl = baseUrl;

    while (nextPageUrl != null) {
      final response = await http.get(
        Uri.parse(nextPageUrl),
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = List<Map<String, dynamic>>.from(data['orders']);
        allOrders.addAll(orders);

        // Check for pagination
        String? linkHeader = response.headers['link'];
        if (linkHeader != null && linkHeader.contains('rel="next"')) {
          final match = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          nextPageUrl = match?.group(1);
        } else {
          nextPageUrl = null;
        }
      } else {
        print('Error fetching orders: ${response.statusCode} - ${response.body}');
        break;
      }
    }

    print('✅ Totaaaaaaaaaaal paid orders fetched: ${allOrders.length}');
    // You can process or return the `allOrders` list here
    return allOrders;
  }

  /// Get summary statistics for paid orders in a date range
  Future<Map<String, dynamic>> getPaidOrdersSummary(DateTime startDate, DateTime endDate) async {
    try {
      final orders = await getPaidOrdersInCustomRange(startDate, endDate);
      
      double totalRevenue = 0;
      int totalOrders = orders.length;
      int totalItems = 0;
      Map<String, int> productCounts = {};
      
      for (final order in orders) {
        final totalPrice = double.tryParse(order['total_price']?.toString() ?? '0') ?? 0;
        totalRevenue += totalPrice;
        
        final lineItems = order['line_items'] as List? ?? [];
        for (final item in lineItems) {
          final quantity = item['quantity'] as int? ?? 0;
          totalItems += quantity;
          
          final productTitle = item['title']?.toString() ?? 'Unknown Product';
          productCounts[productTitle] = (productCounts[productTitle] ?? 0) + quantity;
        }
      }
      
      // Sort products by quantity sold
      final sortedProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'total_items_sold': totalItems,
        'average_order_value': totalOrders > 0 ? totalRevenue / totalOrders : 0,
        'top_products': sortedProducts.take(10).map((e) => {
          'product': e.key,
          'quantity_sold': e.value,
        }).toList(),
        'date_range': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        }
      };
    } catch (e) {
      debugPrint('Error getting paid orders summary: $e');
      return {
        'error': 'Failed to get summary: $e',
        'total_orders': 0,
        'total_revenue': 0,
        'total_items_sold': 0,
        'average_order_value': 0,
        'top_products': [],
      };
    }
  }

  Future<List<Map<String, dynamic>>> getProductSellsInDateRange({
    required int productShopifyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    List<Map<String, dynamic>> allOrders = [];
    List<Map<String, dynamic>> productOrders = [];

    // Fetch all paid orders in the date range
    final orders = await getPaidOrdersInDateRange(fromDate, toDate);

    // Filter orders that contain the specific product
    for (final order in orders) {
      final lineItems = order['line_items'] as List? ?? [];
      for (final item in lineItems) {
        if (item['product_id'] == productShopifyId) {
          productOrders.add(order);
          break;
        }
      }
    }

    return productOrders;
  }
}

