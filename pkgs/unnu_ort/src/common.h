#ifndef _UNNU_ORT_COMMON_H
#define _UNNU_ORT_COMMON_H

#if defined(__WIN32__) || defined(_WIN32) || defined(WIN32) || defined(__WINDOWS__) || defined(__TOS_WIN__)

#include <windows.h>

#define FLT_SQRT_OF_2 1.4142135623731

inline void delay(unsigned long ms)
{
	Sleep(ms);
}

#else  /* presume POSIX */

#include <unistd.h>

inline void delay(unsigned long ms)
{
	usleep(ms * 1000);
}

#endif



#endif //_UNNU_ORT_COMMON_H