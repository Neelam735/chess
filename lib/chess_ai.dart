import 'dart:math';
import 'chess_logic.dart';

// ── Piece value tables for positional scoring ─────────────────────────────
class ChessAI {
  static const Map<PieceType, int> _pieceValues = {
    PieceType.pawn:   100,
    PieceType.knight: 320,
    PieceType.bishop: 330,
    PieceType.rook:   500,
    PieceType.queen:  900,
    PieceType.king:   20000,
  };

  // Positional bonus tables (white's perspective, flip for black)
  static const List<List<int>> _pawnTable = [
    [ 0,  0,  0,  0,  0,  0,  0,  0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [ 5,  5, 10, 25, 25, 10,  5,  5],
    [ 0,  0,  0, 20, 20,  0,  0,  0],
    [ 5, -5,-10,  0,  0,-10, -5,  5],
    [ 5, 10, 10,-20,-20, 10, 10,  5],
    [ 0,  0,  0,  0,  0,  0,  0,  0],
  ];

  static const List<List<int>> _knightTable = [
    [-50,-40,-30,-30,-30,-30,-40,-50],
    [-40,-20,  0,  0,  0,  0,-20,-40],
    [-30,  0, 10, 15, 15, 10,  0,-30],
    [-30,  5, 15, 20, 20, 15,  5,-30],
    [-30,  0, 15, 20, 20, 15,  0,-30],
    [-30,  5, 10, 15, 15, 10,  5,-30],
    [-40,-20,  0,  5,  5,  0,-20,-40],
    [-50,-40,-30,-30,-30,-30,-40,-50],
  ];

  static const List<List<int>> _bishopTable = [
    [-20,-10,-10,-10,-10,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20],
  ];

  static const List<List<int>> _rookTable = [
    [ 0,  0,  0,  0,  0,  0,  0,  0],
    [ 5, 10, 10, 10, 10, 10, 10,  5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [ 0,  0,  0,  5,  5,  0,  0,  0],
  ];

  static const List<List<int>> _queenTable = [
    [-20,-10,-10, -5, -5,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5,  5,  5,  5,  0,-10],
    [ -5,  0,  5,  5,  5,  5,  0, -5],
    [  0,  0,  5,  5,  5,  5,  0, -5],
    [-10,  5,  5,  5,  5,  5,  0,-10],
    [-10,  0,  5,  0,  0,  0,  0,-10],
    [-20,-10,-10, -5, -5,-10,-10,-20],
  ];

  static const List<List<int>> _kingTable = [
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-20,-30,-30,-40,-40,-30,-30,-20],
    [-10,-20,-20,-20,-20,-20,-20,-10],
    [ 20, 20,  0,  0,  0,  0, 20, 20],
    [ 20, 30, 10,  0,  0, 10, 30, 20],
  ];

  // ── Evaluate board from white's perspective ────────────────────────────
  static int _evaluate(List<List<ChessPiece?>> board) {
    int score = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece == null) continue;

        final value = _pieceValues[piece.type]!;
        final tableRow = piece.color == PieceColor.white ? r : (7 - r);
        int positional = 0;

        switch (piece.type) {
          case PieceType.pawn:   positional = _pawnTable[tableRow][c]; break;
          case PieceType.knight: positional = _knightTable[tableRow][c]; break;
          case PieceType.bishop: positional = _bishopTable[tableRow][c]; break;
          case PieceType.rook:   positional = _rookTable[tableRow][c]; break;
          case PieceType.queen:  positional = _queenTable[tableRow][c]; break;
          case PieceType.king:   positional = _kingTable[tableRow][c]; break;
        }

        final total = value + positional;
        if (piece.color == PieceColor.white) {
          score += total;
        } else {
          score -= total;
        }
      }
    }
    return score;
  }

  // ── Get all moves for a color ─────────────────────────────────────────
  static List<AIMove> _getAllMoves(
    List<List<ChessPiece?>> board,
    PieceColor color,
    Position? enPassantTarget,
    Map<String, bool> castlingRights,
  ) {
    final moves = <AIMove>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c]?.color == color) {
          final from = Position(r, c);
          final legal = ChessLogic.getLegalMoves(board, from, enPassantTarget, castlingRights);
          for (final to in legal) {
            moves.add(AIMove(from, to));
          }
        }
      }
    }
    return moves;
  }

  // ── Apply move and return new board state ─────────────────────────────
  static _BoardState _applyMove(
    List<List<ChessPiece?>> board,
    AIMove move,
    Position? enPassantTarget,
    Map<String, bool> castlingRights,
  ) {
    final newBoard = board.map((r) => List<ChessPiece?>.from(r)).toList();
    final piece = newBoard[move.from.row][move.from.col]!;
    final newCastling = Map<String, bool>.from(castlingRights);

    // En passant
    Position? newEP;
    if (piece.type == PieceType.pawn &&
        enPassantTarget != null &&
        move.to == enPassantTarget) {
      final captureRow = piece.color == PieceColor.white ? move.to.row + 1 : move.to.row - 1;
      newBoard[captureRow][move.to.col] = null;
    }

    // Castling move rook
    if (piece.type == PieceType.king) {
      final colDiff = move.to.col - move.from.col;
      if (colDiff == 2) {
        newBoard[move.from.row][5] = newBoard[move.from.row][7];
        newBoard[move.from.row][7] = null;
      } else if (colDiff == -2) {
        newBoard[move.from.row][3] = newBoard[move.from.row][0];
        newBoard[move.from.row][0] = null;
      }
      final prefix = piece.color == PieceColor.white ? 'w' : 'b';
      newCastling['${prefix}K'] = false;
      newCastling['${prefix}Q'] = false;
    }

    if (piece.type == PieceType.rook) {
      if (move.from.col == 7) newCastling[piece.color == PieceColor.white ? 'wK' : 'bK'] = false;
      if (move.from.col == 0) newCastling[piece.color == PieceColor.white ? 'wQ' : 'bQ'] = false;
    }

    // En passant target
    if (piece.type == PieceType.pawn && (move.to.row - move.from.row).abs() == 2) {
      newEP = Position((move.from.row + move.to.row) ~/ 2, move.from.col);
    }

    newBoard[move.to.row][move.to.col] = piece;
    newBoard[move.from.row][move.from.col] = null;

    // Auto-promote to queen for AI
    if (piece.type == PieceType.pawn && (move.to.row == 0 || move.to.row == 7)) {
      newBoard[move.to.row][move.to.col] =
          ChessPiece(color: piece.color, type: PieceType.queen);
    }

    return _BoardState(newBoard, newEP, newCastling);
  }

  // ── Minimax with alpha-beta pruning ───────────────────────────────────
  static int _minimax(
    List<List<ChessPiece?>> board,
    int depth,
    int alpha,
    int beta,
    bool maximizing,
    PieceColor color,
    Position? enPassantTarget,
    Map<String, bool> castlingRights,
  ) {
    if (depth == 0) return _evaluate(board);

    final moves = _getAllMoves(board, color, enPassantTarget, castlingRights);
    if (moves.isEmpty) {
      if (ChessLogic.isKingInCheck(board, color)) {
        return maximizing ? -99999 : 99999;
      }
      return 0; // stalemate
    }

    final nextColor = color == PieceColor.white ? PieceColor.black : PieceColor.white;

    if (maximizing) {
      int maxEval = -999999;
      for (final move in moves) {
        final state = _applyMove(board, move, enPassantTarget, castlingRights);
        final eval = _minimax(state.board, depth - 1, alpha, beta, false,
            nextColor, state.enPassantTarget, state.castlingRights);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (final move in moves) {
        final state = _applyMove(board, move, enPassantTarget, castlingRights);
        final eval = _minimax(state.board, depth - 1, alpha, beta, true,
            nextColor, state.enPassantTarget, state.castlingRights);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  // ── Public: get best move for AI ──────────────────────────────────────
  static AIMove? getBestMove({
    required List<List<ChessPiece?>> board,
    required PieceColor aiColor,
    required AIDifficulty difficulty,
    required Position? enPassantTarget,
    required Map<String, bool> castlingRights,
  }) {
    final moves = _getAllMoves(board, aiColor, enPassantTarget, castlingRights);
    if (moves.isEmpty) return null;

    final random = Random();

    // Easy: random move
    if (difficulty == AIDifficulty.easy) {
      moves.shuffle(random);
      // Prefer captures 50% of time
      final captures = moves.where((m) => board[m.to.row][m.to.col] != null).toList();
      if (captures.isNotEmpty && random.nextBool()) {
        return captures[random.nextInt(captures.length)];
      }
      return moves[random.nextInt(moves.length)];
    }

    // Medium: depth 2, with some randomness
    // Hard: depth 3, pure best move
    final depth = difficulty == AIDifficulty.medium ? 2 : 3;
    final isMaximizing = aiColor == PieceColor.white;
    final nextColor = aiColor == PieceColor.white ? PieceColor.black : PieceColor.white;

    AIMove? bestMove;
    int bestScore = isMaximizing ? -999999 : 999999;

    // Shuffle to avoid always picking same move when equal
    moves.shuffle(random);

    for (final move in moves) {
      final state = _applyMove(board, move, enPassantTarget, castlingRights);
      final score = _minimax(
        state.board, depth - 1, -999999, 999999,
        !isMaximizing, nextColor,
        state.enPassantTarget, state.castlingRights,
      );

      if (isMaximizing ? score > bestScore : score < bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    // Medium: 20% chance of making a suboptimal move
    if (difficulty == AIDifficulty.medium && random.nextDouble() < 0.2) {
      return moves[random.nextInt(moves.length)];
    }

    return bestMove;
  }
}

enum AIDifficulty { easy, medium, hard }

class AIMove {
  final Position from;
  final Position to;
  const AIMove(this.from, this.to);
}

class _BoardState {
  final List<List<ChessPiece?>> board;
  final Position? enPassantTarget;
  final Map<String, bool> castlingRights;
  const _BoardState(this.board, this.enPassantTarget, this.castlingRights);
}
