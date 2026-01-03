import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iwak_peyek/data/database.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool isOutcome = true;
  final AppDatabase database = AppDatabase();
  TextEditingController categoryNameController = TextEditingController();

  Future<List<Category>> getAllCategories(int type) async {
    return await database.getAllCategoriesRepo(type);
  }

  Future insert(String name, int type) async {
    DateTime now = DateTime.now();
    final row = await database
        .into(database.categories)
        .insertReturning(
          CategoriesCompanion.insert(
            name: name,
            type: type,
            createdAt: now,
            updatedAt: now,
          ),
        );
    print('Masuk :' + row.toString());
  }

  Future<List<Category>> getCategories(int type) async {
    return await database.getAllCategoriesRepo(type);
  }

  Future deleteCategory(int id) async {
    await (database.delete(
      database.categories,
    )..where((tbl) => tbl.id.equals(id))).go();
    setState(() {});
  }

  void openEditDialog(Category category) {
    categoryNameController.text = category.name;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  Text(
                    (isOutcome) ? "Edit Outcome" : "Edit Income",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: (isOutcome) ? Colors.red : Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: categoryNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Name",
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await database
                          .update(database.categories)
                          .replace(
                            category.copyWith(
                              name: categoryNameController.text,
                              updatedAt: DateTime.now(),
                            ),
                          );
                      Navigator.of(context, rootNavigator: true).pop();
                      setState(() {});
                      categoryNameController.clear();
                    },
                    child: Text("Update"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void openDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  Text(
                    (isOutcome) ? "Add Outcome" : "Add Income",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: (isOutcome) ? Colors.red : Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: categoryNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Name",
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await insert(
                        categoryNameController.text,
                        (isOutcome) ? 0 : 1,
                      );
                      Navigator.of(context, rootNavigator: true).pop('dialog');
                      setState(() {});
                      categoryNameController.clear();
                    },
                    child: Text("Save"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch(
                  value: isOutcome,
                  onChanged: (bool value) {
                    setState(() {
                      isOutcome = value;
                    });
                  },
                  inactiveTrackColor: Colors.green[200],
                  inactiveThumbColor: Colors.green,
                  activeThumbColor: Colors.red,
                ),
                IconButton(
                  onPressed: () {
                    openDialog();
                  },
                  icon: Icon(Icons.add),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Category>>(
            future: getAllCategories(isOutcome ? 0 : 1),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData && snapshot.data!.length > 0) {
                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final category = snapshot.data![index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Card(
                          elevation: 4,
                          child: ListTile(
                            leading: (isOutcome)
                                ? Icon(Icons.upload, color: Colors.red)
                                : Icon(Icons.download, color: Colors.green),
                            title: Text(
                              category.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    openEditDialog(category);
                                  },
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                ),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete'),
                                        content: Text(
                                          'Are you sure want to delete this category?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              deleteCategory(category.id);
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else {
                return Center(child: Text("No data"));
              }
            },
          ),
        ],
      ),
    );
  }
}
