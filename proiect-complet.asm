assume cs:code, ds:data

data segment
mesaj db 'Introduceti intre 8-16 octeti in hex (ex: 3F 7A 12 5C etc.):', 10, 13, '$'
eroare db 10, 13, 'Eroare: Trebuie sa introduceti intre 8 si 16 octeti!', 10, 13, '$'
numere db 50, ?, 50 dup(?) 
sir db 20 dup(?) 
linie_noua db 10, 13, '$'
contor_octeti dw 0   ;variabila word (pentru a o putea muta direct in cx) folosita la numararea octetilor convertiti 

C dw (?)
	mesaj_afisare db "Valoarea lui C este: $"
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
	mov cx, 4	; 4 cifre hex
afis_hex:
	mov dh,4
    rol ax, dh; rotim spre stanga ca urmatorul grup de 4 biți să ajungă în al              
    mov dl, al
    and dl, 0Fh; folosim masca ca sa ramana daor 4 biti
    cmp dl, 9; comparam cu 9 pt a vedea daca este cifra
    jbe cifra
	mov dh, 7
    add dl, dh; adaugam 7 pentru a putea face conversia(sarim peste cele 7 caractere aflate intre cifre si litere)
cifra:
    add dl, '0'; adunam codul ascii al lui zero pentru a converti in cifra
    mov ah, 02h; afisam caracterul obtinut
    int 21h
loop afis_hex
    ret
afisare_hex endp

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
jcxz Final                ;daca nu se citesc elemente sarim direct la final

conversie:
lodsb                 ;se incarca primul caracter in al (ex: '3')
cmp al, ' '           ;verificam daca este spatiu
je skip_loop          ;daca este, sarim la final

call ascii_binar      ;apelam procedura de conversie
shl al, 4             ;mutam valoarea pe partea superioara a lui al
mov bl, al            ;salvam temporar in bl               
                  
lodsb                 ;incarcam umatorul caracter in al
dec cx                ;decrementam manual cx-ul pentru al doilea element procesat in loop
call ascii_binar      ;apelam procedura
or al, bl             ;combinam cu partea superioara

stosb                 ;salvam elementul in sir
inc contor_octeti     ;incrementam numarul de octeti salvati

skip_loop:
loop conversie

;verificarea numarului de octeti si afisarea unui mesaj in cazul unui numar din afara intervalului 8-16
verificare:
cmp contor_octeti, 8
jb MesajEroare
cmp contor_octeti, 16
ja MesajEroare

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
jmp Final              ;sarim peste mesajul de eroare

MesajEroare:
mov ah, 09h
mov dx, offset eroare
int 21h

;calculam cuvantul C

mov si, offset sir; parcurgem sirul de numere dupa conversia lor
mov bx, 0; in bx vom afla cuvantul C final

;bitii 0-3

lodsb
and al, 00001111b; in ax avem primii 4 biti ai primului octet
mov cl, [sir+contor_octeti-1]; cum si a crescut dupa instructiunea lodsb, folosim sir, care se refera la offset ul sirului
and cl, 11110000b; in bx avem ultimii 4 biti ai ultimului octet
shr cl, 4; am mutat bitii lui ax pe locurile corespunzatoare
xor al, cl
mov ah,0
or bx, ax; putem face aceatsa operatie deoarece pe bitii 0-3 din ax sunt bitii ceruti iar pe celelalte pozitii este 0, care nu modfica rezultatul

;bitii 4-7

mov si, offset sir; parcurgem sirul de numere dupa conversia lor
mov cx, contor_octeti
mov dl,0
jcxz Final
repeta4_7:
	lodsb
	and al,00111100b
	or dl, al
loop repeta4_7
mov dh,0
shl dl,2; deplasam la stanga pentru ca rezultatul sa fie pe pozitiile corecte
or bx, dx; punem rezultatul in bx
mov C, bx

;bitii 8-15
mov si, offset sir; parcurgem sirul de numere dupa conversia lor
mov cx, contor_octeti
mov dl,0
jcxz Final
repeta8_15:
	lodsb
	add dl,al;  modulo 256 este automat cand folosim un registru de 8 biți pentru că overflow-ul se taie la 8 biți
loop repeta8_15
mov dh, dl; punem rezultatul in dh pentru a fi pe pozitiile corecte
mov dl,0
or bx, dx

;afisam C

mov C, bx
mov ah, 09h
mov dx, offset mesaj_afisare
int 21h

mov ax, C; ax primeste valoarea ce trebuie afisata
call afisare_hex

Final:
mov ax, 4C00h
int 21h
code ends
end start
