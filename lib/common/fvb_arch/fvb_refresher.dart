import 'package:flutter/material.dart';

const String snackbarCode='''
void showSnackbar(context,String message,double second){
  ScaffoldMessenger.maybeOf(context)!
      .showSnackBar(SnackBar(
    content: Text(
      message,
      style: const TextStyle(fontSize:14, color: Colors.white),
      textAlign: TextAlign.center,
    ),
    // backgroundColor: Colors.grey,
    duration:
    Duration(milliseconds: (1000 * second).toInt()),
  ));
}
''';

const String fvbRefresherCode = '''
final refreshNotifiers = <String,RefreshNotifier>{};

class RefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

class Refresher extends StatelessWidget {
  final Widget Function() builder;
  final String id;
  Refresher(this.id, this.builder, {Key? key}) : super(key: key){
    refreshNotifiers[id]=RefreshNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: refreshNotifiers[id]!,
      builder: (context, child) {
        return builder();
      },
    );
  }
}

void refresh(String id) {
  refreshNotifiers[id]!.refresh();
}
''';

const fvbLookUpCode = '''
dynamic lookUp(String id) {
  return (GlobalObjectKey(id).currentWidget!);
}
''';

dynamic lookUp(String id) {
  return (GlobalObjectKey(id).currentWidget!);
}

final refreshNotifiers = <String, RefreshNotifier>{};

class RefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

class Refresher extends StatelessWidget {
  final Widget Function() builder;
  final String id;
  Refresher(this.id, this.builder, {Key? key}) : super(key: key) {
    refreshNotifiers[id] = RefreshNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: refreshNotifiers[id]!,
      builder: (context, child) {
        return builder();
      },
    );
  }
}

void refresh(String id) {
  refreshNotifiers[id]!.refresh();
}
