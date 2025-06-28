import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:label_scanner/widgets/picker_option_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:label_scanner/pages/initial_drug_add.dart';
import 'package:label_scanner/widgets/custom_app_bar.dart';
import 'package:label_scanner/pages/result_page.dart';



class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _extractedText = '';
  File? _processedImage;

//pick image from the source
  Future<File?> _pickerImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  //varianta simpla cu flutter de a preprocesa imagine(doar convertire grayscale)
  Future<File> _preprocessImage(File imageFile) async {
    try {
      // 1. Citim imaginea ca obiect Image
      final rawImage = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(rawImage);

      if (image == null) return imageFile;

      // 2. Convertim la grayscale
      img.Image grayImage = img.grayscale(image);

      // 4. Salvăm imaginea preprocesată
      final processedBytes = img.encodeJpg(grayImage);
      final processedFile = File(imageFile.path)..writeAsBytesSync(processedBytes);

      return processedFile;
    }catch (e) {
      print("Eroare la procesare: $e");
      return imageFile;
    }
  }

  //extragem textul cu OCR folosind TextRecognizer din GoogleMLKitTextRecognizer
  Future<String> _recognizeTextFromImage({required String imgPath}) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final image = InputImage.fromFile(File(imgPath));
    final recognized = await textRecognizer.processImage(image);

    return recognized.text;
  }

//textul extras il trimitem la server de unde primim inapoi lista de ingrediente
  Future<List<String>> getIngredientsFromServer(String text) async {
    final url = Uri.parse('http://192.168.100.87:5000/extract_ingredients');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['ingredients']);
    } else {
      throw Exception('Eroare la server: ${response.statusCode}');
    }
  }

  //functie ce afiseaza ingredientele extrase
  void _showIngredientsDialog(List<String> ingredients) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Ingrediente Extrase"),
          content: ingredients.isNotEmpty
              ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ingredients.map((ingredient) => Text("• $ingredient")).toList(),
          )
              : Text("Nu s-au găsit ingrediente."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
//-----------------------------------------------------------------------------
  List<String> _extractIngredients(String text) {
    RegExp regex = RegExp(r"Ingrediente:\s*(.+?)(?=\.)", caseSensitive: false);
    Match? match = regex.firstMatch(text);

    if (match != null) {
      String ingredientString = match.group(1) ?? "";
      // Separăm ingredientele pe bază de virgulă
      List<String> rawIngredients = ingredientString.split(RegExp(r",\s*"));
      // Curățăm fiecare ingredient: eliminăm procentele și numerele de la început
      List<String> cleanedIngredients = rawIngredients.map((ingredient) {
        return ingredient.replaceAll(RegExp(r"^\d+([,.]\d+)?%\s*"), "").trim();
      }).toList();
      return cleanedIngredients;
    }
    return []; // Returnează listă goală dacă nu găsește "Ingrediente:"
  }

//functie care foloseste regex pentru a extrage ingredientele
  Future<void> _processImageExtractTextOLD({
    required ImageSource imageSource,
  }) async {
    final imageFile = await _pickerImage(source: imageSource);

    if (imageFile == null) return;

    final preprocessedImage = await _preprocessImage(imageFile);

    setState(() {
      _processedImage = preprocessedImage;
    });

    final recognizedText = await _recognizeTextFromImage(
      imgPath: preprocessedImage.path,
    );

    // ✅ Transformăm textul OCR într-un singur string coerent
    String formattedText = recognizedText.replaceAll("\n", " ");
    print("Text formatat: $formattedText");

    List<String> ingredients = _extractIngredients(formattedText);

    setState(() => _extractedText = recognizedText);

    _showIngredientsDialog(ingredients);
  }
  //-----------------------------------------------------------------------------

  Future<File?> sendImageToFlask(File imageFile) async {
    final uri = Uri.parse('http://192.168.100.87:5000/process-image');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Uint8List imageBytes = base64Decode(response.body);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(imageBytes);
      return file;
    } else {
      throw Exception("Procesarea imaginii a eșuat: ${response.statusCode}");
    }
  }

  Future<File?> sendImageToFlaskOld(File imageFile) async {
    try {
      final uri = Uri.parse('http://192.168.100.87:5000/process-image');
      // Curăță imaginile vechi procesate
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      final files = dir.listSync();
      for (var file in files) {
        if (file is File && file.path.contains('processed_')) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
      // Trimite imaginea originală la server
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        // Decodează imaginea procesată primită de la server
        final Uint8List imageBytes = base64Decode(response.body);
        // Salvează local cu nume unic
        final fileName = 'processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final processedFile = File('${tempDir.path}/$fileName');
        await processedFile.writeAsBytes(imageBytes);

        return processedFile;
      } else {
        throw Exception("Procesarea imaginii a eșuat: ${response.statusCode}");
      }
    } catch (e) {
      print("Eroare la trimiterea imaginii către server: $e");
      return null;
    }
  }

