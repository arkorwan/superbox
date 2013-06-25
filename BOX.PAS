program SuperBox;
uses crt, graph;
const
 maxlevel=12;
 path='C:\superbox\data\';
var
 p:array[0..5] of pointer;
 po:array[0..149] of shortint;
 bpo:array[1..5,0..149] of shortint;
 minmove:array[1..12] of word;
 move,i,j:integer;
 ch:char;
 cp,cx,cy:shortint;
 level,menuindex,character,undoable:shortint;
 points,snddelay:word;
 won,quit:boolean;

procedure putimg(x,y,n:shortint);
begin
 putimage(20+40*x, 40+40*y, p[n]^,normalput);
 po[x+15*y]:=n;
end;

procedure getimg(var p:pointer);
var
 size:word;
begin
 size:=imagesize(0,0,39,39);
 getmem(p,size);
 getimage(0,0,39,39,p^);
 cleardevice;
end;

function chpo(x,y,n:shortint):boolean;
begin
 if po[x+15*y]=n then chpo:=true else chpo:=false;
end;

procedure drawandget;
var
 pic:text;
begin
 setbkcolor(0);
 cleardevice;
{blank}
 getimg(p[0]);
{brick}
 setfillstyle(1,4);bar(0,0,39,39);
 setcolor(7);rectangle(0,20,39,39);line(20,0,20,20);
 setcolor(12);rectangle(-1,0,19,19);rectangle(21,0,40,19);rectangle(1,21,38,38);
 getimg(p[1]);
{block}
 setfillstyle(1,1);bar(1,1,38,38);setcolor(9);rectangle(0,0,39,39);
 getimg(p[2]);
{door}
 setfillstyle(1,9);bar(1,1,38,38);setcolor(11);rectangle(0,0,39,39);
 rectangle(19,0,20,39);setfillstyle(1,14);bar(4,5,15,17);bar(24,5,35,17);
 getimg(p[5]);
{right}
 assign(pic,path+'img01.bgf');
 reset(pic);
 for i:=0 to 39 do for j:=0 to 39 do
 begin
  read(pic,ch);
  putpixel(i,j,ord(ch)-50);
 end;
 close(pic);
 getimg(p[3]);
{left}
 putimage(40,0,p[3]^,normalput);
 for i:=0 to 39 do for j:=0 to 39 do putpixel(i,j,getpixel(79-i,j));
 getimg(p[4]);
end;

procedure checkgraphic;
var
 gd,gm:integer;
begin
 gd := detect;
 initgraph(gd, gm, ' ');
 if graphresult <> grok then halt;
end;

procedure loadlevel(n:shortint);
const x='R-Restart  U-Undo  H-Hint  ESC-Exit to Menu';
var
 lvl:text;
 lvls:string[5];
begin
 cleardevice;
 settextstyle(7,0,7);
 setcolor(7); outtextxy(190,230,'LEVEL '+chr(n+64));
 setcolor(15); outtextxy(193,233,'LEVEL '+chr(n+64));
 readkey;
 lvls:=chr(n+64)+'.lvl';
 assign(lvl,path+lvls);
 reset(lvl);
 i:=0;
 while not eof(lvl) do
 begin
  read(lvl,ch);
  po[i]:=ord(ch)-48;
  inc(i);
 end;
 close(lvl);
 for i:=0 to 9 do for j:=0 to 14 do
 begin
  putimg(j,i,po[15*i+j]);
  if (chpo(j,i,3))or(chpo(j,i,4)) then
  begin
   cx:=j; cy:=i;
  end;
 end;
 for i:=0 to 149 do for j:=1 to 5 do bpo[j,i]:=0;
 settextstyle(0,0,1);setcolor(15);
 outtextxy(20,460,'LEVEL '+chr(n+64));
 outtextxy(619-textwidth(x),460,x);
 rectangle(0,450,639,479);
 won:=false;
 undoable:=0;
 move:=0;
end;

procedure seehint;
var
 f:file;
 x:string[96];
begin
 assign(f,path+'hints.dat');
 reset(f,7);
 seek(f,(filesize(f) div maxlevel)*(level-1));
 blockread(f,x,12);
 close(f);
 settextstyle(2,0,5);
 setcolor(2);
 outtextxy(320-(textwidth(x) div 2),20,x);
 setcolor(10);
 outtextxy(321-(textwidth(x) div 2),21,x);
 move:=move+(minmove[level] div 2);
