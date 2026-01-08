assume cs:code, ds:data

data segment
    mesaj db 'Introduceti intre 8-16 octeti in hex (ex: 3F 7A 12 5C etc.):', 10, 13, '$'
    eroare db 10, 13, 'Eroare: Trebuie sa introduceti intre 8 si 16 octeti!', 10, 13, '$'
    numere db 50, ?, 50 dup(?) 
    sir db 20 dup(?) 
    linie_noua db 10, 13, '$'
    contor_octeti dw 0   ;variabila word (pentru a o putea muta direct in cx) folosita la numararea octetilor convertiti 

    C dw (?)
    mesaj_afisare db 10, 13, "Valoarea lui C este: $"

    msg_sortat    db 10, 13, 'Sirul sortat (descrescator): $'
    msg_pozitie   db 10, 13, 'Pozitia octetului cu cei mai multi biti de 1 (>3): $'
    msg_nu_exista db 10, 13, 'Nu exista octeti cu mai mult de 3 biti de 1.$'
    max_bits      db 0        ;variabila pentru numarul maxim de biti de 1 gasiti
    pozitie_max   db 0        ;variabila pentru a memora pozitia octetului gasit
	
	;sir db 83h, 0C4h, 33h test
	temp dw ?
    mesaj_binar db 10,13,'Sir dupa rotire (binar):',10,13,'$'
    mesaj_hex   db 10,13,'Sir dupa rotire (hex):',10,13,'$'
data ends

code segment

;subrutina ce converteste un caracter ascii in valoare binara
ascii_binar proc
    cmp al, '9'       ;verificam daca caracterul este cifra
    jbe cifra        
    cmp al, 'a'       ;verificam daca este litera mica
    jb litera         
    sub al, 'a'-'A'   ;transformam litera mica in litera mare
litera:      
    sub al, 7         ;scadem diferenta pentru litere
cifra:
    sub al, '0'       ;transformam in valoare numerica
    ret
ascii_binar endp

;subrutina pentru afisarea lui C
afisare_hex proc
    mov cx, 4   ; 4 cifre hex
afis_hex:
    mov dh,4
    rol ax, dh  ; rotim spre stanga ca urmatorul grup de 4 biți să ajungă în al              
    mov dl, al
    and dl, 0Fh ; folosim masca ca sa ramana daor 4 biti
    cmp dl, 9   ; comparam cu 9 pt a vedea daca este cifra
    jbe cifra_hex
    mov dh, 7
    add dl, dh  ; adaugam 7 pentru a putea face conversia(sarim peste cele 7 caractere aflate intre cifre si litere)
cifra_hex:
    add dl, '0' ; adunam codul ascii al lui zero pentru a converti in cifra
    mov ah, 02h ; afisam caracterul obtinut
    int 21h
    loop afis_hex
    ret
afisare_hex endp


;subrutina pentru a astepta apasarea unei taste 
wait_key proc
    mov ah, 08h ;08h asteapta un caracter de la tastatura
    int 21h
    ret
wait_key endp

;afiseaza AL in binar 
afisare_binar proc
    push ax
    push bx
    push cx

    mov bl, al ;salvam octetul original
    mov cx, 8 ;afis 8 biti

afis_bit:
    mov dl, bl ;copiem octetul
    and dl, 80h ;verificam bitul cel mai semnificativ
    jz zero	;daca e 0, sare la eticheta "zero"
    mov dl, '1' ;altfel afisam '1'
    jmp afis

zero:
    mov dl, '0'

afis:
    mov ah, 02h ;02h afiseaza un caracter
    int 21h
    shl bl, 1 ;rotim spre stanga ca următorul bit să ajungă sa fie cel mai semnificativ
    loop afis_bit

    mov dl, ' ' ;afisam spatiu intre octeti
    mov ah, 02h
    int 21h

    pop cx
    pop bx
    pop ax
    ret
afisare_binar endp


afisare_hexa proc
    push ax
    push cx

    mov cx, 2 ;afisam 2 cifre in hexa
afiss_hex:
    rol al, 4 ;mutam cei 4 biti sup in partea inf
    mov dl, al
    and dl, 0Fh ;ii izolam
    cmp dl, 9
    jbe este_cifra
    add dl, 7 ;ajustare pentru pozitiile 10-15 A-F
este_cifra:
    add dl, '0' ;conversie in ascii
    mov ah, 02h
    int 21h
    loop afiss_hex

    mov dl, ' '
    int 21h

    pop cx
    pop ax
    ret
afisare_hexa endp


