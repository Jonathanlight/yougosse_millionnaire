import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Premium currency type
enum CurrencyType {
  money,
  gems,
}

/// Rarity of shop items
enum ItemRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Shop pack containing premium monuments
class ShopPack {
  final String id;
  final String name;
  final String description;
  final int priceGems;
  final int? priceMoney;
  final List<BuildingType> buildings;
  final ItemRarity rarity;
  final String iconAsset;
  final Color accentColor;
  final bool isLimited;

  const ShopPack({
    required this.id,
    required this.name,
    required this.description,
    required this.priceGems,
    this.priceMoney,
    required this.buildings,
    required this.rarity,
    required this.iconAsset,
    required this.accentColor,
    this.isLimited = false,
  });

  int get buildingCount => buildings.length;

  Color get rarityColor {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.epic:
        return Colors.purple;
      case ItemRarity.legendary:
        return Colors.amber;
    }
  }

  String get rarityName {
    switch (rarity) {
      case ItemRarity.common:
        return 'Commun';
      case ItemRarity.rare:
        return 'Rare';
      case ItemRarity.epic:
        return 'Epique';
      case ItemRarity.legendary:
        return 'Legendaire';
    }
  }
}

/// Special offer in the shop
class ShopOffer {
  final String id;
  final String title;
  final int gems;
  final int bonusGems;
  final double priceEuros;
  final bool isBestValue;
  final Color color;

  const ShopOffer({
    required this.id,
    required this.title,
    required this.gems,
    this.bonusGems = 0,
    required this.priceEuros,
    this.isBestValue = false,
    required this.color,
  });

  int get totalGems => gems + bonusGems;
}

/// Available shop packs
class ShopData {
  ShopData._();

  static const List<ShopPack> monumentPacks = [
    // Pack Or - Monuments dores
    ShopPack(
      id: 'golden_wonders',
      name: 'Merveilles Dorees',
      description: 'Monuments en or massif pour impressionner vos citoyens',
      priceGems: 500,
      buildings: [BuildingType.tourEiffel, BuildingType.arcDeTriomphe],
      rarity: ItemRarity.legendary,
      iconAsset: 'assets/shop/golden_pack.png',
      accentColor: Color(0xFFFFD700),
    ),

    // Pack Diamant
    ShopPack(
      id: 'diamond_collection',
      name: 'Collection Diamant',
      description: 'Monuments incrustes de diamants scintillants',
      priceGems: 750,
      buildings: [BuildingType.statueLiberte, BuildingType.bigBen],
      rarity: ItemRarity.legendary,
      iconAsset: 'assets/shop/diamond_pack.png',
      accentColor: Color(0xFF00FFFF),
      isLimited: true,
    ),

    // Pack Platine
    ShopPack(
      id: 'platinum_elite',
      name: 'Elite Platine',
      description: 'Les monuments les plus prestigieux en platine',
      priceGems: 400,
      buildings: [BuildingType.monument3, BuildingType.monument4],
      rarity: ItemRarity.epic,
      iconAsset: 'assets/shop/platinum_pack.png',
      accentColor: Color(0xFFE5E4E2),
    ),

    // Pack Bronze
    ShopPack(
      id: 'bronze_classics',
      name: 'Classiques Bronze',
      description: 'Monuments classiques avec finition bronze antique',
      priceGems: 200,
      priceMoney: 500000,
      buildings: [BuildingType.monument1, BuildingType.monument2],
      rarity: ItemRarity.rare,
      iconAsset: 'assets/shop/bronze_pack.png',
      accentColor: Color(0xFFCD7F32),
    ),

    // Pack Cristal
    ShopPack(
      id: 'crystal_dreams',
      name: 'Reves de Cristal',
      description: 'Monuments en cristal transparent lumineux',
      priceGems: 600,
      buildings: [BuildingType.tourEiffel, BuildingType.monument4],
      rarity: ItemRarity.epic,
      iconAsset: 'assets/shop/crystal_pack.png',
      accentColor: Color(0xFFADD8E6),
      isLimited: true,
    ),

    // Pack Neon
    ShopPack(
      id: 'neon_nights',
      name: 'Nuits Neon',
      description: 'Monuments avec eclairage neon futuriste',
      priceGems: 350,
      buildings: [BuildingType.bigBen, BuildingType.arcDeTriomphe],
      rarity: ItemRarity.epic,
      iconAsset: 'assets/shop/neon_pack.png',
      accentColor: Color(0xFFFF00FF),
    ),

    // Pack Starter
    ShopPack(
      id: 'starter_monuments',
      name: 'Pack Debutant',
      description: 'Parfait pour commencer votre collection',
      priceGems: 100,
      priceMoney: 100000,
      buildings: [BuildingType.monument1],
      rarity: ItemRarity.common,
      iconAsset: 'assets/shop/starter_pack.png',
      accentColor: Color(0xFF90EE90),
    ),

    // Pack Ruby
    ShopPack(
      id: 'ruby_royale',
      name: 'Royale Rubis',
      description: 'Monuments ornes de rubis precieux',
      priceGems: 550,
      buildings: [BuildingType.statueLiberte, BuildingType.monument3],
      rarity: ItemRarity.legendary,
      iconAsset: 'assets/shop/ruby_pack.png',
      accentColor: Color(0xFFE0115F),
    ),
  ];

