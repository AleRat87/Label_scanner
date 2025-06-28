from flask import Flask, request, jsonify
import spacy
from flask import Response
import json
import re
from langdetect import detect
import csv
import cv2
import numpy as np
import base64
import pytesseract
from googletrans import Translator
from spacy.language import Language
import unicodedata

# Încarcă modelul spaCy antrenat
nlp = spacy.load("model_ingrediente_best_with_diacritics3")

# Inițializează aplicația Flask
app = Flask(__name__)
#--------------------------------------------------------------------------------------------

def crop_image(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    data = pytesseract.image_to_data(gray, lang="ron", output_type=pytesseract.Output.DICT)
    x_min, y_min, x_max, y_max = np.inf, np.inf, 0, 0

    for i in range(len(data['text'])):
        if data['text'][i].strip() != "":
            x, y, w, h = data['left'][i], data['top'][i], data['width'][i], data['height'][i]
            x_min = min(x_min, x)
            y_min = min(y_min, y)
            x_max = max(x_max, x + w)
            y_max = max(y_max, y + h)
    if x_max > x_min and y_max > y_min:
        cropped = img[y_min:y_max, x_min:x_max]
        return cropped
    else:
        return img  # fallback: returnează originalul dacă nu detectează text

@app.route('/process-image', methods=['POST'])
def process_image():
    file = request.files['image']
    img_bytes = np.frombuffer(file.read(), np.uint8)
    img = cv2.imdecode(img_bytes, cv2.IMREAD_COLOR)

    cropped = crop_image(img)#  Aplicăm doar crop bazat pe text
    gray = cv2.cvtColor(cropped, cv2.COLOR_BGR2GRAY)

    _, buffer = cv2.imencode('.jpg', gray) # Encode înapoi ca JPG
    img_base64 = base64.b64encode(buffer).decode('utf-8')
    return img_base64, 200
#--------------------------------------------------------------------------------------------
def normalize_text(text):
    # Înlocuim caractere străine asemănătoare cu diacriticele românești, dar păstrează ăîșțâ.
    replacements = {
        'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ā': 'a', 'ã': 'a', 'å': 'a', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ì': 'i', 'í': 'i', 'ï': 'i', 'î': 'i', 'ī': 'i', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ō': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ç': 'c', 'ñ': 'n', 'ÿ': 'y', 'Ā': 'A', 'Ē': 'E', 'Ī': 'I', 'Ō': 'O', 'Ū': 'U', 'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ü': 'u', 'ÿ': 'y', 'ș': 'ș', 'ț': 'ț', 'ă': 'ă', 'î': 'î', 'â': 'â'  # păstrăm diacriticele românești
    }
    # Înlocuim caracterele străine și convertim la litere mici
    text_normalizat = ''.join(replacements.get(c, c) for c in text)
    return text_normalizat.lower()

def extrage_text_romana(text):
    text = normalize_text(text)
    # Caută secțiunea care începe cu "Ingrediente:"
    pattern = re.compile(r"ingrediente:(.*?)(?=(?:[A-ZĂÎȘȚ][a-zăîșț]+\s*:)|$)", re.DOTALL)
    match = pattern.search(text)
    if match:
        sectiune = match.group(1).strip()
        #return f"Ingrediente: {sectiune}"

    # Dacă nu găsește "Ingrediente", aplică detecția de limbă
    propozitii = re.split(r'[.!?]', sectiune)
    propozitii_romana = []
    for prop in propozitii:
        prop_curata = prop.strip()
        if len(prop_curata) >= 20:  # ignoră fragmente scurte
            try:
                if detect(prop_curata) == "ro":
                    propozitii_romana.append(prop_curata)
            except:
                continue
    return " ".join(propozitii_romana) if propozitii_romana else text

@app.route('/extract_ingredients', methods=['POST'])
def extract_ingredients():
    data = request.get_json() # Obține textul trimis de client (din JSON)
    if not data or 'text' not in data:
        return jsonify({'error': 'Furnizează câmpul "text"'}), 400

    text = data['text']
    #print(text)
   
    text = extrage_text_romana(text) # Extrage doar porțiunea relevantă
    print(text)
    doc = nlp(text)

    # Extrage entitățile
    ingredients = [ent.text for ent in doc.ents if ent.label_ == 'INGREDIENT']
    
    print("Ingredientele extrase sunt ", ingredients)

    return Response(
    json.dumps({"ingredients": ingredients}, ensure_ascii=False),
    content_type='application/json; charset=utf-8')

#--------------------------------------------------------------------------------------------
def normalize(text):
    if not isinstance(text, str):
        return ''
    text = text.lower().strip()
    text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('utf-8')  # elimină diacritice
    text = re.sub(r'\s+', ' ', text)  # înlocuiește spații multiple cu unul singur
    return text

# Încarcă fișierul CSV
def load_csv():
    drugs = {}
    with open('extracted_drug_data3.csv', mode='r', encoding='utf-8') as file:
        reader = csv.reader(file)
        next(reader)  # Sari peste header-ul CSV-ului
        for row in reader:
            name = normalize(row[0])
            food_interactions = row[1].strip()
            drugs[name] = food_interactions
            if 'lepirudina' in name:
                print(f"✔ Găsit în CSV: {name}")
    return drugs

drugs_data = load_csv()

# Creăm un obiect Translator pentru Google Translate
translator = Translator()

# Traducerea textului din engleză în română
def translate_text(text, src='en', dest='ro'):
    translation = translator.translate(text, src=src, dest=dest)
    return translation.text

# Preprocesare text pentru a adăuga un spațiu după semnul punct și virgulă (dacă nu există) si a scapa de articolele cuvintelor
def preprocess_text(text):
    # Înlocuim punctul și virgula urmat de un cuvânt fără spațiu cu punct și virgulă urmat de un spațiu
    text = text.replace(';', '; ')  # Adăugăm un spațiu după punct și virgulă
    text = re.sub(r'\b([a-zA-Zăîâșț]+)ul\b', r'\1', text)  # Eliminăm „ul” (articol definit la singular)
    text = re.sub(r'\b([a-zA-Zăîâșț]+)le\b', r'\1', text)  # Eliminăm „le” (articol definit la plural)    
    text = re.sub(r'(\.)([^\s])', r'. \2', text)  # Dacă există punct fără spațiu, adăugăm spațiu
    return text

# Definim un sentencizer personalizat
# Decorator pentru a înregistra funcția ca component spaCy
@Language.component("custom_sentencizer")
def custom_sentencizer(doc):
    for token in doc[:-1]:  # Iterăm prin toate token-urile din document
        if token.text == ";":  # Dacă găsim punct și virgulă
            token.is_sent_start = True  # Considerăm că următorul token începe o propoziție
        else:
            token.is_sent_start = False  # Continuăm propoziția curentă
    return doc

# Adăugăm funcția custom_sentencizer în pipeline-ul spaCy
nlp.add_pipe("custom_sentencizer", before='ner')  # Adăugăm 'custom_sentencizer' înainte de NER

@app.route('/get_food_interactions', methods=['POST'])

def get_food_interactions():
    data = request.get_json()
    medicamente = data.get('name', [])  # O listă de medicamente trimisă din Flutter
    ingrediente = data.get('ingrediente', [])  # Lista de ingrediente trimisă din Flutter
    
    alimente_evitate_totale = [] # Inițializăm liste pentru rezultate
    alimente_recomandate_totale = []

    # Iterăm prin fiecare medicament din lista trimisă
    for medicament in medicamente:
        medicament = normalize(medicament)
        print(f"🔸 Primit din Flutter: {medicament}")
        #medicament = medicament.strip().lower() 
        
        if medicament in drugs_data:
            food_interactions = drugs_data[medicament]
            print(f"Interacțiuni alimentare pentru {medicament}: {food_interactions}")  # Log pentru a verifica interacțiunile

            food_interactions_ro = translate_text(food_interactions, src='en', dest='ro') # Traducem textul din engleză în română
            print(f"Textul alimentar in romana pentru {medicament}: {food_interactions_ro}") 

            food_interactions_ro = preprocess_text(food_interactions_ro.lower())  # Procesăm textul interacțiunilor alimentare
            print(f"Textul alimentar in romana preprocesat pentru {medicament}: {food_interactions_ro}") 

            doc = nlp(food_interactions_ro) # Aplicăm modelul NER pe textul procesat

            alimente_evitate = [] # Liste pentru alimentele recomandate și evitate
            alimente_recomandate = []

            # Iterăm prin entitățile recunoscute
            for ent in doc.ents:
                if ent.label_ == "INGREDIENT":
                    ingredient = ent.text.lower()

                    # Extragem propoziția în care apare ingredientul
                    sentence = ent.sent.text.lower()  # Obținem întreaga propoziție

                    # Căutăm cuvinte cheie pentru a determina dacă ingredientul este recomandat sau evitat
                    if "evitați" in sentence or "limitează" in sentence:
                        alimente_evitate.append(ingredient)
                    elif "ia cu" in sentence or "administrează" in sentence or "luați cu" in sentence:
                        alimente_recomandate.append(ingredient)

            # Adăugăm rezultatele pentru fiecare medicament la listele totale
            alimente_evitate_totale.extend(alimente_evitate)
            alimente_recomandate_totale.extend(alimente_recomandate)

            print(f"Alimente recomandate pentru {medicament}: {alimente_recomandate}")
            print(f"Alimente evitate pentru {medicament}: {alimente_evitate}")

        else:
            print(f"Medicamentul {medicament} nu a fost găsit în baza de date.")

    # Verificăm dacă vreun ingredient evitat se regăsește în lista trimisă din Flutter
    alimente_evitate_gasite = [ingredient for ingredient in alimente_evitate_totale if ingredient in [i.lower() for i in ingrediente]]

    # Returnăm rezultatele pentru toate medicamentele
    return jsonify({
        'alimente_recomandate': alimente_recomandate_totale,
        'alimente_evitate': alimente_evitate_gasite
    })

# def get_food_interactions():
#     data = request.get_json()
#     medicamente = data.get('name', [])  # lista de medicamente trimisă din Flutter
#     ingrediente = data.get('ingrediente', [])  # Lista de ingrediente trimisă din Flutter
#     alimente_evitate_totale = [] # Inițializăm liste pentru rezultate
#     alimente_recomandate_totale = []

#     for medicament in medicamente: # Iterăm prin fiecare medicament din lista trimisă
#         medicament = medicament.strip().lower() 
#         if medicament in drugs_data:
#             food_interactions = drugs_data[medicament]
#             food_interactions_ro = translate_text(food_interactions, src='en', dest='ro') # Traducem textul din engleză în română
#             food_interactions_ro = preprocess_text(food_interactions_ro.lower())  # Procesăm textul interacțiunilor alimentare
#             alimente_evitate = [] # Liste pentru alimentele recomandate și evitate
#             alimente_recomandate = []

#             doc = nlp(food_interactions_ro) # Aplicăm modelul NER pe textul procesat
#             for ent in doc.ents: # Iterăm prin entitățile recunoscute
#                 if ent.label_ == "INGREDIENT":
#                     ingredient = ent.text.lower()
#                     sentence = ent.sent.text.lower()  # Extragem propoziția în care apare ingredientul
#                     # Căutăm cuvinte cheie pentru a determina dacă ingredientul este recomandat sau evitat
#                     if "evitați" in sentence or "limitează" in sentence:
#                         alimente_evitate.append(ingredient)
#                     elif "ia cu" in sentence or "administrează" in sentence or "luați cu" in sentence:
#                         alimente_recomandate.append(ingredient)

#             alimente_evitate_totale.extend(alimente_evitate) # Adăugăm rezultatele pentru fiecare medicament la listele totale
#             alimente_recomandate_totale.extend(alimente_recomandate)
#         else:
#             print(f"Medicamentul {medicament} nu a fost găsit în baza de date.")
#     # Verificăm dacă vreun ingredient evitat se regăsește în lista trimisă din Flutter
#     alimente_evitate_gasite = [ingredient for ingredient in alimente_evitate_totale if ingredient in [i.lower() for i in ingrediente]]

#     return jsonify({
#         'alimente_recomandate': alimente_recomandate_totale,
#         'alimente_evitate': alimente_evitate_gasite
#     })
#--------------------------------------------------------------------------------------------
# Endpoint pentru a verifica dacă serverul funcționează
@app.route('/test_connection', methods=['GET'])
def test_connection():
    return jsonify({'message': 'Conexiunea cu serverul este activă!'})

if __name__ == '__main__':
    app.run(debug=True)
