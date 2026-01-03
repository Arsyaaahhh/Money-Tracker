import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iwak_peyek/data/database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDatabase database = AppDatabase();
  late Future<List<TransactionData>> _transactionFuture;

  @override
  void initState() {
    super.initState();
    _transactionFuture = database.getAllTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      _transactionFuture = database.getAllTransactions();
    });
  }

  Future<int> _calculateIncome() async {
    final transactions = await database.getAllTransactions();
    return transactions
        .where((t) => t.categories_id % 2 == 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  Future<int> _calculateOutcome() async {
    final transactions = await database.getAllTransactions();
    return transactions
        .where((t) => t.categories_id % 2 != 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  String formatRupiah(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _generateAndPrintPDF() async {
    final now = DateTime.now();
    final allTransactions = await database.getAllTransactions();

    // Filter transactions for current month
    final transactions = allTransactions.where((t) {
      return t.transaction_date.month == now.month &&
          t.transaction_date.year == now.year;
    }).toList();

    final income = transactions
        .where((t) => t.categories_id % 2 == 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final outcome = transactions
        .where((t) => t.categories_id % 2 != 0)
        .fold<int>(0, (sum, t) => sum + t.amount);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Transaksi ${DateFormat('MMMM yyyy', 'id_ID').format(now)}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(now)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Ringkasan',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Income: Rp ${_formatNumber(income)}'),
                    pw.Text('Total Outcome: Rp ${_formatNumber(outcome)}'),
                    pw.Text('Saldo: Rp ${_formatNumber(income - outcome)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Detail Transaksi',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Kategori',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Tanggal',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Jumlah',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Tipe',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...transactions.map((t) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(t.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            DateFormat(
                              'dd MMM yyyy',
                              'id_ID',
                            ).format(t.transaction_date),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Rp ${_formatNumber(t.amount)}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            t.categories_id % 2 == 0 ? 'Income' : 'Outcome',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name:
          'Laporan_Transaksi_${DateFormat('dd_MM_yyyy').format(DateTime.now())}',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,##0', 'id_ID').format(number).replaceAll(',', '.');
  }

  Future<void> _showEditDialog(TransactionData transaction) async {
    final TextEditingController amountController = TextEditingController(
      text: transaction.amount.toString(),
    );
    final TextEditingController dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(transaction.transaction_date),
    );
    List<Category> categories = [];
    late int selectedCategoryId;

    // Load categories based on type
    final categoryList = await database.getAllCategoriesRepo(
      transaction.categories_id % 2 == 0 ? 1 : 0,
    );
    categories = categoryList;
    selectedCategoryId = transaction.categories_id;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value != null) {
                            selectedCategoryId = value;
                          }
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date (yyyy-MM-dd)',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: transaction.transaction_date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          dateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(pickedDate);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (amountController.text.isEmpty ||
                          dateController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      DateTime parsedDate = DateFormat(
                        'yyyy-MM-dd',
                      ).parse(dateController.text);
                      int amount = int.parse(amountController.text);

                      // Get selected category name
                      final selectedCategory = categories.firstWhere(
                        (c) => c.id == selectedCategoryId,
                      );

                      final updatedTransaction = TransactionData(
                        id: transaction.id,
                        name: selectedCategory.name,
                        categories_id: selectedCategoryId,
                        amount: amount,
                        transaction_date: parsedDate,
                        createdAt: transaction.createdAt,
                        updatedAt: DateTime.now(),
                        deletedAt: transaction.deletedAt,
                      );

                      await database.updateTransaction(updatedTransaction);
                      _refreshTransactions();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Transaction updated successfully'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTransaction(int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (result ?? false) {
      try {
        await database.deleteTransaction(id);
        _refreshTransactions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //dashboard total income & outcome
            FutureBuilder<int>(
              future: _calculateIncome(),
              builder: (context, incomeSnapshot) {
                return FutureBuilder<int>(
                  future: _calculateOutcome(),
                  builder: (context, outcomeSnapshot) {
                    final income = incomeSnapshot.data ?? 0;
                    final outcome = outcomeSnapshot.data ?? 0;

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  child: Icon(
                                    Icons.download,
                                    color: Colors.green,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Income",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      formatRupiah(income),
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  child: Icon(Icons.upload, color: Colors.red),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Outcome",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      formatRupiah(outcome),
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            //text transaction
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Transaction",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            //list transaction
            FutureBuilder<List<TransactionData>>(
              future: _transactionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Column(
                    children: snapshot.data!.map((transaction) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Card(
                          elevation: 4,
                          child: ListTile(
                            title: Text(
                              formatRupiah(transaction.amount),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${transaction.name} - ${DateFormat('dd MMM yyyy').format(transaction.transaction_date)}',
                            ),
                            leading: Icon(
                              transaction.categories_id % 2 == 0
                                  ? Icons.download
                                  : Icons.upload,
                              color: transaction.categories_id % 2 == 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditDialog(transaction),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _deleteTransaction(transaction.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No transactions yet'),
                  );
                }
              },
            ),
            //button download
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    onPressed: _generateAndPrintPDF,
                    backgroundColor: Color.fromARGB(255, 99, 0, 174),
                    child: Icon(Icons.download, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
