                                                ; Basic Window Extended, 64 bit. V1.03
ANSI_CHARSET         EQU 0                      ; Constants
BLACKNESS            EQU 42h
CLIP_DEFAULT_PRECIS  EQU 0
CS_BYTEALIGNWINDOW   EQU 2000h
CS_HREDRAW           EQU 2
CS_VREDRAW           EQU 1
DEFAULT_PITCH        EQU 0
ES_AUTOHSCROLL       EQU 80h
ES_CENTER            EQU 1
FALSE                EQU 0
GRAY_BRUSH           EQU 2
IDC_ARROW            EQU 7F00h
IDI_APPLICATION      EQU 7F00h
IDNO                 EQU 7
IMAGE_CURSOR         EQU 2
IMAGE_ICON           EQU 1
LR_SHARED            EQU 8000h
MB_DEFBUTTON2        EQU 100h
MB_YESNO             EQU 4
NULL                 EQU 0
NULL_BRUSH           EQU 5
OPAQUE               EQU 2
PROOF_QUALITY        EQU 2
SM_CXFULLSCREEN      EQU 10h
SM_CYFULLSCREEN      EQU 11h
SS_CENTER            EQU 1
SS_NOTIFY            EQU 100h
SW_SHOWNORMAL        EQU 1
TRUE                 EQU 1
WM_CLOSE             EQU 10h
WM_COMMAND           EQU 111h
WM_CREATE            EQU 1
WM_CTLCOLOREDIT      EQU 133h
WM_CTLCOLORSTATIC    EQU 138h
WM_DESTROY           EQU 2
WM_PAINT             EQU 0Fh
WM_SETFONT           EQU 30h
OUT_DEFAULT_PRECIS   EQU 0
WS_CHILD             EQU 40000000h
WS_EX_COMPOSITED     EQU 2000000h
WS_OVERLAPPEDWINDOW  EQU 0CF0000h
WS_TABSTOP           EQU 10000h
WS_VISIBLE           EQU 10000000h

WindowWidth          EQU 640
WindowHeight         EQU 170
Static1ID            EQU 100
Static2ID            EQU 101
Edit1ID              EQU 102
Edit2ID              EQU 103

extern AdjustWindowRectEx                       ; Import external symbols
extern BeginPaint                               ; Windows API functions, not decorated
extern BitBlt
extern CreateFontA
extern CreateSolidBrush
extern CreateWindowExA
extern DefWindowProcA
extern DeleteObject
extern DestroyWindow
extern DispatchMessageA
extern EndPaint
extern ExitProcess
extern GetDlgCtrlID
extern GetStockObject
extern GetMessageA
extern GetModuleHandleA
extern GetSystemMetrics
extern InvalidateRect
extern IsDialogMessageA
extern LoadImageA
extern MessageBoxA
extern PostQuitMessage
extern RegisterClassExA
extern SendMessageA
extern SetBkColor
extern SetBkMode
extern SetTextColor
extern ShowWindow
extern TranslateMessage
extern UpdateWindow

global Start                                    ; Export symbols. The entry point

section .data                                   ; Initialized data segment
 Static1Colour    dd 0F0F0F0h                   ; Colour (0BBGGRRh)
 Static1ColourA   dd 020A0F0h
 Static2Colour    dd 000FFFFh
 Static2ColourA   dd 08000FFh
 Edit1TextColour  dd 0F590F5h
 Edit1BackColour  dd 0A00000h
 Edit2TextColour  dd 0A56E3Bh
 Edit2BackColour  dd 0FEFE8Eh
 BackgroundColour dd 0A56E3Bh   
 WindowName       db "Basic Window Extended 64", 0
 ClassName        db "Window", 0
 SegoeUI          db "Segoe UI", 0
 StaticClass      db "STATIC", 0
 EditClass        db "EDIT", 0
 Text1            db "ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789", 0
 Text2            db "abcdefghijklmnopqrstuvwxyz_0123456789", 0
 ExitText         db "Do you want to exit?", 0