rotire_sir proc
    mov si, offset sir
    mov cx, contor_octeti ;nr octeti
    jcxz iesire ;daca nr e 0, iesim

rotire_loop:
    lodsb ;punem octetul pe care suntem in AL
    mov bl, al ;pastram o copie in BL

    ;suma primilor 2 biti
    mov al, bl
    shr al, 7 ;bitul 7 devine bitul 0
    and al, 1 ;izolam bitul 7

    mov dl, bl
    shr dl, 6 ;bitul 6 devine bitul 0
    and dl, 1 ;izolam bitul 6

    add al, dl ;N

    cmp al, 0
    je skip_rot ;N este 0, nu rotim

    mov cl, al ; CL = N, nr rotatii
    mov al, bl
    rol al, cl ;rotim octetul cu N pozitii la stanga

skip_rot:
    mov [si-1], al ;salvam in sir

    dec cx
    jnz rotire_loop

iesire:
    ret
rotire_sir endp

start: 
    mov ax, data  
    mov ds, ax
    mov es, ax    ;es e necesar pentru instructiunea stosb

    ;afisare mesaj pentru introducerea valorilor
    mov ah, 09h
    mov dx, offset mesaj
    int 21h

    ;citire valori de la tastatura
    mov ah, 0Ah
    lea dx, numere    ;mov dx, offset numere
    int 21h

    ;initializare registre pentru conversie
    mov si, offset numere+2   ;caracterele introduse
    mov di, offset sir        ;sirul final de valori binare
    mov cl, [numere+1]        ;cl = numarul de caractere citite efectiv
    mov ch, 0                 ;extindem la cx
    cld                       ;directia de parcurgere (de la stanga la dreapta)
    jcxz Final_Program        ;daca nu se citesc elemente sarim direct la final

conversie:
    lodsb                     ;se incarca primul caracter in al (ex: '3')
    cmp al, ' '               ;verificam daca este spatiu
    je skip_loop              ;daca este, sarim la final

    call ascii_binar          ;apelam procedura de conversie
    shl al, 4                 ;mutam valoarea pe partea superioara a lui al
    mov bl, al                ;salvam temporar in bl               
    
    lodsb                     ;incarcam umatorul caracter in al
    dec cx                    ;decrementam manual cx-ul pentru al doilea element procesat in loop
    call ascii_binar          ;apelam procedura
    or al, bl                 ;combinam cu partea superioara

    stosb                     ;salvam elementul in sir
    inc contor_octeti         ;incrementam numarul de octeti salvati

skip_loop:
    loop conversie

;verificarea numarului de octeti si afisarea unui mesaj in cazul unui numar din afara intervalului 8-16
verificare:
    cmp contor_octeti, 8
    jb MesajEroare
    cmp contor_octeti, 16
    ja MesajEroare

;salvez numarul total de octeti intr-o variabila temporara
;avem nevoie pentru ultima parte
	mov ax, contor_octeti
	mov temp, ax     ; temp este o variabila word definita in data segment

;afisarea octetilor in baza 2
;adaugam o linie noua
mov ah, 09h
mov dx, offset linie_noua
int 21h

mov si, offset sir     ;octetii salvati
mov cx, contor_octeti  ;mutam numarul de octeti de afisat in contor
jcxz Final

Repeta_Octet:
push cx                ;salvam cx-ul pe stiva 
lodsb                  ;incarcam octetul curent in al
    
mov cx, 8              ;pregatim afisarea celor 8 biti
Repeta_Bit:
shl al, 1              ;punem bitul in CF
jc Unu                 ;daca in CF avem 1 mergem la eticheta Unu
mov dl, '0'            ;daca nu, pregatim afisarea lui 0
jmp Afisare_Bit

Unu:
mov dl, '1'            ;pregatim afisarea lui 1

Afisare_Bit:
push ax                ;salvam ax-ul pe stiva pentru a nu pierde configuratia bitilor din al
mov ah, 02h            ;functia pentru afisarea unui caracter
int 21h
pop ax                 ;restauram ax-ul
loop Repeta_Bit

;afisam un spatiu intre octeti
mov ah, 02h
mov dl, ' '
int 21h

pop cx                 ;restauram cx-ul
loop Repeta_Octet

