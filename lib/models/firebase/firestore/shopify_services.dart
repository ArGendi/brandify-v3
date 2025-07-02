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
  const int maxAttempts = 20; // Safety net
  bool hasMorePages = true;

  while (hasMorePages && attemptCount < maxAttempts) {
    attemptCount++;
    debugPrint('Fetching page $attemptCount');

    try {
      final params = {
        'limit': '250',
        if (nextPageToken != null) 'page_info': nextPageToken,
      };

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
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List? ?? [];
        allProducts.addAll(products);

        // Debug print to verify response
        debugPrint('Fetched ${products.length} products');
        debugPrint('Response headers: ${response.headers}');

        // Check if there are more pages
        final linkHeader = response.headers['link'] ?? '';
        hasMorePages = linkHeader.contains('rel="next"');
        
        if (hasMorePages) {
          nextPageToken = _extractNextPageToken(linkHeader);
          debugPrint('Next page token: $nextPageToken');
          
          if (nextPageToken == null) {
            debugPrint('Warning: Found next page marker but no token');
            hasMorePages = false;
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } else {
          debugPrint('No more pages detected');
          nextPageToken = null;
        }
      } else {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  if (attemptCount >= maxAttempts) {
    debugPrint('Warning: Reached maximum attempts but may have more data');
  }

  return allProducts;
}

String? _extractNextPageToken(String linkHeader) {
  try {
    // Handle both comma-separated links and single links
    final links = linkHeader.split(',');
    for (final link in links) {
      if (link.contains('rel="next"')) {
        final match = RegExp(r'page_info=([^&>]+)').firstMatch(link);
        return match?.group(1);
      }
    }
    return null;
  } catch (e) {
    debugPrint('Error parsing link header: $e');
    return null;
  }
}

  Future<List<dynamic>> getOrders() async {
    try {
      final response = await http.get( 
        Uri.parse('https://$storeId.myshopify.com/admin/api/2023-10/orders.json'), // ?status=completed
        headers: {
          'X-Shopify-Access-Token': adminAPIAcessToken!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
}

