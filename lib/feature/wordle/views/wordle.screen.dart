import 'dart:math';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:wordle/app/app.colors.dart';
import 'package:wordle/feature/wordle/data/word_list.dart';
import 'package:wordle/feature/wordle/models/letter.model.dart';
import 'package:wordle/feature/wordle/models/word.model.dart';
import 'package:wordle/feature/wordle/widgets/board.dart';
import 'package:wordle/feature/wordle/widgets/keyboard.dart';

enum GameStatus { playing, submitting, lost, won }

class WordleScreen extends StatefulWidget {
  const WordleScreen({Key? key}) : super(key: key);

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  GameStatus _gameStatus = GameStatus.playing;

  final List<Word> _board = List.generate(
    6,
    (_) => Word(
      letters: List.generate(
        5,
        (_) => Letter.empty(),
      ),
    ),
  );

  final List<List<GlobalKey<FlipCardState>>> _flipCardKeys = List.generate(
    6,
    (_) => List.generate(
      5,
      (_) => GlobalKey<FlipCardState>(),
    ),
  );

  int _currWordIndex = 0;

  Word? get _currentWord =>
      _currWordIndex < _board.length ? _board[_currWordIndex] : null;

  Word _solution = Word.fromString(
    fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),
  );

  final Set<Letter> _keyboardLetter = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "WORDLE",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Board(board: _board, flipCardKeys: _flipCardKeys),
          const SizedBox(
            height: 80,
          ),
          Keyboard(
            onKeyTapped: onKeyTapped,
            onDeleteTapped: onDeleteTapped,
            letters: _keyboardLetter,
            onEnterTapped: onEnterTapped,
          )
        ],
      ),
    );
  }

  void onKeyTapped(String val) {
    if (_gameStatus == GameStatus.playing) {
      setState(
        () => _currentWord?.addLetter(val),
      );
    }
  }

  void onDeleteTapped() {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.removeLetter());
    }
  }

  Future<void> onEnterTapped() async {
    if (_gameStatus == GameStatus.playing &&
        _currentWord != null &&
        !_currentWord!.letters.contains(
          Letter.empty(),
        )) {
      _gameStatus = GameStatus.submitting;

      for (var i = 0; i < _currentWord!.letters.length; i++) {
        final currWordLetter = _currentWord!.letters[i];
        final currSolLetter = _solution.letters[i];

        setState(
          () {
            if (currWordLetter == currSolLetter) {
              _currentWord!.letters[i] =
                  currWordLetter.copyWith(status: LetterStatus.correct);
            } else if (_solution.letters.contains(currWordLetter)) {
              _currentWord!.letters[i] =
                  currWordLetter.copyWith(status: LetterStatus.inWord);
            } else {
              _currentWord!.letters[i] =
                  currWordLetter.copyWith(status: LetterStatus.notInWord);
            }
          },
        );
        final letter = _keyboardLetter.firstWhere(
          (e) => e.val == currWordLetter.val,
          orElse: () => Letter.empty(),
        );
        if (letter.status != LetterStatus.correct) {
          _keyboardLetter.remove((e) => e.val == currWordLetter.val);
          _keyboardLetter.add(_currentWord!.letters[i]);
        }

        await Future.delayed(
          const Duration(milliseconds: 150),
          () => _flipCardKeys[_currWordIndex][i].currentState?.toggleCard(),
        );
      }

      _checkIfWinOrLoss();
    }
  }

  void _checkIfWinOrLoss() {
    if (_currentWord!.wordString == _solution.wordString) {
      _gameStatus = GameStatus.won;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.none,
          duration: const Duration(days: 1),
          backgroundColor: correctColor,
          content: const Text(
            'You Won!',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          action: SnackBarAction(
            onPressed: _restart,
            textColor: Colors.white,
            label: 'New Game',
          ),
        ),
      );
    } else if (_currWordIndex + 1 >= _board.length) {
      _gameStatus = GameStatus.lost;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.none,
          duration: const Duration(days: 1),
          backgroundColor: Colors.red,
          content: Text(
            'You Lost! Solution ${_solution.wordString}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          action: SnackBarAction(
            onPressed: _restart,
            textColor: Colors.white,
            label: 'New Game',
          ),
        ),
      );
    } else {
      _gameStatus = GameStatus.playing;
    }
    _currWordIndex += 1;
  }

  void _restart() {
    setState(() {
      _gameStatus = GameStatus.playing;
      _currWordIndex = 0;
      _board
        ..clear()
        ..addAll(List.generate(
          6,
          (_) => Word(
            letters: List.generate(
              5,
              (_) => Letter.empty(),
            ),
          ),
        ));
      _solution = Word.fromString(
        fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),
      );
      _flipCardKeys
        ..clear()
        ..addAll(
          List.generate(
            6,
            (_) => List.generate(
              5,
              (_) => GlobalKey<FlipCardState>(),
            ),
          ),
        );
      _keyboardLetter.clear();
    });
  }
}
