from PIL import Image, ImageDraw, ImageFilter, ImageFont
import sys
# Kilder: skjermbilder fra simulatoren «Skjermbilder 6,3» (h-kontrast-, h-lys-, h-mork-<språk>.png), se AppStore.md.
S='skudd/'
W,H=3840,1646
BG=(244,242,238); TXT=(28,37,48); PIL_GRA=(150,158,166)
font=ImageFont.truetype('/System/Library/Fonts/SFNS.ttf',118); font.set_variation_by_axes([100,96,400,600])
titler={'nb':'Fra palett gjennom validering til designsystem','en':'From palette through validation to design system'}
R=56
def avrund(im,r=R):
    m=Image.new('L',im.size,0); ImageDraw.Draw(m).rounded_rectangle([0,0,im.width-1,im.height-1],r,fill=255); return m
def legg(c,im,x,y):
    m=avrund(im)
    sk=Image.new('L',(im.width+200,im.height+200),0); sk.paste(m,(100,100)); sk=sk.filter(ImageFilter.GaussianBlur(40))
    skygge=Image.new('RGB',sk.size,(0,0,0)); c.paste(skygge,(x-100,y-100+24),sk.point(lambda v:int(v*0.20)))
    c.paste(im,(x,y),m)
def pil(d,x0,x1,y):
    d.line([(x0,y),(x1-10,y)],fill=PIL_GRA,width=14)
    d.polygon([(x1,y),(x1-46,y-34),(x1-46,y+34)],fill=PIL_GRA)
for L in ['nb','en']:
    c=Image.new('RGB',(W,H),BG); d=ImageDraw.Draw(c)
    t=titler[L]; b=d.textbbox((0,0),t,font=font); d.text(((W-(b[2]-b[0]))/2-b[0],120),t,font=font,fill=TXT)
    hoyde=1180; topp=380; s=None
    kon=Image.open(S+f'h-kontrast-{L}.png').convert('RGB').crop((48,336,1158,1740))
    lys=Image.open(S+f'h-lys-{L}.png').convert('RGB').crop((48,744,1158,1958))
    mork=Image.open(S+f'h-mork-{L}.png').convert('RGB').crop((48,744,1158,1958))
    k=hoyde/kon.height
    kon=kon.resize((round(kon.width*k),hoyde),Image.LANCZOS)
    k2=(hoyde-90)/lys.height
    lys=lys.resize((round(lys.width*k2),hoyde-90),Image.LANCZOS); mork=mork.resize(lys.size,Image.LANCZOS)
    palb=380; pilb=190; forskyv=280
    total=palb+pilb+kon.width+pilb+lys.width+forskyv
    x=(W-total)//2
    # palett
    farger=['#2F7FD8','#AC58AF','#C95530','#858400','#009784']
    pal=Image.new('RGB',(palb,hoyde),(255,255,255)); pd=ImageDraw.Draw(pal)
    bh=hoyde/len(farger)
    for i,f in enumerate(farger): pd.rectangle([0,round(i*bh),palb,round((i+1)*bh)],fill=f)
    legg(c,pal,x,topp); x+=palb
    pil(d,x+40,x+pilb-40,topp+hoyde//2); x+=pilb
    legg(c,kon,x,topp); x+=kon.width
    pil(d,x+40,x+pilb-40,topp+hoyde//2); x+=pilb
    legg(c,mork,x+forskyv,topp+90); legg(c,lys,x,topp)
    c.save(S+f'header-{L}.png')
    c.resize((W//4,H//4),Image.LANCZOS).save(S+f'header-{L}-sml.png')
    print(L,c.size,c.mode)