section .bss                                    ; Uninitialized data segment
 alignb 8
 hInstance        resq 1
 BackgroundBrush  resq 1
 Font             resq 1
 Static1          resq 1
 Static2          resq 1
 Edit1            resq 1
 Edit2            resq 1

section .text                                   ; Code segment
Start:
 and   RSP, 0FFFFFFFFFFFFFFF0h                  ; Align stack pointer to 16 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 xor   RCX, RCX
 call  GetModuleHandleA
 mov   qword [REL hInstance], RAX
 add   RSP, 32                                  ; Remove the 32 bytes

 call  WinMain

.Exit:
 xor   RCX, RCX
 call  ExitProcess

WinMain:
 push  RBP                                      ; Set up a stack frame
 mov   RBP, RSP
 sub   RSP, 160 + 32 + 64                       ; 160 bytes for local variables +
                                                ; 32 shadow space + 8 parameters, keep
                                                ; to a multiple of 16 for API functions

%define Screen.Width       RBP - 160            ; 4 bytes
%define Screen.Height      RBP - 156            ; 4 bytes

%define ClientArea         RBP - 152            ; RECT structure. 16 bytes
%define ClientArea.left    RBP - 152            ; 4 bytes. Start on a 4 byte boundary
%define ClientArea.top     RBP - 148            ; 4 bytes
%define ClientArea.right   RBP - 144            ; 4 bytes
%define ClientArea.bottom  RBP - 140            ; 4 bytes. End on a 4 byte boundary

%define wc                 RBP - 136            ; WNDCLASSEX structure, 80 bytes
%define wc.cbSize          RBP - 136            ; 4 bytes. Start on an 8 byte boundary
%define wc.style           RBP - 132            ; 4 bytes
%define wc.lpfnWndProc     RBP - 128            ; 8 bytes
%define wc.cbClsExtra      RBP - 120            ; 4 bytes
%define wc.cbWndExtra      RBP - 116            ; 4 bytes
%define wc.hInstance       RBP - 112            ; 8 bytes
%define wc.hIcon           RBP - 104            ; 8 bytes
%define wc.hCursor         RBP - 96             ; 8 bytes
%define wc.hbrBackground   RBP - 88             ; 8 bytes
%define wc.lpszMenuName    RBP - 80             ; 8 bytes
%define wc.lpszClassName   RBP - 72             ; 8 bytes
%define wc.hIconSm         RBP - 64             ; 8 bytes. End on an 8 byte boundary

%define msg                RBP - 56             ; MSG structure, 48 bytes
%define msg.hwnd           RBP - 56             ; 8 bytes. Start on an 8 byte boundary
%define msg.message        RBP - 48             ; 4 bytes
%define msg.Padding1       RBP - 44             ; 4 bytes. Natural alignment padding
%define msg.wParam         RBP - 40             ; 8 bytes
%define msg.lParam         RBP - 32             ; 8 bytes
%define msg.time           RBP - 24             ; 4 bytes
%define msg.py.x           RBP - 20             ; 4 bytes
%define msg.pt.y           RBP - 16             ; 4 bytes
%define msg.Padding2       RBP - 12             ; 4 bytes. Structure length padding

