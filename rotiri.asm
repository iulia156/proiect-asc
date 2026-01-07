assume cs:code, ds:data

data segment
    ;sir db 83h, 0C4h, 33h test
    contor_octeti dw 3

    mesaj_binar db 10,13,'Sir dupa rotire (binar):',10,13,'$'
    mesaj_hex   db 10,13,'Sir dupa rotire (hex):',10,13,'$'
data ends

code segment

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


afisare_hex proc
    push ax
    push cx

    mov cx, 2 ;afisam 2 cifre in hexa
afis_hex:
    rol al, 4 ;mutam cei 4 biti sup in partea inf
    mov dl, al
    and dl, 0Fh ;ii izolam
    cmp dl, 9
    jbe cifra
    add dl, 7 ;ajustare pentru pozitiile 10-15 A-F
cifra:
    add dl, '0' ;conversie in ascii
    mov ah, 02h
    int 21h
    loop afis_hex

    mov dl, ' '
    int 21h

    pop cx
    pop ax
    ret
afisare_hex endp


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
    call afisare_hex
    loop hex_loop

    call wait_key

    mov ax, 4C00h
    int 21h

code ends
end start
