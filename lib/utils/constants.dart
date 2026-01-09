import 'package:flutter/material.dart';

/// Game configuration constants
class GameConstants {
  GameConstants._();

  // Grid settings - Base grid (100x100 x 2 subdivisions)
  static const int gridWidth = 140;
  static const int gridHeight = 140;
  static const double cellSize = 45.0; // 64/√2 ≈ 45

  // Camera settings
  static const double minZoom = 0.08;
  static const double maxZoom = 3.0;
  static const double defaultZoom = 0.4;

  // Economy settings
  static const int startingMoney = 10000;

  // Bank credit settings
  static const int minCredit = 1000;
  static const int maxCredit = 10000;
  static const int dailyCreditPayment = 500;
  static const int revenueIntervalSeconds = 60;
  static const double happinessMultiplierMax = 2.0;

  // Game timing
  static const int autoSaveIntervalSeconds = 30;

  // XP settings
  static const int xpPerBuilding = 10;
  static const int xpPerLevel = 100;

  // Audio settings
  static const double musicVolume = 0.5;
  static const double sfxVolume = 0.8;
}

/// Asset paths
class AssetPaths {
  AssetPaths._();

  static const String logo = 'assets/logo.png';
  static const String buildingSprite = 'assets/build.png';
  static const String backgroundMusic = 'music_background.mp3';
  static const String cashRegisterSound = 'cash-register.mp3';
}

/// Building type enumeration - ALL building variants
enum BuildingType {
  // ===== Maisons (10) =====
  maison1, maison2, maison3, maison4, maison5,
  maison6, maison7, maison8, maison9, maison10,

  // ===== Immeubles (16) =====
  immeuble1, immeuble2, immeuble3, immeuble4, immeuble5,
  immeuble6, immeuble7, immeuble8, immeuble9, immeuble10,
  immeuble11, immeuble12, immeuble13, immeuble14, immeuble15, immeuble16,

  // ===== Commerces (9) =====
  commerce1, commerce2, commerce3, commerce4, commerce5,
  commerce6, commerce7, commerce8, commerce9,

  // ===== Usines (16) =====
  usine1, usine2, usine3, usine4, usine5,
  usine6, usine7, usine8, usine9, usine10,
  usine11, usine12, usine13, usine14, usine15, usine16,

  // ===== Decorations (6) =====
  decoration1, decoration2, decoration3, decoration4, decoration5, decoration6,

  // ===== Monuments (8) =====
  tourEiffel, arcDeTriomphe, statueLiberte, bigBen,
  monument1, monument2, monument3, monument4,

  // ===== Routes (4) =====
  route1, route2, route3, route4,
}

/// Building category for menu organization
enum BuildingCategory {
  residential,
  commercial,
  industrial,
  decoration,
  monument,
  infrastructure,
}

/// Building configuration data
class BuildingConfig {
  final BuildingType type;
  final String name;
  final int cost;
  final int revenuePerMinute;
  final int constructionTimeSeconds;
  final int width;
  final int height;
  final int population;
  final double happinessBonus;
  final BuildingCategory category;
  final int unlockLevel;
  final Color color;
  final Color roofColor;
  final String? spritePath;

  const BuildingConfig({
    required this.type,
    required this.name,
    required this.cost,
    required this.revenuePerMinute,
    required this.constructionTimeSeconds,
    required this.width,
    required this.height,
    this.population = 0,
    this.happinessBonus = 0.0,
    required this.category,
    this.unlockLevel = 1,
    required this.color,
    this.roofColor = Colors.brown,
    this.spritePath,
  });
}

/// All building configurations
class BuildingConfigs {
  BuildingConfigs._();

