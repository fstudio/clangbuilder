#Nmake Makefile

CC=cl
LD=link
#-std:c++latest 
CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -O2 -MT 
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t -std:c++17
LDFLAGS=/NOLOGO -OPT:REF  
LIBS=KERNEL32.lib ADVAPI32.lib Shell32.lib USER32.lib GDI32.lib comctl32.lib Shlwapi.lib \
ComDlg32.lib d2d1.lib dwrite.lib shcore.lib Winmm.lib Pathcch.lib
OBJS=pwshex.obj
PWSHEX=pwshex.exe
POWSH=powsh.exe

all:$(POWSH) $(PWSHEX)


$(PWSHEX):pwshex.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) pwshex.res /MANIFEST:EMBED -MANIFESTINPUT:pwshex.manifest -OUT:$(PWSHEX) $(LIBS)

$(POWSH):powsh.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) powsh.res /MANIFEST:EMBED -MANIFESTINPUT:pwshex.manifest -OUT:$(POWSH) $(LIBS)
	
clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul
	
pwshex.res:pwshex.rc
	rc pwshex.rc

powsh.res:powsh.rc
	rc powsh.rc
	
{.}.cpp.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
