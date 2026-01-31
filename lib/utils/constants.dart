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
  static const int startingMoney = 500; // Just enough for the cheapest house

  // Bank credit settings
  static const int minCredit = 1000;
  static const int maxCredit = 10000;
  static const int dailyCreditPayment = 500;
  static const double happinessMultiplierMax = 2.0;

  // Game timing
  static const int autoSaveIntervalSeconds = 30;

  // XP settings
  static const int xpPerBuilding = 10;
  static const int xpPerLevel = 100;

  // Audio settings
  static const double defaultMusicVolume = 0.5;
  static const double defaultSfxVolume = 0.8;
  static const double volumeStep = 0.05;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;

  // Building movement settings
  static const int longPressDurationMs = 800;
  static const int dropAnimationMs = 200;
  static const int returnAnimationMs = 300;
}

/// Asset paths
class AssetPaths {
  AssetPaths._();

  static const String logo = 'assets/logo.png';
  static const String buildingSprite = 'assets/build.png';
  static const String backgroundMusic = 'music_background.mp3';
  static const String cashRegisterSound = 'cash-register.mp3';

  // NPC characters for daily greeting
  static const String nora = 'assets/person/nora.png';
  static const String christine = 'assets/person/christine.png';
  static const String james = 'assets/person/james.png';
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

  // ===== Activity (7) =====
  activity1, activity2, activity3, activity4, activity5, activity6, activity7, activity8,

  // ===== Decorations (6) =====
  decoration1, decoration2, decoration3, decoration4, decoration5, decoration6,

  // ===== Monuments (8) =====
  tourEiffel, arcDeTriomphe, statueLiberte, bigBen,
  monument1, monument2, monument3, monument4,

  // ===== Routes (4) =====
  route1, route2, route3, route4, route5, route6, route7, route8,
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

/// Placement mode for building operations
enum PlacementMode {
  none,
  placing,  // Placing a new building
  moving,   // Moving an existing building
}

/// Building configuration data
class BuildingConfig {
  final BuildingType type;
  final String name;
  final int cost;
  final int revenuePerCycle;       // Revenue per collection cycle
  final int revenueCycleMinutes;   // Duration of a cycle in minutes
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
    required this.revenuePerCycle,
    required this.revenueCycleMinutes,
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

  /// Expected sprite width in pixels
  int get spritePixelWidth => width * 45;

  /// Expected sprite height in pixels
  int get spritePixelHeight => height * 45;

  /// Check if this building generates revenue
  bool get hasRevenue => revenuePerCycle > 0 && revenueCycleMinutes > 0;

  /// Get revenue per minute (for display/calculations)
  double get revenuePerMinute {
    if (revenueCycleMinutes == 0) return 0;
    return revenuePerCycle / revenueCycleMinutes;
  }

  /// Get cycle duration as Duration
  Duration get cycleDuration => Duration(minutes: revenueCycleMinutes);
}

/// All building configurations
class BuildingConfigs {
  BuildingConfigs._();

