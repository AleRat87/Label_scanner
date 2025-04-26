import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:label_scanner/widgets/picker_option_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;


class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _extractedText = '';
  File? _processedImage;

  Future<File?> _pickerImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

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

  // Future<CroppedFile?> _cropImage({required File imageFile}) async {
  //   CroppedFile? croppedfile = await ImageCropper().cropImage(
  //     sourcePath: imageFile.path,
  //     uiSettings: [
  //       AndroidUiSettings(
  //         aspectRatioPresets: [
  //           CropAspectRatioPreset.square,
  //           CropAspectRatioPreset.ratio3x2,
  //           CropAspectRatioPreset.original,
  //           CropAspectRatioPreset.ratio4x3,
  //           CropAspectRatioPreset.ratio16x9
  //         ],
  //       ),
  //       IOSUiSettings(
  //         minimumAspectRatio: 1.0,
  //       ),
  //     ],
  //   );
  //
  //   if (croppedfile != null) {
  //     return croppedfile;
  //   }
  //
  //   return null;
  // }

  Future<String> _recognizeTextFromImage({required String imgPath}) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final image = InputImage.fromFile(File(imgPath));
    final recognized = await textRecognizer.processImage(image);

    return recognized.text;
  }

  List<String> _extractIngredients(String text) {
    RegExp regex = RegExp(r"Ingrediente:\s*(.+?)(?=\.)", caseSensitive: false);
    Match? match = regex.firstMatch(text);

    if (match != null) {
      String ingredientString = match.group(1) ?? "";

      // ✅ Separăm ingredientele pe bază de virgulă
      List<String> rawIngredients = ingredientString.split(RegExp(r",\s*"));

      // ✅ Curățăm fiecare ingredient: eliminăm procentele și numerele de la început
      List<String> cleanedIngredients = rawIngredients.map((ingredient) {
        return ingredient.replaceAll(RegExp(r"^\d+([,.]\d+)?%\s*"), "").trim();
      }).toList();

      return cleanedIngredients;
    }

    return []; // Returnează listă goală dacă nu găsește "Ingrediente:"
  }



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



  Future<void> _processImageExtractText({
    required ImageSource imageSource,
  }) async {
    final imageFile = await _pickerImage(source: imageSource);

    if (imageFile == null) return;

    // final croppedImage = await _cropImage(
    //   imageFile: imageFile,
    // );

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Label Scanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Select an Option',
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15.0),

            /// 🔹 Butoane pentru selectarea imaginii
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PickerOptionWidget(
                  label: 'From Gallery',
                  color: Colors.blueAccent,
                  icon: Icons.image_outlined,
                  onTap: () => _processImageExtractText(
                    imageSource: ImageSource.gallery,
                  ),
                ),
                const SizedBox(width: 10.0),
                PickerOptionWidget(
                  label: 'From Camera',
                  color: Colors.redAccent,
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _processImageExtractText(
                    imageSource: ImageSource.camera,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            /// 🔹 Afișare imagine procesată
            if (_processedImage != null) ...[
              const Text(
                'Processed Image:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.file(_processedImage!, width: 300, height: 300),
              const SizedBox(height: 20),
            ],

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
          ],
        ),
      ),
    );
  }
}