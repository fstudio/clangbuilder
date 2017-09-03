### NMake file

CC=cl
LD=link

CFLAGS=-nologo -DNODEBUG -DUNICODE -D_UNICODE -O2 -MT 
CXXFLAGS=-TP  -W3 -EHsc -Zc:forScope -Zc:wchar_t
LDFLAGS=/NOLOGO -OPT:REF  
OBJS=basal-link.obj

all:basal-link.res $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) basal-link.res /MANIFEST:EMBED -MANIFESTINPUT:basal-link.manifest -OUT:basal-link.exe $(LIBS)

clean:
	del /s /q *.res *.obj *.pdb *.exe >nul 2>nul

basal-link.res:basal-link.rc
	rc basal-link.rc

{.}.cpp.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<
	
{.}.cxx.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<

{.}.cc.obj::
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $<