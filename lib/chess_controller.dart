import 'package:flutter/foundation.dart';
import 'chess_ai.dart';
import 'chess_logic.dart';

enum GameMode { twoPlayer, vsComputer }

class ChessController extends ChangeNotifier {
  late List<List<ChessPiece?>> _board;
  late PieceColor _currentTurn;
  late List<Move> _moveHistory;
  late Map<String, bool> _castlingRights;
  Position? _enPassantTarget;
  Position? _selectedPos;
  List<Position> _legalMoves = [];
  bool _isCheck = false;
  bool _isCheckmate = false;
  bool _isStalemate = false;
  List<ChessPiece> _capturedByWhite = [];
  List<ChessPiece> _capturedByBlack = [];
  Position? _lastMoveFrom;
  Position? _lastMoveTo;
  Position? _pendingPromotion;
  bool _aiThinking = false;
  Position? _hintFrom;
  Position? _hintTo;

  final GameMode gameMode;
  final AIDifficulty aiDifficulty;
  final PieceColor playerColor;

  ChessController({
    this.gameMode = GameMode.twoPlayer,
    this.aiDifficulty = AIDifficulty.medium,
    this.playerColor = PieceColor.white,
  }) {
    _initGame();
    _maybeTriggerAI();
  }

  PieceColor get aiColor =>
      playerColor == PieceColor.white ? PieceColor.black : PieceColor.white;

  bool get isAiTurn =>
      gameMode == GameMode.vsComputer && _currentTurn == aiColor;

  bool get aiThinking => _aiThinking;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<List<ChessPiece?>> get board           => _board;
  PieceColor get currentTurn                  => _currentTurn;
  List<Move> get moveHistory                  => _moveHistory;
  Position? get selectedPos                   => _selectedPos;
  List<Position> get legalMoves               => _legalMoves;
  bool get isCheck                            => _isCheck;
  bool get isCheckmate                        => _isCheckmate;
  bool get isStalemate                        => _isStalemate;
  List<ChessPiece> get capturedByWhite        => _capturedByWhite;
  List<ChessPiece> get capturedByBlack        => _capturedByBlack;
  Position? get lastMoveFrom                  => _lastMoveFrom;
  Position? get lastMoveTo                    => _lastMoveTo;
  Position? get hintFrom                      => _hintFrom;
  Position? get hintTo                        => _hintTo;
  Position? get enPassantTarget               => _enPassantTarget;
  Map<String, bool> get castlingRights        => _castlingRights;
  bool get isGameOver                         => _isCheckmate || _isStalemate;
  bool get awaitingPromotion                  => _pendingPromotion != null;

  void setHint(Position from, Position to) {
    _hintFrom = from;
    _hintTo = to;
    notifyListeners();
  }

  void clearHint() {
    if (_hintFrom == null && _hintTo == null) return;
    _hintFrom = null;
    _hintTo = null;
    notifyListeners();
  }

