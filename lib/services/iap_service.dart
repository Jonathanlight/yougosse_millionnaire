import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/shop_model.dart';

/// Service for handling in-app purchases (gems)
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  bool get isAvailable => _available;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  /// Callback when gems are purchased successfully
  void Function(String productId, int gems)? onGemsPurchased;

  /// Product IDs matching ShopOffer IDs
  static const Set<String> _productIds = {
    'gems_small',
    'gems_medium',
    'gems_large',
    'gems_huge',
    'gems_mega',
  };

  /// Map product ID to total gems (gems + bonus)
  static int gemsForProduct(String productId) {
    final offer = ShopData.gemOffers.cast<ShopOffer?>().firstWhere(
          (o) => o!.id == productId,
          orElse: () => null,
        );
    return offer?.totalGems ?? 0;
  }

  /// Initialize IAP and listen for purchases
  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Listen for purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('IAP error: $error'),
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);

    if (response.error != null) {
      debugPrint('IAP: Error loading products: ${response.error}');
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('IAP: Loaded ${_products.length} products');
  }

  /// Get the store price for an offer, or null if not available
  String? getPriceForOffer(String offerId) {
    final product = _products.cast<ProductDetails?>().firstWhere(
          (p) => p!.id == offerId,
          orElse: () => null,
        );
    return product?.price;
  }

  /// Purchase gems by offer ID
  Future<bool> buyGems(String offerId) async {
    if (!_available) {
      debugPrint('IAP: Store not available');
      return false;
    }

    final product = _products.cast<ProductDetails?>().firstWhere(
          (p) => p!.id == offerId,
          orElse: () => null,
        );

    if (product == null) {
      debugPrint('IAP: Product $offerId not found');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    // Gems are consumable products
    return _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Deliver the gems
      final gems = gemsForProduct(purchase.productID);
      if (gems > 0) {
        onGemsPurchased?.call(purchase.productID, gems);
        debugPrint('IAP: Delivered $gems gems for ${purchase.productID}');
      }
    }

    if (purchase.status == PurchaseStatus.error) {
      debugPrint('IAP: Purchase error: ${purchase.error}');
    }

    // Complete pending purchases
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Restore previous purchases (non-consumable only, gems are consumable)
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
