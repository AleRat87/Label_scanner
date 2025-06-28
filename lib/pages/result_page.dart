import 'dart:io';
import 'package:flutter/material.dart';
import 'package:label_scanner/widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


// class ResultPage extends StatefulWidget {
//   final File processedImage;
//   final String extractedText;
//   final List<String> ingredients;
//
//   const ResultPage({
//     super.key,
//     required this.processedImage,
//     required this.extractedText,
//     required this.ingredients,
//   });
//
//   @override
//   State<ResultPage> createState() => _ResultPageState();
// }
// class _ResultPageState extends State<ResultPage> {
//   String _mesaj = '';
//
//   Future<void> getFoodInteractionMessage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final medicamenteRaw = prefs.getStringList('medicamente') ?? [];
//
//     // extrage doar substanțele active
//     final substante = medicamenteRaw
//         .map((e) => json.decode(e)['substanta'] as String)
//         .toSet()
//         .toList();
//
//     if (substante.isEmpty || widget.ingredients.isEmpty) {
//       setState(() {
//         _mesaj = 'Nu există medicamente sau ingrediente.';
//       });
//       return;
//     }
//
//     try {
//       final response = await http.post(
//         Uri.parse('http://192.168.100.87:5000/get_food_interactions'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'name': substante,
//           'ingrediente': widget.ingredients,
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         // Construirea mesajului detaliat pentru interacțiuni
//         String mesajEvitate = '';
//         if (data['alimente_evitate'].isNotEmpty) {
//           mesajEvitate = 'ATENȚIE! Acest aliment se recomandă să fie evitat deoarece conține ';
//           data['alimente_evitate'].forEach((alimente) {
//             mesajEvitate += '$alimente\n';
//           });
//         }
//
//         setState(() {
//           _mesaj = '$mesajEvitate\n';
//         });
//       } else {
//         final errorData = json.decode(response.body);
//         setState(() {
//           _mesaj = errorData['error'] ?? 'Eroare necunoscută';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _mesaj = 'Eroare la comunicarea cu serverul.';
//       });
//     }
//   }
//
//
//   @override
//   void initState() {
//     super.initState();
//     getFoodInteractionMessage();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//
//             Image.file(widget.processedImage, width: double.infinity, height: 400),
//             const SizedBox(height: 20),
//
//             Text(_mesaj.isNotEmpty ? _mesaj : 'Se verifică...',
//               style: TextStyle(
//                 fontSize: 20.0,               // Dimensiunea textului
//                 fontWeight: FontWeight.bold,  // Grosimea textului (bold)
//                 color: Colors.redAccent,    // Culoarea textului
//                 letterSpacing: 1.2,           // Spațierea între litere
//               ),
//             ),
//             const Text(
//               'Ingrediente Extrase:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             widget.ingredients.isNotEmpty
//                 ? Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: widget.ingredients
//                   .map((ingredient) => Text("• $ingredient"))
//                   .toList(),
//             )
//                 : const Text("Nu s-au găsit ingrediente."),
//           ],
//         ),
//       ),
//     );
//   }
// }

class ResultPage extends StatefulWidget {
  final File processedImage;
  final String extractedText;
  final List<String> ingredients;

  const ResultPage({
    super.key,
    required this.processedImage,
    required this.extractedText,
    required this.ingredients,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String _mesaj = '';

  Future<void> getFoodInteractionMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final medicamenteRaw = prefs.getStringList('medicamente') ?? [];

    // extrage doar substanțele active
    final substante = medicamenteRaw
        .map((e) => json.decode(e)['substanta'] as String)
        .toSet()
        .toList();

    if (substante.isEmpty || widget.ingredients.isEmpty) {
      setState(() {
        _mesaj = 'Nu există medicamente sau ingrediente.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.87:5000/get_food_interactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': substante,
          'ingrediente': widget.ingredients,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Construirea mesajului detaliat pentru interacțiuni
        String mesajEvitate = '';
        if (data['alimente_evitate'].isNotEmpty) {
          mesajEvitate = 'ATENȚIE! Acest aliment se recomandă să fie evitat deoarece conține ';
          data['alimente_evitate'].forEach((alimente) {
            mesajEvitate += '$alimente.';
          });
        }

        setState(() {
          _mesaj = mesajEvitate;
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _mesaj = errorData['error'] ?? 'Eroare necunoscută';
        });
      }
    } catch (e) {
      setState(() {
        _mesaj = 'Eroare la comunicarea cu serverul.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getFoodInteractionMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imaginea procesată
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 3), // Umbră ușoară
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.processedImage,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mesajul de interacțiune cu alimentele
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: _mesaj.isEmpty ? Colors.green.shade400 : Colors.redAccent.shade200,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _mesaj.isEmpty ? Colors.green.shade200 : Colors.redAccent.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _mesaj.isEmpty
                      ? 'Acest aliment nu interacționează cu medicamentația dumneavoastră.'
                      : _mesaj,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ingrediente extrase
            const Text(
              'Ingrediente extrase:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            widget.ingredients.isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.ingredients
                  .map((ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ))
                  .toList(),
            )
                : const Text("Nu s-au găsit ingrediente."),
          ],
        ),
      ),
    );
  }
}
