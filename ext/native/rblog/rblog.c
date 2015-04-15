#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rblog/rblog.h"

//used for debugging
#define TERM_NRM "\x1b[0m"   //normal
#define TERM_RED "\x1b[31m"  //red
#define TERM_GRN "\x1b[32m"  //green
#define TERM_CYN "\x1b[36m"  //cyan
#define TERM_LGY "\x1b[37m"  //light gray

enum rblog_levels rblog_level;

void set_rblog_level(enum rblog_levels log_level){
  rblog_level = log_level;
};

const char *tag(enum rblog_levels log_level){
  if ( log_level == RBLOG_ERROR )
    return "RBLOG_ERROR";
  if ( log_level == RBLOG_WARN )
    return "RBLOG_WARN";
  if (log_level == RBLOG_INFO )
    return "RBLOG_INFO";
  if ( log_level == RBLOG_DEBUG )
    return "RBLOG_DEBUG";
  return "??";
}

enum rblog_levels str_to_loglevel(char *strlevel){

  if ( strlevel ){
   if ( strcmp(strlevel, "RBLOG_ERROR") == 0 )
     return RBLOG_ERROR;
   if ( strcmp(strlevel, "RBLOG_WARN") == 0 )
     return RBLOG_WARN;
   if ( strcmp(strlevel, "RBLOG_INFO") == 0 )
     return RBLOG_INFO;
   if ( strcmp(strlevel, "RBLOG_DEBUG") == 0 )
     return RBLOG_DEBUG;
  }

  return RBLOG_UNDEF;
}

int rbloggable(enum rblog_levels log_level){
  if (log_level <= rblog_level){
    return 1;
  }
  return 0;
}


void rblog(enum rblog_levels log_level, char *msg){
  if (log_level <= rblog_level){

    char *term_color;
    if( log_level == RBLOG_ERROR)
      term_color = TERM_RED;
    if ( log_level == RBLOG_WARN)
      term_color = TERM_CYN;
    if ( log_level == RBLOG_INFO)
      term_color = TERM_GRN;
    if ( log_level == RBLOG_DEBUG)
      term_color = TERM_LGY;

    fprintf(stderr, "%s%s: %s\n%s", term_color, tag(log_level), msg, TERM_NRM);
  }
}

void testing(void){
  printf("current log level: %d\n", rblog_level);
  rblog(RBLOG_ERROR, "error msg");
  rblog(RBLOG_WARN,  "warn msg");
  rblog(RBLOG_INFO,  "info msg");
  rblog(RBLOG_DEBUG, "info msg");
}
