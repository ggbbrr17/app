from gtts import gTTS
import os

# Create assets folder if it doesn't exist
assets_dir = "assets"
if not os.path.exists(assets_dir):
    os.makedirs(assets_dir)

# We use 'es' (Spanish) voice because gTTS doesn't support Wayuunaiki directly, 
# but reading Wayuunaiki with Spanish phonetics is a passable robotic approximation.
# "ü" will sound a bit like 'u'

# 1. Normal / Sano
text_sano = "Anaasü chi tepichikai. Püna ekülü anasü nümüin."
# (El niño está bien. Dale buena comida.)
tts_sano = gTTS(text=text_sano, lang='es')
tts_sano.save(os.path.join(assets_dir, "wayuu_sano.mp3"))

# 2. Desnutrición / Peligro
text_peligro = "Mo'usü. Nnojoishi anain chi tepichikai. Püshata hospitalmüin."
# (Está mal. El niño no está bien. Llévalo al hospital.)
tts_peligro = gTTS(text=text_peligro, lang='es')
tts_peligro.save(os.path.join(assets_dir, "wayuu_peligro.mp3"))

# 3. Sobrepeso / Precaución
text_precaucion = "Kaa'yasü chi tepichikai. Anasü pütchajain wane pütchi."
# (El niño está gordo/pesado. Es bueno buscar consejo/hablar.)
tts_precaucion = gTTS(text=text_precaucion, lang='es')
tts_precaucion.save(os.path.join(assets_dir, "wayuu_precaucion.mp3"))

print("Audios generados exitosamente en assets/")
