from PIL import Image, ImageDraw, ImageFilter, ImageFont
# Header (21:9, 3840 × 1646) for 1.4: finne, se og jobbe med farger – Studio (iPhone), Harmoni på åpen iPhone Duo og
# designsystem (iPhone). Kilder: App Store-skjermbildene i iphone63-<språk>/ og iphoneduo-<språk>/, se AppStore.md.
S='skudd/'
W,H=3840,1646
BG=(244,242,238); TXT=(28,37,48)
font=ImageFont.truetype('/System/Library/Fonts/SFNS.ttf',118); font.set_variation_by_axes([100,96,400,600])
titler={'nb':'Finn farger, se farger, jobb med farger','en':'Find colours, see colours, work with colours'}
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
    venstre=Image.open(f'iphone63-{L}/01-studio.png').convert('RGB')
    duo=Image.open(f'iphoneduo-{L}/02-apen-studio-harmoni.png').convert('RGB')
    høyre=Image.open(f'iphone63-{L}/05-designsystem.png').convert('RGB')
    tlf=lambda i: i.resize((round(i.width*h/i.height),h),Image.LANCZOS)
    venstre, høyre = tlf(venstre), tlf(høyre)
    duo=duo.resize((round(duo.width*h/duo.height),h),Image.LANCZOS)
    gap=150; total=venstre.width+duo.width+høyre.width+2*gap; x=(W-total)//2
    legg(c,venstre,x,topp,80); x+=venstre.width+gap
    legg(c,duo,x,topp,70); x+=duo.width+gap
    legg(c,høyre,x,topp,80)
    c.save(f'header-{L}.png'); c.resize((W//4,H//4),Image.LANCZOS).save(f'header-{L}-sml.png'); print(L,c.size)
