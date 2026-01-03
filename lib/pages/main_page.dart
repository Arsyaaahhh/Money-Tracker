import 'package:flutter/material.dart';
import 'package:iwak_peyek/pages/category.dart';
import 'package:iwak_peyek/pages/home_page.dart';
import 'package:iwak_peyek/pages/transaction_page.dart';
import 'package:iwak_peyek/widgets/custom_calendar_appbar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Widget> _children = [HomePage(), CategoryPage()];
  int currentIndex = 0;

  void onTapTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (currentIndex == 0)
          ? CustomCalendarAppBar(
              onDateChanged: (value) => print(value),
              firstDate: DateTime.now().subtract(Duration(days: 140)),
              lastDate: DateTime.now(),
            )
          : AppBar(title: Text('Categories')),

      floatingActionButton: Visibility(
        visible: (currentIndex == 0) ? true : false,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => TransactionPage()));
          },
          backgroundColor: const Color.fromARGB(255, 99, 0, 174),
          child: Icon(Icons.add),
        ),
      ),

      body: _children[currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                onTapTapped(0);
              },
              icon: Icon(Icons.home),
            ),
            SizedBox(width: 20),
            IconButton(
              onPressed: () {
                onTapTapped(1);
              },
              icon: Icon(Icons.list),
            ),
          ],
        ),
      ),
    );
  }
}
