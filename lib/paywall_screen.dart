import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'billing_service.dart';

const Color _kGold = Color(0xFFC8A96E);
const Color _kGoldBright = Color(0xFFE6C488);
const Color _kBg = Color(0xFF0A0A0A);
const Color _kSurface = Color(0xFF161616);
const Color _kSurfaceMuted = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _ctaCtrl;
  late final Animation<double> _ctaPulse;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    _ctaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _ctaPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _ctaCtrl.dispose();
    super.dispose();
  }

  void _close() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final billing = BillingService.instance;
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _ChessboardBackdrop()),
          const Positioned.fill(child: _GoldGlow()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _TopBar(onClose: _close, onRestore: billing.restorePurchases),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            _Hero(),
                            SizedBox(height: 28),
                            _FeatureList(),
                            SizedBox(height: 22),
                            _PuzzleCallout(),
                            SizedBox(height: 22),
                            _ComparisonCard(),
                            SizedBox(height: 22),
                            _PriceBlock(),
                          ],
                        ),
                      ),
                    ),
                    _BottomCta(pulse: _ctaPulse, onClose: _close),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F1F1F), Color(0xFF111111)],
            ),
            border: Border.all(color: _kGold.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _kGold.withOpacity(0.25),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text('♛', style: TextStyle(fontSize: 46, color: _kGold)),
          ),
        ),
        const SizedBox(height: 20),
        const _GoldPill(text: 'PREMIUM UPGRADE'),
        const SizedBox(height: 14),
        const Text(
          'Upgrade Your Chess\nExperience  ♟️',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 28,
            height: 1.18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Play smarter, improve faster, and enjoy chess without limits.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kGold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kGold.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 3,
          fontWeight: FontWeight.bold,
          color: _kGold,
        ),
      ),
    );
  }
}

// ─── Feature list ────────────────────────────────────────────────────────────

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    const features = <_Feature>[
      _Feature(icon: '🚫', title: 'Remove all ads',
          subtitle: 'Zero interruptions, zero distractions'),
      _Feature(icon: '♟️', title: 'Unlock Medium AI',
          subtitle: 'A balanced challenge to sharpen your play', locked: true),
      _Feature(icon: '♛', title: 'Unlock Hard AI',
          subtitle: 'Aggressive engine that punishes mistakes', locked: true),
      _Feature(icon: '🧠', title: 'Access Chess Puzzles',
          subtitle: 'Tactics, mates and endgames — every day', locked: true),
      _Feature(icon: '⚡', title: 'Smooth, uninterrupted gameplay',
          subtitle: 'Faster boards, instant transitions'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            _FeatureRow(feature: features[i]),
            if (i != features.length - 1)
              const Divider(height: 1, color: _kBorder),
          ],
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.locked = false,
  });
  final String icon;
  final String title;
  final String subtitle;
  final bool locked;
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kSurfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            alignment: Alignment.center,
            child: Text(feature.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (feature.locked)
            const Icon(Icons.lock_rounded, size: 16, color: _kGold)
          else
            Icon(Icons.check_rounded, size: 18, color: _kGold.withOpacity(0.85)),
        ],
      ),
    );
  }
}

// ─── Puzzle callout ──────────────────────────────────────────────────────────

class _PuzzleCallout extends StatelessWidget {
  const _PuzzleCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kGold.withOpacity(0.10),
            _kSurface,
          ],
        ),
        border: Border.all(color: _kGold.withOpacity(0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withOpacity(0.35)),
            ),
            alignment: Alignment.center,
            child: const Text('🧠', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Train Your Brain',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kGold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('💡', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Train your brain with chess puzzles designed to improve '
                  'tactics, checkmates and strategy.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comparison ──────────────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'WHAT YOU GET',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.5,
                fontWeight: FontWeight.bold,
                color: Colors.white38,
              ),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(
                  child: _ComparisonColumn(
                    title: 'FREE',
                    accent: Colors.white54,
                    items: [
                      _CompareItem('Easy mode only', false),
                      _CompareItem('3 puzzles per day', false),
                      _CompareItem('Ads enabled', false),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: _kBorder),
                Expanded(
                  child: _ComparisonColumn(
                    title: 'PREMIUM',
                    accent: _kGold,
                    items: [
                      _CompareItem('No ads', true),
                      _CompareItem('Medium + Hard AI', true),
                      _CompareItem('Unlimited puzzles', true),
                      _CompareItem('Full experience', true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  const _ComparisonColumn({
    required this.title,
    required this.accent,
    required this.items,
  });

  final String title;
  final Color accent;
  final List<_CompareItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: accent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.included ? Icons.check_rounded : Icons.close_rounded,
                  size: 14,
                  color: item.included ? _kGold : Colors.white24,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: item.included
                          ? Colors.white.withOpacity(0.85)
                          : Colors.white.withOpacity(0.45),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _CompareItem {
  const _CompareItem(this.label, this.included);
  final String label;
  final bool included;
}

// ─── Price ───────────────────────────────────────────────────────────────────

class _PriceBlock extends StatelessWidget {
  const _PriceBlock();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProductDetails?>(
      valueListenable: BillingService.instance.product,
      builder: (context, product, _) {
        final priceText = product?.price ?? '₹99';
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF181513), Color(0xFF0F0F0F)],
            ),
            border: Border.all(color: _kGold.withOpacity(0.35)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 48,
                      height: 1,
                      fontWeight: FontWeight.bold,
                      color: _kGoldBright,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'one-time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pay once, unlock forever',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onRestore});
  final VoidCallback onClose;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          _IconButton(icon: Icons.close_rounded, onTap: onClose),
          const Spacer(),
          GestureDetector(
            onTap: onRestore,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Restore',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _kSurface,
          shape: BoxShape.circle,
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.8)),
      ),
    );
  }
}

// ─── Bottom CTA ──────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.pulse, required this.onClose});
  final Animation<double> pulse;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final billing = BillingService.instance;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kGold.withOpacity(0.18 * pulse.value),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: ValueListenableBuilder<bool>(
              valueListenable: billing.isPurchasing,
              builder: (context, busy, _) {
                return ValueListenableBuilder<ProductDetails?>(
                  valueListenable: billing.product,
                  builder: (context, product, __) {
                    final label = product != null
                        ? 'Unlock for ${product.price}'
                        : 'Unlock for ₹99';
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGold,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: _kGold.withOpacity(0.6),
                          disabledForegroundColor: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: busy ? null : billing.buyPremium,
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_open_rounded, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded,
                  size: 13, color: Colors.white.withOpacity(0.45)),
              const SizedBox(width: 6),
              Text(
                'Secure payment via Google Play',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.5,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Continue with Free Version',
                style: TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withOpacity(0.25),
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background ──────────────────────────────────────────────────────────────

class _ChessboardBackdrop extends StatelessWidget {
  const _ChessboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.06,
        child: CustomPaint(painter: _BoardPainter()),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cells = 10;
    final cell = size.width / cells;
    final rows = (size.height / cell).ceil() + 1;
    final paint = Paint()..color = _kGold;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cells; c++) {
        if ((r + c).isEven) continue;
        canvas.drawRect(
          Rect.fromLTWH(c * cell, r * cell, cell, cell),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoldGlow extends StatelessWidget {
  const _GoldGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.85),
            radius: 0.9,
            colors: [
              _kGold.withOpacity(0.18),
              _kGold.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}
