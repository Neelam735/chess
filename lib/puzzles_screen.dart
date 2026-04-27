import 'package:flutter/material.dart';

import 'billing_service.dart';
import 'chess_logic.dart';
import 'entitlement_service.dart';
import 'paywall_screen.dart';
import 'puzzle_data.dart';

const Color _kGold = Color(0xFFC8A96E);
const Color _kBg = Color(0xFF0A0A0A);
const Color _kSurface = Color(0xFF161616);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kLight = Color(0xFFE6D2A6);
const Color _kDark = Color(0xFF7A5C3A);

// ─── List screen ─────────────────────────────────────────────────────────────

class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  late final Future<_PuzzleData> _data;

  @override
  void initState() {
    super.initState();
    _data = _PuzzleData.load();
  }

  void _openPaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  void _openPuzzle(ChessPuzzle puzzle) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PuzzleSolveScreen(puzzle: puzzle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: const Text(
          'Daily Puzzles',
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            color: _kGold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: FutureBuilder<_PuzzleData>(
        future: _data,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _kGold),
            );
          }
          return _PuzzlesBody(
            data: snap.data!,
            onOpenPaywall: _openPaywall,
            onOpenPuzzle: _openPuzzle,
          );
        },
      ),
    );
  }
}

class _PuzzleData {
  _PuzzleData({required this.all, required this.todayIndex});
  final List<ChessPuzzle> all;
  final int todayIndex;

  ChessPuzzle get today => all[todayIndex];

  static Future<_PuzzleData> load() async {
    final repo = PuzzleRepository.instance;
    final all = await repo.all();
    final idx = await repo.todaysIndex();
    return _PuzzleData(all: all, todayIndex: idx);
  }
}

class _PuzzlesBody extends StatelessWidget {
  const _PuzzlesBody({
    required this.data,
    required this.onOpenPaywall,
    required this.onOpenPuzzle,
  });

  final _PuzzleData data;
  final VoidCallback onOpenPaywall;
  final void Function(ChessPuzzle) onOpenPuzzle;

  @override
  Widget build(BuildContext context) {
    final ent = EntitlementService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: BillingService.instance.isPremium,
      builder: (context, premium, _) {
        return ValueListenableBuilder<int>(
          valueListenable: ent.puzzlesSolvedToday,
          builder: (context, solvedToday, __) {
            final dailyDone =
                solvedToday >= EntitlementService.freeDailyPuzzleLimit;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _TierBanner(
                  premium: premium,
                  totalPuzzles: data.all.length,
                  onUpgrade: onOpenPaywall,
                ),
                const SizedBox(height: 18),
                _TodayHeroCard(
                  puzzle: data.today,
                  dayNumber: data.todayIndex + 1,
                  solved: dailyDone,
                  onTap: () {
                    if (!premium && dailyDone) {
                      onOpenPaywall();
                    } else {
                      onOpenPuzzle(data.today);
                    }
                  },
                ),
                const SizedBox(height: 22),
                if (premium)
                  _ArchiveList(
                    all: data.all,
                    todayIndex: data.todayIndex,
                    onOpen: onOpenPuzzle,
                  )
                else
                  _ArchiveTeaser(
                    total: data.all.length,
                    onUpgrade: onOpenPaywall,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Tier banner ─────────────────────────────────────────────────────────────

class _TierBanner extends StatelessWidget {
  const _TierBanner({
    required this.premium,
    required this.totalPuzzles,
    required this.onUpgrade,
  });

  final bool premium;
  final int totalPuzzles;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _kSurface,
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGold.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: const Text('🧠', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premium ? 'Premium · Full archive unlocked' : 'Free · 1 puzzle a day',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  premium
                      ? '$totalPuzzles puzzles a year — solve in any order.'
                      : 'Premium unlocks all $totalPuzzles puzzles for the year.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (!premium) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onUpgrade,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _kGold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'UPGRADE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Today hero ──────────────────────────────────────────────────────────────

class _TodayHeroCard extends StatelessWidget {
  const _TodayHeroCard({
    required this.puzzle,
    required this.dayNumber,
    required this.solved,
    required this.onTap,
  });

  final ChessPuzzle puzzle;
  final int dayNumber;
  final bool solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1612), Color(0xFF0F0F0F)],
          ),
          border: Border.all(color: _kGold.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: _kGold.withOpacity(0.12),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    "TODAY'S PUZZLE",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.8,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Day $dayNumber',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniBoardThumb(puzzle: puzzle, size: 96),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        puzzle.title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        puzzle.objective,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Pill(text: puzzle.difficulty.toUpperCase()),
                          _Pill(text: puzzle.theme.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      solved ? Icons.check_rounded : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      solved ? 'Replay Today' : 'Solve Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kGold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kGold.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: _kGold,
        ),
      ),
    );
  }
}

// ─── Archive (premium) ───────────────────────────────────────────────────────

class _ArchiveList extends StatelessWidget {
  const _ArchiveList({
    required this.all,
    required this.todayIndex,
    required this.onOpen,
  });

  final List<ChessPuzzle> all;
  final int todayIndex;
  final void Function(ChessPuzzle) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'FULL ARCHIVE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
        ),
        for (var i = 0; i < all.length; i++) ...[
          _ArchiveTile(
            index: i,
            puzzle: all[i],
            isToday: i == todayIndex,
            onTap: () => onOpen(all[i]),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
    required this.index,
    required this.puzzle,
    required this.isToday,
    required this.onTap,
  });

  final int index;
  final ChessPuzzle puzzle;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday ? _kGold.withOpacity(0.5) : _kBorder,
          ),
        ),
        child: Row(
          children: [
            _MiniBoardThumb(puzzle: puzzle, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Day ${index + 1} · ${puzzle.title}',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${puzzle.difficulty} · ${puzzle.theme}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _kGold),
          ],
        ),
      ),
    );
  }
}

