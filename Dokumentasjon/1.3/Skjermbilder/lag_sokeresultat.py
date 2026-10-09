from PIL import Image, ImageDraw, ImageFilter, ImageFont
# Søkeresultat (3:2, 3840 × 2560) i samme stil som headeren: palett (Harmoni), kontroll (Kontrast) og designsystem.
S='skudd/'
W,H=3840,2560
BG=(244,242,238); TXT=(28,37,48); GRA=(150,158,166)
font=ImageFont.truetype('/System/Library/Fonts/SFNS.ttf',150); font.set_variation_by_axes([100,96,400,600])
titler={'nb':'Fra palett gjennom validering til designsystem','en':'From palette through validation to design system'}
def maske(sz,r):
    m=Image.new('L',sz,0); ImageDraw.Draw(m).rounded_rectangle([0,0,sz[0]-1,sz[1]-1],r,fill=255); return m
def legg(c,im,x,y,r):
    m=maske(im.size,r)
    sk=Image.new('L',(im.width+240,im.height+240),0); sk.paste(m,(120,120)); sk=sk.filter(ImageFilter.GaussianBlur(48))
    c.paste(Image.new('RGB',sk.size,(0,0,0)),(x-120,y-120+30),sk.point(lambda v:int(v*0.22)))
    c.paste(im,(x,y),m)
def pil(d,x0,x1,y):
    d.line([(x0,y),(x1-12,y)],fill=GRA,width=16); d.polygon([(x1,y),(x1-52,y-38),(x1-52,y+38)],fill=GRA)
for L in ['nb','en']:
    c=Image.new('RGB',(W,H),BG); d=ImageDraw.Draw(c)
    t=titler[L]; b=d.textbbox((0,0),t,font=font); d.text(((W-(b[2]-b[0]))/2-b[0],170),t,font=font,fill=TXT)
    tlf=[Image.open(S+f).convert('RGB') for f in [f's-harmoni-{L}.png',f'h-kontrast-{L}.png',f's-designsystem-{L}.png']]
    h=1960; k=h/tlf[0].height; tlf=[i.resize((round(i.width*k),h),Image.LANCZOS) for i in tlf]
    gap=230; total=sum(i.width for i in tlf)+2*gap; x=(W-total)//2; y=470
    for n,i in enumerate(tlf):
        legg(c,i,x,y,120); x+=i.width
        if n<2: pil(d,x+50,x+gap-50,y+h//2); x+=gap
    c.save(S+f'sok-{L}.png'); c.resize((W//4,H//4),Image.LANCZOS).save(S+f'sok-{L}-sml.png'); print(L,c.size,c.mode)
