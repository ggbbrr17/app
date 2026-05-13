"""
Script para extraer el diccionario Wayuunaiki completo de pueblosoriginarios.com
y guardarlo como assets/wayuu_dictionary.json
Ejecutar: python extract_wayuu.py
"""
import json, re, os

try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    import time

    options = webdriver.ChromeOptions()
    options.add_argument('--headless')
    driver = webdriver.Chrome(options=options)
    driver.get('https://pueblosoriginarios.com/lenguas/wayuu.php')
    time.sleep(3)

    # Show all rows
    driver.execute_script("""
        if(typeof jQuery !== 'undefined') {
            jQuery('#diccionario').DataTable().page.len(-1).draw();
        }
    """)
    time.sleep(2)

    rows = driver.find_elements(By.CSS_SELECTOR, '#diccionario tbody tr')
    dictionary = {}
    for row in rows:
        cells = row.find_elements(By.TAG_NAME, 'td')
        if len(cells) >= 2:
            wayuu = cells[0].text.strip()
            esp = cells[1].text.strip()
            if wayuu and esp:
                dictionary[wayuu] = esp

    driver.quit()
    print(f"Extraídas {len(dictionary)} entradas con Selenium")

except Exception as e:
    print(f"Selenium no disponible ({e}), usando diccionario base...")
    dictionary = {}

