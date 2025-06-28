from lxml import etree
import csv

xml_file = "full database.xml" # numele fișierului XML de intrare
output_file = "extracted_drug_data4.csv" # numele fișierului CSV de ieșire

context = etree.iterparse(xml_file, events=("start", "end"), huge_tree=True) # parsez fișierul XML
with open(output_file, "w", newline="", encoding="utf-8") as csvfile: #scriem în fișierul de ieșire
    writer = csv.writer(csvfile)
    writer.writerow(["name", "food_interactions", "international_brands"])  # header CSV
    # initializare flaguri de control
    inside_main_drug = False
    inside_pathway = False
    drug_name = None
    food_interactions = []
    international_brands = []
    inside_international_brands = False

    for event, elem in context:
        if event == "start" and elem.tag == "{http://www.drugbank.ca}drug":
            if not inside_pathway:  # verificăm dacă NU suntem într-un pathway
                inside_main_drug = True  # Setăm flag-ul doar pentru medicamente principale
                drug_name = None
                food_interactions = []
                international_brands = []
        elif event == "start" and elem.tag == "{http://www.drugbank.ca}pathways": 
            inside_pathway = True # cand intram in interiorul Pathways setam flag pentru a ignora acesta intrare 
        elif event == "end" and elem.tag == "{http://www.drugbank.ca}pathways":
            inside_pathway = False # cand iesim din Pathways resetam flag pentru a ignora acesta intrare 
        elif event == "end" and elem.tag == "{http://www.drugbank.ca}name" and inside_main_drug and drug_name is None:
            drug_name = elem.text.strip() if elem.text else "" # am gasit nume de drug
        elif event == "end" and elem.tag == "{http://www.drugbank.ca}food-interaction":
            if elem.text:
                interaction = elem.text.strip()
                food_interactions.append(interaction) # am gasit food-interaction
        elif event == "start" and elem.tag == "{http://www.drugbank.ca}international-brands":
            inside_international_brands = True
        elif event == "end" and elem.tag == "{http://www.drugbank.ca}international-brands":
            inside_international_brands = False
        elif event == "end" and elem.tag == "{http://www.drugbank.ca}name" and inside_international_brands:
            international_brands.append(elem.text.strip() if elem.text else "")
        elif event == "end" and elem.tag == "{http://www.drugbank.ca}drug":
            if inside_main_drug:  # Ne asigurăm că scriem doar medicamentele principale
                writer.writerow([drug_name, "; ".join(food_interactions), "; ".join(international_brands)])
            inside_main_drug = False  # Resetăm flag-ul pentru medicamentele principale
            elem.clear()

print(f" Datele au fost extrase cu succes în {output_file}")
