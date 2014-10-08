#Nmake Makefile

CC=cl
LD=link
CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -O1 -Oi -MT 
CXXFLAGS=-TP  -W4 -EHsc -Zc:forScope -Zc:wchar_t
LDFLAGS=/NOLOGO -OPT:REF  
LIBS=KERNEL32.lib   ADVAPI32.lib Shell32.lib USER32.lib GDI32.lib comctl32.lib



all:Launcher.res Launcher.obj
	$(LD) $(LDFLAGS) launcher.obj Launcher.res -OUT:Launcher.exe $(LIBS)
	

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul
	
Launcher.res:Launcher.rc
	rc Launcher.rc
	
Launcher.obj:
	$(CC) -c $(CFLAGS) $(CXXFLAGS) Launcher.cpp
	
