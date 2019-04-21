#Nmake Makefile

CC=cl
LD=link
#-std:c++latest 
CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -GR -O2 -Ob2 -MT -GL
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t -std:c++17
LDFLAGS=-NOLOGO -INCREMENTAL:NO -LTCG
LIBS=Kernel32.lib
OBJS=cli.obj


all:cli.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) cli.res -OUT:cli.exe $(LIBS)

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul
	
cli.res:../res/cli.rc
	rc  /focli.res ../res/cli.rc

{.}.cc.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