%define hWnd               RBP - 8              ; 8 bytes

 mov   ECX, dword [REL BackgroundColour]
 call  CreateSolidBrush                         ; Create a brush for the window backgound
 mov   qword [REL BackgroundBrush], RAX

 mov   dword [wc.cbSize], 80                    ; [RBP - 136]
 mov   dword [wc.style], CS_HREDRAW | CS_VREDRAW | CS_BYTEALIGNWINDOW  ; [RBP - 132]
 mov   RAX, WndProc
 mov   qword [wc.lpfnWndProc], RAX              ; [RBP - 128]
 mov   dword [wc.cbClsExtra], NULL              ; [RBP - 120]
 mov   dword [wc.cbWndExtra], NULL              ; [RBP - 116]
 mov   RAX, qword [REL hInstance]
 mov   qword [wc.hInstance], RAX                ; [RBP - 112]

 xor   RCX, RCX
 mov   RDX, IDI_APPLICATION
 mov   R8, IMAGE_ICON
 xor   R9, R9
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Large program icon
 mov   qword [wc.hIcon], RAX                    ; [RBP - 104]

 xor   RCX, RCX
 mov   RDX, IDC_ARROW
 mov   R8, IMAGE_CURSOR
 xor   R9, R9
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Cursor
 mov   qword [wc.hCursor], RAX                  ; [RBP - 96]

 mov   RAX, qword [REL BackgroundBrush]
 mov   qword [wc.hbrBackground], RAX            ; [RBP - 88]
 mov   qword [wc.lpszMenuName], NULL            ; [RBP - 80]
 lea   RAX, [REL ClassName]
 mov   qword [wc.lpszClassName], RAX            ; [RBP - 72]

 xor   RCX, RCX
 mov   RDX, IDI_APPLICATION
 mov   R8, IMAGE_ICON
 xor   R9, R9
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Small program icon
 mov   qword [wc.hIconSm], RAX                  ; [RBP - 64]

 lea   RCX, [wc]                                ; [RBP - 136]
 call  RegisterClassExA

 mov   RCX, SM_CXFULLSCREEN
 call  GetSystemMetrics                         ; Get the current screen width
 mov   dword [Screen.Width], EAX                ; [RBP - 160]

 mov   RCX, SM_CYFULLSCREEN
 call  GetSystemMetrics                         ; Get the current screen height
 mov   dword [Screen.Height], EAX               ; [RBP - 156]

 mov   dword [ClientArea.left], 0               ; [RBP - 152]
 mov   dword [ClientArea.top], 0                ; [RBP - 148]
 mov   dword [ClientArea.right], WindowWidth    ; [RBP - 144]
 mov   dword [ClientArea.bottom], WindowHeight  ; [RBP - 140]

 lea   RCX, [ClientArea]                        ; [RBP - 152]
 mov   RDX, WS_OVERLAPPEDWINDOW                 ; Style
 xor   R8, R8
 mov   R9, WS_EX_COMPOSITED                     ; Extended style
 call  AdjustWindowRectEx                       ; Get window size for the desired client size
                                                ; Size is returned in ClientArea
 mov   EAX, dword [ClientArea.bottom]           ; [RBP - 140]
 sub   EAX, dword [ClientArea.top]              ; Height = ClientArea.bottom - ClientArea.top
 mov   dword [ClientArea.bottom], EAX           ; Save the corrected height

 mov   EAX, dword [ClientArea.right]            ; [RBP - 144]
 sub   EAX, dword [ClientArea.left]             ; Width = ClientArea.right - ClientArea.left
 mov   dword [ClientArea.right], EAX            ; Save the corrected width

 mov   RCX, WS_EX_COMPOSITED
 lea   RDX, [REL ClassName]
 lea   R8, [REL WindowName]
 mov   R9, WS_OVERLAPPEDWINDOW

 xor   ECX, ECX
 mov   EAX, dword [Screen.Width]                ; [RBP - 160]
 sub   EAX, dword [ClientArea.right]            ; Corrected window width. [RBP - 144]
 cmovs EAX, ECX                                 ; Clamp to 0 (left) if negative
 shr   EAX, 1                                   ; EAX = (Screen.Width - window height) / 2
 mov   dword [RSP + 4 * 8], EAX                 ; X position, now centred

 mov   EAX, dword [Screen.Height]               ; [RBP - 156]
 sub   EAX, dword [ClientArea.bottom]           ; Corrected window height. [RBP - 140]
 cmovs EAX, ECX                                 ; Clamp to 0 (top) if negative
 shr   EAX, 1                                   ; EAX = (Screen.Height - window height) / 2
 mov   dword [RSP + 5 * 8], EAX                 ; Y position, now centred

 mov   EAX, dword [ClientArea.right]            ; [RBP - 144]
 mov   dword [RSP + 6 * 8], EAX                 ; Width

 mov   EAX, dword [ClientArea.bottom]           ; [RBP - 140]
 mov   dword [RSP + 7 * 8], EAX                 ; Height

 mov   qword [RSP + 8 * 8], NULL
 mov   qword [RSP + 9 * 8], NULL
 mov   RAX, qword [REL hInstance]
 mov   qword [RSP + 10 * 8], RAX
 mov   qword [RSP + 11 * 8], NULL
 call  CreateWindowExA
 mov   qword [hWnd], RAX                        ; [RBP - 8]

 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 mov   RDX, SW_SHOWNORMAL
 call  ShowWindow

 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 call  UpdateWindow