  static const Map<BuildingType, BuildingConfig> configs = {
    // ==================== MAISONS (10) ====================
    BuildingType.maison1: BuildingConfig(
      type: BuildingType.maison1, name: 'Petite Maison', cost: 500,
      revenuePerMinute: 10, constructionTimeSeconds: 0, width: 3, height: 3,
      population: 4, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF87CEEB), spritePath: 'assets/building/maison/maison_1.png',
    ),
    BuildingType.maison2: BuildingConfig(
      type: BuildingType.maison2, name: 'Maison Simple', cost: 700,
      revenuePerMinute: 14, constructionTimeSeconds: 5, width: 3, height: 3,
      population: 5, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF90EE90), spritePath: 'assets/building/maison/maison_2.png',
    ),
    BuildingType.maison3: BuildingConfig(
      type: BuildingType.maison3, name: 'Maison Familiale', cost: 900,
      revenuePerMinute: 18, constructionTimeSeconds: 10, width: 3, height: 3,
      population: 6, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFFFB6C1), spritePath: 'assets/building/maison/maison_3.png',
    ),
    BuildingType.maison4: BuildingConfig(
      type: BuildingType.maison4, name: 'Jolie Maison', cost: 1200,
      revenuePerMinute: 24, constructionTimeSeconds: 15, width: 3, height: 3,
      population: 7, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFDDA0DD), spritePath: 'assets/building/maison/maison_4.png',
    ),
    BuildingType.maison5: BuildingConfig(
      type: BuildingType.maison5, name: 'Belle Maison', cost: 1500,
      revenuePerMinute: 30, constructionTimeSeconds: 20, width: 3, height: 3,
      population: 8, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFE6E6FA), spritePath: 'assets/building/maison/maison_5.png',
    ),
    BuildingType.maison6: BuildingConfig(
      type: BuildingType.maison6, name: 'Grande Maison', cost: 2000,
      revenuePerMinute: 40, constructionTimeSeconds: 25, width: 3, height: 3,
      population: 10, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFFFFACD), spritePath: 'assets/building/maison/maison_6.png',
    ),
    BuildingType.maison7: BuildingConfig(
      type: BuildingType.maison7, name: 'Maison de Luxe', cost: 2500,
      revenuePerMinute: 50, constructionTimeSeconds: 30, width: 3, height: 3,
      population: 12, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFFFE4E1), spritePath: 'assets/building/maison/maison_7.png',
    ),
    BuildingType.maison8: BuildingConfig(
      type: BuildingType.maison8, name: 'Villa', cost: 3500,
      revenuePerMinute: 70, constructionTimeSeconds: 40, width: 6, height: 3,
      population: 15, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFB0E0E6), spritePath: 'assets/building/maison/maison_8.png',
    ),
    BuildingType.maison9: BuildingConfig(
      type: BuildingType.maison9, name: 'Grande Villa', cost: 5000,
      revenuePerMinute: 100, constructionTimeSeconds: 50, width: 6, height: 3,
      population: 18, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF98FB98), spritePath: 'assets/building/maison/maison_9.png',
    ),
    BuildingType.maison10: BuildingConfig(
      type: BuildingType.maison10, name: 'Manoir', cost: 8000,
      revenuePerMinute: 160, constructionTimeSeconds: 60, width: 6, height: 6,
      population: 25, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFF0E68C), spritePath: 'assets/building/maison/maison_10.png',
    ),

    // ==================== IMMEUBLES (16) - Prix: 100K€ à 5M€ ====================
    BuildingType.immeuble1: BuildingConfig(
      type: BuildingType.immeuble1, name: 'Petit Immeuble', cost: 100000,
      revenuePerMinute: 2000, constructionTimeSeconds: 60, width: 3, height: 3,
      population: 50, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF808080), spritePath: 'assets/building/immeuble/immeuble_1.png',
    ),
    BuildingType.immeuble2: BuildingConfig(
      type: BuildingType.immeuble2, name: 'Immeuble Simple', cost: 150000,
      revenuePerMinute: 3000, constructionTimeSeconds: 90, width: 3, height: 3,
      population: 75, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF778899), spritePath: 'assets/building/immeuble/immeuble_2.png',
    ),
    BuildingType.immeuble3: BuildingConfig(
      type: BuildingType.immeuble3, name: 'Immeuble Moderne', cost: 200000,
      revenuePerMinute: 4000, constructionTimeSeconds: 120, width: 3, height: 3,
      population: 100, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF696969), spritePath: 'assets/building/immeuble/immeuble_3.png',
    ),
    BuildingType.immeuble4: BuildingConfig(
      type: BuildingType.immeuble4, name: 'Immeuble Standing', cost: 300000,
      revenuePerMinute: 6000, constructionTimeSeconds: 150, width: 3, height: 3,
      population: 150, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF708090), spritePath: 'assets/building/immeuble/immeuble_4.png',
    ),
    BuildingType.immeuble5: BuildingConfig(
      type: BuildingType.immeuble5, name: 'Residence', cost: 400000,
      revenuePerMinute: 8000, constructionTimeSeconds: 180, width: 6, height: 3,
      population: 200, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF5F9EA0), spritePath: 'assets/building/immeuble/immeuble_5.png',
    ),
    BuildingType.immeuble6: BuildingConfig(
      type: BuildingType.immeuble6, name: 'Residence Luxe', cost: 500000,
      revenuePerMinute: 10000, constructionTimeSeconds: 210, width: 6, height: 3,
      population: 250, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF4682B4), spritePath: 'assets/building/immeuble/immeuble_6.png',
    ),
    BuildingType.immeuble7: BuildingConfig(
      type: BuildingType.immeuble7, name: 'Tour Residence', cost: 700000,
      revenuePerMinute: 14000, constructionTimeSeconds: 240, width: 6, height: 6,
      population: 350, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF6495ED), spritePath: 'assets/building/immeuble/immeuble_7.png',
    ),
    BuildingType.immeuble8: BuildingConfig(
      type: BuildingType.immeuble8, name: 'Tour Moderne', cost: 900000,
      revenuePerMinute: 18000, constructionTimeSeconds: 270, width: 6, height: 6,
      population: 450, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF7B68EE), spritePath: 'assets/building/immeuble/immeuble_8.png',
    ),
    BuildingType.immeuble9: BuildingConfig(
      type: BuildingType.immeuble9, name: 'Tour Luxe', cost: 1100000,
      revenuePerMinute: 22000, constructionTimeSeconds: 300, width: 6, height: 6,
      population: 550, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF9370DB), spritePath: 'assets/building/immeuble/immeuble_9.png',
    ),
    BuildingType.immeuble10: BuildingConfig(
      type: BuildingType.immeuble10, name: 'Gratte-Ciel', cost: 1400000,
      revenuePerMinute: 28000, constructionTimeSeconds: 360, width: 6, height: 6,
      population: 700, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF8A2BE2), spritePath: 'assets/building/immeuble/immeuble_10.png',
    ),
    BuildingType.immeuble11: BuildingConfig(
      type: BuildingType.immeuble11, name: 'Tour Premium', cost: 1800000,
      revenuePerMinute: 36000, constructionTimeSeconds: 420, width: 6, height: 6,
      population: 900, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF9932CC), spritePath: 'assets/building/immeuble/immeuble_11.png',
    ),
    BuildingType.immeuble12: BuildingConfig(
      type: BuildingType.immeuble12, name: 'Tour Elite', cost: 2200000,
      revenuePerMinute: 44000, constructionTimeSeconds: 480, width: 6, height: 6,
      population: 1100, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFBA55D3), spritePath: 'assets/building/immeuble/immeuble_12.png',
    ),
    BuildingType.immeuble13: BuildingConfig(
      type: BuildingType.immeuble13, name: 'Tour Prestige', cost: 2800000,
      revenuePerMinute: 56000, constructionTimeSeconds: 540, width: 6, height: 6,
      population: 1400, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFDA70D6), spritePath: 'assets/building/immeuble/immeuble_13.png',
    ),
    BuildingType.immeuble14: BuildingConfig(
      type: BuildingType.immeuble14, name: 'Mega Tour', cost: 3500000,
      revenuePerMinute: 70000, constructionTimeSeconds: 600, width: 9, height: 6,
      population: 1750, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFEE82EE), spritePath: 'assets/building/immeuble/immeuble_14.png',
    ),
    BuildingType.immeuble15: BuildingConfig(
      type: BuildingType.immeuble15, name: 'Tour Diamant', cost: 4200000,
      revenuePerMinute: 84000, constructionTimeSeconds: 720, width: 9, height: 6,
      population: 2100, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFFF00FF), spritePath: 'assets/building/immeuble/immeuble_15.png',
    ),
    BuildingType.immeuble16: BuildingConfig(
      type: BuildingType.immeuble16, name: 'Tour Platine', cost: 5000000,
      revenuePerMinute: 100000, constructionTimeSeconds: 900, width: 9, height: 9,
      population: 2500, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFE6E6FA), spritePath: 'assets/building/immeuble/immeuble_16.png',
    ),

    // ==================== COMMERCES (9) ====================
    BuildingType.commerce1: BuildingConfig(
      type: BuildingType.commerce1, name: 'Petite Boutique', cost: 1000,
      revenuePerMinute: 30, constructionTimeSeconds: 15, width: 3, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFFFA500), spritePath: 'assets/building/commerce/commerce_1.png',
    ),
    BuildingType.commerce2: BuildingConfig(
      type: BuildingType.commerce2, name: 'Boutique', cost: 1500,
      revenuePerMinute: 45, constructionTimeSeconds: 20, width: 3, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFFF8C00), spritePath: 'assets/building/commerce/commerce_2.png',
    ),
    BuildingType.commerce3: BuildingConfig(
      type: BuildingType.commerce3, name: 'Magasin', cost: 2500,
      revenuePerMinute: 75, constructionTimeSeconds: 30, width: 3, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFFFD700), spritePath: 'assets/building/commerce/commerce_3.png',
    ),
    BuildingType.commerce4: BuildingConfig(
      type: BuildingType.commerce4, name: 'Grand Magasin', cost: 4000,
      revenuePerMinute: 120, constructionTimeSeconds: 45, width: 6, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFF0E68C), spritePath: 'assets/building/commerce/commerce_4.png',
    ),
    BuildingType.commerce5: BuildingConfig(
      type: BuildingType.commerce5, name: 'Supermarche', cost: 6000,
      revenuePerMinute: 180, constructionTimeSeconds: 60, width: 6, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFBDB76B), spritePath: 'assets/building/commerce/commerce_5.png',
    ),
    BuildingType.commerce6: BuildingConfig(
      type: BuildingType.commerce6, name: 'Hypermarche', cost: 10000,
      revenuePerMinute: 300, constructionTimeSeconds: 80, width: 6, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFDAA520), spritePath: 'assets/building/commerce/commerce_6.png',
    ),
    BuildingType.commerce7: BuildingConfig(
      type: BuildingType.commerce7, name: 'Centre Commercial', cost: 15000,
      revenuePerMinute: 450, constructionTimeSeconds: 100, width: 6, height: 6,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFB8860B), spritePath: 'assets/building/commerce/commerce_7.png',
    ),
    BuildingType.commerce8: BuildingConfig(
      type: BuildingType.commerce8, name: 'Grand Centre', cost: 25000,
      revenuePerMinute: 750, constructionTimeSeconds: 120, width: 9, height: 6,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFCD853F), spritePath: 'assets/building/commerce/commerce_8.png',
    ),
    BuildingType.commerce9: BuildingConfig(
      type: BuildingType.commerce9, name: 'Mega Centre', cost: 40000,
      revenuePerMinute: 1200, constructionTimeSeconds: 150, width: 9, height: 9,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFD2691E), spritePath: 'assets/building/commerce/commerce_9.png',
    ),

    // ==================== USINES (16) ====================
    BuildingType.usine1: BuildingConfig(
      type: BuildingType.usine1, name: 'Petit Atelier', cost: 2000,
      revenuePerMinute: 60, constructionTimeSeconds: 30, width: 3, height: 3,
      happinessBonus: -0.02, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFF8B4513), spritePath: 'assets/building/activite/usine_1.png',
    ),
    BuildingType.usine2: BuildingConfig(
      type: BuildingType.usine2, name: 'Atelier', cost: 3000,
      revenuePerMinute: 90, constructionTimeSeconds: 40, width: 3, height: 3,
      happinessBonus: -0.03, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFA0522D), spritePath: 'assets/building/activite/usine_2.png',
    ),
    BuildingType.usine3: BuildingConfig(
      type: BuildingType.usine3, name: 'Petite Usine', cost: 4500,
      revenuePerMinute: 135, constructionTimeSeconds: 50, width: 6, height: 3,
      happinessBonus: -0.05, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFCD853F), spritePath: 'assets/building/activite/usine_3.png',
    ),
    BuildingType.usine4: BuildingConfig(
      type: BuildingType.usine4, name: 'Usine', cost: 6000,
      revenuePerMinute: 180, constructionTimeSeconds: 60, width: 6, height: 3,
      happinessBonus: -0.07, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFD2691E), spritePath: 'assets/building/activite/usine_4.png',
    ),
    BuildingType.usine5: BuildingConfig(
      type: BuildingType.usine5, name: 'Grande Usine', cost: 8000,
      revenuePerMinute: 240, constructionTimeSeconds: 70, width: 6, height: 6,
      happinessBonus: -0.10, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFDEB887), spritePath: 'assets/building/activite/usine_5.png',
    ),
    BuildingType.usine6: BuildingConfig(
      type: BuildingType.usine6, name: 'Manufacture', cost: 10000,
      revenuePerMinute: 300, constructionTimeSeconds: 80, width: 6, height: 6,
      happinessBonus: -0.12, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFF4A460), spritePath: 'assets/building/activite/usine_6.png',
    ),
    BuildingType.usine7: BuildingConfig(
      type: BuildingType.usine7, name: 'Fabrique', cost: 12000,
      revenuePerMinute: 360, constructionTimeSeconds: 90, width: 6, height: 6,
      happinessBonus: -0.14, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFD2B48C), spritePath: 'assets/building/activite/usine_7.png',
    ),
    BuildingType.usine8: BuildingConfig(
      type: BuildingType.usine8, name: 'Industrie', cost: 15000,
      revenuePerMinute: 450, constructionTimeSeconds: 100, width: 6, height: 6,
      happinessBonus: -0.16, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFBC8F8F), spritePath: 'assets/building/activite/usine_8.png',
    ),
    BuildingType.usine9: BuildingConfig(
      type: BuildingType.usine9, name: 'Complexe', cost: 20000,
      revenuePerMinute: 600, constructionTimeSeconds: 110, width: 9, height: 6,
      happinessBonus: -0.18, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFF5DEB3), spritePath: 'assets/building/activite/usine_9.png',
    ),
    BuildingType.usine10: BuildingConfig(
      type: BuildingType.usine10, name: 'Mega Usine', cost: 25000,
      revenuePerMinute: 750, constructionTimeSeconds: 120, width: 9, height: 6,
      happinessBonus: -0.20, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFFFE4C4), spritePath: 'assets/building/activite/usine_10.png',
    ),
    BuildingType.usine11: BuildingConfig(
      type: BuildingType.usine11, name: 'Raffinerie', cost: 30000,
      revenuePerMinute: 900, constructionTimeSeconds: 130, width: 9, height: 6,
      happinessBonus: -0.22, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFFFDEAD), spritePath: 'assets/building/activite/usine_11.png',
    ),
    BuildingType.usine12: BuildingConfig(
      type: BuildingType.usine12, name: 'Acierie', cost: 38000,
      revenuePerMinute: 1140, constructionTimeSeconds: 140, width: 9, height: 9,
      happinessBonus: -0.24, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFFFE4B5), spritePath: 'assets/building/activite/usine_12.png',
    ),
    BuildingType.usine13: BuildingConfig(
      type: BuildingType.usine13, name: 'Zone Industrielle', cost: 48000,
      revenuePerMinute: 1440, constructionTimeSeconds: 150, width: 9, height: 9,
      happinessBonus: -0.26, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFFFDAB9), spritePath: 'assets/building/activite/usine_13.png',
    ),
    BuildingType.usine14: BuildingConfig(
      type: BuildingType.usine14, name: 'Port Industriel', cost: 60000,
      revenuePerMinute: 1800, constructionTimeSeconds: 160, width: 9, height: 9,
      happinessBonus: -0.28, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFEEE8AA), spritePath: 'assets/building/activite/usine_14.png',
    ),
    BuildingType.usine15: BuildingConfig(
      type: BuildingType.usine15, name: 'Mega Complexe', cost: 80000,
      revenuePerMinute: 2400, constructionTimeSeconds: 180, width: 12, height: 9,
      happinessBonus: -0.30, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFF0E68C), spritePath: 'assets/building/activite/usine_15.png',
    ),
    BuildingType.usine16: BuildingConfig(
      type: BuildingType.usine16, name: 'Cite Industrielle', cost: 100000,
      revenuePerMinute: 3000, constructionTimeSeconds: 200, width: 12, height: 12,
      happinessBonus: -0.35, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFBDB76B), spritePath: 'assets/building/activite/usine.png',
    ),

    // ==================== DECORATIONS (6) ====================
    BuildingType.decoration1: BuildingConfig(
      type: BuildingType.decoration1, name: 'Jardin', cost: 500,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 3, height: 3,
      happinessBonus: 0.05, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF228B22), spritePath: 'assets/building/decoration/decoration_1.png',
    ),
    BuildingType.decoration2: BuildingConfig(
      type: BuildingType.decoration2, name: 'Parc', cost: 1000,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 3, height: 3,
      happinessBonus: 0.10, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF32CD32), spritePath: 'assets/building/decoration/decoration_2.png',
    ),
    BuildingType.decoration3: BuildingConfig(
      type: BuildingType.decoration3, name: 'Grand Parc', cost: 2000,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 6, height: 3,
      happinessBonus: 0.15, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF00FF00), spritePath: 'assets/building/decoration/decoration_3.png',
    ),
    BuildingType.decoration4: BuildingConfig(
      type: BuildingType.decoration4, name: 'Fontaine', cost: 3000,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 3, height: 3,
      happinessBonus: 0.20, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF00CED1), spritePath: 'assets/building/decoration/decoration_4.png',
    ),
    BuildingType.decoration5: BuildingConfig(
      type: BuildingType.decoration5, name: 'Place', cost: 5000,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 6, height: 6,
      happinessBonus: 0.25, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF20B2AA), spritePath: 'assets/building/decoration/decoration_5.png',
    ),
    BuildingType.decoration6: BuildingConfig(
      type: BuildingType.decoration6, name: 'Grand Jardin', cost: 8000,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 6, height: 6,
      happinessBonus: 0.35, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF3CB371), spritePath: 'assets/building/decoration/decoration_6.png',
    ),

    // ==================== MONUMENTS (8) - Prix: 100K€ à 10M€ ====================
    BuildingType.monument1: BuildingConfig(
      type: BuildingType.monument1, name: 'Obelisque', cost: 100000,
      revenuePerMinute: 2000, constructionTimeSeconds: 180, width: 3, height: 3,
      happinessBonus: 0.30, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFFAF0E6), spritePath: 'assets/building/monument/monument_1.png',
    ),
    BuildingType.monument2: BuildingConfig(
      type: BuildingType.monument2, name: 'Statue', cost: 500000,
      revenuePerMinute: 10000, constructionTimeSeconds: 300, width: 3, height: 3,
      happinessBonus: 0.40, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFFFEFD5), spritePath: 'assets/building/monument/monument_2.png',
    ),
    BuildingType.monument3: BuildingConfig(
      type: BuildingType.monument3, name: 'Colonne', cost: 1000000,
      revenuePerMinute: 20000, constructionTimeSeconds: 420, width: 3, height: 6,
      happinessBonus: 0.50, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFFFF8DC), spritePath: 'assets/building/monument/monument_3.png',
    ),
    BuildingType.monument4: BuildingConfig(
      type: BuildingType.monument4, name: 'Memorial', cost: 2000000,
      revenuePerMinute: 40000, constructionTimeSeconds: 540, width: 6, height: 6,
      happinessBonus: 0.60, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFFFFFE0), spritePath: 'assets/building/monument/monument_4.png',
    ),
    BuildingType.arcDeTriomphe: BuildingConfig(
      type: BuildingType.arcDeTriomphe, name: 'Arc de Triomphe', cost: 3500000,
      revenuePerMinute: 70000, constructionTimeSeconds: 720, width: 6, height: 6,
      happinessBonus: 0.70, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFD2B48C), spritePath: 'assets/building/monument/arc_de_triomphe.png',
    ),
    BuildingType.bigBen: BuildingConfig(
      type: BuildingType.bigBen, name: 'Big Ben', cost: 5000000,
      revenuePerMinute: 100000, constructionTimeSeconds: 900, width: 6, height: 9,
      happinessBonus: 0.80, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFDEB887), spritePath: 'assets/building/monument/london_clock.png',
    ),
    BuildingType.tourEiffel: BuildingConfig(
      type: BuildingType.tourEiffel, name: 'Tour Eiffel', cost: 7500000,
      revenuePerMinute: 150000, constructionTimeSeconds: 1200, width: 9, height: 9,
      happinessBonus: 0.90, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFB87333), spritePath: 'assets/building/monument/tour_effeil.png',
    ),
    BuildingType.statueLiberte: BuildingConfig(
      type: BuildingType.statueLiberte, name: 'Statue de la Liberte', cost: 10000000,
      revenuePerMinute: 200000, constructionTimeSeconds: 1500, width: 9, height: 9,
      happinessBonus: 1.00, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFF20B2AA), spritePath: 'assets/building/monument/statut_liberte.png',
    ),

    // ==================== ROUTES (4) ====================
    BuildingType.route1: BuildingConfig(
      type: BuildingType.route1, name: 'Route 1', cost: 50,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 1, height: 3,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFF696969), spritePath: 'assets/building/route/route_1.png',
    ),
    BuildingType.route2: BuildingConfig(
      type: BuildingType.route2, name: 'Route 2', cost: 100,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 3, height: 1,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFF808080), spritePath: 'assets/building/route/route_2.png',
    ),
    BuildingType.route3: BuildingConfig(
      type: BuildingType.route3, name: 'Avenue', cost: 150,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 1, height: 1,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFFA9A9A9), spritePath: 'assets/building/route/route_3.png',
    ),
    BuildingType.route4: BuildingConfig(
      type: BuildingType.route4, name: 'Boulevard', cost: 200,
      revenuePerMinute: 0, constructionTimeSeconds: 0, width: 1, height: 1,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFFC0C0C0), spritePath: 'assets/building/route/route_4.png',
    ),
  };

  static BuildingConfig getConfig(BuildingType type) {
    return configs[type]!;
  }

  static List<BuildingConfig> getByCategory(BuildingCategory category) {
    return configs.values
        .where((config) => config.category == category)
        .toList();
  }

  static List<BuildingConfig> getUnlocked(int level) {
    return configs.values
        .where((config) => config.unlockLevel <= level)
        .toList();
  }
}

/// Color palette for UI
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color accent = Color(0xFFFFD700);
  static const Color background = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF2D2D2D);
  static const Color error = Color(0xFFE53935);

  static const Color terrainGrass = Color(0xFF90EE90);
  static const Color terrainEmpty = Color(0xFFA8D8A8);
  static const Color gridLine = Color(0x40000000);
  static const Color validPlacement = Color(0x8000FF00);
  static const Color invalidPlacement = Color(0x80FF0000);

  // Bling effect colors
  static const Color blingGold = Color(0xFFFFD700);
  static const Color blingWhite = Color(0xFFFFFFFF);
}