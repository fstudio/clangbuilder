#Nmake Makefile

CC=cl
LD=link
CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -O1 -Oi -MT 
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t
LDFLAGS=/NOLOGO -OPT:REF  
LIBS=KERNEL32.lib ADVAPI32.lib Shell32.lib USER32.lib GDI32.lib comctl32.lib Shlwapi.lib \
ComDlg32.lib d2d1.lib dwrite.lib shcore.lib Winmm.lib
OBJS=ClangbuilderUI.obj MainWindow.obj MessageWindow.obj VisualStudioSearch.obj WindowsUtil.obj


all:ClangbuilderUI.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) ClangbuilderUI.res /MANIFEST:EMBED -MANIFESTINPUT:ClangbuilderUI.manifest -OUT:ClangbuilderUI.exe $(LIBS)

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul
	
ClangbuilderUI.res:ClangbuilderUI.rc
	rc ClangbuilderUI.rc
	
{.}.cpp.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
	
