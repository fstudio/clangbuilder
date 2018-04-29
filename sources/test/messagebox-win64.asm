MB_DEFBUTTON1 EQU 0                             ; Constants
MB_DEFBUTTON2 EQU 100h
IDNO          EQU 7
MB_YESNO      EQU 4

extern MessageBoxA                              ; Import external symbols
extern ExitProcess                              ; Windows API functions, not decorated

global _main                                    ; Export symbols. The entry point

section .data                                   ; Initialized data segment
 MessageBoxText    db "Do you want to exit?", 0
 MessageBoxCaption db "MessageBox 64", 0

section .text                                   ; Code segment
_main:
 and   RSP, 0FFFFFFFFFFFFFFF0h                  ; Align the stack to a multiple of 16 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space

.DisplayMessageBox:
 xor   RCX, RCX                                 ; 1st parameter
 lea   RDX, [REL MessageBoxText]                ; 2nd parameter
 lea   R8, [REL MessageBoxCaption]              ; 3rd parameter
 mov   R9, MB_YESNO | MB_DEFBUTTON2             ; 4th parameter. 2 constants ORed together
 call  MessageBoxA

 cmp   RAX, IDNO                                ; Check the return value for "No"
 je    .DisplayMessageBox

 add   RSP, 32                                  ; Remove the 32 bytes

 xor   RCX, RCX
 call  ExitProcess