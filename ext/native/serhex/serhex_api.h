#ifndef _SERHEX_H_
#define _SERHEX_H_

#include <termios.h> // POSIX terminal control definitions

int configure_port(int fd , speed_t st);
int open_port(char *port);
int send_cmd(char *, uint8_t *, int, uint8_t *);
int send_cmd_with_delay(char *, uint8_t *, int, uint8_t *, int);

#endif /* _SERHEX_H_ */