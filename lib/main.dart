import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:label_scanner/pages/home_page.dart';
import 'package:label_scanner/pages/login.dart';
import 'package:label_scanner/pages/drug_add.dart';
import 'package:label_scanner/pages/initial_drug_add.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasDrugs = prefs.getStringList('medicamente')?.isNotEmpty ?? false;

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: hasDrugs ? const HomePage() : const InitialDrugAdd(),
  ));
}
// void main() async{
//   runApp(MaterialApp(
//     home: DrugAddPage(), // temporar pentru testare
//   ));
// }