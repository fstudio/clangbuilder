#Nmake Makefile

CC=cl
LD=link
#-std:c++latest 
INCDIR=-I../include
CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -GR -O2 -Ob2 -MT -GL
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t -std:c++latest $(INCDIR)
LDFLAGS=-NOLOGO -INCREMENTAL:NO -LTCG
# INCS=inc/apphelp.hpp inc/apputils.hpp inc/base.hpp inc/comutils.hpp inc/json.hpp \
# inc/sdkver.hpp inc/settings.hpp inc/Setup.Configuration.h inc/string.hpp inc/systemtools.hpp \
# inc/vsinstance.hpp inc/vssearch.hpp inc/vssetup.hpp
LIBS=KERNEL32.lib ADVAPI32.lib Shell32.lib USER32.lib comctl32.lib Shlwapi.lib \
d2d1.lib dwrite.lib shcore.lib Winmm.lib Pathcch.lib ole32.lib comsupp.lib
OBJS=main.obj appui.obj appexec.obj apputils.obj vssearch.obj settings.obj


all:app.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) app.res /MANIFEST:EMBED -MANIFESTINPUT:../res/app.manifest -OUT:ClangbuilderUI.exe $(LIBS)

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul
	
app.res:../res/app.rc
	rc  /foapp.res ../res/app.rc
	
{.}.cpp.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
	
{.}.cxx.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<

{.}.cc.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
