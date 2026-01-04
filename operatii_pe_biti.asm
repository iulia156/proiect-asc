data segment
	C dw (?)
	mesaj_afisare db "Valoarea lui C este: $"
data ends
code segment
;subrutina pentru afisarea lui C
afisare_hex proc
	mov cx, 4	; 4 cifre hex
afis_hex:
    rol ax, 4; rotim spre stanga ca byte ul cel mai semnificativ sa ajunga in al                  
    mov dl, al
    and dl, 0Fh; folosim masca ca sa ramana daor 4 biti
    cmp dl, 9; comparam cu 9 pt a vedea daca este cifra
    jbe cifra
    add dl, 7; adaugam 7 pentru a putea face conversia(sarim peste cele 7 caractere aflate intre cifre si litere)
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
jcxz Final
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