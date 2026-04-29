import 'package:flutter/material.dart';
import '../chess_controller.dart';
import '../chess_logic.dart';

class BoardWidget extends StatefulWidget {
  final ChessController controller;
  const BoardWidget({super.key, required this.controller});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth < constraints.maxHeight
          ? constraints.maxWidth
          : constraints.maxHeight;
      final sq = size / 8;

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 5),
            BoxShadow(
                color: const Color(0xFFC8A96E).withOpacity(0.1),
                blurRadius: 50,
                spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(children: [
            // ── 64 squares ─────────────────────────────────────────────
            Column(
              children: List.generate(8, (row) {
                return Row(
                  children: List.generate(8, (col) {
                    return _buildSquare(row, col, sq);
                  }),
                );
              }),
            ),
            // ── Rank labels ─────────────────────────────────────────────
            ...List.generate(8, (i) => Positioned(
              left: 3,
              top: sq * i + sq * 0.5 - 7,
              child: IgnorePointer(
                child: Text('${8 - i}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: (i % 2 == 0
                            ? const Color(0xFF8B6343)
                            : const Color(0xFFE8D5B0))
                        .withOpacity(0.8),
                  )),
              ),
            )),
            // ── File labels ─────────────────────────────────────────────
            ...List.generate(8, (i) => Positioned(
              left: sq * i + sq * 0.5 - 5,
              bottom: 3,
              child: IgnorePointer(
                child: Text('abcdefgh'[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: (i % 2 == 1
                            ? const Color(0xFF8B6343)
                            : const Color(0xFFE8D5B0))
                        .withOpacity(0.8),
                  )),
              ),
            )),
          ]),
        ),
      );
    });
  }

  Widget _buildSquare(int row, int col, double sq) {
    final ctrl       = widget.controller;
    final piece      = ctrl.board[row][col];
    final sel        = ctrl.selectedPos;
    final isSelected = sel != null && sel.row == row && sel.col == col;
    final isLegal    = ctrl.legalMoves.any((m) => m.row == row && m.col == col);
    final isLastFrom = ctrl.lastMoveFrom != null &&
        ctrl.lastMoveFrom!.row == row && ctrl.lastMoveFrom!.col == col;
    final isLastTo   = ctrl.lastMoveTo != null &&
        ctrl.lastMoveTo!.row == row && ctrl.lastMoveTo!.col == col;
    final isHintFrom = ctrl.hintFrom != null &&
        ctrl.hintFrom!.row == row && ctrl.hintFrom!.col == col;
    final isHintTo   = ctrl.hintTo != null &&
        ctrl.hintTo!.row == row && ctrl.hintTo!.col == col;
    final isLight    = (row + col) % 2 == 0;
    final isCapture  = isLegal && piece != null;
    final isInCheck  = piece != null &&
        piece.type == PieceType.king &&
        piece.color == ctrl.currentTurn &&
        ctrl.isCheck;

    Color bg = isLight
        ? const Color(0xFFE8D5B0)
        : const Color(0xFF8B6343);
    if (isSelected) {
      bg = const Color(0xFFC8A96E);
    } else if (isHintFrom || isHintTo) {
      bg = isLight ? const Color(0xFFE6C488) : const Color(0xFFB6883E);
    } else if (isLastFrom || isLastTo) {
      bg = isLight ? const Color(0xFFD4C07A) : const Color(0xFF9E7A30);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ctrl.onSquareTap(Position(row, col)),
      child: SizedBox(
        width: sq,
        height: sq,
        child: CustomPaint(
          painter: _SquarePainter(
            bg: bg,
            isLegal: isLegal,
            isCapture: isCapture,
            isInCheck: isInCheck,
          ),
          child: piece != null
              ? Center(
                  child: IgnorePointer(
                    child: AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      child: _PieceWidget(piece: piece, size: sq),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────
class _SquarePainter extends CustomPainter {
  final Color bg;
  final bool isLegal;
  final bool isCapture;
  final bool isInCheck;

  const _SquarePainter({
    required this.bg,
    required this.isLegal,
    required this.isCapture,
    required this.isInCheck,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;

    // Background
    p.color = bg;
    canvas.drawRect(Offset.zero & size, p);

    // Check glow
    if (isInCheck) {
      p.shader = RadialGradient(colors: [
        const Color(0xFFE05050).withOpacity(0.8),
        Colors.transparent,
      ]).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, p);
      p.shader = null;
    }

    // Move dot
    if (isLegal && !isCapture) {
      p
        ..color = const Color(0x66000000)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.17,
        p,
      );
    }

    // Capture ring
    if (isCapture) {
      p
        ..color = const Color(0x88000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09;
      final inset = p.strokeWidth / 2;
      canvas.drawRect(
        Rect.fromLTWH(inset, inset,
            size.width - p.strokeWidth, size.height - p.strokeWidth),
        p,
      );
      p.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(_SquarePainter o) =>
      o.bg != bg ||
      o.isLegal != isLegal ||
      o.isCapture != isCapture ||
      o.isInCheck != isInCheck;
}

// ── Piece ─────────────────────────────────────────────────────────────────────
class _PieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;
  const _PieceWidget({required this.piece, required this.size});

  static const _w = {
    PieceType.king: '♔', PieceType.queen: '♕', PieceType.rook: '♖',
    PieceType.bishop: '♗', PieceType.knight: '♘', PieceType.pawn: '♙',
  };
  static const _b = {
    PieceType.king: '♚', PieceType.queen: '♛', PieceType.rook: '♜',
    PieceType.bishop: '♝', PieceType.knight: '♞', PieceType.pawn: '♟',
  };

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == PieceColor.white;
    final fs = size * 0.72;

    if (isWhite) {
      return Text(_w[piece.type]!,
          style: TextStyle(fontSize: fs, height: 1, shadows: [
            Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 2),
                blurRadius: 3),
          ]));
    }

    final sym = _b[piece.type]!;
    return Stack(alignment: Alignment.center, children: [
      Text(sym,
          style: TextStyle(
              fontSize: fs,
              height: 1,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2
                ..color = Colors.black.withOpacity(0.3))),
      Text(sym,
          style: TextStyle(
              fontSize: fs,
              height: 1,
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..color = const Color(0xFF050505))),
    ]);
  }
}
