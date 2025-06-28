import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DrugAddPage extends StatefulWidget {

  const DrugAddPage({super.key});

  @override
  State<DrugAddPage> createState() => _DrugAddPageState();
}

class _DrugAddPageState extends State<DrugAddPage> {
  final TextEditingController _controller = TextEditingController();
  String _mesaj = '';

  final List<String> listaIngrediente = ['usturoi', 'zahar', 'mere', 'chimion', 'naut']; // Lista de ingrediente dorite

// Functie pentru a trimite cererea POST
  Future<void> _afiseazaMesaj() async {
    String substanta = _controller.text.trim();
    if (substanta.isEmpty) {
      setState(() {
        _mesaj = 'Te rog introdu un nume de substanță!';
      });
      return;
    }

    final response = await http.post(
      Uri.parse('http://192.168.100.87:5000/get_food_interactions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': substanta,
        'ingrediente': listaIngrediente,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);

        // Verificăm dacă răspunsul conține alimentele evitate și recomandate
        if (data.containsKey('alimente_evitate') && data['alimente_evitate'] != null) {
          final alimenteEvitate = data['alimente_evitate'];
          if (alimenteEvitate.isEmpty) {
            print('Nu există alimente evitate.');
          } else {
            print('Alimente evitate: $alimenteEvitate');
          }
        }

        if (data.containsKey('alimente_recomandate') && data['alimente_recomandate'] != null) {
          final alimenteRecomandate = data['alimente_recomandate'];
          if (alimenteRecomandate.isEmpty) {
            print('Nu există alimente recomandate.');
          } else {
            print('Alimente recomandate: $alimenteRecomandate');
          }
        }

        // Setăm mesajul în funcție de datele extrase
        setState(() {
          _mesaj = 'Alimente evitate: ${data['alimente_evitate']}\nAlimente recomandate: ${data['alimente_recomandate']}';
        });

      } catch (e) {
        setState(() {
          _mesaj = 'Eroare la procesarea răspunsului JSON.';
        });
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        setState(() {
          _mesaj = errorData['error'] ?? 'Eroare necunoscută';
        });
      } catch (e) {
        setState(() {
          _mesaj = 'Eroare la procesarea răspunsului JSON.';
        });
      }
    }
  }


  // Functie pentru a face cererea GET
  // Future<void> _afiseazaMesajTextCSV() async {
  //   String substanta = _controller.text.trim();
  //   if (substanta.isEmpty) {
  //     setState(() {
  //       _mesaj = 'Te rog introdu un nume de substanță!';
  //     });
  //     return;
  //   }
  //
  //   final response = await http.get(Uri.parse('http://192.168.100.87:5000/get_food_interactions?name=$substanta'));
  //
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     setState(() {
  //       _mesaj = 'Interacțiuni cu alimente: ${data['food_interactions']}';
  //     });
  //   } else {
  //     setState(() {
  //       _mesaj = 'Eroare: ${json.decode(response.body)['error']}';
  //     });
  //   }
  // }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Introducere substanță de bază'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _controller,
//               decoration: InputDecoration(
//                 labelText: 'Introdu numele substanței de bază',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _afiseazaMesajTextCSV,
//               child: Text('Căutare în server'),
//             ),
//             SizedBox(height: 20),
//             Text(
//               _mesaj,
//               style: TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interacțiuni aliment - medicament'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Introdu numele substanței de bază',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _afiseazaMesaj,
              child: Text('Căutare în server'),
            ),
            SizedBox(height: 20),
            Text(
              _mesaj,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}