;calculam cuvantul C

    mov si, offset sir; parcurgem sirul de numere dupa conversia lor
    mov bx, 0; in bx vom afla cuvantul C final

    ;bitii 0-3

    lodsb
    and al, 11110000b; in ax avem primii 4 biti ai primului octet
    mov cl, [sir+contor_octeti-1]; cum si a crescut dupa instructiunea lodsb, folosim sir, care se refera la offset ul sirului
    and cl, 00001111b; in bx avem ultimii 4 biti ai ultimului octet
    mov dl, 4
    rol al, dl; am mutat bitii lui ax pe locurile corespunzatoare
    xor al, cl
    mov ah,0
    or bx, ax; putem face aceatsa operatie deoarece pe bitii 0-3 din ax sunt bitii ceruti iar pe celelalte pozitii este 0, care nu modfica rezultatul

    ;bitii 4-7

    mov si, offset sir; parcurgem sirul de numere dupa conversia lor
    mov cx, contor_octeti
    mov dl,0
    jcxz Final_Program
repeta4_7:
    lodsb
    and al,00111100b
    or dl, al
    loop repeta4_7
    
    mov dh,0
    mov cx,2
    shl dl,2; deplasam la stanga pentru ca rezultatul sa fie pe pozitiile corecte
    or bx, dx; punem rezultatul in bx
    mov C, bx

    ;bitii 8-15
    mov si, offset sir; parcurgem sirul de numere dupa conversia lor
    mov cx, contor_octeti
    mov dl,0
    jcxz Final_Program
repeta8_15:
    lodsb
    add dl,al;  modulo 256 este automat cand folosim un registru de 8 biți pentru că overflow-ul se taie la 8 biți
    loop repeta8_15
    
    mov dh, dl; punem rezultatul in dh pentru a fi pe pozitiile corecte
    mov dl,0
    or bx, dx
    mov C, bx

    ;afisam C

    mov ah, 09h
    mov dx, offset mesaj_afisare
    int 21h

    mov ax, C; ax primeste valoarea ce trebuie afisata
    call afisare_hex

;sortam descrescator sirul folosind bubble sort
    
    mov cx, contor_octeti   ;incarcam numarul de octeti in cx pentru bucla exterioara
    dec cx                  ;decrementam cx deoarece bucla exterioara ruleaza de n-1 ori
    cmp cx, 0               ;verificam daca avem elemente de sortat
    jle Gata_Sortare        ;daca sirul e prea scurt, sarim peste sortare

Repeta_Sortare:
    mov bx, cx              ;salvam contorul in bx pt sortare
    mov si, offset sir      ;resetam pointerul la inceputul sirului 
    mov di, contor_octeti   ;initializam contorul 
    dec di                  ;merge pana la n-1
    mov si, 0               ;folosim si ca index de la 0

Verifica_perechi:
    mov al, sir[si]         ;incarcam elementul curent in al
    mov ah, sir[si+1]       ;incarcam elementul urmator in ah
    
    cmp al, ah              ;comparam elementul curent cu cel urmator
    jae NoSwap              ;daca curent >= urmator, sarim peste interschimbare (pentru descrescator)
    
    ;interschimbare
    mov sir[si], ah         ;punem elementul mai mare pe pozitia curenta
    mov sir[si+1], al       ;punem elementul mai mic pe pozitia urmatoare

NoSwap:
    inc si                  ;trecem la urmatoarea pereche de elemente
    dec di                  ;decrementam contorul 
    jnz Verifica_perechi    

    mov cx, bx              ;resetam contorul 
    loop Repeta_Sortare     ;decrementam cx si repetam pana sirul este sortat

Gata_Sortare:
    ;afisare mesaj confirmare sortare
    mov ah, 09h
    mov dx, offset msg_sortat
    int 21h

;determinarea octetului cu maxim de biti de 1 
    mov cx, contor_octeti   ;pregatim parcurgerea sirului sortat
    mov si, 0               ;resetam indexul sirului
    mov max_bits, 0         ;initializam maximul gasit cu 0
    mov pozitie_max, 255    ;initializam pozitie_max cu 255

Loop_Analiza:
    mov al, sir[si]         ;incarcam octetul curent din sir
    mov bl, 0               ;resetam contorul de biti pentru acest octet
    push cx                 ;salvam contorul principal pe stiva
    
    mov cx, 8               ;vom verifica toti cei 8 biti
CountBits:
    shl al, 1               ;shiftam stanga, cel mai semnificativ bit intra in Carry Flag 
    adc bl, 0               ;adunam valoarea din CF la bl (daca bitul a fost 1, bl creste)
    loop CountBits          ;repetam pentru toti bitii
    
    pop cx                  ;restauram contorul principal de pe stiva

    ;verificam conditia 1: numarul de biti 1 trebuie sa fie > 3
    cmp bl, 3
    jbe NextByte            ;daca este <= 3, trecem la urmatorul octet

    ;verificam conditia 2: numarul de biti trebuie sa fie > maximul curent
    cmp bl, max_bits
    jbe NextByte            ;daca nu este strict mai mare decat maximul anterior, ignoram

    ;am gasit un nou maxim
    mov max_bits, bl        ;actualizam valoarea maxima
    mov ax, si              ;copiem indexul curent in ax
    inc ax                  ;incrementam ax
    mov pozitie_max, al     ;salvam pozitia gasita

