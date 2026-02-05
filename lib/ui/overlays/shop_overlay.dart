import 'package:flutter/material.dart';
import '../../game/data/game_state.dart';
import '../../models/shop_model.dart';
import '../../utils/helpers.dart';

/// Shop overlay for premium content
class ShopOverlay extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onClose;
  final void Function(ShopPack pack) onPackPurchased;

  const ShopOverlay({
    super.key,
    required this.gameState,
    required this.onClose,
    required this.onPackPurchased,
  });

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _close() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onClose();
    }
  }

  void _purchasePack(ShopPack pack) {
    if (!mounted) return;

    final canAffordGems = widget.gameState.player.canAffordGems(pack.priceGems);
    final canAffordMoney = pack.priceMoney != null &&
        widget.gameState.player.canAfford(pack.priceMoney!);

    if (!canAffordGems && !canAffordMoney) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade300),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Pas assez de gemmes ou d\'argent!'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show purchase dialog
    _showPurchaseDialog(pack, canAffordGems, canAffordMoney);
  }

  void _showPurchaseDialog(
      ShopPack pack, bool canAffordGems, bool canAffordMoney) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: pack.accentColor.withValues(alpha: 0.5)),
        ),
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: pack.accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Acheter ${pack.name}?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pack.description,
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Contient ${pack.buildingCount} monument(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (canAffordGems)
              _buildPaymentOption(
                icon: Icons.diamond,
                color: Colors.cyan,
                label: '${pack.priceGems} Gemmes',
                onTap: () {
                  Navigator.pop(context);
                  _confirmPurchase(pack, CurrencyType.gems);
                },
              ),
            if (canAffordMoney && pack.priceMoney != null) ...[
              const SizedBox(height: 8),
              _buildPaymentOption(
                icon: Icons.euro,
                color: Colors.amber,
                label: pack.priceMoney!.toCurrency(),
                onTap: () {
                  Navigator.pop(context);
                  _confirmPurchase(pack, CurrencyType.money);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPurchase(ShopPack pack, CurrencyType currency) {
    bool success = false;

    if (currency == CurrencyType.gems) {
      success = widget.gameState.player.trySpendGems(pack.priceGems);
    } else if (pack.priceMoney != null) {
      success = widget.gameState.player.trySpend(pack.priceMoney!);
    }

    if (success) {
      // Use post frame callback to avoid build issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onPackPurchased(pack);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.celebration, color: pack.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${pack.name} achete avec succes!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildTabs(),
                      Flexible(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPacksTab(),
                            _buildGemsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade800,
            Colors.orange.shade700,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Boutique Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Gems display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyan, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${widget.gameState.player.gems}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.grey.shade800,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.amber,
        labelColor: Colors.amber,
        unselectedLabelColor: Colors.grey.shade400,
        tabs: const [
          Tab(
            icon: Icon(Icons.card_giftcard),
            text: 'Packs',
          ),
          Tab(
            icon: Icon(Icons.diamond),
            text: 'Gemmes',
          ),
        ],
      ),
    );
  }

  Widget _buildPacksTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ShopData.monumentPacks.length,
      itemBuilder: (context, index) {
        final pack = ShopData.monumentPacks[index];
        return _PackCard(
          pack: pack,
          canAffordGems: widget.gameState.player.canAffordGems(pack.priceGems),
          canAffordMoney: pack.priceMoney != null &&
              widget.gameState.player.canAfford(pack.priceMoney!),
          onPurchase: () => _purchasePack(pack),
        );
      },
    );
  }

  Widget _buildGemsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ShopData.gemOffers.length,
      itemBuilder: (context, index) {
        final offer = ShopData.gemOffers[index];
        return _GemOfferCard(offer: offer);
      },
    );
  }
}

class _PackCard extends StatelessWidget {
  final ShopPack pack;
  final bool canAffordGems;
  final bool canAffordMoney;
  final VoidCallback onPurchase;

  const _PackCard({
    required this.pack,
    required this.canAffordGems,
    required this.canAffordMoney,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = canAffordGems || canAffordMoney;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pack.accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: pack.accentColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with rarity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  pack.accentColor.withValues(alpha: 0.3),
                  pack.accentColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pack.rarityColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: pack.rarityColor),
                  ),
                  child: Text(
                    pack.rarityName,
                    style: TextStyle(
                      color: pack.rarityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (pack.isLimited)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.timer, color: Colors.red, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'LIMITE',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        pack.accentColor,
                        pack.accentColor.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: pack.accentColor.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pack.description,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.account_balance,
                              color: pack.accentColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${pack.buildingCount} monument(s)',
                            style: TextStyle(
                              color: pack.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price & Buy button
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.diamond, color: Colors.cyan, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${pack.priceGems}',
                          style: TextStyle(
                            color: canAffordGems ? Colors.cyan : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (pack.priceMoney != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ou ${pack.priceMoney!.toCurrency()}',
                        style: TextStyle(
                          color:
                              canAffordMoney ? Colors.amber : Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: canAfford ? onPurchase : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canAfford ? pack.accentColor : Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Acheter',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GemOfferCard extends StatelessWidget {
  final ShopOffer offer;

  const _GemOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            offer.color.withValues(alpha: 0.2),
            Colors.grey.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: offer.color.withValues(alpha: 0.5),
          width: offer.isBestValue ? 3 : 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gem icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.cyan,
                        Colors.cyan.withValues(alpha: 0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: TextStyle(
                          color: offer.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${offer.gems}',
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (offer.bonusGems > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${offer.bonusGems}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          const Icon(Icons.diamond,
                              color: Colors.cyan, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Achats in-app non disponibles (demo)'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: offer.color,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '${offer.priceEuros.toStringAsFixed(2)} EUR',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Best value badge
          if (offer.isBestValue)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'MEILLEURE OFFRE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
