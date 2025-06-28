import spacy
from spacy.training.example import Example
from spacy.util import minibatch, compounding
from spacy.scorer import Scorer
import random
from sklearn.model_selection import train_test_split
import os
import shutil

# Încarcă datele
from train_data3 import TRAIN_DATA3

# Împarte în train și dev (80/20)
train_data, dev_data = train_test_split(TRAIN_DATA3, test_size=0.2, random_state=42)

# Creează model spaCy gol pentru limba română
nlp = spacy.blank("ro")

# Adaugă componenta NER
if "ner" not in nlp.pipe_names:
    ner = nlp.add_pipe("ner")
else:
    ner = nlp.get_pipe("ner")

# Adaugă etichetele NER
for _, annotations in train_data:
    for ent in annotations.get("entities"):
        ner.add_label(ent[2])

# Funcție de evaluare pe setul de validare
# Funcție de evaluare
def evaluate_model(nlp_model, examples):
    scorer = Scorer()
    example_objs = []
    for text, annot in examples:
        doc = nlp_model(text)
        example = Example.from_dict(doc, annot)
        example_objs.append(example)
    return scorer.score(example_objs)

# Dezactivează componentele nefolosite și începe antrenarea
other_pipes = [pipe for pipe in nlp.pipe_names if pipe != "ner"]
best_f1 = 0.0
output_dir = "model_ingrediente_best_with_diacritics2"

with nlp.disable_pipes(*other_pipes):
    optimizer = nlp.begin_training()
    
    for itn in range(30):  # numărul de epoci
        print(f"\n🔁 Epoca {itn + 1}")
        random.shuffle(train_data)
        losses = {}
        batches = minibatch(train_data, size=compounding(4.0, 32.0, 1.001))
        
        for batch in batches:
            examples = []
            for text, annotations in batch:
                doc = nlp.make_doc(text)
                example = Example.from_dict(doc, annotations)
                examples.append(example)
            nlp.update(examples, drop=0.5, losses=losses)
        
        print(f"📉 Pierderi: {losses}")
        
        # Evaluează modelul pe setul de validare
        scores = evaluate_model(nlp, dev_data)
        f1 = scores.get("ents_f", 0.0)
        precision = scores.get("ents_p", 0.0)
        recall = scores.get("ents_r", 0.0)
        print(f"🎯 Precizie: {precision:.4f}, Recall: {recall:.4f}, F1: {f1:.4f}")

        # Salvează modelul dacă scorul F1 e mai bun
        if f1 > best_f1:
            best_f1 = f1
            if os.path.exists(output_dir):
                shutil.rmtree(output_dir)
            nlp.to_disk(output_dir)
            print("✅ Model îmbunătățit salvat în 'model_ingrediente_best_with_diacritics2'")

print(f"\n🏁 Antrenare finalizată. Cel mai bun F1: {best_f1:.4f}")