.MessageLoop:
 lea   RCX, [msg]                               ; [RBP - 56]
 xor   RDX, RDX
 xor   R8, R8
 xor   R9, R9
 call  GetMessageA
 cmp   RAX, 0
 je    .Done

 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 lea   RDX, [msg]                               ; [RBP - 56]
 call  IsDialogMessageA                         ; For keyboard strokes
 cmp   RAX, 0
 jne   .MessageLoop                             ; Skip TranslateMessage and DispatchMessageA

 lea   RCX, [msg]                               ; [RBP - 56]
 call  TranslateMessage

 lea   RCX, [msg]                               ; [RBP - 56]
 call  DispatchMessageA
 jmp   .MessageLoop

.Done:
 xor   RAX, RAX
 mov   RSP, RBP                                 ; Remove the stack frame
 pop   RBP
 ret

WndProc:
 push  RBP                                      ; Set up a stack frame
 mov   RBP, RSP

 sub   RSP, 80 + 32 + 80                        ; 80 bytes for local variables + 32
                                                ; shadow space + 10 (8 byte) parameters. Kept
                                                ; to a multiple of 16 for API functions

%define hWnd                RBP + 16            ; Location of the shadow space setup by
%define uMsg                RBP + 24            ; the calling function
%define wParam              RBP + 32
%define lParam              RBP + 40

%define ps                  RBP - 80            ; PAINTSTRUCT structure. 72 bytes
%define ps.hdc              RBP - 80            ; 8 bytes. Start on an 8 byte boundary
%define ps.fErase           RBP - 72            ; 4 bytes
%define ps.rcPaint.left     RBP - 68            ; 4 bytes
%define ps.rcPaint.top      RBP - 64            ; 4 bytes
%define ps.rcPaint.right    RBP - 60            ; 4 bytes
%define ps.rcPaint.bottom   RBP - 56            ; 4 bytes
%define ps.Restore          RBP - 52            ; 4 bytes
%define ps.fIncUpdate       RBP - 48            ; 4 bytes
%define ps.rgbReserved      RBP - 44            ; 32 bytes
%define ps.Padding          RBP - 12            ; 4 bytes. Structure length padding

%define hdc                 RBP - 8             ; 8 bytes

 mov   qword [hWnd], RCX                        ; Free up RCX RDX R8 R9 by spilling the
 mov   qword [uMsg], RDX                        ; 4 passed parameters to the shadow space
 mov   qword [wParam], R8                       ; We can now access these parameters by name
 mov   qword [lParam], R9

 cmp   qword [uMsg], WM_CLOSE                   ; [RBP + 24]
 je    WMCLOSE

 cmp   qword [uMsg], WM_COMMAND                 ; [RBP + 24]
 je    WMCOMMAND

 cmp   qword [uMsg], WM_CREATE                  ; [RBP + 24]
 je    WMCREATE

 cmp   qword [uMsg], WM_CTLCOLOREDIT            ; [RBP + 24]
 je    WMCTLCOLOREDIT

 cmp   qword [uMsg], WM_CTLCOLORSTATIC          ; [RBP + 24]
 je    WMCTLCOLORSTATIC

 cmp   qword [uMsg], WM_DESTROY                 ; [RBP + 24]
 je    WMDESTROY

 cmp   qword [uMsg], WM_PAINT                   ; [RBP + 24]
 je    WMPAINT

