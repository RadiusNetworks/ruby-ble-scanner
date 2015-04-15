#include <stdio.h>   // standard input / output functions
#include <stdlib.h>  // general standard library functions
#include <unistd.h>  // UNIX standard function definitions
#include <fcntl.h>   // File control definitions
#include <string.h>
#include <stdint.h>
#include <sys/select.h>
#include <errno.h>
#include "serhex_api.h"
#include "rblog/rblog.h"

/* optimized for 38400 baud rate, max of 64 byte transmission */
/* => 16.667 msec txmt time */
/* ToDo: User configurable baud rate */

/* using 20 msecs for a bit of safety factor */
const int DEFAULT_WAIT=40000;  /* micro seconds */
const int MAX_WRITE_LEN=64; /* maximum bytes to write */
const int MAX_READ_LEN=64;  /* maximum bytes to read */

const char *RB_PORT_TEMPLATE = "/dev/cu.usbmodem*";

// Defining configure function in header file
// to make the platform specific interface simpler
// An including source only has to use the
// platform independent function: configure_port

int configure_port(int fd , speed_t st)
{
  struct termios port_settings;      // structure to store the port settings in
  int i;
  tcgetattr(fd, &port_settings);
  cfsetispeed(&port_settings, st);    // set baud rates
  cfsetospeed(&port_settings, st);

  port_settings.c_cflag &= ~(PARENB | CSTOPB | CSIZE | CRTSCTS | HUPCL );
  port_settings.c_cflag |= (CS8 | CLOCAL | CREAD);
  port_settings.c_lflag &= ~(ICANON | ISIG | ECHO | ECHOE | ECHOK | ECHONL | ECHOCTL | ECHOPRT | ECHOKE | IEXTEN);
  port_settings.c_lflag &= ~(INPCK | IXON | IXOFF | IXANY | ICRNL);
  port_settings.c_oflag &= ~(OPOST | ONLCR);

  for(i=0; i<sizeof(port_settings.c_cc);i++){
    port_settings.c_cc[i] = _POSIX_VDISABLE;
  }

  port_settings.c_cc[VTIME] = 0;
  port_settings.c_cc[VMIN] = 1;

  tcsetattr(fd, TCSAFLUSH, &port_settings);    // apply the settings to the port

  return(fd);
}

int open_port(char *port)
{
  char logmsg[255];

  snprintf(logmsg, 255, "Opening port ...");
  rblog(RBLOG_DEBUG, logmsg);

  int fd = open(port, O_RDWR | O_NOCTTY | O_NONBLOCK);

  snprintf(logmsg, 255, "opened port, fd is: %d", fd);
  rblog(RBLOG_DEBUG, logmsg);

  // ToDo: use errno?
  if(fd == -1) // if open is unsucessful
  {
    snprintf(logmsg, 255, "Unable to open serial port, exiting");
    rblog(RBLOG_ERROR, logmsg);
    exit(1);
  }
  else
  {
    configure_port(fd, B38400);
    fcntl(fd, F_SETFL, O_NONBLOCK);
  }

  return(fd);
}


