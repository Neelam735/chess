import 'package:flutter/material.dart';
import '../chess_logic.dart';

class CapturedPiecesWidget extends StatelessWidget {
  final List<ChessPiece> pieces;
  final bool small;

  const CapturedPiecesWidget({
    super.key,
    required this.pieces,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    if (pieces.isEmpty) return const SizedBox();
    final fontSize = small ? 14.0 : 18.0;

    return Wrap(
      spacing: -2,
      children: pieces.map((p) {
        return Text(
          p.symbol,
          style: TextStyle(
            fontSize: fontSize,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
