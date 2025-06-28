// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:label_scanner/widgets/custom_app_bar.dart';
// // import 'home_page.dart';
// //
// // class InitialDrugAdd extends StatefulWidget {
// //   const InitialDrugAdd({super.key});
// //
// //   @override
// //   State<InitialDrugAdd> createState() => _InitialDrugAddPageState();
// // }
// //
// // class _InitialDrugAddPageState extends State<InitialDrugAdd> {
// //   final TextEditingController _controller = TextEditingController();
// //   List<String> _medicamente = [];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadSavedDrugs();
// //   }
// //
// //   Future<void> _loadSavedDrugs() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final saved = prefs.getStringList('medicamente') ?? [];
// //     setState(() {
// //       _medicamente = saved;
// //     });
// //   }
// //
// //   Future<void> _saveDrugs() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setStringList('medicamente', _medicamente);
// //   }
// //
// //   void _adaugaMedicament() {
// //     String input = _controller.text.trim();
// //     if (input.isNotEmpty && !_medicamente.contains(input.toLowerCase())) {
// //       setState(() {
// //         _medicamente.add(input.toLowerCase());
// //         _controller.clear();
// //       });
// //       _saveDrugs();
// //     }
// //   }
// //
// //   void _stergeMedicament(String med) {
// //     setState(() {
// //       _medicamente.remove(med);
// //     });
// //     _saveDrugs();
// //   }
// //
// //   Future<void> _salveazaSiContinua() async {
// //     await _saveDrugs();
// //     Navigator.pushReplacement(
// //       context,
// //       MaterialPageRoute(builder: (_) => const HomePage()),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: const CustomAppBar(),
// //       body: Padding(
// //         padding: const EdgeInsets.all(20.0),
// //         child: Column(
// //           children: [
// //             const Text(
// //               'Adaugă medicamentele pe care le iei',
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //
// //             /// 🔹 Input + Button
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _controller,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Nume medicament',
// //                       labelStyle: TextStyle(
// //                         color: Color.fromARGB(255, 1, 139, 203),
// //                       ),
// //                     ),
// //                     onSubmitted: (_) => _adaugaMedicament(),
// //                   ),
// //                 ),
// //                 IconButton(
// //                   icon: const Icon(Icons.add),
// //                   color: const Color.fromARGB(255, 1, 139, 203),
// //                   onPressed: _adaugaMedicament,
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 10),
// //
// //             /// 🔹 Lista de medicamente
// //             Expanded(
// //               child: _medicamente.isEmpty
// //                   ? const Text('Nu ai introdus încă medicamente.')
// //                   : ListView.builder(
// //                 itemCount: _medicamente.length,
// //                 itemBuilder: (context, index) {
// //                   final med = _medicamente[index];
// //                   return Card(
// //                     elevation: 3,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                     margin: const EdgeInsets.symmetric(vertical: 6),
// //                     child: ListTile(
// //                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //                       title: Text(
// //                         med,
// //                         style: const TextStyle(
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                       trailing: IconButton(
// //                         icon: const Icon(Icons.delete, color: Colors.red),
// //                         onPressed: () => _stergeMedicament(med),
// //                         tooltip: 'Șterge',
// //                       ),
// //                     ),
// //                   );
// //
// //                 },
// //               ),
// //             ),
// //
// //             /// 🔹 Buton de continuare
// //             ElevatedButton(
// //               onPressed: _medicamente.isEmpty ? null : _salveazaSiContinua,
// //               style: ElevatedButton.styleFrom(
// //                 foregroundColor: const Color.fromARGB(255, 1, 139, 203), // culoarea textului
// //               ),
// //               child: const Text('Salvează'),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:label_scanner/widgets/custom_app_bar.dart';
// import 'home_page.dart';
//
// class InitialDrugAdd extends StatefulWidget {
//   const InitialDrugAdd({super.key});
//
//   @override
//   State<InitialDrugAdd> createState() => _InitialDrugAddPageState();
// }
//
// class _InitialDrugAddPageState extends State<InitialDrugAdd> {
//   final TextEditingController _controller = TextEditingController();
//   List<String> _medicamente = [];
//   List<String> _sugestii = [];
//   bool _isLoadingSuggestions = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSavedDrugs();
//   }
//
//   //Încarcă lista salvată în memoria locală
//   Future<void> _loadSavedDrugs() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList('medicamente') ?? [];
//     setState(() {
//       _medicamente = saved;
//     });
//   }
//
//   //Salvează lista curentă de medicamente local, sub cheia medicamente
//   Future<void> _saveDrugs() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList('medicamente', _medicamente);
//   }
//
//   void _adaugaMedicament() {
//     String input = _controller.text.trim();
//     //Verifică dacă inputul este valid și îl adaugă în listă.
//     if (input.isNotEmpty && !_medicamente.contains(input.toLowerCase())) {
//       setState(() {
//         _medicamente.add(input.toLowerCase());
//         _controller.clear();
//         _sugestii.clear();
//       });
//       _saveDrugs();
//     }
//   }
//
//   void _stergeMedicament(String med) {
//     setState(() {
//       _medicamente.remove(med);
//     });
//     _saveDrugs();
//   }
//
//   Future<void> _salveazaSiContinua() async {
//     await _saveDrugs();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const HomePage()),
//     );
//   }
//
//   Future<void> searchMedicines(String query) async {
//     if (query.length < 3) return;
//
//     setState(() {
//       _isLoadingSuggestions = true;
//     });
//
//     final response = await http.get(
//       Uri.parse('https://myhealthbox.p.rapidapi.com/search/fulltext?q=$query&l=ro'),
//       headers: {
//         'X-RapidAPI-Key': '6c30338101msh1eb51ac53e34f45p137cc6jsnded834403064',
//         'X-RapidAPI-Host': 'myhealthbox.p.rapidapi.com',
//       },
//     );
//
//     print('🔹 URL: ${response.request?.url}');
//     print('🔹 Status: ${response.statusCode}');
//     print('🔹 Body: ${response.body}');
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final List<String> results = [];
//
//       for (var item in data['result'] ?? []) {
//         if (item['commercial_name'] != null) {
//           results.add(item['commercial_name']);
//         }
//       }
//
//       setState(() {
//         _sugestii = results;
//       });
//     } else {
//       setState(() {
//         _sugestii = [];
//       });
//     }
//
//     setState(() {
//       _isLoadingSuggestions = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               const Text(
//                 'Adaugă medicamentele pe care le iei',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _controller,
//                       decoration: const InputDecoration(
//                         labelText: 'Nume medicament',
//                         labelStyle: TextStyle(
//                           color: Color.fromARGB(255, 1, 139, 203),
//                         ),
//                       ),
//                       onSubmitted: (_) => _adaugaMedicament(),
//                       onChanged: (value) {
//                         searchMedicines(value.trim());
//                       },
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.add),
//                     color: const Color.fromARGB(255, 1, 139, 203),
//                     onPressed: _adaugaMedicament,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//
//               /// 🔹 Sugestii din API
//               if (_sugestii.isNotEmpty)
//                 ..._sugestii.map((sugestie) => ListTile(
//                   title: Text(sugestie),
//                   onTap: () {//Când dai tap pe o sugestie este adăugată în listă
//                     _controller.text = sugestie;
//                     _sugestii.clear();
//                     _adaugaMedicament();
//                   },
//                 )),
//               //Arată că se face o căutare
//               if (_isLoadingSuggestions)
//                 const Padding(
//                   padding: EdgeInsets.only(top: 8),
//                   child: CircularProgressIndicator(),
//                 ),
//
//               const SizedBox(height: 10),
//
//               /// 🔹 Lista de medicamente
//               SizedBox(
//                 height: 570,
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: _medicamente.length,
//                   itemBuilder: (context, index) {
//                     final med = _medicamente[index];
//                     return Card(
//                       elevation: 3,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       margin: const EdgeInsets.symmetric(vertical: 6),
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                         title: Text(
//                           med,
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () => _stergeMedicament(med),
//                           tooltip: 'Șterge',
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//
//                /// 🔹 Buton de salvare a medicamentelor
//               ElevatedButton(
//                 onPressed: _medicamente.isEmpty ? null : _salveazaSiContinua,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor:
//                   const Color.fromARGB(255, 1, 139, 203), // text color
//                 ),
//                 child: const Text('Salvează'),
//               ),
//             ],
//         ),
//       ),
//       )
//     );
//   }
// }
//
// //varianta simpla fara myhealthbox
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:label_scanner/widgets/custom_app_bar.dart';
// import 'home_page.dart';
//
// class InitialDrugAdd extends StatefulWidget {
//   const InitialDrugAdd({super.key});
//
//   @override
//   State<InitialDrugAdd> createState() => _InitialDrugAddPageState();
// }
//
// class _InitialDrugAddPageState extends State<InitialDrugAdd> {
//   final TextEditingController _controller = TextEditingController();
//   List<String> _medicamente = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSavedDrugs();
//   }
//
//   Future<void> _loadSavedDrugs() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList('medicamente') ?? [];
//     setState(() {
//       _medicamente = saved;
//     });
//   }
//   Future<void> _saveDrugs() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList('medicamente', _medicamente);
//   }
//
//   void _adaugaMedicament() {
//     String input = _controller.text.trim();
//     if (input.isNotEmpty && !_medicamente.contains(input.toLowerCase())) {
//       setState(() {
//         _medicamente.add(input.toLowerCase());
//         _controller.clear();
//       });
//       _saveDrugs();
//     }
//   }
//
//   void _stergeMedicament(String med) {
//     setState(() {
//       _medicamente.remove(med);
//     });
//     _saveDrugs();
//   }
//
//   Future<void> _salveazaSiContinua() async {
//     await _saveDrugs();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const HomePage()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             const Text(
//               'Adaugă medicamentele pe care le iei',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//
//             /// 🔹 Input + Button
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       labelText: 'Nume medicament',
//                       labelStyle: TextStyle(
//                         color: Color.fromARGB(255, 1, 139, 203),
//                       ),
//                     ),
//                     onSubmitted: (_) => _adaugaMedicament(),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.add),
//                   color: const Color.fromARGB(255, 1, 139, 203),
//                   onPressed: _adaugaMedicament,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//
//             /// 🔹 Lista de medicamente
//             Expanded(
//               child: _medicamente.isEmpty
//                   ? const Text('Nu ai introdus încă medicamente.')
//                   : ListView.builder(
//                 itemCount: _medicamente.length,
//                 itemBuilder: (context, index) {
//                   final med = _medicamente[index];
//                   return Card(
//                     elevation: 3,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     margin: const EdgeInsets.symmetric(vertical: 6),
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       title: Text(
//                         med,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.red),
//                         onPressed: () => _stergeMedicament(med),
//                         tooltip: 'Șterge',
//                       ),
//                     ),
//                   );
//
//                 },
//               ),
//             ),
//
//             /// 🔹 Buton de continuare
//             ElevatedButton(
//               onPressed: _medicamente.isEmpty ? null : _salveazaSiContinua,
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: const Color.fromARGB(255, 1, 139, 203), // culoarea textului
//               ),
//               child: const Text('Salvează'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//varianta cu myHealthBox
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:label_scanner/widgets/custom_app_bar.dart';
import 'home_page.dart';

class InitialDrugAdd extends StatefulWidget {
  const InitialDrugAdd({super.key});

  @override
  State<InitialDrugAdd> createState() => _InitialDrugAddPageState();
}

class _InitialDrugAddPageState extends State<InitialDrugAdd> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _medicamente = [];
  List<Map<String, String>> _sugestii = [];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDrugs();
  }

  Future<void> _loadSavedDrugs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('medicamente') ?? [];
    setState(() {
      _medicamente =
          saved.map((e) => Map<String, String>.from(json.decode(e))).toList();
    });
  }
  Future<void> _saveDrugs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _medicamente.map((e) => json.encode(e)).toList();
    await prefs.setStringList('medicamente', jsonList);
  }

  void _adaugaMedicament(String nume, String substanta) {
    final medicament = {'nume': nume, 'substanta': substanta};
    if (!_medicamente
        .any((m) => m['nume']!.toLowerCase() == nume.toLowerCase())) {
      setState(() {
        _medicamente.add(medicament);
        _controller.clear();
        _sugestii.clear();
      });
      _saveDrugs();
    }
  }

  void _stergeMedicament(Map<String, String> med) {
    setState(() {
      _medicamente.remove(med);
    });
    _saveDrugs();
  }

  Future<void> _salveazaSiContinua() async {
    await _saveDrugs();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> searchMedicines(String query) async {
    if (query.length < 3) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    final response = await http.get(
      Uri.parse(
          'https://myhealthbox.p.rapidapi.com/search/fulltext?q=$query&l=ro'),
      headers: {
        'X-RapidAPI-Key': '6c30338101msh1eb51ac53e34f45p137cc6jsnded834403064',
        'X-RapidAPI-Host': 'myhealthbox.p.rapidapi.com',
      },
    );

    print('🔹 URL: ${response.request?.url}');
    print('🔹 Status: ${response.statusCode}');
    print('🔹 Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Map<String, String>> results = [];

      for (var item in data['result'] ?? []) {
        if (item['commercial_name'] != null &&
            item['active_ingredient'] != null) {
          results.add({
            'nume': item['commercial_name'],
            'substanta': item['active_ingredient']
          });
        }
      }

      setState(() {
        _sugestii = results;
      });
    } else {
      setState(() {
        _sugestii = [];
      });
    }
    setState(() {
      _isLoadingSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adaugă medicamentele pe care le iei',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Nume medicament',
                        labelStyle:
                        TextStyle(color: Color.fromARGB(255, 1, 139, 203)),
                      ),
                      onChanged: (value) {
                        searchMedicines(value.trim());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              /// Sugestii
              if (_sugestii.isNotEmpty)
                ..._sugestii.map((sugestie) => ListTile(
                  title: Text(sugestie['nume']!),
                  subtitle: Text(sugestie['substanta']!),
                  onTap: () {
                    _controller.text = sugestie['nume']!;
                    _adaugaMedicament(
                        sugestie['nume']!, sugestie['substanta']!);
                  },
                )),
              if (_isLoadingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 10),

              /// Lista medicamente adăugate
              const Text(
                'Medicamente adăugate:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 400,
                child: _medicamente.isEmpty
                    ? const Text('Nu ai introdus încă medicamente.')
                    : ListView.builder(
                  itemCount: _medicamente.length,
                  itemBuilder: (context, index) {
                    final med = _medicamente[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        title: Text(med['nume']!),
                        subtitle: Text(med['substanta']!),
                        trailing: IconButton(
                          icon:
                          const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _stergeMedicament(med),
                          tooltip: 'Șterge',
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 150),
              Center(
                child: ElevatedButton(
                  onPressed: _medicamente.isEmpty ? null : _salveazaSiContinua,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 1, 139, 203),
                  ),
                  child: const Text('Salvează'),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
