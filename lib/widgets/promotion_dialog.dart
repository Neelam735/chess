import 'package:flutter/material.dart';
import '../chess_logic.dart';

class PromotionDialog extends StatelessWidget {
  final PieceColor color;
  final Function(PieceType) onSelect;

  const PromotionDialog({
    super.key,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFC8A96E).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PROMOTE PAWN',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC8A96E),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: options.map((type) {
                final piece = ChessPiece(color: color, type: type);
                return GestureDetector(
                  onTap: () => onSelect(type),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                    ),
                    child: Center(
                      child: Text(
                        piece.symbol,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
