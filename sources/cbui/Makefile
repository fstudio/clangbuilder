#Nmake Makefile

CC=cl
LD=link
#-std:c++latest 
CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -O2 -MT
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t -std:c++17
LDFLAGS=/NOLOGO -OPT:REF  
LIBS=KERNEL32.lib ADVAPI32.lib Shell32.lib USER32.lib GDI32.lib comctl32.lib Shlwapi.lib \
ComDlg32.lib d2d1.lib dwrite.lib shcore.lib Winmm.lib Pathcch.lib ole32.lib comsupp.lib
OBJS=main.obj cmVSSetupHelper.obj appui.obj \
VisualStudioSearch.obj apputils.obj


all:res/app.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) res/app.res /MANIFEST:EMBED -MANIFESTINPUT:res/app.manifest -OUT:ClangbuilderUI.exe $(LIBS)

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul
	
res/app.res:res/app.rc
	rc res\app.rc
	
{.}.cpp.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
	
{.}.cxx.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<

{.}.cc.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<