#include <stdio.h>   // standard input / output functions
#include <stdlib.h>  // general standard library functions
#include <unistd.h>  // UNIX standard function definitions
#include <string.h>
#include "rblog/rblog.h"
#include "serhex_api.h"

const int MAX_OUT_LEN=32;
const enum rblog_levels RBS_LOGLEVEL_DEFAULT = RBLOG_ERROR;

// Error Codes
const int RBS_ERR_NO_INPUT = -1;
const int RBS_ERR_BAD_INPUT = -2;

void send_stdout(unsigned char *buf);

int rbsererr(int err_code, char *errmsg){

  if ( err_code < 0 ){
    rblog(RBLOG_ERROR, errmsg);
    //fprintf(stderr, "Error code was: %d\n", err_code);
  }
  return err_code;
}

/* ToDo: Initialize any arrays to all zeros to prevent data leakage (security issue?) */

int main(int argc, char* argv[])
{
   char *env_loglevel = getenv("RBLOG_LEVEL");
   enum rblog_levels rbs_loglevel = str_to_loglevel(env_loglevel);

   //holds debugging data
   char errmsg[255];
   char bytecheck[8];

   if (rbs_loglevel == RBLOG_UNDEF ){
     //default
     set_rblog_level(RBLOG_ERROR);
   } else {
     set_rblog_level(rbs_loglevel);
   }

   char *port = argv[1];

   const unsigned char *hexstring = (unsigned char *)argv[2];
   /* return -1 if there is no data, or it is odd numbered, (byte string should be even) */
   int inlen = strlen((char *)hexstring);
   if (hexstring[0] == '\0') {
     //printf("No input string\n");
     return rbsererr(RBS_ERR_NO_INPUT, "No command string provided");
   }
   
   if (inlen % 2) {
     //printf("Input string was not even (expecting hex byte representation)\n");
     return rbsererr(RBS_ERR_BAD_INPUT, "Input string was not even (expecting hex bytes)");
   }

   unsigned const char *pos = hexstring;
   char *endptr;
   size_t count = 0;
   int outlen = inlen/2; /* inlen must be even */
   unsigned char bytes[outlen];
   size_t idx=0;


   snprintf( errmsg, 255, "Input length: %d", inlen);
   rblog(RBLOG_DEBUG, errmsg);

   snprintf( errmsg, 255, "Translating input to bytes ");
   rblog(RBLOG_DEBUG, errmsg);


   errmsg[0]='\0';

   for(count=0;count < inlen; count++){
     // debug data
     snprintf(bytecheck, 8, ".%c%c.", pos[0], pos[1]);
     strncat(errmsg, bytecheck, 8);
     // end debug

     char buf[5] = {'0', 'x', pos[0], pos[1], 0};
     bytes[count] = strtol(buf, &endptr, 0);
     pos += 2 * sizeof(char);
     
     /* non hex values are interpreted as 0 */
   };

   rblog(RBLOG_DEBUG, errmsg);
   snprintf( errmsg, 255, "Done translating");
   rblog(RBLOG_DEBUG, errmsg);

   errmsg[0]='\0';
   bytecheck[0]='\0';
   if( rbloggable(RBLOG_DEBUG) ){
     strncat(errmsg, "Bytes: ", 8);
     while (idx< sizeof(bytes)) {
      snprintf(bytecheck, 8, "%02x", (int)bytes[idx]);
      strncat(errmsg, bytecheck, 8);
      idx++;
     }
     rblog(RBLOG_DEBUG, errmsg);
   }

   unsigned char respbuf[MAX_OUT_LEN];

    snprintf( errmsg, 255, "Writing to serial port");
    rblog(RBLOG_DEBUG, errmsg);
    snprintf(errmsg, 255, "Size of bytes: %lu", (unsigned long) sizeof(bytes));
    rblog(RBLOG_DEBUG, errmsg);


   /* respbuf will hold response */
   send_cmd(port, bytes, sizeof(bytes), respbuf);

   //debug
   errmsg[0]='\0';
   bytecheck[0]='\0';
   if ( rbloggable(RBLOG_DEBUG) ){
     snprintf(errmsg, 255, "Size of response: %lu", (unsigned long) sizeof(respbuf));

     size_t idx2 = 0;
     while (idx2< sizeof(respbuf)) {
        snprintf(bytecheck, 8, "%02x", (int)respbuf[idx2]);
        strncat(errmsg, bytecheck, 8);
        idx2++;
     }
     rblog( RBLOG_DEBUG, errmsg);
   }
   // end debug

   send_stdout( respbuf );
   return 0;
}
 
void send_stdout(unsigned char *buf)
{
   //printf("RadBeacon Response: ");
   int outlen = buf[0];
   for (size_t i=0; i<outlen+1; i++) {
     fprintf(stdout, "%02x ", buf[i]);
   }
   printf("\n");
}
