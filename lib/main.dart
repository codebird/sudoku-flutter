import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Sudoku'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool checkIfGoodNumber(number, row, column) {
    if (hiddenNumbers.containsKey("r${row}_c$column")) {
      if (number != hiddenNumbers["r${row}_c$column"]) {
        return false;
      }
    }
    return true;
  }

  void generateGrid() {
    final rand = Random();
    for (int i = 0; i < 9; i++) {
      List<int> numbers = List.generate(9, (index) => index + 1);

      for (int j = 0; j < 9; j++) {
        int newNumIndex = rand.nextInt(numbers.length);
        int newNum = numbers[newNumIndex];
        int innerLoop = max(i, j);
        int retries = 0;

        for (int k = 0; k <= innerLoop; k++) {
          bool regenerate = false;
          if (mainMatrix[i][k] == newNum || mainMatrix[k][j] == newNum) {
            regenerate = true;
          } else {
            int startI = i - (i % 3);
            int startJ = j - (j % 3);
            for (int m = startI; m < startI + 3; m++) {
              if (m >= i) {
                continue;
              }
              for (int l = startJ; l < startJ + 3; l++) {
                if (l == j) {
                  continue;
                }
                if (mainMatrix[m][l] == newNum) {
                  regenerate = true;
                  break;
                }
              }
              if (regenerate) {
                break;
              }
            }
          }
          if (regenerate) {
            newNumIndex = rand.nextInt(numbers.length);
            newNum = numbers[newNumIndex];
            k = -1; // reset loop
            retries++;

            if (retries > numbers.length * 4) {
              i = -1; // force restart
              mainMatrix =
                  List.generate(9, (_) => List.filled(9, 0)); // reset matrix
              break;
            }
          }
        }
        if (i == -1) {
          break;
        }
        numbers.removeAt(newNumIndex);
        mainMatrix[i][j] = newNum;
        solutionMatrix[i][j] = newNum;
      }
    }

    int hiddenCount = 0;
    while (hiddenCount <= 50) {
      int row = rand.nextInt(9);
      int col = rand.nextInt(9);

      if (mainMatrix[row][col] != 0) {
        hiddenNumbers['r${row}_c$col'] = mainMatrix[row][col];
        remainingHiddenNumbers['r${row}_c$col'] = mainMatrix[row][col];
        mainMatrix[row][col] = 0;
        solutionMatrix[row][col] = 0;
        hiddenCount++;
      }
    }
  }

  List<List<int>> mainMatrix = List.generate(9, (_) => List.filled(9, 0));
  List<List<int>> solutionMatrix = List.generate(9, (_) => List.filled(9, 0));
  Map<String, int> hiddenNumbers = {};
  Map<String, List<int>> drafts = {};
  Map<String, int> remainingHiddenNumbers = {};

  int currentPosRow = 0;
  int currentPosCol = 0;
  int mistakes = 0;
  int chosenNumber = 0;
  bool draftMode = false;
  int timePassed = 0;
  int timePassedMinutes = 0;
  int timePassedHours = 0;
  int timePassedSeconds = 0;
  late Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void newGrid() {
    setState(() {
      hiddenNumbers = {};
      drafts = {};
      draftMode = false;
      remainingHiddenNumbers = {};
      mainMatrix = List.generate(9, (_) => List.filled(9, 0));
      solutionMatrix = List.generate(9, (_) => List.filled(9, 0));
      mistakes = 0;
      generateGrid();
      if (timePassed > 0) {
        _timer.cancel();
      }
      timePassed = 0;
      startTimer();
    });
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        setState(() {
          if (remainingHiddenNumbers.isEmpty) {
            _timer.cancel();
            return;
          }
          timePassed++;
          if (timePassed < 60) {
            timePassedSeconds = timePassed;
            timePassedMinutes = 0;
            timePassedHours = 0;
          } else if (timePassed < 3600) {
            timePassedMinutes = (timePassed / 60).floor();
            timePassedHours = 0;
            timePassedSeconds = timePassed % 60;
          } else {
            timePassedMinutes = (timePassed / 60).floor();
            timePassedHours = (timePassedMinutes / 60).floor();
            timePassedMinutes = timePassedMinutes % 60;
            timePassedSeconds = timePassed % 60;
          }
        });
      },
    );
  }

  void resetGrid() {
    setState(() {
      chosenNumber = 0;
      remainingHiddenNumbers = Map.of(hiddenNumbers);
      drafts = {};
      draftMode = false;
      solutionMatrix = [];
      for (var list in mainMatrix) {
        solutionMatrix.add(List.of(list));
      }
      mistakes = 0;
      timePassed = 0;
      _timer.cancel();
      startTimer();
    });
  }

  void toggleDraftMode() {
    setState(() {
      draftMode = !draftMode;
    });
  }

  void changeChosenNumber(int newOne) {
    setState(() {
      chosenNumber = newOne;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // Aspect ratio will keep the cells as squares
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "mistakes: $mistakes",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.black,
                    // Responsive text size
                    fontSize: min(MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height) /
                        25,
                  ),
                ),
                Text(
                  timePassed > 0
                      ? remainingHiddenNumbers.isEmpty
                          ? " You won "
                          : "remaining: ${remainingHiddenNumbers.length}"
                      : " ",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black,
                    // Responsive text size
                    fontSize: min(MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height) /
                        25,
                  ),
                ),
                Text(
                  "${timePassedHours.toString().padLeft(2, '0')}:${timePassedMinutes.toString().padLeft(2, '0')}:${timePassedSeconds.toString().padLeft(2, '0')}",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black,
                    // Responsive text size
                    fontSize: min(MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height) /
                        25,
                  ),
                ),
              ],
            ),
            AspectRatio(
              aspectRatio: 1,
              child: LayoutGrid(
                // Set the cols and rows to be equal sizes
                columnSizes: List<TrackSize>.generate(9, (index) => 1.fr),
                rowSizes: List<TrackSize>.generate(9, (index) => 1.fr),
                children: [
                  for (var j = 0; j < 9; j++)
                    for (var i = 0; i < 9; i++)
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: chosenNumber != 0 &&
                                  solutionMatrix[j][i] == chosenNumber
                              ? Colors.green
                              : Colors.white,
                          border: Border(
                            // Conditionally set the border thickness
                            top: BorderSide(
                                color:
                                    (i == currentPosCol && j == currentPosRow)
                                        ? Colors.blue
                                        : Colors.black,
                                width: j > 0 && j % 3 == 0 ? 1.5 : 1),
                            right: BorderSide(
                                color:
                                    (i == currentPosCol && j == currentPosRow)
                                        ? Colors.blue
                                        : Colors.black,
                                width: i > 0 && i % 3 == 2 ? 1.5 : 1),
                            bottom: BorderSide(
                                color:
                                    (i == currentPosCol && j == currentPosRow)
                                        ? Colors.blue
                                        : Colors.black,
                                width: j < 8 && j % 3 == 2 ? 1.5 : 1),
                            left: BorderSide(
                                color:
                                    (i == currentPosCol && j == currentPosRow)
                                        ? Colors.blue
                                        : Colors.black,
                                width: i < 8 && i % 3 == 0 ? 1.5 : 1),
                          ),
                        ),
                        // Substitute text with text entry or
                        // wrap with a gesture detector to make interactive
                        child: mainMatrix[j][i] == 0
                            ? InkWell(
                                onTap: () {
                                  setState(() {
                                    currentPosCol = i;
                                    currentPosRow = j;
                                    if (solutionMatrix[j][i] == 0) {
                                      chosenNumber = 0;
                                    } else {
                                      chosenNumber = solutionMatrix[j][i];
                                    }
                                  });
                                },
                                child: solutionMatrix[j][i] == 0
                                    ? drafts.containsKey("r${j}_c$i")
                                        ? Text(
                                            drafts["r${j}_c$i"].toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                              // Responsive text size
                                              fontSize: min(
                                                      MediaQuery.of(context)
                                                          .size
                                                          .width,
                                                      MediaQuery.of(context)
                                                          .size
                                                          .height) /
                                                  45,
                                            ),
                                          )
                                        : Container()
                                    : Text(
                                        solutionMatrix[j][i].toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: checkIfGoodNumber(
                                                  solutionMatrix[j][i], j, i)
                                              ? Colors.blue
                                              : Colors.red,
                                          // Responsive text size
                                          fontSize: min(
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  MediaQuery.of(context)
                                                      .size
                                                      .height) /
                                              25,
                                        ),
                                      ),
                              )
                            : InkWell(
                                onTap: () {
                                  changeChosenNumber(solutionMatrix[j][i]);
                                },
                                child: Text(
                                  solutionMatrix[j][i].toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    // Responsive text size
                                    fontSize: min(
                                            MediaQuery.of(context).size.width,
                                            MediaQuery.of(context)
                                                .size
                                                .height) /
                                        25,
                                  ),
                                ),
                              ),
                      ),
                ],
              ),
            ),
            Row(children: [
              for (var j = 1; j <= 9; j++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(1.5, 10, 1.5, 0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (draftMode) {
                          if (drafts.containsKey(
                              "r${currentPosRow}_c$currentPosCol")) {
                            if (!drafts["r${currentPosRow}_c$currentPosCol"]!
                                .contains(j)) {
                              drafts["r${currentPosRow}_c$currentPosCol"]!
                                  .add(j);
                            } else {
                              drafts["r${currentPosRow}_c$currentPosCol"]!
                                  .remove(j);
                            }
                          } else {
                            drafts["r${currentPosRow}_c$currentPosCol"] = [j];
                          }
                        } else {
                          if (solutionMatrix[currentPosRow][currentPosCol] ==
                              j) {
                            chosenNumber = 0;
                            solutionMatrix[currentPosRow][currentPosCol] = 0;
                            if (hiddenNumbers.containsKey(
                                "r${currentPosRow}_c$currentPosCol")) {
                              remainingHiddenNumbers[
                                      "r${currentPosRow}_c$currentPosCol"] =
                                  hiddenNumbers[
                                      "r${currentPosRow}_c$currentPosCol"]!;
                            }
                          } else if (solutionMatrix[currentPosRow]
                                  [currentPosCol] ==
                              0) {
                            solutionMatrix[currentPosRow][currentPosCol] = j;
                            chosenNumber = j;
                            if (!checkIfGoodNumber(
                                j, currentPosRow, currentPosCol)) {
                              mistakes += 1;
                            } else {
                              drafts
                                  .remove("r${currentPosRow}_c$currentPosCol");
                              remainingHiddenNumbers
                                  .remove("r${currentPosRow}_c$currentPosCol");
                            }
                          }
                        }
                      });
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 11,
                      height: 37,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        border: const Border(
                          // Conditionally set the border thickness
                          top: BorderSide(color: Colors.black, width: 1),
                          right: BorderSide(color: Colors.black, width: 1),
                          bottom: BorderSide(color: Colors.black, width: 1),
                          left: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            remainingHiddenNumbers.entries
                                .where((x) => x.value == j)
                                .toList()
                                .length
                                .toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.black,
                              // Responsive text size
                              fontSize: min(MediaQuery.of(context).size.width,
                                      MediaQuery.of(context).size.height) /
                                  45,
                            ),
                          ),
                          Text(
                            remainingHiddenNumbers.entries
                                    .where((x) => x.value == j)
                                    .toList()
                                    .isNotEmpty
                                ? j.toString()
                                : " ",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: draftMode ? Colors.blueGrey : Colors.black,
                              // Responsive text size
                              fontSize: min(MediaQuery.of(context).size.width,
                                      MediaQuery.of(context).size.height) /
                                  30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(1.5, 10, 1.5, 0),
                child: InkWell(
                  onTap: () {
                    toggleDraftMode();
                  },
                  child: Icon(
                    Icons.create_sharp,
                    size: MediaQuery.of(context).size.width / 12,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: FloatingActionButton(
              onPressed: resetGrid,
              child: const Icon(Icons.refresh),
            ),
          ),
          FloatingActionButton(
            onPressed: newGrid,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