// //functie in care luam imaginea, o preprocesam, extragem textul cu OCR si il trimitem la server,
//   //primind o lista de ingrediente inapoi pe care o afisam
//   Future<void> _processImageExtractText({
//     required ImageSource imageSource,
//   }) async {
//     final imageFile = await _pickerImage(source: imageSource);
//
//     if (imageFile == null) return;
//
//     final preprocessedImage = await _preprocessImage(imageFile);
//
//     // final preprocessedImage = await sendImageToFlask(imageFile);
//     // if (preprocessedImage == null) return;
//
//     setState(() {
//       _processedImage = preprocessedImage;
//     });
//
//     final recognizedText = await _recognizeTextFromImage(
//       imgPath: preprocessedImage.path,
//     );
//
//     // ✅ Transformăm textul OCR într-un singur string coerent
//     String formattedText = recognizedText.replaceAll("\n", " ");
//     print("Text formatat: $formattedText");
//
//     List<String> ingredients = [];
//     try {
//       ingredients = await getIngredientsFromServer(formattedText);
//     } catch (e) {
//       print("Eroare la comunicarea cu serverul: $e");
//     }
//
//     setState(() => _extractedText = recognizedText);
//
//     _showIngredientsDialog(ingredients);
//   }

  //functie in care luam imaginea, o preprocesam, extragem textul cu OCR si il trimitem la server,
  //primind o lista de ingrediente inapoi pe care o afisam
  Future<void> _processImageExtractText({
    required ImageSource imageSource,
  }) async {
    final imageFile = await _pickerImage(source: imageSource);

    if (imageFile == null) return;

    //final preprocessedImage = await _preprocessImage(imageFile);

    final preprocessedImage = await sendImageToFlask(imageFile);
    if (preprocessedImage == null) return;

    setState(() {
      _processedImage = preprocessedImage;
    });

    final recognizedText = await _recognizeTextFromImage(
      imgPath: preprocessedImage.path,
    );

    // ✅ Transformăm textul OCR într-un singur string coerent
    String formattedText = recognizedText.replaceAll("\n", " ");
    print("Text formatat: $formattedText");

    List<String> ingredients = [];
    try {
      ingredients = await getIngredientsFromServer(formattedText);
    } catch (e) {
      print("Eroare la comunicarea cu serverul: $e");
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          processedImage: preprocessedImage,
          extractedText: recognizedText,
          ingredients: ingredients,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Scanează eticheta alimentară',
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15.0),

            /// 🔹 Butoane pentru selectarea imaginii
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PickerOptionWidget(
                  label: 'Galerie',
                  color: Colors.blueAccent,
                  icon: Icons.image_outlined,
                  onTap: () => _processImageExtractText(
                    imageSource: ImageSource.gallery,
                  ),
                ),
                const SizedBox(width: 10.0),
                PickerOptionWidget(
                  label: 'Cameră',
                  color: Colors.redAccent,
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _processImageExtractText(
                    imageSource: ImageSource.camera,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // /// 🔹 Afișare imagine procesată
            // if (_processedImage != null) ...[
            //   const Text(
            //     'Processed Image:',
            //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            //   ),
            //   const SizedBox(height: 10),
            //   Image.file(_processedImage!, width: 300, height: 300),
            //   const SizedBox(height: 20),
            // ],

            /// 🔹 Afișare text extras din imagine
            if (_extractedText.isNotEmpty) ...[
              const Text(
                'Extracted Text:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _extractedText,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
            ],
            /// 🔹 Buton pentru schimbare medicamente
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InitialDrugAdd()),
                );
              },
              icon: Icon(Icons.medication, color: Color.fromARGB(255,255,255,255),),
              label: Text('Schimbă medicamentele'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 1, 139, 203),
                foregroundColor: const Color.fromARGB(255,255,255,255), // culoarea textului
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}