  static const Map<BuildingType, BuildingConfig> configs = {
    // ==================== MAISONS (10) ====================
    // Maisons 1-5: cost < 2000, cycle = 30min, revenue = cost * 0.005
    BuildingType.maison1: BuildingConfig(
      type: BuildingType.maison1, name: 'Petite Maison', cost: 500,
      revenuePerCycle: 3, revenueCycleMinutes: 30, constructionTimeSeconds: 0, width: 3, height: 3,
      population: 4, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF87CEEB), spritePath: 'assets/building/maison/maison_1.png',
    ),
    BuildingType.maison2: BuildingConfig(
      type: BuildingType.maison2, name: 'Maison Simple', cost: 700,
      revenuePerCycle: 4, revenueCycleMinutes: 30, constructionTimeSeconds: 5, width: 3, height: 3,
      population: 5, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF90EE90), spritePath: 'assets/building/maison/maison_2.png',
    ),
    BuildingType.maison3: BuildingConfig(
      type: BuildingType.maison3, name: 'Maison Familiale', cost: 900,
      revenuePerCycle: 5, revenueCycleMinutes: 30, constructionTimeSeconds: 10, width: 3, height: 3,
      population: 6, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFFFB6C1), spritePath: 'assets/building/maison/maison_3.png',
    ),
    BuildingType.maison4: BuildingConfig(
      type: BuildingType.maison4, name: 'Jolie Maison', cost: 1200,
      revenuePerCycle: 6, revenueCycleMinutes: 30, constructionTimeSeconds: 15, width: 3, height: 3,
      population: 7, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFDDA0DD), spritePath: 'assets/building/maison/maison_4.png',
    ),
    BuildingType.maison5: BuildingConfig(
      type: BuildingType.maison5, name: 'Belle Maison', cost: 1500,
      revenuePerCycle: 8, revenueCycleMinutes: 30, constructionTimeSeconds: 20, width: 3, height: 3,
      population: 8, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFE6E6FA), spritePath: 'assets/building/maison/maison_5.png',
    ),
    // Maisons 6-10: cost >= 2000, cycle = 60min
    BuildingType.maison6: BuildingConfig(
      type: BuildingType.maison6, name: 'Grande Maison', cost: 2000,
      revenuePerCycle: 10, revenueCycleMinutes: 60, constructionTimeSeconds: 25, width: 3, height: 3,
      population: 10, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFFFFACD), spritePath: 'assets/building/maison/maison_6.png',
    ),
    BuildingType.maison7: BuildingConfig(
      type: BuildingType.maison7, name: 'Maison de Luxe', cost: 2500,
      revenuePerCycle: 13, revenueCycleMinutes: 60, constructionTimeSeconds: 30, width: 3, height: 3,
      population: 12, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFFFE4E1), spritePath: 'assets/building/maison/maison_7.png',
    ),
    BuildingType.maison8: BuildingConfig(
      type: BuildingType.maison8, name: 'Villa', cost: 3500,
      revenuePerCycle: 18, revenueCycleMinutes: 60, constructionTimeSeconds: 40, width: 6, height: 3,
      population: 15, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFB0E0E6), spritePath: 'assets/building/maison/maison_8.png',
    ),
    BuildingType.maison9: BuildingConfig(
      type: BuildingType.maison9, name: 'Grande Villa', cost: 5000,
      revenuePerCycle: 25, revenueCycleMinutes: 60, constructionTimeSeconds: 50, width: 6, height: 3,
      population: 18, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF98FB98), spritePath: 'assets/building/maison/maison_9.png',
    ),
    BuildingType.maison10: BuildingConfig(
      type: BuildingType.maison10, name: 'Manoir', cost: 8000,
      revenuePerCycle: 40, revenueCycleMinutes: 60, constructionTimeSeconds: 60, width: 6, height: 6,
      population: 25, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFF0E68C), spritePath: 'assets/building/maison/maison_10.png',
    ),

    // ==================== IMMEUBLES (16) - Prix: 100K€ à 5M€ ====================
    // Immeubles 1-8: cost < 1M, cycle = 120min, revenue = cost * 0.003
    BuildingType.immeuble1: BuildingConfig(
      type: BuildingType.immeuble1, name: 'Petit Immeuble', cost: 100000,
      revenuePerCycle: 300, revenueCycleMinutes: 120, constructionTimeSeconds: 60, width: 3, height: 3,
      population: 50, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF808080), spritePath: 'assets/building/immeuble/immeuble_1.png',
    ),
    BuildingType.immeuble2: BuildingConfig(
      type: BuildingType.immeuble2, name: 'Immeuble Simple', cost: 150000,
      revenuePerCycle: 450, revenueCycleMinutes: 120, constructionTimeSeconds: 90, width: 3, height: 3,
      population: 75, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF778899), spritePath: 'assets/building/immeuble/immeuble_2.png',
    ),
    BuildingType.immeuble3: BuildingConfig(
      type: BuildingType.immeuble3, name: 'Immeuble Moderne', cost: 200000,
      revenuePerCycle: 600, revenueCycleMinutes: 120, constructionTimeSeconds: 120, width: 3, height: 3,
      population: 100, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF696969), spritePath: 'assets/building/immeuble/immeuble_3.png',
    ),
    BuildingType.immeuble4: BuildingConfig(
      type: BuildingType.immeuble4, name: 'Immeuble Standing', cost: 300000,
      revenuePerCycle: 900, revenueCycleMinutes: 120, constructionTimeSeconds: 150, width: 3, height: 3,
      population: 150, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF708090), spritePath: 'assets/building/immeuble/immeuble_4.png',
    ),
    BuildingType.immeuble5: BuildingConfig(
      type: BuildingType.immeuble5, name: 'Residence', cost: 400000,
      revenuePerCycle: 1200, revenueCycleMinutes: 120, constructionTimeSeconds: 180, width: 6, height: 3,
      population: 200, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF5F9EA0), spritePath: 'assets/building/immeuble/immeuble_5.png',
    ),
    BuildingType.immeuble6: BuildingConfig(
      type: BuildingType.immeuble6, name: 'Residence Luxe', cost: 500000,
      revenuePerCycle: 1500, revenueCycleMinutes: 120, constructionTimeSeconds: 210, width: 6, height: 3,
      population: 250, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF4682B4), spritePath: 'assets/building/immeuble/immeuble_6.png',
    ),
    BuildingType.immeuble7: BuildingConfig(
      type: BuildingType.immeuble7, name: 'Tour Residence', cost: 700000,
      revenuePerCycle: 2100, revenueCycleMinutes: 120, constructionTimeSeconds: 240, width: 6, height: 6,
      population: 350, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF6495ED), spritePath: 'assets/building/immeuble/immeuble_7.png',
    ),
    BuildingType.immeuble8: BuildingConfig(
      type: BuildingType.immeuble8, name: 'Tour Moderne', cost: 900000,
      revenuePerCycle: 2700, revenueCycleMinutes: 120, constructionTimeSeconds: 270, width: 6, height: 6,
      population: 450, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF7B68EE), spritePath: 'assets/building/immeuble/immeuble_8.png',
    ),
    // Immeubles 9-16: cost >= 1M, cycle = 240min
    BuildingType.immeuble9: BuildingConfig(
      type: BuildingType.immeuble9, name: 'Tour Luxe', cost: 1100000,
      revenuePerCycle: 3300, revenueCycleMinutes: 240, constructionTimeSeconds: 300, width: 6, height: 6,
      population: 550, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF9370DB), spritePath: 'assets/building/immeuble/immeuble_9.png',
    ),
    BuildingType.immeuble10: BuildingConfig(
      type: BuildingType.immeuble10, name: 'Gratte-Ciel', cost: 1400000,
      revenuePerCycle: 4200, revenueCycleMinutes: 240, constructionTimeSeconds: 360, width: 6, height: 6,
      population: 700, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF8A2BE2), spritePath: 'assets/building/immeuble/immeuble_10.png',
    ),
    BuildingType.immeuble11: BuildingConfig(
      type: BuildingType.immeuble11, name: 'Tour Premium', cost: 1800000,
      revenuePerCycle: 5400, revenueCycleMinutes: 240, constructionTimeSeconds: 420, width: 6, height: 6,
      population: 900, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFF9932CC), spritePath: 'assets/building/immeuble/immeuble_11.png',
    ),
    BuildingType.immeuble12: BuildingConfig(
      type: BuildingType.immeuble12, name: 'Tour Elite', cost: 2200000,
      revenuePerCycle: 6600, revenueCycleMinutes: 240, constructionTimeSeconds: 480, width: 6, height: 6,
      population: 1100, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFBA55D3), spritePath: 'assets/building/immeuble/immeuble_12.png',
    ),
    BuildingType.immeuble13: BuildingConfig(
      type: BuildingType.immeuble13, name: 'Tour Prestige', cost: 2800000,
      revenuePerCycle: 8400, revenueCycleMinutes: 240, constructionTimeSeconds: 540, width: 6, height: 6,
      population: 1400, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFDA70D6), spritePath: 'assets/building/immeuble/immeuble_13.png',
    ),
    BuildingType.immeuble14: BuildingConfig(
      type: BuildingType.immeuble14, name: 'Mega Tour', cost: 3500000,
      revenuePerCycle: 10500, revenueCycleMinutes: 240, constructionTimeSeconds: 600, width: 9, height: 6,
      population: 1750, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFEE82EE), spritePath: 'assets/building/immeuble/immeuble_14.png',
    ),
    BuildingType.immeuble15: BuildingConfig(
      type: BuildingType.immeuble15, name: 'Tour Diamant', cost: 4200000,
      revenuePerCycle: 12600, revenueCycleMinutes: 240, constructionTimeSeconds: 720, width: 9, height: 6,
      population: 2100, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFFF00FF), spritePath: 'assets/building/immeuble/immeuble_15.png',
    ),
    BuildingType.immeuble16: BuildingConfig(
      type: BuildingType.immeuble16, name: 'Tour Platine', cost: 5000000,
      revenuePerCycle: 15000, revenueCycleMinutes: 240, constructionTimeSeconds: 900, width: 9, height: 9,
      population: 2500, category: BuildingCategory.residential, unlockLevel: 1,
      color: Color(0xFFE6E6FA), spritePath: 'assets/building/immeuble/immeuble_16.png',
    ),

    // ==================== COMMERCES (9) ====================
    // Commerces 1-4: cost < 5000, cycle = 30min, revenue = cost * 0.008
    BuildingType.commerce1: BuildingConfig(
      type: BuildingType.commerce1, name: 'Petite Boutique', cost: 1000,
      revenuePerCycle: 8, revenueCycleMinutes: 30, constructionTimeSeconds: 15, width: 3, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFFFA500), spritePath: 'assets/building/commerce/commerce_1.png',
    ),
    BuildingType.commerce2: BuildingConfig(
      type: BuildingType.commerce2, name: 'Boutique', cost: 1500,
      revenuePerCycle: 12, revenueCycleMinutes: 30, constructionTimeSeconds: 20, width: 3, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFFF8C00), spritePath: 'assets/building/commerce/commerce_2.png',
    ),
    BuildingType.commerce3: BuildingConfig(
      type: BuildingType.commerce3, name: 'Magasin', cost: 2500,
      revenuePerCycle: 20, revenueCycleMinutes: 30, constructionTimeSeconds: 30, width: 3, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFFFD700), spritePath: 'assets/building/commerce/commerce_3.png',
    ),
    BuildingType.commerce4: BuildingConfig(
      type: BuildingType.commerce4, name: 'Grand Magasin', cost: 4000,
      revenuePerCycle: 32, revenueCycleMinutes: 30, constructionTimeSeconds: 45, width: 6, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFF0E68C), spritePath: 'assets/building/commerce/commerce_4.png',
    ),
    // Commerces 5-9: cost >= 5000, cycle = 60min
    BuildingType.commerce5: BuildingConfig(
      type: BuildingType.commerce5, name: 'Supermarche', cost: 6000,
      revenuePerCycle: 48, revenueCycleMinutes: 60, constructionTimeSeconds: 60, width: 6, height: 3,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFBDB76B), spritePath: 'assets/building/commerce/commerce_5.png',
    ),
    BuildingType.commerce6: BuildingConfig(
      type: BuildingType.commerce6, name: 'Hypermarche', cost: 10000,
      revenuePerCycle: 80, revenueCycleMinutes: 60, constructionTimeSeconds: 80, width: 6, height: 4,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFDAA520), spritePath: 'assets/building/commerce/commerce_6.png',
    ),
    BuildingType.commerce7: BuildingConfig(
      type: BuildingType.commerce7, name: 'Centre Commercial', cost: 15000,
      revenuePerCycle: 120, revenueCycleMinutes: 60, constructionTimeSeconds: 100, width: 6, height: 6,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFB8860B), spritePath: 'assets/building/commerce/commerce_7.png',
    ),
    BuildingType.commerce8: BuildingConfig(
      type: BuildingType.commerce8, name: 'Grand Centre', cost: 25000,
      revenuePerCycle: 200, revenueCycleMinutes: 60, constructionTimeSeconds: 120, width: 9, height: 6,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFCD853F), spritePath: 'assets/building/commerce/commerce_8.png',
    ),
    BuildingType.commerce9: BuildingConfig(
      type: BuildingType.commerce9, name: 'Mega Centre', cost: 40000,
      revenuePerCycle: 320, revenueCycleMinutes: 60, constructionTimeSeconds: 150, width: 9, height: 9,
      category: BuildingCategory.commercial, unlockLevel: 1,
      color: Color(0xFFD2691E), spritePath: 'assets/building/commerce/commerce_9.png',
    ),

    // ==================== Activity (8) - cycle = 240min, revenue = cost * 0.002 ====================
    BuildingType.activity1: BuildingConfig(
      type: BuildingType.activity1, name: 'Gare Train', cost: 500000,
      revenuePerCycle: 1000, revenueCycleMinutes: 240, constructionTimeSeconds: 30, width: 6, height: 4,
      happinessBonus: 0.25, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFF8B4513), spritePath: 'assets/building/activity/activity_1.png',
    ),
    BuildingType.activity2: BuildingConfig(
      type: BuildingType.activity2, name: 'La Poste', cost: 300000,
      revenuePerCycle: 600, revenueCycleMinutes: 240, constructionTimeSeconds: 40, width: 4, height: 3,
      happinessBonus: 0.15, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFA0522D), spritePath: 'assets/building/activity/activity_2.png',
    ),
    BuildingType.activity3: BuildingConfig(
      type: BuildingType.activity3, name: 'La Banque', cost: 450000,
      revenuePerCycle: 900, revenueCycleMinutes: 240, constructionTimeSeconds: 50, width: 6, height: 4,
      happinessBonus: 0.40, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFCD853F), spritePath: 'assets/building/activity/activity_3.png',
    ),
    BuildingType.activity4: BuildingConfig(
      type: BuildingType.activity4, name: 'La Police', cost: 100000,
      revenuePerCycle: 200, revenueCycleMinutes: 240, constructionTimeSeconds: 60, width: 6, height: 4,
      happinessBonus: 0.10, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFD2691E), spritePath: 'assets/building/activity/activity_4.png',
    ),
    BuildingType.activity5: BuildingConfig(
      type: BuildingType.activity5, name: 'Hôpital', cost: 89000,
      revenuePerCycle: 178, revenueCycleMinutes: 240, constructionTimeSeconds: 70, width: 6, height: 4,
      happinessBonus: 0.30, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFDEB887), spritePath: 'assets/building/activity/activity_5.png',
    ),
    BuildingType.activity6: BuildingConfig(
      type: BuildingType.activity6, name: 'Pompiers', cost: 150000,
      revenuePerCycle: 300, revenueCycleMinutes: 240, constructionTimeSeconds: 80, width: 6, height: 4,
      happinessBonus: 0.18, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFF4A460), spritePath: 'assets/building/activity/activity_6.png',
    ),
    BuildingType.activity7: BuildingConfig(
      type: BuildingType.activity7, name: 'Electricité', cost: 350000,
      revenuePerCycle: 700, revenueCycleMinutes: 240, constructionTimeSeconds: 90, width: 6, height: 3,
      happinessBonus: 0.35, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFD2B48C), spritePath: 'assets/building/activity/activity_7.png',
    ),
    BuildingType.activity8: BuildingConfig(
      type: BuildingType.activity8, name: 'Service Eau', cost: 450000,
      revenuePerCycle: 900, revenueCycleMinutes: 240, constructionTimeSeconds: 90, width: 6, height: 3,
      happinessBonus: 0.35, category: BuildingCategory.industrial, unlockLevel: 1,
      color: Color(0xFFD2B48C), spritePath: 'assets/building/activity/activity_8.png',
    ),

    // ==================== DECORATIONS (6) - No revenue ====================
    BuildingType.decoration1: BuildingConfig(
      type: BuildingType.decoration1, name: 'Jardin', cost: 500,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 3, height: 2,
      happinessBonus: 0.05, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF228B22), spritePath: 'assets/building/decoration/decoration_1.png',
    ),
    BuildingType.decoration2: BuildingConfig(
      type: BuildingType.decoration2, name: 'Parc', cost: 1000,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 3, height: 2,
      happinessBonus: 0.10, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF32CD32), spritePath: 'assets/building/decoration/decoration_2.png',
    ),
    BuildingType.decoration3: BuildingConfig(
      type: BuildingType.decoration3, name: 'Grand Parc', cost: 2000,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 6, height: 3,
      happinessBonus: 0.15, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF00FF00), spritePath: 'assets/building/decoration/decoration_3.png',
    ),
    BuildingType.decoration4: BuildingConfig(
      type: BuildingType.decoration4, name: 'Fontaine', cost: 3000,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 6, height: 3,
      happinessBonus: 0.20, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF00CED1), spritePath: 'assets/building/decoration/decoration_4.png',
    ),
    BuildingType.decoration5: BuildingConfig(
      type: BuildingType.decoration5, name: 'Place', cost: 5000,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 5, height: 4,
      happinessBonus: 0.25, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF20B2AA), spritePath: 'assets/building/decoration/decoration_5.png',
    ),
    BuildingType.decoration6: BuildingConfig(
      type: BuildingType.decoration6, name: 'Grand Jardin', cost: 8000,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 4, height: 3,
      happinessBonus: 0.35, category: BuildingCategory.decoration, unlockLevel: 1,
      color: Color(0xFF3CB371), spritePath: 'assets/building/decoration/decoration_6.png',
    ),

    // ==================== MONUMENTS (8) - cycle = 480min, revenue = cost * 0.004 ====================
    BuildingType.monument1: BuildingConfig(
      type: BuildingType.monument1, name: 'Obelisque', cost: 100000,
      revenuePerCycle: 400, revenueCycleMinutes: 480, constructionTimeSeconds: 180, width: 3, height: 3,
      happinessBonus: 0.30, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFFAF0E6), spritePath: 'assets/building/monument/monument_1.png',
    ),
    BuildingType.monument2: BuildingConfig(
      type: BuildingType.monument2, name: 'Statue', cost: 500000,
      revenuePerCycle: 2000, revenueCycleMinutes: 480, constructionTimeSeconds: 300, width: 3, height: 3,
      happinessBonus: 0.40, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFFFEFD5), spritePath: 'assets/building/monument/monument_2.png',
    ),
    BuildingType.monument3: BuildingConfig(
      type: BuildingType.monument3, name: 'Colonne', cost: 1000000,
      revenuePerCycle: 4000, revenueCycleMinutes: 480, constructionTimeSeconds: 420, width: 3, height: 6,
      happinessBonus: 0.50, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFFFF8DC), spritePath: 'assets/building/monument/monument_3.png',
    ),
    BuildingType.monument4: BuildingConfig(
      type: BuildingType.monument4, name: 'Memorial', cost: 2000000,
      revenuePerCycle: 8000, revenueCycleMinutes: 480, constructionTimeSeconds: 540, width: 6, height: 6,
      happinessBonus: 0.60, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFFFFFE0), spritePath: 'assets/building/monument/monument_4.png',
    ),
    BuildingType.arcDeTriomphe: BuildingConfig(
      type: BuildingType.arcDeTriomphe, name: 'Arc de Triomphe', cost: 3500000,
      revenuePerCycle: 14000, revenueCycleMinutes: 480, constructionTimeSeconds: 720, width: 6, height: 6,
      happinessBonus: 0.70, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFD2B48C), spritePath: 'assets/building/monument/arc_de_triomphe.png',
    ),
    BuildingType.bigBen: BuildingConfig(
      type: BuildingType.bigBen, name: 'Big Ben', cost: 5000000,
      revenuePerCycle: 20000, revenueCycleMinutes: 480, constructionTimeSeconds: 900, width: 6, height: 9,
      happinessBonus: 0.80, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFDEB887), spritePath: 'assets/building/monument/london_clock.png',
    ),
    BuildingType.tourEiffel: BuildingConfig(
      type: BuildingType.tourEiffel, name: 'Tour Eiffel', cost: 7500000,
      revenuePerCycle: 30000, revenueCycleMinutes: 480, constructionTimeSeconds: 1200, width: 9, height: 9,
      happinessBonus: 0.90, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFFB87333), spritePath: 'assets/building/monument/tour_effeil.png',
    ),
    BuildingType.statueLiberte: BuildingConfig(
      type: BuildingType.statueLiberte, name: 'Statue de la Liberte', cost: 10000000,
      revenuePerCycle: 40000, revenueCycleMinutes: 480, constructionTimeSeconds: 1500, width: 9, height: 9,
      happinessBonus: 1.00, category: BuildingCategory.monument, unlockLevel: 1,
      color: Color(0xFF20B2AA), spritePath: 'assets/building/monument/statut_liberte.png',
    ),

    // ==================== ROUTES (8) - No revenue ====================
    BuildingType.route1: BuildingConfig(
      type: BuildingType.route1, name: 'Route 1', cost: 50,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 1, height: 3,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFF696969), spritePath: 'assets/building/route/route_1.png',
    ),
    BuildingType.route2: BuildingConfig(
      type: BuildingType.route2, name: 'Route 2', cost: 100,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 3, height: 1,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFF808080), spritePath: 'assets/building/route/route_2.png',
    ),
    BuildingType.route5: BuildingConfig(
      type: BuildingType.route5, name: 'Route 1/1', cost: 100,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 1, height: 1,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFF808080), spritePath: 'assets/building/route/route_1_1.png',
    ),
    BuildingType.route6: BuildingConfig(
      type: BuildingType.route5, name: 'Route 2/1', cost: 100,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 1, height: 1,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFF808080), spritePath: 'assets/building/route/route_2_1.png',
    ),
    BuildingType.route7: BuildingConfig(
      type: BuildingType.route7, name: 'Route 1/2', cost: 100,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 1, height: 2,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFF808080), spritePath: 'assets/building/route/route_1_2.png',
    ),
    BuildingType.route8: BuildingConfig(
      type: BuildingType.route8, name: 'Route 2/2', cost: 100,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 2, height: 1,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFF808080), spritePath: 'assets/building/route/route_2_2.png',
    ),
    BuildingType.route3: BuildingConfig(
      type: BuildingType.route3, name: 'Herbe', cost: 150,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 1, height: 1,
      category: BuildingCategory.infrastructure, unlockLevel: 1,
      color: Color(0xFFA9A9A9), spritePath: 'assets/building/route/route_3.png',
    ),
    BuildingType.route4: BuildingConfig(
      type: BuildingType.route4, name: 'Terre', cost: 200,
      revenuePerCycle: 0, revenueCycleMinutes: 0, constructionTimeSeconds: 0, width: 1, height: 1,
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

  // Move mode indicator colors
  static const Color moveValidBg = Color(0x4000FF00);
  static const Color moveValidBorder = Color(0xFF00FF00);
  static const Color moveInvalidBg = Color(0x40FF0000);
  static const Color moveInvalidBorder = Color(0xFFFF0000);
  static const Color movePulseHalo = Color(0xFF4DA6FF);
}
