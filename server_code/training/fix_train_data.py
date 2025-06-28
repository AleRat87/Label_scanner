import json

# Fișierul de intrare cu datele în format JSON (liste)
INPUT_FILE = "train_data3.json"
# Fișierul de ieșire, care va conține TRAIN_DATA în format Python
OUTPUT_FILE = "train_data3.py"

with open(INPUT_FILE, "r", encoding="utf8") as f:
    data = json.load(f)

converted_data = []

for item in data:
    text, annotations = item
    # Convertim fiecare [start, end, label] în tuple (start, end, label)
    entities = [tuple(ent) for ent in annotations["entities"]]
    converted_data.append((text, {"entities": entities}))

# Scriem fișierul .py final
with open(OUTPUT_FILE, "w", encoding="utf8") as f:
    f.write("TRAIN_DATA3 = [\n")
    for text, ann in converted_data:
        f.write(f"    ({repr(text)}, {ann}),\n")
    f.write("]\n")

print(f"Conversie completă! Scris în: {OUTPUT_FILE}")
