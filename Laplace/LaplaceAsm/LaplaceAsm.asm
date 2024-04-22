.data
  LaplaceMask BYTE 9 DUP (0,-1,0,-1,4,-1,0,-1,0) ;Maska dla filtru laplace
  ;LaplaceEXAMPLE BYTE 9 DUP (10,10,10,10,100,10,10,10,10) ;Do testowanie liczenia nowej wartosci piksela 
.code

_DllMainCRTStartup proc parameter1:DWORD, parameter2:DWORD, parameter3:DWORD  ;entry point
    MOV EAX, 1
    RET
_DllMainCRTStartup endp

GetNewPixelValue PROC
   
    PXOR XMM0,XMM0
    MOVQ XMM0, QWORD PTR [LaplaceMask] ;przeniesienie wartosci maski do rejestru XMM0
    ;MOVQ XMM10, QWORD PTR [LaplaceEXAMPLE] ; Testowanie obliczania wartosci piksela
    MOVDQU XMM10, XMM2 ;przeniesienie wektora koloru, ktory chcemy liczyc do wektora XMM10
    PMOVSXBW XMM0, XMM0 ;konwersja na word
   
    PMADDWD	XMM0, XMM10	;monozenie dwoch wektorow i sumowanie parami
    PHADDD XMM0, XMM0   ;sumuje elemenety parami 
    PHADDD XMM0, XMM0   ;sumuje elemenety parami
   
    MOVD ECX, XMM0    ;zapisanie wyniku do ECX 
    MOVSXD RDX, ECX ;przeniesienie wartosc do rejestru RDX
    
    ;Sprawdzanie czy wartosc jest z przedzialu 0-255
    CMP RDX, 0
    JL UnderZero 
    CMP RDX, 255
    JG Overflow 
    JMP DONE
    UnderZero:
    MOV RDX, 0 
    JMP DONE
    Overflow:
    MOV RDX, 255 
    DONE:
    RET
GetNewPixelValue ENDP

LaplaceApply PROC EXPORT
    
    MOV R11, RCX ; Wskaznik na tablice wejsciowa
    MOV R12, RDX ; Szerokosc obrazka (zapisana jako r b g a r g b a r g b a)
    MOV R13, R8 ; Wysokosc obrazka
    MOV R14, R9 ; Wskaznik na tablice wyjsciowa
    XOR RAX,RAX
    MOV RAX, QWORD PTR [RSP+40] ;przesuniecie dla threadow
    ADD R11, RAX
    ADD R14, RAX

    XOR RAX, RAX ;COLOMN_LOOP iterator (i=0)
    INC RAX ;i=1 zeby zaczac od 2 wiersza
    ;DEC R13

