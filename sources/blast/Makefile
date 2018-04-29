### NMake file

CC=cl
LD=link

CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -O2 -MT 
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t
LDFLAGS=/NOLOGO -OPT:REF  ole32.lib KERNEL32.lib ADVAPI32.lib Shell32.lib USER32.lib
OBJS=blast.obj symlink.obj readlink.obj dumpbin.obj

all:blast.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) blast.res /MANIFEST:EMBED -MANIFESTINPUT:blast.manifest -OUT:blast.exe $(LIBS)

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul

blast.res:blast.rc
	rc blast.rc

{.}.cpp.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
	
{.}.cxx.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<

{.}.cc.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<