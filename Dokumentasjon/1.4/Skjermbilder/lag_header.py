from PIL import Image, ImageDraw, ImageFilter, ImageFont
# Header (21:9, 3840 × 1646) for 1.4: tonebanen på kula (iPhone), live 3D på åpen iPhone Duo og fargerom sammenlignet (iPhone).
# Kilder i skudd/: 3d-tonebane-, duo-3d- og 3d-gamut-<språk>.png (simulatorene «Skjermbilder 6,3» og iPhone Duo), se AppStore.md.
S='skudd/'
W,H=3840,1646
BG=(244,242,238); TXT=(28,37,48)
font=ImageFont.truetype('/System/Library/Fonts/SFNS.ttf',118); font.set_variation_by_axes([100,96,400,600])
titler={'nb':'Farger og fargerom i 3D – live mens du jobber','en':'Colours and colour spaces in 3D – live as you work'}
def maske(sz,r):
    m=Image.new('L',sz,0); ImageDraw.Draw(m).rounded_rectangle([0,0,sz[0]-1,sz[1]-1],r,fill=255); return m
def legg(c,im,x,y,r):
    m=maske(im.size,r)
    sk=Image.new('L',(im.width+200,im.height+200),0); sk.paste(m,(100,100)); sk=sk.filter(ImageFilter.GaussianBlur(40))
    c.paste(Image.new('RGB',sk.size,(0,0,0)),(x-100,y-100+24),sk.point(lambda v:int(v*0.20)))
    c.paste(im,(x,y),m)
for L in ['nb','en']:
    c=Image.new('RGB',(W,H),BG); d=ImageDraw.Draw(c)
    t=titler[L]; b=d.textbbox((0,0),t,font=font); d.text(((W-(b[2]-b[0]))/2-b[0],120),t,font=font,fill=TXT)
    h=1180; topp=380
    venstre=Image.open(S+f'3d-tonebane-{L}.png').convert('RGB')
    duo=Image.open(S+f'duo-3d-{L}.png').convert('RGB')
    høyre=Image.open(S+f'3d-gamut-{L}.png').convert('RGB')
    tlf=lambda i: i.resize((round(i.width*h/i.height),h),Image.LANCZOS)
    venstre, høyre = tlf(venstre), tlf(høyre)
    duo=duo.resize((round(duo.width*h/duo.height),h),Image.LANCZOS)
    gap=150; total=venstre.width+duo.width+høyre.width+2*gap; x=(W-total)//2
    legg(c,venstre,x,topp,80); x+=venstre.width+gap
    legg(c,duo,x,topp,70); x+=duo.width+gap
    legg(c,høyre,x,topp,80)
    c.save(f'header-{L}.png'); c.resize((W//4,H//4),Image.LANCZOS).save(f'header-{L}-sml.png'); print(L,c.size)
