;PRAGYA PRAKASH(2016067)
;TANYA RAJ(2016108)
;Reference:- https://wiki.osdev.org/Setting_Up_Long_Mode
[BITS 16]
org 0x7c00

boot_start:
    int 0x15
    int 0x10
    mov eax, 0                                
    mov cr0, eax       ;enable paging and go into protected mode by setting control register 0
    mov edi, 0x1000    ; Set the destination index to 0x1000.
    mov cr3, edi       ; Set control register 3 to the destination  
    mov DWORD [edi], 0x2003      
    add edi, 0x1000              ; Add 0x1000 to the destination 
    mov DWORD [edi], 0x3003    
    add edi, 0x1000              ; Add 0x1000 to the destination 
    mov DWORD [edi], 0x4003
    mov ebx, 0x00000003          ; Set the B-register to 0x00000003.
    add edi, 0x1000 
 
.Entry_Set:
    mov DWORD [edi], ebx    
    add edi, 8      
    add ebx, 0x1000              ; Add 0x1000 to the B-register.
    loop .Entry_Set              ; Set the next entry.
    mov eax, cr4                 ; Set the A-register to control .
    or eax, 1 << 5               ; Set the PAE-bit, which is the 
    mov cr4, eax                 ; Set control register 4 to the A-
    mov ecx, 0xC0000080          ; Set the C-register to 0xC0000080, 
    rdmsr                        ; Read from the model-specific 
    or eax, 1 << 8               ; Set the LM-bit which is the 9th 
    wrmsr                        ; Write to the model-specific 
    mov eax,0                    ; Set the A-register to control 
    or eax, 1 << 31 | 1 << 0     ; Set the PG-bit, which is the 31nd and going to protected mode
    mov cr0, eax   
    lgdt [gdt.Pointer]
    jmp gdt.Code:boot2

gdt:                           ; Global Descriptor Table (64-bit).
    .Null: equ $ - gdt         ; The null descriptor.
    dw 0xFFFF                    ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 0                         ; Access.
    db 1                         ; Granularity.
    db 0                         ; Base (high).
    .Code: equ $ - gdt         ; The code descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 10011010b                 ; Access (exec/read).
    db 10101111b                 ; Granularity, 64 bits flag, limit19:16.
    db 0                         ; Base (high).
    .Data: equ $ - gdt         ; The data descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 10010010b                 ; Access (read/write).
    db 00000000b                 ; Granularity.
    db 0                         ; Base (high).
    .Pointer:                    ; The GDT-pointer.
    dw $ - gdt - 1             ; Limit.
    dq gdt                     ; Base.



[BITS 64]
boot2:
    mov ax, gdt.Data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov edi, 0xB8000
    mov rcx, 500                      ; Since we are clearing uint64_t over here, we put the count as Count/4.
    mov rax, 0x1F201F201F201F20       ; Set the value to set the screen to: Blue background, white foreground, blank spaces.
    rep stosq                         ; Clear the entire screen. 
    mov ebx,0xb8000
    mov rbx,0xb8000                   ;video buffer initialzation
    mov r14, cr3
    mov r12, 63
    mov esi,print_string
.loop:
    lodsb
    or al,al
    cmp al,0
    je .loop1
    or eax,0x0100
    mov word [rbx], ax
    add rbx,2
    jmp .loop
.loop1:				      ;cr3 printing
    mov r13,r12
    .loop2:
      shr r14,1
      add r13,-1
      cmp r13,0
      jne .loop2
    and r14,1
    cmp r14,0
    je .if_true
        mov r14,0x31
        jmp .end_if
    .if_true:
        mov r14,0x30
    .end_if: 
    or r14, 0x1000
    mov [rbx], r14
    add rbx,2
    sub r12,1
    mov r14,cr3
    cmp r12,0
    jz halt
    jne .loop1


halt:
    cli
    hlt
print_string: db "Hello world!",0

times 510 - ($-$$) db 0
dw 0xaa55


