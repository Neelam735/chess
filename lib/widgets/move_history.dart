import 'package:flutter/material.dart';
import '../chess_logic.dart';

class MoveHistoryBar extends StatelessWidget {
  final List<Move> moves;

  const MoveHistoryBar({super.key, required this.moves});

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return const Center(
        child: Text(
          'No moves yet',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    final pairs = <String>[];
    for (int i = 0; i < moves.length; i += 2) {
      final white = moves[i].notation;
      final black = i + 1 < moves.length ? moves[i + 1].notation : '';
      pairs.add('${(i ~/ 2) + 1}. $white  $black');
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: pairs.length,
      reverse: true,
      itemBuilder: (context, index) {
        final reverseIndex = pairs.length - 1 - index;
        final isLast = reverseIndex == pairs.length - 1;
        return Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: isLast
              ? BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFC8A96E).withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Text(
            pairs[reverseIndex],
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: isLast ? const Color(0xFFC8A96E) : Colors.white38,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

class MoveHistoryPanel extends StatelessWidget {
  final List<Move> moves;

  const MoveHistoryPanel({super.key, required this.moves});

  @override
  Widget build(BuildContext context) {
    final pairs = <_MovePair>[];
    for (int i = 0; i < moves.length; i += 2) {
      pairs.add(_MovePair(
        number: (i ~/ 2) + 1,
        white: moves[i].notation,
        black: i + 1 < moves.length ? moves[i + 1].notation : '',
      ));
    }

    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFF161616),
            child: const Center(
              child: Text(
                'MOVES',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: Color(0xFFC8A96E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: pairs.length,
              itemBuilder: (ctx, i) {
                final pair = pairs[pairs.length - 1 - i];
                final isLast = i == 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: isLast
                      ? const Color(0xFFC8A96E).withOpacity(0.08)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${pair.number}.',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          pair.white,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isLast ? const Color(0xFFC8A96E) : Colors.white60,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          pair.black,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isLast && pair.black.isNotEmpty
                                ? const Color(0xFFC8A96E)
                                : Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MovePair {
  final int number;
  final String white;
  final String black;
  const _MovePair({required this.number, required this.white, required this.black});
}
