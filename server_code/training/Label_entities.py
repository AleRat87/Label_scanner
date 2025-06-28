import json
import re
import spacy

# Inițializează pipeline-ul spaCy (fără model pre-antrenat)
nlp = spacy.blank("ro")

# Încarcă textele din fișier
with open("text_ingrediente.txt", "r", encoding="utf-8") as f:
    texte = [line.strip() for line in f if line.strip()]

ingrediente_cunoscute = [
    # zaharuri și îndulcitori
    "zahăr", "dextroză", "glucoză", "fructoză", "lactoză", "maltoză", "miere", "zahăr brun", "zahăr de cocos", "zahăr de trestie", "sirop de porumb", "sirop de agave", "sirop de arțar", "sirop de orez", "melasă", "nectar de agave", "sirop caramel", "sirop de glucoză", "sirop de fructoză", "maltoză", "sucroză" , "ilitol", "eritritol", "sorbitol", "mannitol", "isomalt", "maltitol", "stevia", "extract de steviol", "glicozide din steviol", "aspartam", "acesulfam K", "acesulfam de potasiu", "ciclamat", "sucraloză", "neotam", "taumatina", "poliglicitol", "inulină", "alluloză", "tagatoză",

    # făinuri și cereale
    "făină de grâu", "făină albă", "făină integrală", "amidon de porumb", "amidon modificat", "gluten", "praf de copt", "făină de ovăz", "făină de orz", "făină de porumb", "făină de orez", "făină albă de grâu", "făină de mei", "făină de quinoa", "făină de amarant", "făină de hrișcă", "făină de năut", "făină de linte", "făină de mazăre", "făină de soia", "făină de migdale", "făină de cocos", "făină de alune", "făină de caju", "făină de castane", "făină de susan", "făină de semințe de in", "făină de semințe de dovleac", "făină de semințe de floarea-soarelui", "făină de tapioca", "făină de cartofi", "făină de banane", "făină de insecte", "făină de alge", "făină de bambus", "făină de gluten", "grâu", "orez", "orez alb", "orez brun", "orz", "secara", "mei", "porumb", "ovăz", "amaranth", "quinoa", "hrișcă", "bulgur", "chia",
    # grăsimi și uleiuri
    "ulei de măsline", "ulei de floarea-soarelui", "ulei de rapiță", "ulei de porumb", "ulei de soia", "ulei de palmier", "ulei de cocos", "ulei de avocado", "ulei de arahide", "ulei de susan", "uleiuri vegetale", "ulei de semințe de struguri", "ulei de semințe de dovleac", "ulei de semințe de in", "ulei de cânepă", "ulei de orez", "ulei de germeni de grâu", "ulei de migdale", "ulei de caju", "ulei de macadamia", "ulei de nucă", "ulei de nucă de brazilia", "ulei de fistic", "ulei de argan", "ulei de șofrănel", "ulei de chia", "ulei de pește", "ulei de ficat de cod", "grăsime vegetală", "grăsime de palmier", "ulei vegetal de floarea soarelui", "seminte de floarea-soarelui",
    "unt", "unt de cacao", "margarină", "unt clarificat", "untură", "slănină", "grăsime de rață", "grăsime de gâscă", "grăsime de vită", "grăsime de porc", "grăsime de miel",
    # lactate și derivate
    "lapte", "lapte integral", "lapte degresat", "lapte semidegresat", "lapte praf", "lapte praf degresat", "lapte condensat", "lapte evaporat", "lapte bătut", "lapte fermentat", "lapte acru", "lapte de capră", "lapte de oaie", "lapte de bivoliță", "iaurt", "chefir", "sana", "smântână", "smântână dulce", "smântână pentru frișcă", "frișcă", "frișcă vegetală", "frișcă bătută", "lapte de unt", "zer", "zer praf", "brânză", "brânză proaspătă", "brânză de vaci", "branza de oaie", "branza de capra", "brânză cottage", "brânză feta", "brânză telemea", "brânză maturată", "brânză topită", "brânză cu mucegai", "caș", "cașcaval", "caș afumat", "urda", "ricotta", "mascarpone", "mozzarella", "parmezan", "gorgonzola", "branza Grana Padano", "roquefort", "brie", "camembert", "lactoză", "proteine din zer", "cazeină", "cazeinat de calciu", "cazeinat de sodiu", "concentrat proteic din lapte", "izolat proteic din lapte", "zer praf", "zer dulce", "zer de lapte praf", "proteine din lapte",
    # ouă și derivate
    "ouă", "ouă de găină", "ouă de prepeliță", "ouă de rață", "ouă de gâscă", "ouă de curcă", "ouă de struț", "albuș", "gălbenuș", "praf de ou", "albuș praf", "gălbenuș praf", "ou lichid pasteurizat", "albuș lichid", "gălbenuș lichid", "ou pasteurizat", "emulsifiant din ou", "lecitină din ou", "enzime din ou", "maioneză", "muștar",
    # carne și derivate
    "carne de vită", "carne de porc", "carne de pui", "carne de curcan", "carne de rață", "carne de gâscă", "carne de miel", "carne de iepure", "ficat de vită", "ficat de porc", "ton", "ficat de pui", "ficat de curcan", "rinichi de vită", "rinichi de porc", "inimă de vită", "inimă de porc", "limbă de vită", "limbă de porc", "creier de vită", "creier de porc", "carne de pasăre", "pui", "șuncă", "slanina", "gelatină", "colagen",
    # legume și fructe
    "cartof", "morcov", "ceapă", "usturoi", "ciuperci", "roșii", "ardei", "ardei iute", "castravete", "dovlecel", "vânătă", "broccoli", "conopidă", "varză", "varză de bruxelles", "sparanghel", "mazăre", "fasole verde", "fasole boabe", "fasole rosie", "linte", "ridiche", "ștevia", "pătrunjel", "țelină", "napi", "sfeclă", "gulie", "coriandru", "fenicul", "păstârnac", "andive", "salată verde", "rucola", "spanac", "mărar", "busuioc", "mentă", "leuștean", "arpagic", "dovleac", "cartof dulce", "anghinare", "praz", "hrean", "usturoi verde", "cicoare", "cartofi", "morcovi", "ceapa alba", "vinete",
	"suc de lămâie", "suc de portocale", "mere", "pere", "banane", "portocale", "mandarine", "lămâie", "lime", "grepfrut", "grapefruit", "piersici", "caise", "nectarine", "prune", "cireșe", "vișine", "struguri", "ananas", "mango", "papaya", "kiwi", "rodii", "guava", "pepene verde", "pepene galben", "afine", "zmeură", "căpșuni", "mure", "coacăze", "fragi", "murături", "smochine", "kaki", "cireșe amare", "mango verde", "fructul pasiunii", "fragi de pădure", "tamarind", "kaki", "salcâm", "piure de mere", "piure de caise", "piure de căpșuni",
    # ingrediente de patiserie
    "cacao", "pastă de cacao", "ciocolată", "fulgi de cocos", "nucă de cocos", "nuci", "alune", "alune", "arahide", "fistic",
    "vanilie", "vanilina", "scorțișoară", "caramel",
    # aditivi, arome, conservanți
    "lecitină", "lecitine (soia)", "arome", "arome naturale", "conservanți", "conservant", "acid citric", "acid ascorbic",
    "colorant", "emulgatori", "stabilizatori", "agenți de îngroșare", "agent de îngroșare", "agenți de afânare", "antioxidant", "antioxidanți",
    # săruri, minerale, condimente
    "sare", "sare iodata", "clorură de sodiu", "piper", "boia", "drojdie", "extract de drojdie", "foi de dafin", "semințe de muștar", "ginseng", "ghimbir", "ginkgo", "ginkgo biloba", "cofeină", "danshen", "piracetam", "mușețel", "echinacea", "echinaceea",
    # alte ingrediente frecvente
    "apă", "alcool", "oțet", "gumă xantan", "gelifiant", "sirop invertit", "fibra de grâu", "fibre vegetale",
	"calciu", "fosfor", "magneziu", "sodiu", "potasiu", "fier", "zinc", "mangan", "iod", "seleniu", "fosfat de calciu", "fosfat de potasiu", "bicarbonat de amoniu", "emulgator", "amidon de porumb", "amidon de cartof", "amidon de tapioca", "pectină", "caragenan", "gluconat de sodiu", "fibre de celuloza", "inulina", "hidrolizat de proteine", "extract de vanilie", "extract de menta", "uleiuri esentiale", "concentrate de legume", "gălbenuș de ou praf", "carbonat de calciu", "lactatul de calciu", "pudră de ceai verde", "glutamat monosodic", "butilhidroxianisol", "butilhidroxitoluena", "bicarbonat de sodiu", "acid tartaric", "aromă de vanilie", "aromă de migdale", "aromă de ciocolată", "aromă de lămâie", "aromă de portocală", "aromă de mentă", "aromă de căpșuni", "aromă de banane", "aromă de afine", "aromă de cireșe", "aromă de ananas", "aromă de pepene verde", "aromă de prune", "aromă de fructe de pădure", "aromă de cocos", "aromă de rom", "aromă de cafea", "cafea", "boabe de cafea", "aromă de caramel", "aromă de caramel sărat", "aromă de ghimbir", "aromă de scorțișoară", "aromă de vanilie bourbon", "aromă de migdale prăjite", "rozmarin", "aromă de busuioc", "aromă de lavandă", "aromă de lime", "aromă de litchi", "aromă de pere", "aromă de prune uscate", "aromă de cocos prăjit", "aromă de mentă verde", "aromă de alune", "aromă de migdale amare", "aromă de cocos natural", "aromă de iasomie", "aromă de trandafiri", "aromă de flori de portocal", "aromă de cedru", "aromă de ciocolată albă", "aromă de mentă rece", "aromă de lime verde", "aromă de zahăr ars", "aromă de fructul pasiunii", "aromă de castravete", "aromă de pere", "aromă de smochine", "aromă de ardei iute", "aromă de trufe", "aromă de piper", "aromă de curcuma", "aromă de bacon", "aromă de brânză", "aromă de muștar", "aromă de tarhon", "aromă de trufe albe", "aromă de caise", "aromă de mango", "aromă de piersici", "aromă de zmeură", "aromă de smântână", "aromă de brânză cheddar", "aromă de lavandă", "aromă de ardei dulce", "e100", "curcumina", "e101", "riboflavină", "vitamina b6", "e102", "tartrazina", "e104", "galben de chinolină", "e110", "e120", "acid carminic", "e122", "azorubină", "e123", "amarant", "e124", "e127", "eritrozina", "e129", "e131", "albastru patent", "e132", "albastru briliant", "e133", "albastru trifenilmetan", "e140", "clorofile", "e141", "complex de clorofilină", "e142", "e150a", "e150b", "caramel acid", "e150c", "caramel caustic", "e150d", "caramel de sulfat de amoniu", "e160a", "carotenoizi", "beta-caroten", "e160b", "bixin", "e160c", "capsanthin", "e160d", "lycopene", "e160e", "beta-apo-8'-carotenal", "e161b", "luteina", "e162", "betanină", "e163", "antocianine", "e170", "carbonat de calciu", "e171", "dioxid de titan", "e172", "oxizi de fier", "e173", "e180", "pigment din ceară de carnauba", "e200", "acid sorbic", "e202", "sorbat de potasiu", "e203", "sorbat de calciu", "e210", "acid benzoic", "e211", "benzoat de sodiu", "e212", "benzoat de potasiu", "e213", "benzoat de calciu", "e214", "etil-p-hidroxibenzoat de sodiu", "e215", "etil-p-hidroxibenzoat de potasiu", "e220", "dioxid de sulf", "sulfiți", "e221", "sulfiti de sodiu", "e222", "sulfiti de potasiu", "e223", "sulfiti de calciu", "e224", "sulfiti de amoniu", "e230", "ortofenilfenol", "e231", "ortocresol", "e232", "ortocresol de sodiu", "e233", "tiofenol", "e240", "formaldehidă", "e241", "acetat de glutaral", "e242", "glutaraldehidă", "e250", "nitrit de sodiu", "e251", "nitrați de sodiu", "e252", "nitrați de potasiu", "e260", "acid acetic", "e261", "acetat de potasiu", "e262", "acetat de sodiu", "e263", "acetat de calciu", "e264", "acetat de amoniu", "e270", "acid lactic", "e280", "acid propionic", "e281", "propionat de sodiu", "e282", "propionat de calciu", "e290", "dioxid de carbon", "e300", "vitamina c", "e301", "ascorbat de sodiu", "e302", "ascorbat de calciu", "e304", "ascorbat de palmitat", "e306", "tocofereoli", "vitamina e", "e307", "alfa-tocoferol", "e308", "gamma-tocoferol", "e309", "delta-tocoferol", "e310", "galat de propil", "e311", "galat de octil", "e312", "galat de dodecil", "e320", "bha", "butilhidroxi-anisol", "e321", "bht", "butilhidroxitoluena", "e322", "lecitină", "e330", "e331", "citrati de sodiu", "e332", "citrati de potasiu", "e333", "citrati de calciu", "e334", "acid tartric", "e335", "tartrat de sodiu", "e336", "tartrat de potasiu", "e337", "tartrat de sodiu și potasiu", "e338", "acid fosforic", "e339", "fosfați de sodiu", "e340", "fosfați de potasiu", "e341", "fosfați de calciu", "e350", "malat de sodiu", "e351", "malat de potasiu", "e352", "malat de calciu", "e353", "malat de magneziu", "e354", "e355", "e400", "alginate", "e401", "alginat de sodiu", "e402", "alginat de potasiu", "e403", "alginat de calciu", "e404", "alginat de amoniu", "e405", "alginat de magneziu", "e406", "agar-agar", "e407", "carragenani", "e408", "agar", "e409", "agarose", "e410", "guma de guar", "e411", "guma de tragacant", "e412", "e413", "guma de acacia", "e414", "guma arabică", "e415", "guma de xanthan", "e416", "guma de locust", "e417", "guma tara", "e418", "guma gellan", "e420", "sorbitol", "e421", "mannitol", "e422", "glicerină", "e423", "isomalt", "e424", "maltitol", "e425", "fucus", "alge", "e426", "glicerol", "e427", "alginat", "e430", "cetonă", "e431"
]

