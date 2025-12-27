assume cs:code, ds:data

data segment
mesaj db 'Introduceti intre 8-16 octeti in hex (ex: 3F 7A 12 5C etc.):', 10, 13, '$'
eroare db 10, 13, 'Eroare: Trebuie sa introduceti intre 8 si 16 octeti!', 10, 13, '$'
numere db 50, ?, 50 dup(?) 
sir db 20 dup(?) 
linie_noua db 10, 13, '$'
contor_octeti dw 0   ;variabila word (pentru a o putea muta direct in cx) folosita la numararea octetilor convertiti 
data ends

code segment

;subrutina ce converteste un caracter ascii 
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
or al, bl             ;combinam cu prima cifra

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
mov dl, '0'            ;daca nu pregatim afisarea lui 0
jmp Afisare_Bit

Unu:
mov dl, '1'

Afisare_Bit:
push ax                ;salvam al-ul pentru a afisa si ceilalti biti
mov ah, 02h            ;functia pentru afisarea unui caracter
int 21h
pop ax
loop Repeta_Bit

;afisam un spatiu intre octeti
mov ah, 02h
mov dl, ' '
int 21h

pop cx                 ;restauram cx-ul
loop Repeta_Octet
jmp Final              ;sarim peste eroare

MesajEroare:
mov ah, 09h
mov dx, offset eroare
int 21h

Final:
mov ax, 4C00h
int 21h
code ends
end start