int send_cmd_with_delay(char *portname, uint8_t *write_bytes, int writelen, uint8_t *read_bytes, int delay)
{
  // initialize read_bytes to 0
  read_bytes[0] = '\0';

  char errmsg[255];
  char bytecheck[8];

  snprintf( errmsg, 255, "Port: %s", portname );
  rblog(RBLOG_DEBUG, errmsg);

  int fd = open_port(portname);
  uint8_t tmpbuf[64];
  size_t bufout_idx=1; /* first element will be length, data starts 2nd element */

  //Needed to use select
  fd_set input;
  int max_fd;
  int s_ret;
  FD_ZERO(&input);
  FD_SET(fd, &input);
  struct timeval timeout;
  max_fd = fd + 1;
  timeout.tv_sec = 1;
  timeout.tv_usec = 0;

  // Give port some time to open
  // Might be able to be removed
  usleep(delay);


  //debug
  errmsg[0]='\0';
  bytecheck[0] = '\0';
  if ( rbloggable(RBLOG_DEBUG) ){
    snprintf(errmsg, 255, "Sending bytes: ");
     size_t idx2 = 0;
     while (idx2< writelen) {
        snprintf(bytecheck, 8, "%02x", (int)write_bytes[idx2]);
        strncat(errmsg, bytecheck, 8);
        idx2++;
      }
    rblog(RBLOG_DEBUG, errmsg);
  }
  // end debug

  /* writing writelen write_bytes to the serial port */
  int bytes_written = write(fd, write_bytes, writelen);

  snprintf(errmsg, 255, "Wrote %d bytes to port", bytes_written);
  rblog(RBLOG_DEBUG, errmsg);

  // Don't need delay with select
  s_ret = select(max_fd, &input, NULL, NULL, &timeout);

  if (s_ret<0) {
    snprintf(errmsg, 255, "Selecting port failed");
    rblog(RBLOG_ERROR, errmsg);
    return -4;
  }

  int exit_code;
  if(FD_ISSET(fd, &input)){
    snprintf(errmsg, 255, "Input on port");
    rblog(RBLOG_DEBUG, errmsg);

    // -- Process input
      size_t len = read(fd, tmpbuf, sizeof(tmpbuf));
      size_t retry_count = 0;
      size_t eagain_max_retry = 3;

      while ((EAGAIN == errno) && (retry_count < eagain_max_retry)){
        snprintf(errmsg, 255, "Recieved: '%s (%d)', retrying(%zu)", strerror(errno), errno, retry_count);
        rblog(RBLOG_WARN, errmsg);
        errno=0;
        len = read(fd, tmpbuf, sizeof(tmpbuf));
        retry_count ++;
      }


      if (len == -1) {
        snprintf(errmsg, 255, "Error reading from port: %s", strerror(errno));
        rblog(RBLOG_ERROR, errmsg);
        exit_code =  -1;

      } else if (len == 0) {
        snprintf(errmsg, 255, "No data from port");
        rblog(RBLOG_ERROR, errmsg);
        exit_code = -2;
      } else if ((len>0) && (len<=MAX_READ_LEN)) {
        /* Success Condition */

        errmsg[0]='\0';
        bytecheck[0]='\0';
        snprintf(errmsg, 255, "Bytes from serial port:");

        read_bytes[0] = len;
        while (bufout_idx < len+1) {


          snprintf(bytecheck, 8, "%02x", (int)tmpbuf[bufout_idx-1]);
          strncat(errmsg, bytecheck, 8);

          read_bytes[bufout_idx] = tmpbuf[bufout_idx-1];
          bufout_idx++;
        }

        rblog(RBLOG_DEBUG, errmsg);
        exit_code = 0;
      } else {
        snprintf(errmsg, 255, "Error in data length");
        rblog(RBLOG_ERROR, errmsg);
        exit_code = -3;
      }

  } else {
    // attemptint to process input but no input available
      snprintf(errmsg, 255, "Input on port");
      rblog(RBLOG_DEBUG, errmsg);
      exit_code = -6;
  }


  snprintf(errmsg, 255, "closing port: %d", fd);
  rblog(RBLOG_DEBUG, errmsg);

  close(fd);
  snprintf(errmsg, 255, "closed port: %d", fd);
  rblog(RBLOG_DEBUG, errmsg);
  snprintf(errmsg, 255, "exit code: %d", exit_code);
  rblog(RBLOG_DEBUG, errmsg);
  return exit_code;
}

// Waits for the port to respond in the default (usually optimum) amount of time
/* send cmd
 *    portname       - serial port to use e.g., /dev/ttyS3
 *    write_bytes    - bytes to write to the port
 *    writelen       - number of bytes to write
 *    read_bytes     - bytes read from serial port, 1st byte is the length
 *
 * returns success code
 */
int send_cmd(char *portname, uint8_t *write_bytes, int writelen, uint8_t *read_bytes)
{
    return send_cmd_with_delay(portname, write_bytes, writelen, read_bytes, DEFAULT_WAIT);
}