import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomCalendarAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final Function(DateTime)? onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomCalendarAppBar({
    Key? key,
    this.onDateChanged,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  State<CustomCalendarAppBar> createState() => _CustomCalendarAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(60);
}

class _CustomCalendarAppBarState extends State<CustomCalendarAppBar> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: widget.firstDate ?? DateTime(2000),
            lastDate: widget.lastDate ?? DateTime.now(),
          );
          if (picked != null && picked != selectedDate) {
            setState(() {
              selectedDate = picked;
            });
            widget.onDateChanged?.call(picked);
          }
        },
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20),
            SizedBox(width: 8),
            Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
          ],
        ),
      ),
      backgroundColor: Color.fromARGB(255, 99, 0, 174),
      elevation: 0,
    );
  }
}
