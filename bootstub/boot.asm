[org 0x7c00]

start:
    cli
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7c00
    sti

    mov bx,0x1000
    mov dh,1
    mov dl,[BOOT_DRIVE]
    mov ah,0x02
    mov al,dh
    mov ch,0
    mov cl,2
    mov dh,0
    int 0x13

    jc load_error

    jmp 0x0000:0x1000

    load_error:
        hlt
        jmp load_error

    BOOT_DRIVE: db 0
    times 510-($-$$)db 0
    dw 0xaa55