# Diccionario base incluido directamente (entradas verificadas)
base_dict = {
    "aa'in": "corazón, alma, sentimiento",
    "aa'inraa": "sentir",
    "aajaa": "tejer",
    "aalijaa": "ver, mirar",
    "aapaa": "recibir",
    "achaa": "comer (forma alternativa)",
    "achajaa": "buscar",
    "achikii": "perro",
    "achon": "hijo",
    "achonnii": "hija",
    "ainküin": "querer, amar",
    "aipia": "cama, hamaca",
    "aippa": "tierra, suelo",
    "aja'ttaa": "golpear",
    "ajapü": "boca",
    "ajattaa": "pensar",
    "ajiee": "gritar",
    "ajünaa": "cocinar",
    "ajüttaa": "llegar",
    "aka'aya": "compañero",
    "akaliijaa": "ayudar",
    "akumajaa": "hacer, construir",
    "alaa": "sueño, soñar",
    "alaainjaa": "trabajar",
    "alaülaa": "cacique, jefe",
    "ale'eya": "verdad",
    "aliikaa": "llorar",
    "aliina": "muela, diente",
    "alijuna": "persona no wayuu, criollo",
    "aluwataaya": "autoridad, gobernante",
    "amaa": "comprar",
    "amüchi": "cerro, montaña",
    "anaajaa": "cuidar",
    "anaa": "bien, estar bien",
    "anasü": "bueno, sano, bonito",
    "anniaa": "llegar (plural)",
    "apaa": "camino",
    "apain": "tres",
    "apanai": "hoja",
    "apünaa": "tres (clasificador)",
    "apünajaa": "sembrar",
    "arüleejaa": "sufrir",
    "asha": "sangre",
    "ashajaa": "escribir",
    "ashii": "padre",
    "asaa": "beber",
    "asalaa": "carne",
    "ashuku": "huevo",
    "asii": "flor",
    "atijaa": "saber, conocer",
    "atpanaa": "escuchar",
    "atüjaa": "conocer, saber",
    "atüna": "brazo",
    "atüttaa": "caer",
    "aürülaa": "flaco, delgado",
    "ayaawajaa": "buscar",
    "ayee": "lengua",
    "ayollee": "dolor",
    "ayonnajaa": "dormir",
    "ayuulii": "enfermedad, estar enfermo",
    "e'iyalaa": "comida preparada",
    "ee": "sí",
    "eemüin": "hacia, en dirección a",
    "eesü": "hay, existe",
    "ei": "madre",
    "eirükü": "leche",
    "ejechi": "ojo",
    "ekaa": "comer",
    "eküülü": "comida, alimento",
    "ekirajaa": "enseñar, aprender",
    "ekirajüi": "profesor, maestro",
    "epijaa": "enterrar",
    "epijaaya": "funeral, entierro",
    "eshi'i": "arena",
    "ii": "nariz",
    "ippa": "tierra",
    "ipa": "tierra, terreno",
    "iraa": "esposo",
    "isaa": "espina",
    "ishoo": "otro",
    "ja'yaa": "caminar, andar",
    "jaajaa": "hace tiempo",
    "jalianaa": "calentar",
    "jama'a": "mucho",
    "jashichi": "caballo",
    "jawata": "fiebre, calentura",
    "jayaa": "ir",
    "jeketü": "nuevo",
    "ji'iree": "semilla",
    "jia": "lluvia (forma corta)",
    "jimelu": "mujer joven",
    "jintü": "niña",
    "jintüi": "muchacho",
    "jintüt": "nombre",
    "joo": "ven, vamos",
    "jootoo": "noche",
    "josoo": "nuevo, reciente",
    "joulü": "casa (forma)",
    "joutai": "viento",
    "ju'u": "dentro de",
    "juchon": "su hijo (de ella)",
    "jüküjülü": "lejos",
    "jülüja aa'in": "precaución, tener cuidado",
    "juya": "lluvia, invierno, año",
    "ka'i": "sol, día",
    "ka'ruwarai": "estrella",
    "kaa'uleein": "estado nutricional",
    "kaachon": "edad",
    "kaalü": "oreja",
    "kaasha": "monte, selva",
    "kachon": "edad en meses",
    "kaleena": "cabra",
    "kalena": "cabra",
    "kamüshii": "rico, sabroso",
    "kanasü": "bonito, lindo",
    "karaloüta": "libro, carta",
    "kasachiki": "sal",
    "kashi": "luna, mes",
    "kasü": "cosa, qué",
    "katsinshi": "fuerte, sano, robusto",
    "katsüin": "fuerte",
    "kaula": "oveja",
    "keeralia": "gallina",
    "keirraa": "joven (mujer)",
    "kiisa": "tos",
    "ko'omüin": "llenar",
    "koloolo": "caballo",
    "koonolaa": "trabajo, oficio",
    "kottaa": "cortar",
    "kottiraa": "convivir, estar juntos",
    "kuluulu": "tela, trapo",
    "laülaa": "viejo, anciano",
    "lumaa": "fiebre",
    "luwomüin": "cerca",
    "ma'i": "muy",
    "ma'aka": "como, igual que",
    "maachon": "huérfano",
    "maalü": "sombra",
    "machon": "huérfano",
    "maiki": "maíz",
    "malamalasü": "enfermizo",
    "maleiwa": "Dios",
    "mamainnaa": "nunca",
    "manaaja": "aun, todavía",
    "mapa": "después, futuro",
    "masaa": "hambre",
    "meeta": "también",
    "mia": "camino",
    "miichi": "casa",
    "mojotsü": "podrido, dañado",
    "mojuü": "malo, feo",
    "molu'u": "arena",
    "muac": "perímetro braquial, brazo",
    "mürülü": "cabello, pelo",
    "müin": "así, como",
    "müle'u": "suerte, buena fortuna",
    "müsüja": "triste",
    "namaa": "con ellos",
    "nee": "carne",
    "nii": "pene",
    "noo'ui": "hueso",
    "nüla": "perro",
    "nümaa": "con él",
    "nüsha": "carne de él",
    "nütüjülü": "talla, estatura",
    "o'u": "barriga, estómago, vientre",
    "o'ulaka": "olvidar",
    "o'yotaa": "regar, derramar",
    "oo'ui": "hueso",
    "oikaa": "matar",
    "ojo'u": "corazón (físico)",
    "olojo'u": "ojo",
    "onnootaa": "pensar, creer",
    "opüsü": "blanco",
    "oütsü": "médico tradicional, piache",
    "pa'a": "dos",
    "palaa": "mar",
    "palaamüin": "hacia el mar",
    "palajana": "langosta",
    "palapaala": "cuentos, historias",
    "palichi": "flojo, perezoso",
    "panaa": "costilla",
    "pasiewa": "amigo",
    "pejee": "cerca",
    "peyaa": "antes, antiguamente",
    "pia": "tú",
    "piama": "dos",
    "piichi": "casa, hogar",
    "pülaa": "grande",
    "pülashii": "gordo",
    "püna": "cerebro, cabeza",
    "püshajaa": "llevar, traer",
    "pütchi": "palabra, mensaje, noticia",
    "pütchipü'ü": "vocero, mensajero",
    "ranchería": "asentamiento wayuu",
    "sa'a": "pie",
    "saa'in": "su corazón, su sentimiento",
    "shaawala": "grillo",
    "shi'i": "arena",
    "shiki'i": "labio",
    "shürüla": "gusano",
    "siki": "fuego",
    "sukaa": "porque, a causa de",
    "sukuaipa": "forma, manera, cultura",
    "süchii": "azúcar, dulce",
    "süchon": "su hijo (de ella)",
    "süi": "chinchorro, hamaca",
    "sümaa": "con (compañía)",
    "sümüin": "hacia, para",
    "süpüla": "para que",
    "süpüshua": "todo, completo",
    "taa'in": "mi corazón",
    "tashii": "mi padre",
    "tatüjaa": "yo sé, yo conozco",
    "taya": "yo",
    "tayaa": "yo tengo",
    "tepichi": "niño pequeño",
    "too'ui": "hueso",
    "tü": "la, esa (artículo femenino)",
    "tüü": "ese, esa",
    "uujolu": "rana, sapo",
    "utta": "llegar",
    "wa": "nosotros",
    "waima": "mucho, bastante, cantidad",
    "wale'eru": "lagarto, iguana",
    "wanee": "uno, un, una",
    "wane": "uno",
    "wanülu": "espíritu, sueño espiritual",
    "wapü": "norte",
    "watüjaa": "nosotros sabemos",
    "waya": "nosotros (pronombre)",
    "wayuu": "persona, gente, ser humano",
    "wayuunaiki": "idioma wayuu, hablar wayuu",
    "wopumüin": "lejos",
    "wüin": "agua",
    "wünü": "semilla",
    "wunu'u": "árbol, planta, palo",
    "ya": "aquí",
    "yaa": "aquí",
    "yalaa": "aquí (estar)",
    "yalajaa": "quedarse",
    "yoonna": "baile tradicional yonna",
    "yootoo": "noche, oscuridad",
    "yosü": "estrella"
}

# Merge: base siempre, selenium si disponible
for k, v in base_dict.items():
    if k not in dictionary:
        dictionary[k] = v

out_path = os.path.join(os.path.dirname(__file__), 'assets', 'wayuu_dictionary.json')
os.makedirs(os.path.dirname(out_path), exist_ok=True)

with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(dictionary, f, ensure_ascii=False, indent=2, sort_keys=True)

print(f"✅ Diccionario guardado en {out_path} ({len(dictionary)} entradas)")