end;

procedure getundo;
begin
 for i:=0 to 149 do
 begin
  for j:=5 downto 2 do bpo[j,i]:=bpo[j-1,i];
  bpo[1,i]:=po[i];
 end;
end;

procedure undo;
begin
 if undoable=0 then exit;
 sound(random(2000)+500); delay(snddelay); nosound;
 dec(undoable);
 inc(move);
 for i:=0 to 149 do
 begin
  po[i]:=bpo[1,i];
  putimg(i mod 15,i div 15,po[i]);
  if (po[i]=3)or(po[i]=4) then
  begin
   cx:=i mod 15;
   cy:=i div 15;
  end;
  for j:=1 to 4 do bpo[j,i]:=bpo[j+1,i];
  bpo[5,i]:=0;
 end;
end;

procedure freefall(x,y,n:shortint);
begin
 while (chpo(x,y+1,0))or(chpo(x,y+1,5)) do
 begin
  if chpo(x,y+1,5) then won:=true;
  putimg(x,y,0);
  putimg(x,y+1,n);
  if (n=4)or(n=3) then
  begin
   if chpo(x,y-1,2) then
   begin
    putimg(x,y-1,0);
    putimg(x,y,2);
   end;
   inc(cy);
  end;
  inc(y);
 end;
end;

procedure slide(n:integer);
begin
 sound(random(2000)+500); delay(snddelay); nosound;
 if cx=7+7*n then
 begin
  if not(chpo(cx,cy,(7-n)div 2)) then move:=move+1;
  putimg(cx,cy,(7-n)div 2);
  exit;
 end;
 if chpo(cx+n,cy,5) then won:=true;
 if (chpo(cx+n,cy,0))or(chpo(cx+n,cy,5)) then
 begin
  inc(move);
  putimg(cx+n,cy,(7-n)div 2);
  putimg(cx,cy,0);
  inc(cx,n);
  if chpo(cx-n,cy-1,2) then
  begin
   if chpo(cx,cy-1,0) then putimg(cx,cy-1,2) else freefall(cx-n,cy-1,2);
   putimg(cx-n,cy-1,0);
  end;
  freefall(cx,cy,(7-n)div 2);
 end
 else
 begin
  if not(chpo(cx,cy,(7-n)div 2)) then move:=move+1;
  putimg(cx,cy,(7-n)div 2);
 end;
end;

procedure climb;
var
 n:shortint;
begin
 n:=7-po[cx+cy*15]*2;
 if cy=0 then exit;
 if (cy=1)and(chpo(cx,cy-1,2)) then exit;
 if cx=7+7*n then exit;
 if chpo(cx,cy-1,1) then exit;
 if (chpo(cx,cy-1,2))and(chpo(cx,cy-2,1)) then exit;
 if not((chpo(cx+n,cy-1,0))or(chpo(cx+n,cy-1,5))) then exit;
 if (chpo(cx+n,cy,1))or(chpo(cx+n,cy,2)) then
 begin
  if chpo(cx,cy-1,2) then putimg(cx,cy-2,2);
  putimg(cx,cy,0);
  dec(cy);
  putimg(cx,cy,(7-n)div 2);
  slide(n);
 end;
end;

procedure pickordrop;
var
 n:shortint;
begin
 sound(random(2000)+500); delay(snddelay); nosound;
 n:=7-(po[cx+cy*15]*2);
 if cy=0 then exit;
 if not(chpo(cx+n,cy-1,0)) then exit;
 if cx=7+7*n then exit;
 if chpo(cx,cy-1,2) then
 begin
  inc(move);
  putimg(cx,cy-1,0);
  putimg(cx+n,cy-1,2);
  freefall(cx+n,cy-1,2);
 end
 else if (chpo(cx,cy-1,0))and(chpo(cx+n,cy,2)) then
 begin
  inc(move);
  putimg(cx+n,cy,0);
  putimg(cx,cy-1,2);
 end;
end;

procedure keyinput;
begin
 ch:=readkey;
 case ch of
 chr(27): quit:=true;
 'r','R': begin
           if points>10 then dec(points,10) else points:=0;
           loadlevel(level);
          end;
 'u','U':undo;
 'h','H':seehint;
 #0:begin
     getundo;
     if undoable<>5 then inc(undoable);
     ch:=readkey;
     case ch of
      #72:climb;
      #75:slide(-1);
      #77:slide(1);
      #80:pickordrop;
     end;
    end;
 end;
