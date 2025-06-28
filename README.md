# Label scanner

APLICAȚIE MOBILĂ PENTRU VERIFICAREA INTERACȚIUNILOR ÎNTRE MEDICAMENTE ȘI ALIMENTE

Această aplicație Flutter permite scanarea etichetelor alimentare folosind camera telefonului, extrage automat textul folosind OCR, identifică ingredientele și le compară cu o listă de medicamente introduse de utilizator, afișând potențiale interacțiuni aliment–medicament.

## Cerințe preliminare
Asigură-te că ai instalat:

- Flutter SDK
- Android Studio sau VS Code cu extensia Flutter
- Un emulator Android sau un dispozitiv fizic conectat
- Un server local Flask 

## Pasii de instalare
1. Clonează repository-ul
2. Instaleaza pachetele necesare:
   ```bash
   flutter pub get
   ```

## Compilarea aplicatiei
1. Conectează un dispozitiv fizic (cu USB debugging activat) sau pornește un emulator Android.
2. Configureaza serverul Flask (adresele IP din aplicație trebuie să corespundă cu IP-ul local al serverului Flask) apoi porneste-l:
   ```bash
   flask --app server.py run --host=0.0.0.0
   ```   
3. Ruleaza aplicatia:
   ```bash
   flutter run
   ```