def elimina_suprapuneri(entitati):
    # sortează entitățile pe baza pozițiilor lor și păstrează entitățile mai lungi
    entitati.sort(key=lambda x: (x[0], -(x[1] - x[0])))
    rezultat = []
    last_end = -1
    for start, end, label in entitati:
        if start >= last_end:
            rezultat.append((start, end, label))
            last_end = end
    return rezultat

def gaseste_ingrediente(text, lista_ingrediente, nlp):
    doc = nlp.make_doc(text)
    entities = []
    for ing in lista_ingrediente:
        for match in re.finditer(re.escape(ing), text, re.IGNORECASE):
            start, end = match.span()
            span = doc.char_span(start, end, label="INGREDIENT")
            if span is not None:
                entities.append((span.start_char, span.end_char, span.label_))
            else:
                print(f" Entitate ignorată (nealiniată): '{text[start:end]}' în: {text}")
    entities = elimina_suprapuneri(entities)
    return entities

train_data = []
nr_total = 0
nr_valid = 0

for text in texte:
    nr_total += 1
    entities = gaseste_ingrediente(text, ingrediente_cunoscute, nlp)
    if entities:
        train_data.append((text, {"entities": entities}))
        nr_valid += 1
    else:
        print(f" Nicio entitate validă în: {text}")

# Salvează fișierele
with open("train_data3.json", "w", encoding="utf-8") as f:
    json.dump(train_data, f, ensure_ascii=False, indent=2)

with open("train_data3.py", "w", encoding="utf-8") as f:
    f.write("TRAIN_DATA3 = " + json.dumps(train_data, ensure_ascii=False, indent=2))

print(f"\n✅ {nr_valid}/{nr_total} exemple valide au fost salvate în train_data.json.")
