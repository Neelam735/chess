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

class PuzzlesScreen extends StatelessWidget {
  const PuzzlesScreen({super.key});

  void _openPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  void _openPuzzle(BuildContext context, ChessPuzzle puzzle) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PuzzleSolveScreen(puzzle: puzzle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ent = EntitlementService.instance;
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
      body: ValueListenableBuilder<bool>(
        valueListenable: BillingService.instance.isPremium,
        builder: (context, premium, _) {
          return ValueListenableBuilder<int>(
            valueListenable: ent.puzzlesSolvedToday,
            builder: (context, solved, __) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _QuotaCard(
                    premium: premium,
                    solved: solved,
                    onUpgrade: () => _openPaywall(context),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < kPuzzles.length; i++) ...[
                    _PuzzleTile(
                      index: i,
                      puzzle: kPuzzles[i],
                      locked: !premium && i >= EntitlementService.freeDailyPuzzleLimit,
                      onTap: () {
                        final locked = !premium &&
                            i >= EntitlementService.freeDailyPuzzleLimit;
                        if (locked || !ent.canSolveAnotherPuzzle) {
                          _openPaywall(context);
                        } else {
                          _openPuzzle(context, kPuzzles[i]);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({
    required this.premium,
    required this.solved,
    required this.onUpgrade,
  });

  final bool premium;
  final int solved;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final remaining = (EntitlementService.freeDailyPuzzleLimit - solved)
        .clamp(0, EntitlementService.freeDailyPuzzleLimit);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premium ? 'Unlimited puzzles' : 'Today: $solved / ${EntitlementService.freeDailyPuzzleLimit} solved',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  premium
                      ? 'Train your tactics, mates and endgames freely.'
                      : (remaining > 0
                          ? '$remaining free puzzle${remaining == 1 ? '' : 's'} left today.'
                          : 'You\'ve completed today\'s free puzzles. Come back tomorrow or upgrade for unlimited access.'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _PuzzleTile extends StatelessWidget {
  const _PuzzleTile({
    required this.index,
    required this.puzzle,
    required this.locked,
    required this.onTap,
  });

  final int index;
  final ChessPuzzle puzzle;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked ? _kGold.withOpacity(0.3) : _kBorder,
          ),
        ),
        child: Row(
          children: [
            _MiniBoardThumb(puzzle: puzzle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${index + 1} · ${puzzle.title}',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    puzzle.objective,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kGold.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _kGold.withOpacity(0.25)),
                    ),
                    child: Text(
                      puzzle.difficulty.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: _kGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
              size: locked ? 16 : 22,
              color: _kGold,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBoardThumb extends StatelessWidget {
  const _MiniBoardThumb({required this.puzzle});
  final ChessPuzzle puzzle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
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

// ─── Puzzle solving screen ───────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzle;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
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
                          ? () => Navigator.pop(context)
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