end;

procedure gameplay;
var
 txt:string[25];
 lvlpoints:word;
begin
 level:=0;
 quit:=false;
 points:=0;
 repeat
  inc(level);
  loadlevel(level);
  repeat keyinput until won or quit;
  if won then
  begin
   cleardevice;
   settextstyle(7,0,5);
   setcolor(15);
   txt:='LEVEL '+chr(level+64)+' PASSED!';
   outtextxy(320-(textwidth(txt) div 2),200,txt);
   lvlpoints:=(minmove[level]*100)div move;
   settextstyle(2,0,5);
   str(lvlpoints,txt);
   txt:='score of this level: '+txt;
   outtextxy(320-(textwidth(txt) div 2),300,txt);
   inc(points,lvlpoints);
   str(points,txt);
   txt:='total score: '+txt;
   outtextxy(320-(textwidth(txt) div 2),330,txt);
   readkey;
  end;
  if quit then exit;
 until level=maxlevel;
end;

procedure setsounddelay(sd:string);
var
 newsd:string[6];
 code:integer;
begin
 repeat
  setcolor(7);
  outtextxy(100,50,'SET SOUND DELAY: ');
  j:=100+textwidth('SET SOUND DELAY: ');
  setcolor(0);
  outtextxy(j,50,sd);
  newsd:='';
  repeat
   ch:=readkey;
   if ch<>chr(13) then
   begin
    newsd:=newsd+ch;
    setcolor(15);
    outtextxy(j,50,newsd);
   end;
  until ch=chr(13);
  val(newsd,snddelay,code);
  if code<>0 then
  begin
   setcolor(0);
   outtextxy(j,50,newsd);
  end;
 until code=0;
end;

procedure cselect;
var
 chs:string[2];
 pic:text;
begin
 character:=(character mod 4)+1;
 str(character,chs);
 assign(pic,path+'img0'+chs+'.bgf');
 reset(pic);
 for i:=320 to 359 do for j:=140 to 179 do
 begin
  read(pic,ch);
  putpixel(i,j,ord(ch)-50);
 end;
 close(pic);
 getimage(320,140,359,179,p[3]^);
 for i:=280 to 319 do for j:=140 to 179 do putpixel(i,j,getpixel(639-i,j));
 getimage(280,140,319,179,p[4]^);
end;

procedure opt(x:shortint);
var
 sd:string[6];
 chs:string[2];
 optindex:shortint;
