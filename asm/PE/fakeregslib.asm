; loaded DLL corrupting registers as much as possible, during TLS and DllMain

; Ange Albertini, BSD LICENCE 2011

%include 'consts.inc'

IMAGEBASE equ 10000000h
org IMAGEBASE
bits 32

SECTIONALIGN equ 1000h
FILEALIGN equ 200h

istruc IMAGE_DOS_HEADER
    at IMAGE_DOS_HEADER.e_magic, db 'MZ'
    at IMAGE_DOS_HEADER.e_lfanew, dd NT_Signature - IMAGEBASE
iend

NT_Signature:
istruc IMAGE_NT_HEADERS
    at IMAGE_NT_HEADERS.Signature, db 'PE', 0, 0
iend
istruc IMAGE_FILE_HEADER
    at IMAGE_FILE_HEADER.Machine,               dw IMAGE_FILE_MACHINE_I386
    at IMAGE_FILE_HEADER.NumberOfSections,      dw NUMBEROFSECTIONS
    at IMAGE_FILE_HEADER.SizeOfOptionalHeader,  dw SIZEOFOPTIONALHEADER
    at IMAGE_FILE_HEADER.Characteristics,       dw IMAGE_FILE_EXECUTABLE_IMAGE | IMAGE_FILE_32BIT_MACHINE | IMAGE_FILE_DLL
iend

OptionalHeader:
istruc IMAGE_OPTIONAL_HEADER32
    at IMAGE_OPTIONAL_HEADER32.Magic,                     dw IMAGE_NT_OPTIONAL_HDR32_MAGIC
    at IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint,       dd EntryPoint - IMAGEBASE
    at IMAGE_OPTIONAL_HEADER32.ImageBase,                 dd IMAGEBASE
    at IMAGE_OPTIONAL_HEADER32.SectionAlignment,          dd SECTIONALIGN
    at IMAGE_OPTIONAL_HEADER32.FileAlignment,             dd FILEALIGN
    at IMAGE_OPTIONAL_HEADER32.MajorSubsystemVersion,     dw 4
    at IMAGE_OPTIONAL_HEADER32.SizeOfImage,               dd 2 * SECTIONALIGN
    at IMAGE_OPTIONAL_HEADER32.SizeOfHeaders,             dd SIZEOFHEADERS
    at IMAGE_OPTIONAL_HEADER32.Subsystem,                 dw IMAGE_SUBSYSTEM_WINDOWS_CUI
    at IMAGE_OPTIONAL_HEADER32.NumberOfRvaAndSizes,       dd 16
iend

DataDirectory:
istruc IMAGE_DATA_DIRECTORY_16
    at IMAGE_DATA_DIRECTORY_16.ImportsVA,   dd Import_Descriptor - IMAGEBASE
    at IMAGE_DATA_DIRECTORY_16.TLSVA,       dd Image_Tls_Directory32 - IMAGEBASE
iend

SIZEOFOPTIONALHEADER equ $ - OptionalHeader
SectionHeader:
istruc IMAGE_SECTION_HEADER
    at IMAGE_SECTION_HEADER.VirtualSize,      dd 1 * SECTIONALIGN
    at IMAGE_SECTION_HEADER.VirtualAddress,   dd 1 * SECTIONALIGN
    at IMAGE_SECTION_HEADER.SizeOfRawData,    dd 1 * FILEALIGN
    at IMAGE_SECTION_HEADER.PointerToRawData, dd 1 * FILEALIGN
    at IMAGE_SECTION_HEADER.Characteristics,  dd IMAGE_SCN_MEM_EXECUTE + IMAGE_SCN_MEM_WRITE
iend
NUMBEROFSECTIONS equ ($ - SectionHeader) / IMAGE_SECTION_HEADER_size

SIZEOFHEADERS equ $ - IMAGEBASE
section progbits vstart=IMAGEBASE + SECTIONALIGN align=FILEALIGN
Section0Start:

randw:
    mov eax, dword [key]
    imul eax, eax, 0x343FD
    add eax, 0x269EC3
    ror eax,0x10
    mov dword [key], eax
    retn

randreg:
    call randw
    mov esi, eax
    call randw
    mov edi, eax
    call randw
    mov ebx, eax
    call randw
    mov ecx, eax
    call randw
    mov edx, eax
    call randw
    mov ebp, eax
    retn

EntryPoint:
    pop dword [ret_]
    mov dword [saved_reg], esi

    call randreg
    call randw
    mov esp, eax
    xor esp, edx
    mov esi, dword [saved_reg]
    jmp dword [ret_]
    retn
_c

ret_ dd 0
saved_reg dd 0
key dd 0

align 20h db 0

tls:
    mov dword [CallBacks], 0
    pop dword [ret_]
    mov dword [saved_reg], esi
    rdtsc
    mov dword [key], eax

    call randreg
    call randw
    mov esp, eax
    xor esp, edx
    mov esi, dword [saved_reg]
    jmp dword [ret_]

printf:
    jmp [__imp__printf]
_c

Msg dd " * corrupted registers on TLS and Exit return", 0ah, 0

_d

Import_Descriptor:
;msvcrt.dll_DESCRIPTOR:
    dd msvcrt.dll_hintnames - IMAGEBASE
    dd 0, 0
    dd msvcrt.dll - IMAGEBASE
    dd msvcrt.dll_iat - IMAGEBASE
;terminator
    dd 0, 0, 0, 0, 0
_d

msvcrt.dll_hintnames:
    dd hnprintf - IMAGEBASE
    dd 0
_d

hnprintf:
    dw 0
    db 'printf', 0
_d

msvcrt.dll_iat:
__imp__printf:
    dd hnprintf - IMAGEBASE
    dd 0
_d

msvcrt.dll db 'msvcrt.dll', 0
_d

Image_Tls_Directory32:
    StartAddressOfRawData dd 0
    EndAddressOfRawData   dd 0
    AddressOfIndex        dd some_value
    AddressOfCallBacks    dd CallBacks
    SizeOfZeroFill        dd 0
    Characteristics       dd 0
_d

some_value dd 012345h

CallBacks:
    dd tls
    dd 0
_d

align FILEALIGN, db 0

Section0Size EQU $ - Section0Start

SIZEOFIMAGE EQU $ - IMAGEBASE