COLOMN_LOOP:

    XOR RBX, RBX ; ROW_LOOP iterator (j=0)
    ADD RBX, 4 ;Przeskakiwanie co 4 wartosc sa w formacie r, g, b , a
    
    ROW_LOOP:

    ;Lewy Gorny
    XOR RCX, RCX 
    XOR RDX, RDX 
    PXOR XMM1, XMM1

    ;kolor czerwony
    MOV RDX, RAX ;przenosimy wartosc i, zeby jej potem nie stracic
    DEC RDX ;zmniejszamy o jeden bo chcemy wartosc z pierwszzego wiersza a jestesmy w drugim
    IMUL RDX, R12 ; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX ; dodajemy iterator j 
    SUB RDX, 4 ; odejmujemy 4 aby cofnac sie do chcianej wartosc poprzedniego piksela 

    MOV CL, BYTE PTR [R11+RDX] ; wartosc piksela zapisujemy w rejestrze CL
    PSLLDQ XMM7, 2 ; przesuwamy rejestr o 2 
    MOVD XMM1, ECX ; przenosimy zawartosc rejestru do rejestry XMM1
    ADDPS XMM7, XMM1 ; dodanie do wektora ktory przechowuje wartosc piksel branych do obliczen 

    ;Tak samo jak wyzej tylko jeden element dalej w tablicy
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;Tak samo jak wyzej tylko jeden element dalej w tablicy
    ;kolor niebieski
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1

    ;Srodek Gora
    XOR RCX, RCX 
    XOR RDX, RDX 
    PXOR XMM1, XMM1

    ;kolor czerwony
    MOV RDX, RAX ;przenisienie iteratora do rdx
    DEC RDX ;przejscie do wiersza wyzej
    IMUL RDX, R12 ; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX ;dodanie przejscie do odpowiedniego piksela w wierszu

    MOV CL, BYTE PTR [R11+RDX] ;przeniesienie wartosci piksela do rejestry cl
    PSLLDQ XMM7, 2 ;przesuniecie rejestru xmm7
    MOVD XMM1, ECX ; przeniesie do rejsetru xmm1 wartosci z ecx 
    ADDPS XMM7,XMM1 ;dodanie nowej wartosci do wektora xmm7

    ;Tak samo jak wyzej tylko jeden element dalej w tablicy
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    ;Tak samo jak wyzej
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;Tak samo jak wyzej tylko jeden element dalej w tablicy
    ;kolor niebieski
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1
    

    ;Prawo Gora
    XOR RCX, RCX 
    XOR RDX, RDX 
    PXOR XMM1, XMM1

    ;kolor czerwony
    MOV RDX, RAX ;przenisienie iteratora i do rdx
    DEC RDX ;przejscie do wiersza powyzej
    IMUL RDX, R12; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX ;przesnie do odpowiedniego elementu w wierszu
    ADD RDX, 4 ;przejscie o 4 aby miec prawy gorny piksel

    MOV CL, BYTE PTR [R11+RDX] ;przeniesienie wartosci piksela do cl
    PSLLDQ XMM7, 2 ;przeusniecie o 2 rejestru xmm7
    MOVD XMM1, ECX ;przenisienie wartosc z ecx do xmm1
    ADDPS XMM7,XMM1 ;dodanie wartosc do xmm7

    ;jak powyzej 
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;jak powyzej
    ;kolor niebieski
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1

    ;Lewo Srodek
    XOR RCX, RCX 
    XOR RDX, RDX 
    PXOR XMM1, XMM1

    ;kolor czerwony
    MOV RDX, RAX ;przeniesienie i do rdx
    IMUL RDX, R12 ; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX ;dodanie j aby dostac sie do odpowiedniego elementu w wierszu
    SUB RDX,4 ;odjecie 4 aby dostac sie do lewego piksela
    
    MOV CL, BYTE PTR [R11+RDX] ;przeniseinie wartosci piksela do cl
    PSLLDQ XMM7, 2 ;przesunie rejestry xmm7 o 2
    MOVD XMM1, ECX ;przeniesienie ecx do xmm1
    ADDPS XMM7,XMM1 ;dodanie nowej wartosci do xmm7

    ;tak samo jak powyzej tylko jeden piksel dalej
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;tak samo jak powyzej tylko jeden piksel dalej
    ;kolor niebieski
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1

    ;Srodek 
    XOR RCX, RCX 
    XOR RDX, RDX 
    XOR R8,R8
    PXOR XMM1, XMM1

    
    ;kolor czerwony
    MOV RDX, RAX  ;przeniesienie iteratora i do rdx
    IMUL RDX, R12 ; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX ;dodanie przjescie do odpoweidniego indexu w wierszu 
    MOV R8, RDX ;zapisanie indexu piksela ktorego zmieniamy
    
    MOV CL, BYTE PTR [R11+RDX] ;przeniesienie wartosci piksela do cl
    PSLLDQ XMM7, 2 ;przesuniecie rejestru xmm7 o 2 
    MOVD XMM1, ECX ;przeniesienie wartosci rejestru ecx do xmm1
    ADDPS XMM7,XMM1 ;dodanie kolejnej wartosci piksela do xmm7

    ;tak samo jak powyzej tylko jeden dalej
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;tak samo jak powyzej tylko jeden dalej
    ;kolor niebiskie
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1

    ;Srodek prawo
    XOR RCX, RCX 
    XOR RDX, RDX 
    PXOR XMM1, XMM1

    ;kolor czerwony
    MOV RDX, RAX ;przeniesienie iteratora i do rdx
    IMUL RDX, R12 ; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX;dodanie j aby byc na odpowiednim indeksie 
    ADD RDX, 4 ;przenisienie sie o 4 aby dostac prawy piksel

    MOV CL, BYTE PTR [R11+RDX] ;przeniesienie wartosci piksela do cl
    PSLLDQ XMM7, 2 ;przesuniecie rejestru xmm7 o 2
    MOVD XMM1, ECX ;przenisienie wartosci ecx do xmm1
    ADDPS XMM7,XMM1 ;dodanie kolejnej wartosci do xmm7

    ;tak samo jak powyzej tylko jeden dalej
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;tak samo jak powyzej tylko jeden dalej
    ;kolor niebieski
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1

    ;Lewo Dol
    XOR RCX, RCX
    XOR RDX, RDX
    PXOR XMM1, XMM1

    ;kolor czerwony
    MOV RDX, RAX ;przeniesienie iteratora i do rdx
    INC RDX ;i++
    IMUL RDX, R12; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX ;dodanie j zeby dostac sie do odpowiedniego indeksu
    SUB RDX, 4 ;odjecie 4 zeby dostac sie do lewego piksela
    
    MOV CL, BYTE PTR [R11+RDX] ;przenisienie wartosci piksela do cl
    PSLLDQ XMM7, 2 ;przesuniecie rejestru o 2
    MOVD XMM1, ECX ;przeniesienie ecx do xmm1
    ADDPS XMM7,XMM1 ; dodanie nowej wartosci do xmm7

    ;tak samo jak powyzej tylko jeden dalej
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;tak samo jak powyzej tylko jeden dalej
    ;kolor niebiski
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1

    ;Dol Srodek
    XOR RCX, RCX 
    XOR RDX, RDX 
    PXOR XMM1, XMM1

    ;kolor czerwony
    MOV RDX, RAX ;przeniseinie iterator i do rdx
    INC RDX ;i++
    IMUL RDX, R12 ; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX ;dodanie j zeby dostac sie do odpowiedniego indeksu

    MOV CL, BYTE PTR [R11+RDX] ;przenisienie wartosc piksela do cl
    PSLLDQ XMM7, 2 ;przesuniecie rejestru xmm7 o 2
    MOVD XMM1, ECX ;przeniesienie ecx do xmm1
    ADDPS XMM7,XMM1 ;dodanie kolejnej wartosci do xmm7

    ;tak samo jak powyzej tylko o jeden dalej
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;tak samo jak powyzej tylko o jeden dalej
    ;kolor niebieski 
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1

    ;Dol Prawo
    XOR RCX, RCX 
    XOR RDX, RDX 
    PXOR XMM1, XMM1

    ;kolor czerwony
    MOV RDX, RAX ;przeniesienie i do rdx
    INC RDX ;i++
    IMUL RDX, R12; mnozymy razy szerokosc aby dostac sie do odpowiedniego indexu
    ADD RDX, RBX ;dodanie j aby dostac sie do odpowiedniego indeksu
    ADD RDX, 4 ; dodanie 4 aby dostac sie do prawego piksela

    MOV CL, BYTE PTR [R11+RDX] ;przeniesienie wartosci piksela do cl
    PSLLDQ XMM7, 2 ;przesuniecie rejestru o 2 
    MOVD XMM1, ECX ; przeniesienie wartosci ecx do xmm1
    ADDPS XMM7,XMM1 ;dodanie kolejnej wartosci do xmm7

    ;tak jak powyzej tylko jeden dalej
    ;kolor zielony
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM8, 2
    MOVD XMM1, ECX
    ADDPS XMM8, XMM1

    ;tak jak powyzej tylko jeden dalej
    ;kolor niebiski
    PXOR XMM1,XMM1
    XOR RCX,RCX
    INC RDX
    MOV CL, BYTE PTR [R11+RDX]
    PSLLDQ XMM9, 2
    MOVD XMM1, ECX
    ADDPS XMM9, XMM1

    ;Czerwony
    PXOR XMM2,XMM2
    XOR RDX, RDX

    MOVDQU XMM2, XMM7 ; przensienie wartosc pikseli ktore bedziemy liczyli do wektora XMM2
    CALL GetNewPixelValue ; wywoanie procedury
    MOV BYTE PTR [R14+R8], DL ; przypisanie nowej wartosc 
   
    ;zielony
    PXOR XMM2,XMM2
    XOR RDX, RDX

    MOVDQU XMM2, XMM8 ; przensienie wartosc pikseli ktore bedziemy liczyli do wektora XMM2
    CALL GetNewPixelValue ; wywoanie procedury
    INC R8 ;przejscie do kolejnej skladowej
    MOV BYTE PTR [R14+R8], DL; przypisanie nowej wartosc 
    
    ;niebiski
    PXOR XMM2,XMM2 
    XOR RDX, RDX

    MOVDQU XMM2, XMM9 ; przensienie wartosc pikseli ktore bedziemy liczyli do wektora XMM2
    CALL GetNewPixelValue ; wywoanie procedury
    INC R8;przejscie do kolejnej skladowej
    MOV BYTE PTR [R14+R8], DL; przypisanie nowej wartosc 
    
    INC R8;przejscie do kolejnej skladowej
    MOV BYTE PTR [R14+R8], 255 ; zapisanie wartosc a na 255 

    ADD RBX, 4 ;j+=4
    CMP RBX, R12 
    JL ROW_LOOP; j < szerokoœæ obrazka

    INC RAX ;i++
    CMP RAX, R13 
    JL COLOMN_LOOP ; i < wysokoœæ obrazka 

    ;USUWAC OBRAMOWANIA 
   
    XOR RAX, RAX
    MOV RAX, R12
    IMUL RAX, R13
    DEC RAX
    XOR RBX, RBX

    ;przenoszenie przedostatniego wiersza od ostatniego
    BOTTOM_EDGE:
        XOR RCX, RCX
        XOR RDX, RDX
        DEC RAX 
        MOV RDX, RAX
        SUB RDX, R12
        MOV CL, BYTE PTR [R14+RDX]
        MOV BYTE PTR [R14+RAX], CL
        INC RBX
    CMP RBX, R12
    JNE BOTTOM_EDGE

    ;przenoszenie drugiego wiersza do pierszego 
    XOR RAX, RAX
    XOR RBX, RBX 
    TOP_EDGE:
        XOR RCX, RCX
        XOR RDX, RDX
        MOV RCX, RAX
        ADD RCX, R12
        MOV DL, BYTE PTR [R14+RCX]
        MOV BYTE PTR [R14+RAX], DL
        INC RAX
    CMP RAX,R12
    JNE TOP_EDGE

    RET 

LaplaceApply ENDP

END



