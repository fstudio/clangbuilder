///cl checkcolor.cpp user32.lib
#include <Windows.h>

bool CheckColor() {
  // TO set Foreground color
  HANDLE hConsole = GetStdHandle(STD_ERROR_HANDLE);
  CONSOLE_SCREEN_BUFFER_INFO csbi;
  GetConsoleScreenBufferInfo(hConsole, &csbi);
  WORD oldColor = csbi.wAttributes;
  WORD newColor = 0;
  wchar_t buf[10];
  DWORD dwWrite=0;
  for(;newColor<0xFF;newColor++){
	    SetConsoleTextAttribute(hConsole, newColor);
		auto n=wsprintfW(buf,L"%3d ",newColor+1);
		if((newColor+1)%16==0){
			buf[n++]=L'\n';
			buf[n]=0;
		}
		WriteConsoleW(hConsole, buf,n, &dwWrite, nullptr);
		SetConsoleTextAttribute(hConsole, oldColor);
  }
  return 0;
}

int wmain(){
	return CheckColor();
}