DefaultMessage:
 mov   RCX, qword [hWnd]                        ; [RBP + 16]
 mov   RDX, qword [uMsg]                        ; [RBP + 24]
 mov   R8, qword [wParam]                       ; [RBP + 32]
 mov   R9, qword [lParam]                       ; [RBP + 40]
 call  DefWindowProcA
 jmp   Return

WMCLOSE:
 mov   RCX, qword [hWnd]                        ; [RBP + 16]
 lea   RDX, [REL ExitText]
 lea   R8, [REL WindowName]
 mov   R9, MB_YESNO | MB_DEFBUTTON2
 call  MessageBoxA

 cmp   RAX, IDNO
 je    Return.WM_Processed

 mov   RCX, qword [hWnd]                        ; [RBP + 16]
 call  DestroyWindow                            ; Send a WM_DESTROY message
 jmp   Return.WM_Processed

WMCOMMAND:
 mov   RAX, qword [wParam]                      ; [RBP + 32]
 and   RAX, 0FFFFh                              ; RAX = ID

 cmp   RAX, Static1ID
 je    .Static1

 cmp   RAX, Static2ID
 je    .Static2

 jmp   Return.WM_Processed

.Static1:
 mov   EAX, dword [REL Static1Colour]
 mov   ECX, dword [REL Static1ColourA]
 mov   dword [REL Static1Colour], ECX
 mov   dword [REL Static1ColourA], EAX          ; Swap colours

 mov   RCX, qword [lParam]                      ; Static1 handle. [RBP + 40]
 mov   RDX, NULL
 mov   R8, TRUE
 call  InvalidateRect                           ; Redraw control
 jmp   Return.WM_Processed

.Static2:
 mov   EAX, dword [REL Static2Colour]
 mov   ECX, dword [REL Static2ColourA]
 mov   dword [REL Static2Colour], ECX
 mov   dword [REL Static2ColourA], EAX          ; Swap colours

 mov   RCX, qword [lParam]                      ; Static2 handle. [RBP + 40]
 mov   RDX, NULL
 mov   R8, TRUE
 call  InvalidateRect                           ; Redraw control
 jmp   Return.WM_Processed