  String get statusText {
    if (_isCheckmate) {
      final winner = _currentTurn == PieceColor.white ? 'Black' : 'White';
      return '$winner wins by checkmate!';
    }
    if (_isStalemate) return 'Draw by stalemate!';
    if (_isCheck)
      return '${_currentTurn == PieceColor.white ? "White" : "Black"} is in check!';
    return '${_currentTurn == PieceColor.white ? "White" : "Black"}\'s turn';
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  void _initGame() {
    _board            = ChessLogic.initialBoard();
    _currentTurn      = PieceColor.white;
    _moveHistory      = [];
    _castlingRights   = ChessLogic.initialCastlingRights();
    _enPassantTarget  = null;
    _selectedPos      = null;
    _legalMoves       = [];
    _isCheck          = false;
    _isCheckmate      = false;
    _isStalemate      = false;
    _capturedByWhite  = [];
    _capturedByBlack  = [];
    _lastMoveFrom     = null;
    _lastMoveTo       = null;
    _pendingPromotion = null;
  }

  void resetGame() {
    _initGame();
    notifyListeners();
    _maybeTriggerAI();
  }

  // ── Square tap ────────────────────────────────────────────────────────────
  void onSquareTap(Position pos) {
    if (isGameOver || awaitingPromotion) return;
    if (isAiTurn || _aiThinking) return;

    final int r = pos.row;
    final int c = pos.col;
    final piece = _board[r][c];

    final bool isLegalDest = _legalMoves
        .any((m) => m.row == r && m.col == c);

    debugLog('onSquareTap r=$r c=$c '
        'selectedPos=$_selectedPos '
        'isLegalDest=$isLegalDest '
        'legalMoves=${_legalMoves.length}');

    if (_selectedPos != null && isLegalDest) {
      _executeMove(_selectedPos!, pos);
      return;
    }

    if (piece != null && piece.color == _currentTurn) {
      _selectedPos = pos;
      _legalMoves = ChessLogic.getLegalMoves(
          _board, pos, _enPassantTarget, _castlingRights);
      notifyListeners();
      return;
    }

    _selectedPos = null;
    _legalMoves = [];
    notifyListeners();
  }

  void debugLog(String msg) {
    // ignore: avoid_print
    print(msg);
  }

  // ── Execute move ──────────────────────────────────────────────────────────
  void _executeMove(Position from, Position to) {
    _hintFrom = null;
    _hintTo = null;
    final piece    = _board[from.row][from.col]!;
    ChessPiece? captured = _board[to.row][to.col];
    bool isEnPassant = false;
    bool isCastling  = false;

    final nb = _board.map((r) => List<ChessPiece?>.from(r)).toList();

    if (piece.type == PieceType.pawn &&
        _enPassantTarget != null && to == _enPassantTarget) {
      final capRow = piece.color == PieceColor.white ? to.row + 1 : to.row - 1;
      final epPiece = nb[capRow][to.col];
      if (epPiece != null) {
        _addCaptured(piece.color, epPiece);
        nb[capRow][to.col] = null;
        captured = epPiece;
      }
      isEnPassant = true;
    } else if (captured != null) {
      _addCaptured(piece.color, captured);
    }

    if (piece.type == PieceType.king) {
      final diff = to.col - from.col;
      if (diff.abs() == 2) {
        isCastling = true;
        if (diff == 2) { nb[from.row][5] = nb[from.row][7]; nb[from.row][7] = null; }
        else           { nb[from.row][3] = nb[from.row][0]; nb[from.row][0] = null; }
      }
    }

    nb[to.row][to.col]     = piece;
    nb[from.row][from.col] = null;

    final nc = Map<String, bool>.from(_castlingRights);
    if (piece.type == PieceType.king) {
      final p = piece.color == PieceColor.white ? 'w' : 'b';
      nc['${p}K'] = false; nc['${p}Q'] = false;
    }
    if (piece.type == PieceType.rook) {
      if (from.col == 7) nc[piece.color == PieceColor.white ? 'wK' : 'bK'] = false;
      if (from.col == 0) nc[piece.color == PieceColor.white ? 'wQ' : 'bQ'] = false;
    }
    _castlingRights = nc;

    _enPassantTarget = (piece.type == PieceType.pawn && (to.row - from.row).abs() == 2)
        ? Position((from.row + to.row) ~/ 2, from.col)
        : null;

    _lastMoveFrom = from;
    _lastMoveTo   = to;
    _board        = nb;

    if (piece.type == PieceType.pawn && (to.row == 0 || to.row == 7)) {
      final isAiMove = gameMode == GameMode.vsComputer && piece.color == aiColor;
      if (isAiMove) {
        nb[to.row][to.col] = ChessPiece(color: piece.color, type: PieceType.queen);
        _board = nb;
        _finishTurn(from, to, piece, captured, isEnPassant, isCastling, PieceType.queen);
        return;
      }
      _pendingPromotion = to;
      _selectedPos      = null;
      _legalMoves       = [];
      notifyListeners();
      return;
    }

    _finishTurn(from, to, piece, captured, isEnPassant, isCastling, null);
  }

  void _addCaptured(PieceColor capturer, ChessPiece piece) {
    if (capturer == PieceColor.white) {
      _capturedByWhite = [..._capturedByWhite, piece];
    } else {
      _capturedByBlack = [..._capturedByBlack, piece];
    }
  }

  void promotePawn(PieceType type) {
    if (_pendingPromotion == null) return;
    final pos   = _pendingPromotion!;
    final piece = _board[pos.row][pos.col]!;
    final nb    = _board.map((r) => List<ChessPiece?>.from(r)).toList();
    nb[pos.row][pos.col] = ChessPiece(color: piece.color, type: type);
    _board            = nb;
    _pendingPromotion = null;

    _switchAndCheck();
    _selectedPos = null;
    _legalMoves  = [];
    notifyListeners();
    _maybeTriggerAI();
  }

  void _finishTurn(Position from, Position to, ChessPiece piece,
      ChessPiece? captured, bool isEnPassant, bool isCastling,
      PieceType? promotionType) {
    _switchAndCheck();

    final notation = ChessLogic.getMoveNotation(
        piece, from, to, captured, _isCheck, _isCheckmate);
    _moveHistory = [
      ..._moveHistory,
      Move(
        from: from, to: to, captured: captured,
        isCastling: isCastling, isEnPassant: isEnPassant,
        promotionType: promotionType, notation: notation,
      ),
    ];

    _selectedPos = null;
    _legalMoves  = [];
    notifyListeners();
    _maybeTriggerAI();
  }

  void _maybeTriggerAI() {
    if (!isAiTurn || isGameOver || awaitingPromotion || _aiThinking) return;
    _aiThinking = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 350), () {
      final move = ChessAI.getBestMove(
        board: _board,
        aiColor: aiColor,
        difficulty: aiDifficulty,
        enPassantTarget: _enPassantTarget,
        castlingRights: _castlingRights,
      );
      _aiThinking = false;
      if (move == null || isGameOver) {
        notifyListeners();
        return;
      }
      _executeMove(move.from, move.to);
    });
  }

  void _switchAndCheck() {
    _currentTurn = _currentTurn == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    _isCheck = ChessLogic.isKingInCheck(_board, _currentTurn);
    final hasMoves = ChessLogic.hasAnyLegalMoves(
        _board, _currentTurn, _enPassantTarget, _castlingRights);
    _isCheckmate = _isCheck  && !hasMoves;
    _isStalemate = !_isCheck && !hasMoves;
  }
}