NextByte:
    inc si                  ;incrementam indexul pentru a trece la urmatorul octet din sir
    loop Loop_Analiza       ;continuam parcurgerea sirului

;afisarea pozitiei octetului gasit
    cmp pozitie_max, 255    ;verificam daca pozitie_max a ramas neschimbat
    je Nu_Gasit             ;daca da, inseamna ca nu am gasit niciun octet valid

    ;afisare mesaj pentru pozitie
    mov ah, 09h
    mov dx, offset msg_pozitie
    int 21h

    ;conversie pozitie din hex in zecimal pentru afisare
    mov al, pozitie_max     ;incarcam pozitia gasita
    cbw                     ;convertim byte la word 
    mov bl, 10              ;pregatim impartitorul 
    div bl                  ;impartim ax la 10: al = cat (zeci), ah = rest (unitati)
    mov bx, ax              ;salvam rezultatul in bx 

    ;afisare cifra zecilor (doar daca este diferita de 0)
    cmp bl, 0
    je PrintUnits           ;daca zecile sunt 0, sarim direct la unitati
    
    mov dl, bl              ;mutam cifra zecilor in dl
    add dl, '0'             ;o convertim in caracter ASCII
    mov ah, 02h             ;functia de afisare caracter
    int 21h

PrintUnits:
    mov dl, bh              ;mutam cifra unitatilor in dl
    add dl, '0'             ;o convertim in caracter ASCII
    mov ah, 02h             ;functia de afisare caracter
    int 21h

    jmp Afisare_Sir_Final   ;sarim peste mesajul de "nu exista"

Nu_Gasit:
    ;afisare mesaj daca nu s-a gasit niciun octet cu >3 biti de 1
    mov ah, 09h
    mov dx, offset msg_nu_exista
    int 21h

;afisarea sirului final sortat in binar
Afisare_Sir_Final:
    ;adaugam o linie noua
    mov ah, 09h
    mov dx, offset linie_noua
    int 21h

    mov si, offset sir      ;pregatim afisarea sirului (care acum este sortat)
    mov cx, contor_octeti 
    jcxz Final_Program

Repeta_Octet_Final:         
    push cx                 ;salvam contorul pe stiva
    lodsb                   ;incarcam octetul curent
    
    mov cx, 8               ;pregatim afisarea celor 8 biti
Repeta_Bit_Final:           
    shl al, 1               ;punem bitul in CF
    jc Unu_Final            ;daca este 1, sarim la eticheta Unu
    mov dl, '0'             ;daca nu, pregatim afisarea lui 0
    jmp Afisare_Bit_Final

Unu_Final:
    mov dl, '1'             ;pregatim afisarea lui 1

Afisare_Bit_Final:
    push ax                 ;salvam ax-ul pe stiva pentru a nu pierde configuratia bitilor din al
    mov ah, 02h             ;functia pentru afisarea unui caracter
    int 21h
    pop ax                  ;restauram ax-ul
    loop Repeta_Bit_Final   ;trecem la urmatorul bit

    ;afisam un spatiu intre octeti
    mov ah, 02h
    mov dl, ' '
    int 21h

    pop cx                  ;restauram contorul principal
    loop Repeta_Octet_Final ;trecem la urmatorul octet din sir
    jmp Final_Program

;restabilim nr de octeti
	mov ax, temp
	mov contor_octeti, ax

;chemam procedura pt rotire
    call rotire_sir

	;afisam in binar
    mov ah, 09h
    mov dx, offset mesaj_binar
    int 21h

    mov si, offset sir
    mov cx, contor_octeti
binar_loop:
    lodsb
    call afisare_binar
    loop binar_loop

    call wait_key

	;afisam in hexa
    mov ah, 09h
    mov dx, offset mesaj_hex
    int 21h

    mov si, offset sir
    mov cx, contor_octeti
hex_loop:
    lodsb
    call afisare_hexa
    loop hex_loop

    call wait_key

MesajEroare:
    mov ah, 09h
    mov dx, offset eroare
    int 21h

Final_Program:
    mov ax, 4C00h
    int 21h
code ends
end start
