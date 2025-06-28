import spacy
from spacy.training.example import Example
from spacy.scorer import Scorer
from test_data import TEST_DATA  # <-- ai grijă că test_data.py conține TEST_DATA = [...]

# Încarcă modelul salvat
nlp = spacy.load("model_ingrediente_best_with_diacritics3")

# Funcție de evaluare
def evaluate_model(nlp_model, examples):
    scorer = Scorer()
    example_objs = []
    for text, annot in examples:
        doc = nlp_model(text)
        example = Example.from_dict(doc, annot)
        example_objs.append(example)
    return scorer.score(example_objs)

# Evaluează pe datele externe
scores = evaluate_model(nlp, TEST_DATA)

# Afișează scorurile
precision = scores.get("ents_p", 0.0)
recall = scores.get("ents_r", 0.0)
f1 = scores.get("ents_f", 0.0)

print(f"\n📊 Evaluare pe date externe (NEVĂZUTE):")
print(f"🎯 Precizie: {precision:.4f}, Recall: {recall:.4f}, F1: {f1:.4f}")