WMCREATE:
 xor   RCX, RCX
 lea   RDX, [REL StaticClass]
 lea   R8, [REL Text1]                          ; Default text
 mov   R9, WS_CHILD | WS_VISIBLE | SS_NOTIFY | SS_CENTER
 mov   qword [RSP + 4 * 8], 120                 ; X
 mov   qword [RSP + 5 * 8], 10                  ; Y
 mov   qword [RSP + 6 * 8], 400                 ; Width
 mov   qword [RSP + 7 * 8], 20                  ; Height
 mov   RAX, qword [hWnd]                        ; [RBP + 16]
 mov   qword [RSP + 8 * 8], RAX 
 mov   qword [RSP + 9 * 8], Static1ID 
 mov   RAX, qword [REL hInstance] 
 mov   qword [RSP + 10 * 8], RAX
 mov   qword [RSP + 11 * 8], NULL
 call  CreateWindowExA
 mov   qword [REL Static1], RAX

 xor   RCX, RCX
 lea   RDX, [REL StaticClass]
 lea   R8, [REL Text2]                          ; Default text
 mov   R9, WS_CHILD | WS_VISIBLE | SS_NOTIFY | SS_CENTER
 mov   qword [RSP + 4 * 8], 120                 ; X
 mov   qword [RSP + 5 * 8], 40                  ; Y
 mov   qword [RSP + 6 * 8], 400                 ; Width
 mov   qword [RSP + 7 * 8], 20                  ; Height
 mov   RAX, qword [hWnd]                        ; [RBP + 16]
 mov   qword [RSP + 8 * 8], RAX 
 mov   qword [RSP + 9 * 8], Static2ID 
 mov   RAX, qword [REL hInstance] 
 mov   qword [RSP + 10 * 8], RAX
 mov   qword [RSP + 11 * 8], NULL
 call  CreateWindowExA
 mov   qword [REL Static2], RAX

 xor   RCX, RCX
 lea   RDX, [REL EditClass]
 lea   R8, [REL Text1]                          ; Default text
 mov   R9, WS_CHILD | WS_VISIBLE | ES_CENTER | WS_TABSTOP | ES_AUTOHSCROLL
 mov   qword [RSP + 4 * 8], 120                 ; X
 mov   qword [RSP + 5 * 8], 70                  ; Y
 mov   qword [RSP + 6 * 8], 400                 ; Width
 mov   qword [RSP + 7 * 8], 20                  ; Height
 mov   RAX, qword [hWnd]                        ; [RBP + 16]
 mov   qword [RSP + 8 * 8], RAX 
 mov   qword [RSP + 9 * 8], Edit1ID 
 mov   RAX, qword [REL hInstance] 
 mov   qword [RSP + 10 * 8], RAX
 mov   qword [RSP + 11 * 8], NULL
 call  CreateWindowExA
 mov   qword [REL Edit1], RAX

 xor   RCX, RCX
 lea   RDX, [REL EditClass]
 lea   R8, [REL Text2]                          ; Default text
 mov   R9, WS_CHILD | WS_VISIBLE | ES_CENTER | WS_TABSTOP | ES_AUTOHSCROLL
 mov   qword [RSP + 4 * 8], 120                 ; X
 mov   qword [RSP + 5 * 8], 100                 ; Y
 mov   qword [RSP + 6 * 8], 400                 ; Width
 mov   qword [RSP + 7 * 8], 20                  ; Height
 mov   RAX, qword [hWnd]                        ; [RBP + 16]
 mov   qword [RSP + 8 * 8], RAX 
 mov   qword [RSP + 9 * 8], Edit2ID 
 mov   RAX, qword [REL hInstance] 
 mov   qword [RSP + 10 * 8], RAX
 mov   qword [RSP + 11 * 8], NULL
 call  CreateWindowExA
 mov   qword [REL Edit2], RAX

 mov   RCX, 20                                  ; Size
 mov   RDX, NULL
 mov   R8, NULL 
 mov   R9, NULL
 mov   qword [RSP + 4 * 8], 400                 ; Weight
 mov   qword [RSP + 5 * 8], NULL
 mov   qword [RSP + 6 * 8], NULL
 mov   qword [RSP + 7 * 8], NULL
 mov   qword [RSP + 8 * 8], ANSI_CHARSET
 mov   qword [RSP + 9 * 8], OUT_DEFAULT_PRECIS
 mov   qword [RSP + 10 * 8], CLIP_DEFAULT_PRECIS
 mov   qword [RSP + 11 * 8], PROOF_QUALITY
 mov   qword [RSP + 12 * 8], DEFAULT_PITCH
 lea   RAX, [REL SegoeUI]
 mov   qword [RSP + 13 * 8], RAX
 call  CreateFontA
 mov   qword [REL Font], RAX

 mov   RCX, qword [REL Static1]
 mov   RDX, WM_SETFONT
 mov   R8, qword [REL Font]
 mov   R9, FALSE
 call  SendMessageA                             ; Set Static1 font

 mov   RCX, qword [REL Static2]
 mov   RDX, WM_SETFONT
 mov   R8, qword [REL Font]
 mov   R9, FALSE
 call  SendMessageA                             ; Set Static2 font

 mov   RCX, qword [REL Edit1]
 mov   RDX, WM_SETFONT
 mov   R8, qword [REL Font]
 mov   R9, FALSE
 call  SendMessageA                             ; Set Edit1 font

 mov   RCX, qword [REL Edit2]
 mov   RDX, WM_SETFONT
 mov   R8, qword [REL Font]
 mov   R9, FALSE
 call  SendMessageA                             ; Set Edit2 font
 jmp   Return.WM_Processed

