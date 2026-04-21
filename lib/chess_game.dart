import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'chess_ai.dart';
import 'chess_controller.dart';
import 'chess_logic.dart';
import 'ad_helper.dart';
import 'widgets/board_widget.dart';
import 'widgets/captured_pieces.dart';
import 'widgets/move_history.dart';
import 'widgets/banner_ad_widget.dart';
import 'widgets/promotion_dialog.dart';

class ChessGameScreen extends StatefulWidget {
  final GameMode gameMode;
  final AIDifficulty aiDifficulty;
  final PieceColor playerColor;

  const ChessGameScreen({
    super.key,
    this.gameMode = GameMode.twoPlayer,
    this.aiDifficulty = AIDifficulty.medium,
    this.playerColor = PieceColor.white,
  });

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}


class _ChessGameScreenState extends State<ChessGameScreen> {
  late ChessController _controller;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _rewardedAdReady = false;

  @override
  void initState() {
    super.initState();
    _controller = ChessController(
      gameMode: widget.gameMode,
      aiDifficulty: widget.aiDifficulty,
      playerColor: widget.playerColor,
    );
    _controller.addListener(_onStateChange);
    _loadInterstitialAd();
    _loadRewardedAd();
  }


  // ── Ads ───────────────────────────────────────────────────────────────────
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (e) => debugPrint('Interstitial failed: $e'),
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { _rewardedAd = ad; setState(() => _rewardedAdReady = true); },
        onAdFailedToLoad: (e) => debugPrint('Rewarded failed: $e'),
      ),
    );
  }

  void _showInterstitial({VoidCallback? onDone}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose(); _interstitialAd = null;
          _loadInterstitialAd(); onDone?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose(); _interstitialAd = null; onDone?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      onDone?.call();
    }
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ad not ready yet, try again shortly.'),
        backgroundColor: Color(0xFF2A2A2A),
      ));
      return;
    }
    _rewardedAd!.show(onUserEarnedReward: (_, __) => _showHint());
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose(); _rewardedAd = null;
        setState(() => _rewardedAdReady = false);
        _loadRewardedAd();
      },
    );
  }

  void _showHint() {
    int total = 0;
    final board = _controller.board;
    final turn  = _controller.currentTurn;
    for (int r = 0; r < 8; r++)
      for (int c = 0; c < 8; c++)
        if (board[r][c]?.color == turn)
          total += ChessLogic.getLegalMoves(board, Position(r, c), null, {}).length;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFF1E1E1E),
      behavior: SnackBarBehavior.floating,   // ← floats above banner
      margin: const EdgeInsets.only(
        bottom: 70,    // ← pushes above banner ad height (50) + safe area
        left: 12,
        right: 12,
      ),
      content: Row(children: [
        const Text('♟ ', style: TextStyle(fontSize: 18)),
        Text(
          '${turn == PieceColor.white ? "White" : "Black"} has $total possible moves.',
          style: const TextStyle(color: Color(0xFFC8A96E)),
        ),
      ]),
    ));
  }

  // ── State change ──────────────────────────────────────────────────────────
  void _onStateChange() {
    setState(() {});
    if (_controller.isGameOver) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _showInterstitial(onDone: _showGameOverDialog);
      });
    }
    if (_controller.awaitingPromotion) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _showPromotionDialog();
      });
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameOverDialog(
        controller: _controller,
        onNewGame: () { Navigator.pop(context); _controller.resetGame(); },
      ),
    );
  }

  void _showPromotionDialog() {
    final color = _controller.currentTurn == PieceColor.white
        ? PieceColor.black : PieceColor.white;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PromotionDialog(
        color: color,
        onSelect: (type) { Navigator.pop(context); _controller.promotePawn(type); },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width >
        MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('♟  CHESS', style: TextStyle(
          fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold,
          color: Color(0xFFC8A96E), letterSpacing: 6,
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline,
                color: _rewardedAdReady ? const Color(0xFFC8A96E) : Colors.white24),
            onPressed: _rewardedAdReady ? _showRewardedAd : null,
            tooltip: 'Watch ad for hint',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC8A96E)),
            onPressed: _confirmNewGame,
            tooltip: 'New Game',
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Column(children: [
        Expanded(child: isLandscape ? _buildLandscape() : _buildPortrait()),
        SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,       // ← pushes banner above nav bar
          child: const BannerAdWidget(),
        ),
      ]),
    );
  }

  Widget _buildPortrait() {
    return Column(children: [
      _PlayerBar(color: PieceColor.black, controller: _controller, isBottom: false),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: BoardWidget(controller: _controller),
          ),
        ),
      ),
      _PlayerBar(color: PieceColor.white, controller: _controller, isBottom: true),
      Container(
        height: 52,
        color: const Color(0xFF161616),
        child: MoveHistoryBar(moves: _controller.moveHistory),
      ),
    ]);
  }

  Widget _buildLandscape() {
    return Row(children: [
      SizedBox(
        width: 140,
        child: Column(children: [
          _PlayerTile(color: PieceColor.black, controller: _controller),
          Expanded(child: MoveHistoryPanel(moves: _controller.moveHistory)),
          _PlayerTile(color: PieceColor.white, controller: _controller),
        ]),
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: BoardWidget(controller: _controller),
          ),
        ),
      ),
      SizedBox(width: 110, child: _StatusPanel(controller: _controller)),
    ]);
  }

  void _confirmNewGame() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Game?', style: TextStyle(color: Color(0xFFC8A96E))),
        content: const Text('Current game will be lost.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8A96E)),
            onPressed: () { Navigator.pop(context); _controller.resetGame(); },
            child: const Text('New Game', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}

// ── Player Bar ────────────────────────────────────────────────────────────────
class _PlayerBar extends StatelessWidget {
  final PieceColor color;
  final ChessController controller;
  final bool isBottom;
  const _PlayerBar({required this.color, required this.controller, required this.isBottom});

  @override
  Widget build(BuildContext context) {
    final isActive = controller.currentTurn == color && !controller.isGameOver;
    final captured = color == PieceColor.white
        ? controller.capturedByBlack : controller.capturedByWhite;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border(
          top:    isBottom  ? const BorderSide(color: Color(0xFF2A2A2A)) : BorderSide.none,
          bottom: !isBottom ? const BorderSide(color: Color(0xFF2A2A2A)) : BorderSide.none,
        ),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color == PieceColor.white
                ? const Color(0xFFF0D9B5) : const Color(0xFF1A1A1A),
            border: Border.all(
              color: isActive ? const Color(0xFFC8A96E) : const Color(0xFF444),
              width: isActive ? 2.5 : 1.5,
            ),
            boxShadow: isActive ? [
              BoxShadow(color: const Color(0xFFC8A96E).withOpacity(0.4), blurRadius: 8),
            ] : null,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          color == PieceColor.white ? 'WHITE' : 'BLACK',
          style: TextStyle(
            fontFamily: 'serif', fontSize: 13,
            fontWeight: FontWeight.bold, letterSpacing: 2,
            color: isActive ? const Color(0xFFC8A96E) : Colors.white54,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: CapturedPiecesWidget(pieces: captured, small: true)),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC8A96E).withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              controller.isCheck ? 'CHECK!' : 'TURN',
              style: TextStyle(
                fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold,
                color: controller.isCheck
                    ? const Color(0xFFE05050) : const Color(0xFFC8A96E),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Player Tile (landscape) ───────────────────────────────────────────────────
class _PlayerTile extends StatelessWidget {
  final PieceColor color;
  final ChessController controller;
  const _PlayerTile({required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isActive = controller.currentTurn == color && !controller.isGameOver;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border(bottom: BorderSide(
          color: isActive ? const Color(0xFFC8A96E) : const Color(0xFF2A2A2A),
          width: isActive ? 2 : 1,
        )),
      ),
      child: Row(children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color == PieceColor.white
                ? const Color(0xFFF0D9B5) : const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFF666), width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          color == PieceColor.white ? 'WHITE' : 'BLACK',
          style: TextStyle(
            fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFFC8A96E) : Colors.white54,
          ),
        ),
      ]),
    );
  }
}

