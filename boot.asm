; boot.asm
bits 16
org 0x7C00

KERNEL_OFFSET equ 0x1000   ; Адрес, по которому мы загрузим ядро

start:
    mov [BOOT_DRIVE], dl   ; Сохраняем номер загрузочного диска

    mov bp, 0x9000         ; Устанавливаем стек
    mov sp, bp

    mov bx, MSG_REAL_MODE
    call print_string

    call load_kernel       ; Загружаем ядро

    call switch_to_pm      ; Переключаемся в защищенный режим

    jmp $                  ; Сюда не должны попасть

%include "boot/print_string.asm"
%include "boot/disk_load.asm"
%include "boot/gdt.asm"
%include "boot/print_string_pm.asm"
%include "boot/switch_to_pm.asm"

bits 16
load_kernel:
    mov bx, MSG_LOAD_KERNEL
    call print_string

    mov bx, KERNEL_OFFSET   ; Адрес для загрузки ядра
    mov dh, 15              ; Количество секторов для загрузки (ядра)
    mov dl, [BOOT_DRIVE]    ; Диск
    call disk_load

    ret

bits 32
BEGIN_PM:
    mov ebx, MSG_PROT_MODE
    call print_string_pm

    call KERNEL_OFFSET      ; Передаем управление ядру

    jmp $                   ; Если ядро вернет управление (не должно)

; Данные
BOOT_DRIVE db 0
MSG_REAL_MODE db "Started in 16-bit Real Mode", 0
MSG_PROT_MODE db "Successfully landed in 32-bit Protected Mode", 0
MSG_LOAD_KERNEL db "Loading kernel into memory", 0

; Заполнение до 512 байт и сигнатура загрузочного сектора
times 510-($-$$) db 0
dw 0xAA55