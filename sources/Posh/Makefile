#Nmake Makefile

CC=cl
LD=link
#-std:c++latest 
CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -O2 -MT 
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t
LDFLAGS=/NOLOGO -OPT:REF  
LIBS=KERNEL32.lib ADVAPI32.lib Shell32.lib USER32.lib GDI32.lib comctl32.lib Shlwapi.lib \
ComDlg32.lib d2d1.lib dwrite.lib shcore.lib Winmm.lib Pathcch.lib
OBJS=Posh.obj


all:Posh.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) Posh.res /MANIFEST:EMBED -MANIFESTINPUT:Posh.manifest -OUT:Posh.exe $(LIBS)

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul
	
Posh.res:Posh.rc
	rc Posh.rc
	
{.}.cpp.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