begin
 cleardevice;
 settextstyle(2,0,8);
 optindex:=x;
 ch:=' ';
 str(snddelay,sd);
 str(character,chs);
 repeat
  while ch=#0 do
  begin
   ch:=readkey;
   if (ch=#72)and(optindex<>1) then dec(optindex);
   if (ch=#80)and(optindex<>3) then inc(optindex);
  end;
  for j:=1 to 3 do
   begin
   if optindex=j then  setcolor(15) else setcolor(7);
    case j of
     1:outtextxy(100,50,'SET SOUND DELAY: '+sd);
     2:outtextxy(100,100,'SELECT CHARACTER: '+chs);
     3:outtextxy(100,200,'RETURN TO MAIN MENU');
    end;
   end;
  putimage(320,140,p[3]^,normalput);
  putimage(280,140,p[4]^,normalput);
  ch:=readkey;
 until ch=chr(13);
 case optindex of
  1: setsounddelay(sd);
  2: cselect;
  3: exit;
 end;
 opt(optindex);
end;

procedure highsc(newscore:integer);
const
 hd='Super Box-Office';
var
 f:file;
 nm:array[1..10] of string[10];
 sc:array[1..10] of string[4];
 scn:array[1..10] of integer;
 code:integer;
 place:shortint;
 newname:string[10];
 newscorex:string[4];
begin
 cleardevice;
 assign(f,path+'highsc.dat');
 reset(f,1);
 for i:=1 to 10 do
 begin
  blockread(f,nm[i],10);
  blockread(f,sc[i],5);
  val(sc[i],scn[i],code);
 end;
 place:=1;
 newname:='';
 while (scn[place]>=newscore)and(place<>11) do inc(place);
 if place<>11 then
 begin
  for i:=9 downto place do
  begin
   sc[i+1]:=sc[i];
   nm[i+1]:=nm[i];
  end;
  str(newscore,newscorex);
  while length(newscorex)<4 do newscorex:='0'+newscorex;
  sc[place]:=newscorex;
  setcolor(10);
  settextstyle(2,0,6);
  outtextxy(50,200,'Your score are high enough to be in the Super Box-Office');
  outtextxy(100,225,'Please enter your name: ');
  ch:=readkey;
  repeat
   if (length(newname)<>0)and(ch=chr(8)) then
   begin
    setcolor(0);
    outtextxy(350,225,newname);
    newname:=copy(newname,1,length(newname)-1);
    setcolor(10);
   end
   else newname:=newname+ch;
   outtextxy(350,225,newname);
   ch:=readkey;
  until (length(newname)=10)or(ch=chr(13));
  nm[place]:=newname;
  rewrite(f,1);
  for i:=1 to 10 do
  begin
   blockwrite(f,nm[i],10);
   blockwrite(f,sc[i],5);
  end;
  cleardevice;
 end;
 close(f);
 setcolor(15);
 settextstyle(7,0,5);
 outtextxy(320-(textwidth(hd) div 2),50,hd);
 settextstyle(2,0,5);
 for i:=1 to 10 do
 begin
  outtextxy(200,150+25*i,nm[i]);
  outtextxy(400,150+25*i,sc[i]);
 end;
 readkey;
end;

procedure title;
begin
 cleardevice;
 for i:=0 to 25 do
 begin
  putimage(i*24-24,100,p[0]^,normalput);
  putimage(i*24,100,p[3]^,normalput);
  delay(500);
 end;
 settextstyle(5,0,6);
 for i:=24 downto 9 do
 begin
  putimage(i*24+24,100,p[0]^,normalput);
  putimage(i*24,100,p[4]^,normalput);
  setcolor(0);
  outtextxy(64+i*24,80,'SuperBox');
  setcolor(9);
  outtextxy(40+i*24,80,'SuperBox');
  delay(500);
 end;
end;

procedure endtitle;
var
 txt:string[30];
begin
 cleardevice;
 settextstyle(7,0,5);
 setcolor(15);
 if (won)and(level=maxlevel) then outtextxy(320-(textwidth('ALL LEVEL PASSED!)') div 2),200,'ALL LEVELS PASSED!');
 setcolor(9);
 str(points,txt);
 txt:='Your final score is '+txt+'.';
 settextstyle(2,0,5);
 outtextxy(320-(textwidth(txt) div 2),300,txt);
 won:=false;
 readkey;
 highsc(points);
end;

procedure menuchange(i:shortint);
var mn:string[10];
begin
 settextstyle(8,0,4);
 for j:=1 to 4 do
 begin
  if j=i then setcolor(15) else setcolor(7);
  case j of
   1:mn:='START';
   2:mn:='OPTIONS';
   3:mn:='HIGH SCORE';
   4:mn:='EXIT';
  end;
  outtextxy(320-textwidth(mn) div 2,250+40*j,mn);
 end;
end;

procedure menu;
begin
 cleardevice;
 quit:=false;
 settextstyle(5,0,6);
 putimage(192,100,p[4]^,normalput);
 setcolor(9);
 outtextxy(232,80,'SuperBox');
 settextstyle(0,0,2);
 menuchange(1);
 menuindex:=1;
 repeat
  ch:=readkey;
  while ch=#0 do
  begin
   ch:=readkey;
   if (ch=#72)and(menuindex<>1) then dec(menuindex);
   if (ch=#80)and(menuindex<>4) then inc(menuindex);
   menuchange(menuindex);
  end;
 until ch=chr(13);
end;

procedure getvalue;
var
 f:file;
begin
 snddelay:=500;
 character:=1;
 assign(f,path+'minmove.dat');
 reset(f,1);
 for i:=1 to 12 do blockread(f,minmove[i],2);
 close(f);
end;

begin
 randomize;
 checkgraphic;
 getvalue;
 drawandget;
 title;
 repeat
  menu;
  case menuindex of
   1:gameplay;
   2:opt(1);
   3:highsc(0);
  end;
  if won or quit then endtitle;
 until menuindex=4;
 closegraph;
end.