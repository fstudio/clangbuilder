#Nmake Makefile

CC=cl
LD=link
#-std:c++latest 
CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -GR -O2 -Ob2 -MT -GL
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t -std:c++17
LDFLAGS=-NOLOGO -INCREMENTAL:NO -LTCG
LIBS=Kernel32.lib
CLIOBJ=cli.obj
CMDEXOBJ=cmdex.obj
TARGETS=cli.exe cmdex.exe

all:$(TARGETS)

cli.exe:cli.res $(CLIOBJ)
	$(LD) $(LDFLAGS) $(CLIOBJ) cli.res -OUT:cli.exe $(LIBS)

cmdex.exe:cmdex.res $(CMDEXOBJ)
	$(LD) $(LDFLAGS) $(CMDEXOBJ) cmdex.res -OUT:cmdex.exe $(LIBS)

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul
	
cli.res:../res/cli.rc
	rc  /focli.res ../res/cli.rc

cmdex.res:../res/cmdex.rc
	rc  /focmdex.res ../res/cmdex.rc

{.}.cc.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