  static const List<ShopOffer> gemOffers = [
    ShopOffer(
      id: 'gems_small',
      title: 'Petit Sac',
      gems: 100,
      priceEuros: 0.99,
      color: Color(0xFF4CAF50),
    ),
    ShopOffer(
      id: 'gems_medium',
      title: 'Sac Moyen',
      gems: 500,
      bonusGems: 50,
      priceEuros: 4.99,
      color: Color(0xFF2196F3),
    ),
    ShopOffer(
      id: 'gems_large',
      title: 'Grand Sac',
      gems: 1200,
      bonusGems: 200,
      priceEuros: 9.99,
      isBestValue: true,
      color: Color(0xFF9C27B0),
    ),
    ShopOffer(
      id: 'gems_huge',
      title: 'Coffre Tresor',
      gems: 2500,
      bonusGems: 500,
      priceEuros: 19.99,
      color: Color(0xFFFF9800),
    ),
    ShopOffer(
      id: 'gems_mega',
      title: 'Coffre Royal',
      gems: 6000,
      bonusGems: 1500,
      priceEuros: 49.99,
      color: Color(0xFFFFD700),
    ),
  ];

  static ShopPack? getPackById(String id) {
    try {
      return monumentPacks.firstWhere((pack) => pack.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Player's purchased packs
class PlayerShopData {
  final Set<String> purchasedPacks;
  final Map<String, int> packPurchaseCounts;

  PlayerShopData({
    Set<String>? purchasedPacks,
    Map<String, int>? packPurchaseCounts,
  })  : purchasedPacks = purchasedPacks ?? {},
        packPurchaseCounts = packPurchaseCounts ?? {};

  bool hasPurchased(String packId) => purchasedPacks.contains(packId);

  int getPurchaseCount(String packId) => packPurchaseCounts[packId] ?? 0;

  void recordPurchase(String packId) {
    purchasedPacks.add(packId);
    packPurchaseCounts[packId] = (packPurchaseCounts[packId] ?? 0) + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'purchasedPacks': purchasedPacks.toList(),
      'packPurchaseCounts': packPurchaseCounts,
    };
  }

  factory PlayerShopData.fromJson(Map<String, dynamic> json) {
    return PlayerShopData(
      purchasedPacks: (json['purchasedPacks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      packPurchaseCounts:
          (json['packPurchaseCounts'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, value as int),
              ) ??
              {},
    );
  }
}
