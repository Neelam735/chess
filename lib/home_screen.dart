import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'billing_service.dart';
import 'chess_ai.dart';
import 'chess_controller.dart';
import 'chess_logic.dart';
import 'chess_game.dart';
import 'paywall_screen.dart';
import 'puzzles_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  AIDifficulty _selectedDifficulty = AIDifficulty.easy;
  PieceColor _selectedColor = PieceColor.white;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _startGame(GameMode mode) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChessGameScreen(
          gameMode: mode,
          aiDifficulty: _selectedDifficulty,
          playerColor: _selectedColor,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openPaywall() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => const PaywallScreen(),
        transitionsBuilder: (_, anim, __, child) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(position: offset, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _openPuzzles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PuzzlesScreen()),
    );
  }

  bool _isPremiumDifficulty(AIDifficulty d) =>
      d == AIDifficulty.medium || d == AIDifficulty.hard;

  Future<void> _onLogoLongPress() async {
    final premium = await BillingService.instance.togglePremiumDebug();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(
              premium ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
              size: 16,
              color: const Color(0xFFC8A96E),
            ),
            const SizedBox(width: 10),
            Text(
              premium ? 'DEBUG: Premium ON' : 'DEBUG: Premium OFF',
              style: const TextStyle(
                color: Color(0xFFC8A96E),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      _buildLogo(),
                      const SizedBox(height: 52),

                      // Mode buttons
                      _buildModeCard(
                        icon: '👥',
                        title: 'Two Players',
                        subtitle: 'Play against a friend on the same device',
                        onTap: () => _startGame(GameMode.twoPlayer),
                      ),
                      const SizedBox(height: 16),
                      _buildVsComputerCard(),
                      const SizedBox(height: 16),
                      _buildModeCard(
                        icon: '🧠',
                        title: 'Daily Puzzles',
                        subtitle: '1 free puzzle a day · 365 a year on Premium',
                        onTap: _openPuzzles,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 16,
                child: ValueListenableBuilder<bool>(
                  valueListenable: BillingService.instance.isPremium,
                  builder: (context, premium, _) {
                    if (premium) return const _PremiumBadge();
                    return _UpgradePill(onTap: _openPaywall);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Animated chess board icon
        GestureDetector(
          onLongPress: kDebugMode ? _onLogoLongPress : null,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              ),
              border: Border.all(color: const Color(0xFFC8A96E).withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC8A96E).withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text('♟', style: TextStyle(fontSize: 52)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CHESS',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC8A96E),
            letterSpacing: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'THE ROYAL GAME',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 5,
            color: Colors.white.withOpacity(0.3),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333)),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC8A96E), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildVsComputerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8A96E).withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8A96E).withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8A96E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8A96E).withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'vs Computer',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC8A96E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Challenge the AI engine',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2A2A2A)),
          const SizedBox(height: 16),

          // Difficulty selector
          const Text(
            'DIFFICULTY',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              color: Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<bool>(
            valueListenable: BillingService.instance.isPremium,
            builder: (context, premium, _) {
              return Row(
                children: AIDifficulty.values.map((d) {
                  final isSelected = _selectedDifficulty == d;
                  final labels = ['Easy', 'Medium', 'Hard'];
                  final icons = ['🌱', '⚡', '🔥'];
                  final idx = d.index;
                  final locked = !premium && _isPremiumDifficulty(d);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (locked) {
                          _openPaywall();
                          return;
                        }
                        setState(() => _selectedDifficulty = d);
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFC8A96E).withOpacity(0.15)
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFC8A96E)
                                : const Color(0xFF333),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Opacity(
                              opacity: locked ? 0.55 : 1,
                              child: Column(
                                children: [
                                  Text(icons[idx],
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                    labels[idx],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFFC8A96E)
                                          : Colors.white54,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (locked)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC8A96E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    size: 9,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),

          // Color selector
          const Text(
            'PLAY AS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              color: Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _colorChoice(PieceColor.white, '♔', 'White', 'Move first'),
              const SizedBox(width: 10),
              _colorChoice(PieceColor.black, '♚', 'Black', 'Move second'),
            ],
          ),
          const SizedBox(height: 20),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8A96E),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (!BillingService.instance.isPremium.value &&
                    _isPremiumDifficulty(_selectedDifficulty)) {
                  _openPaywall();
                  return;
                }
                _startGame(GameMode.vsComputer);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('START GAME', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    fontSize: 14,
                  )),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorChoice(PieceColor color, String piece, String label, String sub) {
    final isSelected = _selectedColor == color;
    final isWhite = color == PieceColor.white;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedColor = color),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isWhite
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.3))
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFC8A96E) : const Color(0xFF333),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                piece,
                style: TextStyle(
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFC8A96E) : Colors.white70,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 10, color: Colors.white30),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradePill extends StatelessWidget {
  const _UpgradePill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFC8A96E).withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFC8A96E).withOpacity(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.workspace_premium_rounded,
                size: 14, color: Color(0xFFC8A96E)),
            SizedBox(width: 6),
            Text(
              'UPGRADE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC8A96E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFC8A96E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_rounded, size: 14, color: Colors.black),
          SizedBox(width: 6),
          Text(
            'PREMIUM',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
