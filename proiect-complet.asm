assume cs:code, ds:data

data segment
    mesaj db 'Introduceti intre 8-16 octeti in hex (ex: 3F 7A 12 5C etc.):', 10, 13, '$'
    eroare db 10, 13, 'Eroare: Trebuie sa introduceti intre 8 si 16 octeti!', 10, 13, '$'
    numere db 50, ?, 50 dup(?) 
    sir db 20 dup(?) 
    linie_noua db 10, 13, '$'
    contor_octeti dw 0 

    C dw (?)
    mesaj_afisare db 10, 13, "Valoarea lui C este: $"

    msg_sortat    db 10, 13, 'Sirul sortat (descrescator): $'
    msg_pozitie   db 10, 13, 'Pozitia octetului cu cei mai multi biti de 1 (>3): $'
    msg_nu_exista db 10, 13, 'Nu exista octeti cu mai mult de 3 biti de 1.$'
    max_bits      db 0        
    pozitie_max   db 0        
data ends

code segment


ascii_binar proc
    cmp al, '9'       
    jbe cifra        
    cmp al, 'a'       
    jb litera         
    sub al, 'a'-'A'   
litera:      
    sub al, 7         
cifra:
    sub al, '0'       
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
    mov es, ax    

    ; conversie
    mov ah, 09h
    mov dx, offset mesaj
    int 21h

    mov ah, 0Ah
    lea dx, numere
    int 21h

    mov si, offset numere+2 
    mov di, offset sir      
    mov cl, [numere+1]      
    mov ch, 0               
    cld                     
    jcxz Final_Program      

conversie:
    lodsb                   
    cmp al, ' '             
    je skip_loop            

    call ascii_binar        
    shl al, 4               
    mov bl, al              
    
    lodsb                   
    dec cx                  
    call ascii_binar        
    or al, bl               

    stosb                   
    inc contor_octeti       
skip_loop:
    loop conversie

verificare:
    cmp contor_octeti, 8
    jb MesajEroare
    cmp contor_octeti, 16
    ja MesajEroare


    mov si, offset sir      ; parcurgem sirul original
    mov bx, 0               ; in bx calculam C

    ;bitii 0-3
    lodsb                   ; incarcam primul octet
    and al, 11110000b       ; pastram primii 4 biti
    mov cl, [sir+contor_octeti-1] ; ultimul octet
    and cl, 00001111b       ; ultimii 4 biti
    mov dl, 4
    rol al, dl              ; mutam bitii pe pozitia corecta
    xor al, cl
    mov ah,0
    or bx, ax               

    ;bitii 4-7
    mov si, offset sir
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
    shl dl,2
    or bx, dx
    mov C, bx

    ;bitii 8-15
    mov si, offset sir
    mov cx, contor_octeti
    mov dl,0
    jcxz Final_Program
repeta8_15:
    lodsb
    add dl,al
    loop repeta8_15
    
    mov dh, dl
    mov dl,0
    or bx, dx
    mov C, bx

    mov ah, 09h
    mov dx, offset mesaj_afisare
    int 21h

    mov ax, C
    call afisare_hex

    ; bubble sort descrescator
    
    mov cx, contor_octeti   
    dec cx                  
    cmp cx, 0               
    jle Gata_Sortare        

Repeta_Sortare:
    mov bx, cx              
    mov si, offset sir      
    mov di, contor_octeti   
    dec di                  
    mov si, 0               

Verifica_perechi:
    mov al, sir[si]         
    mov ah, sir[si+1]       
    
    cmp al, ah              
    jae NoSwap              
    
    ;interschimbare
    mov sir[si], ah         
    mov sir[si+1], al       

NoSwap:
    inc si                  
    dec di                  
    jnz Verifica_perechi    

    mov cx, bx              
    loop Repeta_Sortare     

Gata_Sortare:
    mov ah, 09h
    mov dx, offset msg_sortat
    int 21h

    ; analiza bitilor
    mov cx, contor_octeti   
    mov si, 0               
    mov max_bits, 0         
    mov pozitie_max, 255    

Loop_Analiza:
    mov al, sir[si]         
    mov bl, 0               
    push cx                 
    
    mov cx, 8               
CountBits:
    shl al, 1               
    adc bl, 0               
    loop CountBits          
    
    pop cx                  

    cmp bl, 3
    jbe NextByte            

    cmp bl, max_bits
    jbe NextByte            

    mov max_bits, bl        
    mov ax, si              
    inc ax                  
    mov pozitie_max, al     

NextByte:
    inc si                  
    loop Loop_Analiza       

    ; afisare pozitie
    cmp pozitie_max, 255    
    je Nu_Gasit             

    mov ah, 09h
    mov dx, offset msg_pozitie
    int 21h

    mov al, pozitie_max     
    cbw                     
    mov bl, 10              
    div bl                  
    mov bx, ax              

    cmp bl, 0
    je PrintUnits           
    
    mov dl, bl              
    add dl, '0'             
    mov ah, 02h             
    int 21h

PrintUnits:
    mov dl, bh              
    add dl, '0'             
    mov ah, 02h             
    int 21h

    jmp Afisare_Sir_Final   

Nu_Gasit:
    mov ah, 09h
    mov dx, offset msg_nu_exista
    int 21h

    ; afisare sir sortat
Afisare_Sir_Final:
    mov ah, 09h
    mov dx, offset linie_noua
    int 21h

    mov si, offset sir      
    mov cx, contor_octeti 
    jcxz Final_Program

Repeta_Octet_Final:         
    push cx                 
    lodsb                   
    
    mov cx, 8               
Repeta_Bit_Final:           
    shl al, 1               
    jc Unu_Final            
    mov dl, '0'             
    jmp Afisare_Bit_Final
Unu_Final:
    mov dl, '1'             

Afisare_Bit_Final:
    push ax                 
    mov ah, 02h             
    int 21h
    pop ax                  
    loop Repeta_Bit_Final   

    mov ah, 02h
    mov dl, ' '
    int 21h

    pop cx                  
    loop Repeta_Octet_Final 
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
