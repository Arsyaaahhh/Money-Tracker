import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iwak_peyek/data/database.dart';
import 'package:flutter/services.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({Key? key}) : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  bool isOutcome = true;
  final AppDatabase database = AppDatabase();
  late String dropDownValue;
  List<Category> categories = [];
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categoryList = await database.getAllCategoriesRepo(isOutcome ? 0 : 1);
    setState(() {
      categories = categoryList;
      dropDownValue = categories.isNotEmpty ? categories.first.name : '';
    });
  }

  Future<void> saveTransaction() async {
    if (amountController.text.isEmpty || dateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final category = categories.firstWhere(
      (c) => c.name == dropDownValue,
      orElse: () => categories.first,
    );

    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(dateController.text);
      // Remove dots dari format rupiah
      String amountText = amountController.text.replaceAll('.', '');

      await database
          .into(database.transactions)
          .insert(
            TransactionsCompanion.insert(
              name: dropDownValue,
              categories_id: category.id,
              amount: int.parse(amountText),
              transaction_date: parsedDate,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transaction saved successfully')));

      amountController.clear();
      dateController.clear();

      // Pop dengan signal untuk refresh home page
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving transaction: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add transaction")),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch(
                    value: isOutcome,
                    onChanged: (bool value) {
                      setState(() {
                        isOutcome = value;
                        _loadCategories();
                      });
                    },
                    inactiveTrackColor: Colors.green[200],
                    inactiveThumbColor: Colors.green,
                    activeThumbColor: Colors.red,
                  ),
                  Text(
                    isOutcome ? 'Outcome' : 'Income',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _RupiahInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: "Amount (Rp)",
                    prefixText: 'Rp ',
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Category',
                  style: GoogleFonts.montserrat(fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: categories.isEmpty
                    ? Text('No categories available')
                    : DropdownButton<String>(
                        value: dropDownValue,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_downward),
                        items: categories.map<DropdownMenuItem<String>>((
                          Category category,
                        ) {
                          return DropdownMenuItem<String>(
                            value: category.name,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            dropDownValue = value ?? '';
                          });
                        },
                      ),
              ),
              SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  readOnly: true,
                  controller: dateController,
                  decoration: InputDecoration(labelText: "Enter date"),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      String formattedDate = DateFormat(
                        'yyyy-MM-dd',
                      ).format(pickedDate);

                      dateController.text = formattedDate;
                    }
                  },
                ),
              ),
              SizedBox(height: 25),
              Center(
                child: ElevatedButton(
                  onPressed: saveTransaction,
                  child: Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String value = newValue.text.replaceAll('.', '');

    if (value.length <= 3) {
      return TextEditingValue(
        text: value,
        selection: TextSelection.fromPosition(
          TextPosition(offset: value.length),
        ),
      );
    }

    StringBuffer result = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(value[i]);
    }

    return TextEditingValue(
      text: result.toString(),
      selection: TextSelection.fromPosition(
        TextPosition(offset: result.length),
      ),
    );
  }
}