// ── Status Panel (landscape) ──────────────────────────────────────────────────
class _StatusPanel extends StatelessWidget {
  final ChessController controller;
  const _StatusPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          controller.statusText.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11, letterSpacing: 1.5,
            color: Color(0xFFC8A96E), fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Move ${(controller.moveHistory.length / 2).ceil()}',
          style: const TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: 1),
        ),
      ]),
    );
  }
}

// ── Game Over Dialog ──────────────────────────────────────────────────────────
class _GameOverDialog extends StatelessWidget {
  final ChessController controller;
  final VoidCallback onNewGame;
  const _GameOverDialog({required this.controller, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    final title    = controller.isCheckmate ? '♚  CHECKMATE' : '⚖  STALEMATE';
    final subtitle = controller.isCheckmate
        ? '${controller.currentTurn == PieceColor.white ? "Black" : "White"} wins!'
        : 'The game is a draw.';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC8A96E).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8A96E).withOpacity(0.15),
              blurRadius: 40, spreadRadius: 5,
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(
            fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold,
            color: Color(0xFFC8A96E), letterSpacing: 4,
          )),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(
              fontSize: 16, color: Colors.white70, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            '${(controller.moveHistory.length / 2).ceil()} moves played',
            style: const TextStyle(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8A96E),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onNewGame,
              child: const Text('PLAY AGAIN', style: TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 14,
              )),
            ),
          ),
        ]),
      ),
    );
  }
}
