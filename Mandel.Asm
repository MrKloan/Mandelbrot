.686 
.model flat, stdcall 
option casemap: none

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD 
WinCreate proto :DWORD
WinCommand proto :DWORD, :DWORD, :DWORD
WinPaint proto :DWORD

DrawColorButton proto
RenderText proto
ResetVars proto
InitVars proto :REAL8, :REAL8, :REAL8, :REAL8, :DWORD, :DWORD
DrawMandelbrot proto

include \masm32\include\windows.inc 
include \masm32\include\gdi32.inc
include \masm32\include\user32.inc 
include \masm32\include\kernel32.inc 

includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib
include masm32.inc
includelib masm32.lib

.data 
    AppName db "Mandelbrot", 0
    ps PAINTSTRUCT <0>
    hdc HDC 0
    
    WindowClassName db "Parent Class Name", 0
    WindowClassName_F db "SimpleWinClass", 0 ;classe de type SimpleWinClass (fenêtre simple)
    
    ButtonClassName db "button", 0 ;classe de type button (bouton) 
	ResetButtonText db "Reset", 0
	DrawButtonText db "Draw!", 0
	;ColorButtonText db "",0
	RedButtonText db "Red",0
	GreenButtonText db "Green",0
	BlueButtonText db "Blue",0
	
	EditClassName db "edit",0 ;classe de type edit (zone d'édition de texte)
	X1EditText db "x1"
	X2EditText db "x2"
	Y1EditText db "y1"
	Y2EditText db "y2"
	ZoomEditText db "Zoom"
	IterationsEditText db "Iterations"
	
    choosenColor db 0

.data?
	buffer db 10 dup(?)
    i dd ?
    x dd ?
    y dd ?
    color dd ?
    subcolor dd ?
    temp dd ?
    
    zoom dd ?
    iterations dd ?
    
    x1 REAL8 ?
    x2 REAL8 ?
    y1 REAL8 ?
    y2 REAL8 ?
    
    tmp REAL8 ?
    c_r REAL8 ?
    c_i REAL8 ?
    z_r REAL8 ?
    z_i REAL8 ?
    image_x REAL8 ?
    image_y REAL8 ?

    CommandLine LPSTR ? 
    hWindow HINSTANCE ?
    hFont HFONT ?
     
    hButtonReset HWND ?
    hButtonDraw HWND ?
    hButtonRed HWND ?
    hButtonGreen HWND ?
    hButtonBlue HWND ?
    hEditX1 HWND ?
    hEditX2 HWND ?
    hEditY1 HWND ?
    hEditY2 HWND ?
    hEditZoom HWND ?
    hEditIterations HWND ?

.const
	two dd 2
    four dd 4
    tff dd 255
    
	default_x1 REAL8 -2.1
	default_x2 REAL8 0.6
	default_y1 REAL8 -1.2
	default_y2 REAL8 1.2
	default_zoom dd 200
	default_iterations dd 50
    
	ResetButtonID equ 1
	DrawButtonID equ 2
	X1EditID equ 3
	X2EditID equ 4
	Y1EditID equ 5
	Y2EditID equ 6
	ZoomEditID equ 7
	IterationsEditID equ 8
	RedButtonID equ 9
	GreenButtonID equ 10
	BlueButtonID equ 11

.code 
main: 
	invoke ResetVars
    invoke GetModuleHandle, NULL 
    mov hWindow, eax 
    invoke GetCommandLine
    mov CommandLine, eax
    invoke WinMain, hWindow, NULL, CommandLine, SW_SHOWDEFAULT 
    invoke ExitProcess, eax

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    
    mov wc.cbSize, SIZEOF WNDCLASSEX ;taille de la structure de la window class
    mov wc.style, CS_HREDRAW or CS_VREDRAW ;style de la fenêtre : redessinée si redim. ou mouv. horizontal ou vertical
    mov wc.lpfnWndProc, OFFSET WndProc ;pointeur vers la fonction de gestion de la fenêtre
    mov wc.cbClsExtra, NULL ;nombre de bits supplémentaires à allouer après la window class
    mov wc.cbWndExtra, NULL ;nombre de bits supplémentaires à allouer après l'instance de fenêtre
    push hInst 
    pop wc.hInstance ;un handle de l'instance qui contient la fonction de gestion de la fenêtre
    mov wc.hbrBackground, COLOR_WINDOW+1 ;handle de la class backgroune brush utilisé pour le fond de la fenêtre
    mov wc.lpszMenuName, NULL ;pointeur vers une chaîne précisant le nom de la ressource menu name
    mov wc.lpszClassName, OFFSET WindowClassName ;pointeur vers le nom de la classe de la fenêtre
    
    invoke LoadIcon, NULL, IDI_APPLICATION ;arg1=handle vers le module contenant l'icone à charger, NULL pour une icone prédéfinie, arg2=nom del'icone à charger ou icone prédéfinie 
    mov wc.hIcon, eax ;un handle de la classe icon (vers une ressource de type icon)
    mov wc.hIconSm, eax ;un handle de la classe small icon (vers une ressource de type icon)
    
    invoke LoadCursor, NULL, IDC_ARROW ;arg1=handle vers le module contenant le curseur à charger, NULL pour un curseur prédéfini, arg2=nom du curseur à charger ou curseur prédéfini
    mov wc.hCursor, eax ;un handle de la classe cursor (vers une ressource de type cursor)
    
    invoke RegisterClassEx, addr wc ;enregistre la window class définie au-dessus
    

    invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR WindowClassName, ADDR AppName, WS_OVERLAPPEDWINDOW + WS_HSCROLL + WS_VSCROLL, CW_USEDEFAULT, CW_USEDEFAULT, 800, 580, NULL, NULL, hInst, NULL 
    mov hwnd, eax ;eax=valeur de retour de CreateWindowEx, copiée dans hwnd 
    
    invoke ShowWindow, hwnd, SW_SHOWNORMAL ;handle de la fenêtre, mode d'affichage de la fenêtre
    
    messages:
        invoke GetMessage, ADDR msg, NULL, 0, 0 
        cmp eax, 0
        jle end_loop

        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
        jmp messages
    
    end_loop:
        mov eax, msg.wParam 
        ret 
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    cmp uMsg, WM_DESTROY ;demande de fermeture de la fenêtre (clic sur croix rouge)
    je destroy
    cmp uMsg,WM_CREATE ;message WM_CREATE envoyé à la création de la fenêtre
    je create	
    cmp uMsg, WM_PAINT ;message WM_PAINT envoyé à chaque rafraîchissement de la fenêtre
    je paint
    cmp uMsg, WM_COMMAND ;message WM_COMMAND si reçu d'un menu ou d'un contrôle (bouton, edit, liste...)
    je command
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam ;si aucun des messages précédents
    ret 
    
    destroy:
        invoke PostQuitMessage,NULL
        jmp end_messages   
    create:
    	invoke WinCreate, hWnd
    	jmp end_messages
    command:
    	invoke WinCommand, hWnd, wParam, lParam
    	jmp end_messages
    paint:
        invoke WinPaint, hWnd
        
    end_messages:
        mov eax, 0
        ret 
WndProc endp

WinCreate proc hWnd:HWND
	;Reset Button
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ResetButtonText, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 450, 495, 70, 25, hWnd, ResetButtonID, hWindow, NULL 
    mov hButtonReset, eax
    ;Draw! Button
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR DrawButtonText, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 370, 495, 70, 25, hWnd, DrawButtonID, hWindow, NULL 
    mov hButtonDraw, eax
    ;Red Button
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR RedButtonText, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 530, 495, 70, 25, hWnd, RedButtonID, hWindow, NULL 
    mov hButtonRed, eax
    ;Green Button
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR GreenButtonText, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 610, 495, 70, 25, hWnd, GreenButtonID, hWindow, NULL 
    mov hButtonGreen, eax
    ;Blue Button
    invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR BlueButtonText, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 690, 495, 70, 25, hWnd, BlueButtonID, hWindow, NULL 
    mov hButtonBlue, eax
    ;x1 Edit
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR EditClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or ES_AUTOHSCROLL, 10, 495, 50, 25, hWnd, X1EditID, hWindow, NULL ; création du contrôle EDIT 
    mov hEditX1, eax
    ;x2 Edit
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR EditClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or ES_AUTOHSCROLL, 65, 495, 50, 25, hWnd, X2EditID, hWindow, NULL ; création du contrôle EDIT 
    mov hEditX2, eax
    ;y1 Edit
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR EditClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or ES_AUTOHSCROLL, 120, 495, 50, 25, hWnd, Y1EditID, hWindow, NULL ; création du contrôle EDIT 
    mov hEditY1, eax
    ;y2 Edit
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR EditClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or ES_AUTOHSCROLL, 175, 495, 50, 25, hWnd, Y2EditID, hWindow, NULL ; création du contrôle EDIT 
    mov hEditY2, eax
    ;Zoom Edit
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR EditClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or ES_AUTOHSCROLL, 245, 495, 50, 25, hWnd, ZoomEditID, hWindow, NULL ; création du contrôle EDIT 
    mov hEditZoom, eax
    ;Iterations Edit
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR EditClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or ES_AUTOHSCROLL, 305, 495, 50, 25, hWnd, IterationsEditID, hWindow, NULL ; création du contrôle EDIT 
    mov hEditIterations, eax
	
	ret
WinCreate endp

WinCommand proc hWnd:HWND, wParam:WPARAM, lParam:LPARAM
	mov eax, wParam ;récupération de l'identifiant de l'expéditeur dans eax
        
    cmp lParam, 0
    je end_messages ;si lParam=0 alors le message vient d'un menu : on n'en a pas ici
    	
    ;lParam différent de 0 donc message envoyé par un Control
    cmp ax, ResetButtonID ;s'il s'agit du bouton Reset
    je reset_button
    cmp ax, DrawButtonID ;s'il s'agit du bouton Draw!
    je draw_button
    cmp ax, RedButtonID ;s'il s'agit du bouton Red
    je red_button
    cmp ax, GreenButtonID
    je green_button
    cmp ax, BlueButtonID
    je blue_button
    jne end_messages
 		
 	reset_button:
      	shr eax, 16 ;rotation de 16 bits à droite (poids fort devient poids faible : ax = poids fort)
       	cmp ax, BN_CLICKED ;mot de poids fort de wParam = code de notification du contrôle
      	jne end_messages ;si ce n'est pas un clic sur le bouton qui a envoyé le message
       		
    	invoke ResetVars
    	invoke InvalidateRect, hWnd, NULL, TRUE
    	invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN
    	jmp end_messages
    		
    draw_button:
    	shr eax, 16 ;rotation de 16 bits à droite (poids fort devient poids faible : ax = poids fort)
       	cmp ax, BN_CLICKED ;mot de poids fort de wParam = code de notification du contrôle
       	jne end_messages ;si ce n'est pas un clic sur le bouton qui a envoyé le message
      	
      	invoke GetWindowText, hEditX1, ADDR buffer, 10 ;récupération du contenu de l'edit de x1 dans buffer
        invoke StrToFloat, ADDR buffer, ADDR x1 ;conversion du contenu du buffer dans x1

      	invoke GetWindowText, hEditX2, ADDR buffer, 10 
        invoke StrToFloat, ADDR buffer, ADDR x2
      	
      	invoke GetWindowText, hEditY1, ADDR buffer, 10 
        invoke StrToFloat, ADDR buffer, ADDR y1
      	
      	invoke GetWindowText, hEditY2, ADDR buffer, 10 
        invoke StrToFloat, ADDR buffer, ADDR y2
      	
      	invoke GetWindowText, hEditZoom, ADDR buffer, 10 
        invoke atol, ADDR buffer 
      	mov zoom, eax
      	
      	invoke GetWindowText, hEditIterations, ADDR buffer, 10 
        invoke atol, ADDR buffer 
      	mov iterations, eax
    		
    	invoke InvalidateRect, hWnd, NULL, TRUE
    	invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN
    	jmp end_messages
    
    red_button:
    	mov choosenColor, 0
    	invoke InvalidateRect, hWnd, NULL, TRUE
    	invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN
    	jmp end_messages
    	
    green_button:
    	mov choosenColor, 1
    	invoke InvalidateRect, hWnd, NULL, TRUE
    	invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN
    	jmp end_messages
    	
    blue_button:
    	mov choosenColor, 2
    	invoke InvalidateRect, hWnd, NULL, TRUE
    	invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN
    		
    end_messages:
	ret
WinCommand endp

WinPaint proc hWnd:HWND
	invoke BeginPaint, hWnd, ADDR ps ;lance le dessin de la fenêtre
    mov hdc, eax ;BeginPaint retourne le handle du contexte où on dessine
    invoke DrawMandelbrot
    invoke RenderText
    invoke DrawColorButton
    invoke EndPaint, hWnd, ADDR ps ;fin du dessin de la fenêtre
	
	ret
WinPaint endp

DrawColorButton proc
	;dessine le tour des boutons rouge, vert et bleu dans leur couleur respective
	;le boutoun rouge
	mov y, 494
	red_y:
		mov x, 529
		red_x:
        	invoke SetPixel, hdc, x, y, 0000FFh
        	inc x
			cmp x, 600
			jbe red_x
		inc y
		cmp y, 520
		jbe red_y
	
	;le boutoun vert
	mov y, 494
	green_y:
		mov x, 609
		green_x:
        	invoke SetPixel, hdc, x, y, 00FF00h
        	inc x
			cmp x, 680
			jbe green_x
		inc y
		cmp y, 520
		jbe green_y
		
	;le boutoun bleu
	mov y, 494
	blue_y:
		mov x, 689
		blue_x:
        	invoke SetPixel, hdc, x, y, 0FF0000h
        	inc x
			cmp x, 760
			jbe blue_x
		inc y
		cmp y, 520
		jbe blue_y
	
	ret
DrawColorButton endp


RenderText proc
	invoke TextOut, hdc, 30, 480, ADDR X1EditText, SIZEOF X1EditText
	invoke FloatToStr, x1, ADDR buffer
	invoke SetWindowText, hEditX1, ADDR buffer
	
	invoke TextOut, hdc, 85, 480, ADDR X2EditText, SIZEOF X2EditText
	invoke FloatToStr, x2, ADDR buffer
	invoke SetWindowText, hEditX2, ADDR buffer
	
	invoke TextOut, hdc, 140, 480, ADDR Y1EditText, SIZEOF Y1EditText
	invoke FloatToStr, y1, ADDR buffer
	invoke SetWindowText, hEditY1, ADDR buffer
	
	invoke TextOut, hdc, 195, 480, ADDR Y2EditText, SIZEOF Y2EditText
	invoke FloatToStr, y2, ADDR buffer
	invoke SetWindowText, hEditY2, ADDR buffer
	
	invoke TextOut, hdc, 253, 480, ADDR ZoomEditText, SIZEOF ZoomEditText
	invoke dwtoa, zoom, ADDR buffer
	invoke SetWindowText, hEditZoom, ADDR buffer
	
	invoke TextOut, hdc, 300, 480, ADDR IterationsEditText, SIZEOF IterationsEditText
	invoke dwtoa, iterations, ADDR buffer
	invoke SetWindowText, hEditIterations, ADDR buffer
	
	ret
RenderText endp

ResetVars proc    
    invoke InitVars, default_x1, default_x2, default_y1, default_y2, default_zoom, default_iterations
	ret
ResetVars endp

InitVars proc x1V:REAL8, x2V:REAL8, y1V:REAL8, y2V:REAL8, zoomV:DWORD, iterationsV:DWORD
	fld x1V
	fstp x1
	fld x2V
	fstp x2
	fld y1V
	fstp y1
	fld y2V
	fstp y2
	
	mov eax, zoomV
	mov zoom, eax
	mov eax, iterationsV
	mov iterations, eax
	
	ret
InitVars endp

DrawMandelbrot proc
    ;mov image_x, (x2-x1)*zoom
    fld x2
    fsub x1
    fimul zoom
    fstp image_x
    
    ;mov image_y, (y2-y1)*zoom
    fld y2
    fsub y1
    fimul zoom
    fstp image_y
    
    ;invoke nrandom, 3 ;met un nombre compris entre 0 et 2 dans eax
    ;mov choosenColor, eax ;choosenColor = eax
 
    mov x, 0
    whileX:

        mov y, 0
        whileY:
            ;mov c_r, x / zoom + x1
            fild x ;st(0) = y
            fidiv zoom ;st(0) = st(0)/zoom
            fadd x1 ;st(0) = st(0)+x1
            fstp c_r ;c_r = st(0)

            ;mov c_i, y / zoom + y1
            fild y ;st(0) = y
            fidiv zoom ;st(0) = st(0)/zoom
            fadd y1 ;st(0) = st(0)+y1
            fstp c_i ;c_r = st(0)

            ;mov z_r, 0
            ;mov z_i, 0
            fldz ;st(0) = 0
            fst z_r ;z_r = st(0)
            fstp z_i ;z_i = st(0)
            
            mov i, 0
            repeatStart:
                fld z_r
                fstp tmp

                ;mov z_r, z_r*z_r - z_i*z_i + c_r
                fld z_i ;st(0) = z_i
                fmul z_i ;st(0) = st(0)*z_i
                fld z_r ;st(0) = z_r, st(1) = z_i*z_i
                fmul z_r ;st(0) = st(0)*z_r, st(1) = z_i*z_i
                fsubrp st(1), st(0) ;st(1) = st(0)-st(1), pop st(0), st(0) = z_r*z_r - z_i*z_i
                fadd c_r ;st(0) = z_r*z_r - z_i*z_i + c_r
                fstp z_r ;z_r = st(0)

                ;mov z_i, 2*z_i*tmp + c_i
                fild two ;st(0) = 2
                fmul z_i ;st(0) = 2*z_i
                fmul tmp ;st(0) = 2*z_i*tmp
                fadd c_i ;st(0) = 2*z_i*tmp + c_i
                fstp z_i ;z_i = st(0)

                inc i

                ;mov tmp, z_r*z_r + z_i*z_i
                fld z_i ;st(0) = z_i
                fmul z_i ;st(0) = st(0)*z_i
                fld z_r ;st(0) = z_r, st(1) = z_i*z_i
                fmul z_r ;st(0) = st(0)*z_r, st(1) = z_i*z_i
                fadd st(1), st(0) ;st(1) = st(0)-st(1), pop st(0), st(0) = z_r*z_r + z_i*z_i
                fstp tmp ;tmp = st(0), st(0) = z_r*z_r + z_i*z_i
                fstp tmp ;tmp = z_r*z_r + z_i*z_i

                ;z_r*z_r + z_i*z_i < 4
                fild four ;st(0) = 4
                fld tmp ;st(0) = z_r*z_r + z_i*z_i, st(1) = 4
                fcomip st(0), st(1)
                fstp tmp
                jae repeatEnd
                ;AND
                ;i < iterations
                fild iterations
                fild i
                fcomip st(0), st(1)
                fstp tmp
                jb repeatStart
                repeatEnd:

            fild iterations
            fild i
            fcomip st(0), st(1)
            fstp tmp
            je darkPixel
            jmp colorPixel

            darkPixel:
                mov color, 000000h
                invoke SetPixel, hdc, x, y, 000000h
                jmp endPixel
            colorPixel:
                ;mov color, rgb(0, 0, i*255/iterations)
                fild i ;st(0) = i
                fimul tff ;st(0) = i*255
                fidiv iterations ;st(0) = i*255/iterations
                fistp subcolor ;subcolor = st(0)
                mov eax, subcolor ;place la valeur colorée dégradée dans eax, accessible via al
                mov color, 000000h ;noir comme base, on mettra la nouvelle valeur colorée dans le byte R(+0), G(+1) ou B(+2) souhaité
                
                cmp choosenColor, 0
                je colorR
                cmp choosenColor, 1
                je colorG
                cmp choosenColor, 2
                je colorB
                jmp drawpixel
                
                colorR:
                	mov BYTE ptr [color+0], al
                	jmp drawpixel
                colorG:
                	mov BYTE ptr [color+1], al
                	jmp drawpixel
                colorB:
                	mov BYTE ptr [color+2], al
                
                drawpixel:
                	invoke SetPixel, hdc, x, y, color
            endPixel:

            inc y
            fld image_y
            fild y
            fcomip st(0), st(1)
            fstp tmp
            jb whileY

        inc x
        fld image_x
        fild x
        fcomip st(0), st(1)
        fstp tmp
        jb whileX
	
	ret
DrawMandelbrot endp

end main