assume cs:code, ds:data

data segment
    ; --- VARIABILELE COLEGEI (INPUT & STOCARE) ---
    mesaj db 'Introduceti intre 8-16 octeti in hex (ex: 3F 7A 12 5C etc.):', 10, 13, '$'
    eroare db 10, 13, 'Eroare: Trebuie sa introduceti intre 8 si 16 octeti!', 10, 13, '$'
    numere db 50, ?, 50 dup(?) 
    sir db 20 dup(?) 
    linie_noua db 10, 13, '$'
    contor_octeti dw 0   ;variabila word folosita la numararea octetilor convertiti 

    ; --- VARIABILELE TALE (SORTARE & ANALIZA) ---
    msg_sortat    db 10, 13, 'Sirul sortat (descrescator): $'
    msg_pozitie   db 10, 13, 'Pozitia octetului cu cei mai multi biti de 1 (>3): $'
    msg_nu_exista db 10, 13, 'Nu exista octeti cu mai mult de 3 biti de 1.$'
    max_bits      db 0        ;variabila pentru numarul maxim de biti de 1 gasiti
    pozitie_max   db 0        ;variabila pentru a memora pozitia octetului gasit
data ends

code segment

; --- PROCEDURA CONVERSIE (Din codul colegei) ---
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

start: 
    mov ax, data  
    mov ds, ax
    mov es, ax        ;es e necesar pentru instructiunea stosb

    ; --- PARTEA 1: INPUT SI CONVERSIE (COD COLEGA) ---
    
    ;afisare mesaj pentru introducerea valorilor
    mov ah, 09h
    mov dx, offset mesaj
    int 21h

    ;citire valori de la tastatura
    mov ah, 0Ah
    lea dx, numere
    int 21h

    ;initializare registre pentru conversie
    mov si, offset numere+2   ;caracterele introduse
    mov di, offset sir        ;sirul final de valori binare
    mov cl, [numere+1]        ;cl = numarul de caractere citite efectiv
    mov ch, 0                 ;extindem la cx
    cld                       ;directia de parcurgere
    jcxz Final_Program        ;daca nu se citesc elemente sarim la final

conversie:
    lodsb                     ;se incarca primul caracter in al
    cmp al, ' '               ;verificam daca este spatiu
    je skip_loop              ;daca este, sarim peste
    
    call ascii_binar          ;apelam procedura de conversie
    shl al, 4                 ;mutam valoarea pe partea superioara a lui al
    mov bl, al                ;salvam temporar in bl
    
    lodsb                     ;incarcam urmatorul caracter
    dec cx                    ;decrementam manual cx-ul
    call ascii_binar          ;apelam procedura
    or al, bl                 ;combinam cu prima cifra
    
    stosb                     ;salvam elementul in sir
    inc contor_octeti         ;incrementam numarul de octeti salvati

skip_loop:
    loop conversie

    ; --- PARTEA 2: VALIDARE (COD COLEGA) ---
verificare:
    cmp contor_octeti, 8
    jb MesajEroare
    cmp contor_octeti, 16
    ja MesajEroare

    ; --- PARTEA 3: LOGICA TA (SORTARE, ANALIZA, AFISARE) ---

    ; --- SORTARE BUBBLE SORT ---
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

    ; --- ANALIZA BITI (MAXIM > 3) ---
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
    shl al, 1               ;shiftam stanga, cel mai semnificativ bit intra in Carry Flag (CF)
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

    ; --- AFISARE REZULTAT POZITIE ---
    cmp pozitie_max, 255    ;verificam daca pozitie_max a ramas neschimbat
    je Nu_Gasit             ;daca da, inseamna ca nu am gasit niciun octet valid

    ;afisare mesaj pentru pozitie
    mov ah, 09h
    mov dx, offset msg_pozitie
    int 21h

    ;conversie pozitie din hex in zecimal pentru afisare
    mov al, pozitie_max     ;incarcam pozitia gasita
    cbw                     ;convertim byte la word (ah devine 0)
    
    mov bl, 10              ;pregatim impartitorul (baza 10)
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

    ; --- AFISARE SIR SORTAT IN BINAR ---
Afisare_Sir_Final:
    ;adaugam o linie noua
    mov ah, 09h
    mov dx, offset linie_noua
    int 21h

    mov si, offset sir      ;pregatim afisarea sirului (care acum este sortat)
    mov cx, contor_octeti 
    jcxz Final_Program

Repeta_Octet:
    push cx                 ;salvam contorul pe stiva
    lodsb                   ;incarcam octetul curent
    
    mov cx, 8               ;pregatim loop ul pentru cei 8 biti
Repeta_Bit:
    shl al, 1               ;punem bitul in CF
    jc Unu                  ;daca este 1, sarim la eticheta Unu
    mov dl, '0'             ;daca nu, pregatim afisarea lui 0
    jmp Afisare_Bit
Unu:
    mov dl, '1'             ;pregatim afisarea lui 1

Afisare_Bit:
    push ax                 ;salvam al pentru a nu pierde restul bitilor
    mov ah, 02h             ;functia de afisare caracter
    int 21h
    pop ax                  ;restauram al
    loop Repeta_Bit         ;trecem la urmatorul bit

    ;afisam un spatiu intre octeti
    mov ah, 02h
    mov dl, ' '
    int 21h

    pop cx                  ;restauram contorul principal
    loop Repeta_Octet       ;trecem la urmatorul octet din sir
    jmp Final_Program

MesajEroare:
    mov ah, 09h
    mov dx, offset eroare
    int 21h

Final_Program:
    mov ax, 4C00h
    int 21h
code ends
end start