// ─── Archive teaser (free) ───────────────────────────────────────────────────

class _ArchiveTeaser extends StatelessWidget {
  const _ArchiveTeaser({required this.total, required this.onUpgrade});
  final int total;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpgrade,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kGold.withOpacity(0.10), _kSurface],
          ),
          border: Border.all(color: _kGold.withOpacity(0.30)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_rounded, color: _kGold, size: 22),
            const SizedBox(height: 8),
            const Text(
              'Full Puzzle Archive',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Unlock all $total puzzles for the year — solve at your own pace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _kGold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'UPGRADE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini board thumbnail ────────────────────────────────────────────────────

class _MiniBoardThumb extends StatelessWidget {
  const _MiniBoardThumb({required this.puzzle, this.size = 64});
  final ChessPuzzle puzzle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(painter: _MiniBoardPainter(puzzle.buildBoard())),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  _MiniBoardPainter(this.board);
  final List<List<ChessPiece?>> board;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final lightPaint = Paint()..color = _kLight;
    final darkPaint = Paint()..color = _kDark;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final isLight = (r + c).isEven;
        canvas.drawRect(
          Rect.fromLTWH(c * cell, r * cell, cell, cell),
          isLight ? lightPaint : darkPaint,
        );
        final piece = board[r][c];
        if (piece != null) {
          final tp = TextPainter(
            text: TextSpan(
              text: piece.symbol,
              style: TextStyle(
                fontSize: cell * 0.75,
                color: piece.color == PieceColor.white ? Colors.white : Colors.black,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            Offset(
              c * cell + (cell - tp.width) / 2,
              r * cell + (cell - tp.height) / 2,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Solve screen ────────────────────────────────────────────────────────────

class PuzzleSolveScreen extends StatefulWidget {
  const PuzzleSolveScreen({super.key, required this.puzzle});
  final ChessPuzzle puzzle;

  @override
  State<PuzzleSolveScreen> createState() => _PuzzleSolveScreenState();
}

enum _PuzzleStatus { thinking, success, wrong }

class _PuzzleSolveScreenState extends State<PuzzleSolveScreen> {
  late List<List<ChessPiece?>> _board;
  Position? _selected;
  _PuzzleStatus _status = _PuzzleStatus.thinking;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _board = widget.puzzle.buildBoard();
  }

  void _onSquareTap(int r, int c) {
    if (_status == _PuzzleStatus.success) return;
    final piece = _board[r][c];
    final pos = Position(r, c);
    if (_selected == null) {
      if (piece != null && piece.color == widget.puzzle.toMove) {
        setState(() => _selected = pos);
      }
      return;
    }
    if (_selected == pos) {
      setState(() => _selected = null);
      return;
    }
    final isSolution =
        _selected == widget.puzzle.solutionFromPos && pos == widget.puzzle.solutionToPos;
    if (isSolution) {
      setState(() {
        final p = _board[_selected!.row][_selected!.col];
        _board[pos.row][pos.col] = p;
        _board[_selected!.row][_selected!.col] = null;
        _selected = null;
        _status = _PuzzleStatus.success;
      });
      if (!_recorded) {
        _recorded = true;
        EntitlementService.instance.recordPuzzleSolved();
      }
    } else {
      setState(() {
        _selected = null;
        _status = _PuzzleStatus.wrong;
      });
    }
  }

  void _reset() {
    setState(() {
      _board = widget.puzzle.buildBoard();
      _selected = null;
      _status = _PuzzleStatus.thinking;
    });
  }

  void _showSolution() {
    setState(() {
      _selected = widget.puzzle.solutionFromPos;
    });
  }

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzle;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goHome();
      },
      child: _buildBody(puzzle),
    );
  }

  Widget _buildBody(ChessPuzzle puzzle) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kGold),
          tooltip: 'Home',
          onPressed: _goHome,
        ),
        title: Text(
          puzzle.title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            color: _kGold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        puzzle.objective,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: _PuzzleBoard(
                  board: _board,
                  selected: _selected,
                  hintFrom: _status == _PuzzleStatus.success ? widget.puzzle.solutionFromPos : null,
                  hintTo: _status == _PuzzleStatus.success ? widget.puzzle.solutionToPos : null,
                  onTap: _onSquareTap,
                ),
              ),
              const SizedBox(height: 16),
              _StatusBanner(status: _status),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _status == _PuzzleStatus.success
                          ? _goHome
                          : _showSolution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _status == _PuzzleStatus.success ? 'Done' : 'Show Hint',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final _PuzzleStatus status;

  @override
  Widget build(BuildContext context) {
    late final String text;
    late final Color color;
    late final IconData icon;
    switch (status) {
      case _PuzzleStatus.thinking:
        text = 'Tap your piece, then the destination square.';
        color = Colors.white54;
        icon = Icons.lightbulb_outline_rounded;
        break;
      case _PuzzleStatus.success:
        text = 'Solved! Brilliant move.';
        color = _kGold;
        icon = Icons.emoji_events_rounded;
        break;
      case _PuzzleStatus.wrong:
        text = 'Not quite. Try a different idea.';
        color = const Color(0xFFE08585);
        icon = Icons.error_outline_rounded;
        break;
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: color, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _PuzzleBoard extends StatelessWidget {
  const _PuzzleBoard({
    required this.board,
    required this.selected,
    required this.hintFrom,
    required this.hintTo,
    required this.onTap,
  });

  final List<List<ChessPiece?>> board;
  final Position? selected;
  final Position? hintFrom;
  final Position? hintTo;
  final void Function(int r, int c) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final cell = size / 8;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kGold.withOpacity(0.4), width: 1.5),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: _kGold.withOpacity(0.10),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                for (var r = 0; r < 8; r++)
                  for (var c = 0; c < 8; c++)
                    Positioned(
                      left: c * cell,
                      top: r * cell,
                      width: cell,
                      height: cell,
                      child: GestureDetector(
                        onTap: () => onTap(r, c),
                        child: _Square(
                          row: r,
                          col: c,
                          piece: board[r][c],
                          cell: cell,
                          highlighted: selected == Position(r, c) ||
                              hintFrom == Position(r, c) ||
                              hintTo == Position(r, c),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({
    required this.row,
    required this.col,
    required this.piece,
    required this.cell,
    required this.highlighted,
  });

  final int row;
  final int col;
  final ChessPiece? piece;
  final double cell;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isLight = (row + col).isEven;
    return Container(
      decoration: BoxDecoration(
        color: highlighted
            ? _kGold.withOpacity(0.55)
            : (isLight ? _kLight : _kDark),
      ),
      alignment: Alignment.center,
      child: piece == null
          ? null
          : Text(
              piece!.symbol,
              style: TextStyle(
                fontSize: cell * 0.7,
                color: piece!.color == PieceColor.white ? Colors.white : Colors.black,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0.5, 0.5),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
    );
  }
}