WMCTLCOLOREDIT:                                 ; For colouring edit controls
 mov   RCX, qword [lParam]                      ; [RBP + 40]
 call  GetDlgCtrlID                             ; RAX = ID

 cmp   RAX, Edit1ID
 je    .Edit1

 cmp   RAX, Edit2ID
 je    .Edit2

.Default:
 mov   RCX, NULL_BRUSH
 call  GetStockObject                           ; Return a brush
 jmp   Return

.Edit1:
 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   EDX, dword [REL Edit1TextColour]
 call  SetTextColor

 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   RDX, OPAQUE
 call  SetBkMode

 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   EDX, dword [REL Edit1BackColour]
 call  SetBkColor

 mov   RCX, NULL_BRUSH
 call  GetStockObject                           ; Return a brush
 jmp   Return

.Edit2:
 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   EDX, dword [REL Edit2TextColour]
 call  SetTextColor

 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   RDX, OPAQUE
 call  SetBkMode

 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   EDX, dword [REL Edit2BackColour]
 call  SetBkColor

 mov   RCX, NULL_BRUSH
 call  GetStockObject                           ; Return a brush
 jmp   Return

WMCTLCOLORSTATIC:                               ; For colouring static controls
 mov   RCX, qword [lParam]                      ; [RBP + 40]
 call  GetDlgCtrlID                             ; RAX = ID

 cmp   RAX, Static1ID
 je    .Static1

 cmp   RAX, Static2ID
 je    .Static2

.Default:
 mov   RCX, NULL_BRUSH
 call  GetStockObject                           ; Return a brush
 jmp   Return

.Static1:
 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   EDX, dword [REL Static1Colour]
 call  SetTextColor

 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   RDX, OPAQUE
 call  SetBkMode

 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   RDX, 0604060h
 call  SetBkColor

 mov   RCX, NULL_BRUSH
 call  GetStockObject                           ; Return a brush
 jmp   Return

.Static2:
 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   EDX, dword [REL Static2Colour]
 call  SetTextColor

 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   RDX, OPAQUE
 call  SetBkMode

 mov   RCX, qword [wParam]                      ; [RBP + 32]
 mov   RDX, 0005000h
 call  SetBkColor

 mov   RCX, GRAY_BRUSH
 call  GetStockObject                           ; Return a brush
 jmp   Return

WMDESTROY:
 mov   RCX, qword [REL BackgroundBrush]
 call  DeleteObject

 mov   RCX, qword [REL Font]
 call  DeleteObject

 xor   RCX, RCX
 call  PostQuitMessage
 jmp   Return.WM_Processed

WMPAINT:
 mov   RCX, qword [hWnd]                        ; [RBP + 16]
 lea   RDX, [ps]                                ; [RBP - 80]
 call  BeginPaint
 mov   qword [hdc], RAX                         ; [RBP - 8]

 mov   RCX, qword [hdc]                         ; Destination device context. [RBP - 8]
 mov   RDX, 120                                 ; Destination X
 mov   R8, 130                                  ; Destination Y
 mov   R9, 400                                  ; Width
 mov   qword [RSP + 4 * 8], 20                  ; Height
 mov   RAX, qword [hdc]                         ; [RBP - 8]
 mov   qword [RSP + 5 * 8], RAX                 ; Source device context
 mov   qword [RSP + 6 * 8], 0                   ; Source X
 mov   qword [RSP + 7 * 8], 0                   ; Source Y
 mov   qword [RSP + 8 * 8], BLACKNESS           ; Operation
 call  BitBlt                                   ; Blit a black rectangle

 mov   RCX, qword [hWnd]                        ; [RBP + 16]
 lea   RDX, [ps]                                ; [RBP - 80]
 call  EndPaint

Return.WM_Processed:
 xor   RAX, RAX                                 ; WM_ has been processed, return 0

Return:
 mov   RSP, RBP                                 ; Remove the stack frame
 pop   RBP
 ret