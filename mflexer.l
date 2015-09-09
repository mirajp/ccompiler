%{
// Miraj Patel, ECE 466 Compilers: Flex Lexical Analyzer
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "mparser.tab.h"

#define FALSE   0
#define TRUE    1

int linenum = 1;
char buf[4096] = "";
char filename[128] = "stdin\0";
int filenamefound = 0;

YYSTYPE yylval;

%}

%option noyywrap
%s FILESTR STRSTATE CHARLITSTATE DIRECTIVE

DECIDIGIT	[1-9][0-9]*
LETTER      [a-zA-Z]
IDENTIFIER  {LETTER}({LETTER}|[0-9])*
OCTAL       0[0-7]*
HEXDIGIT    0[xX][0-9a-fA-F]+

EEXPONENT    [eE][-+]?{DECIDIGIT}
PEXPONENT    [pP][-+]?{DECIDIGIT}
%%


<INITIAL>#" "+1" "+\"	            {
													if (linenum > 1)
														filenamefound = 0;

		                                 if (filenamefound == 0) {
		                                 	strcpy(filename, "");
		                                 	BEGIN(FILESTR);
		                                 	filenamefound = 1;
		                                 }	
		                                 else {
		                                 	BEGIN(DIRECTIVE);
		                                 }
                                    }
<INITIAL>#" "+{DECIDIGIT}" "+\"	    {BEGIN(DIRECTIVE);}

<FILESTR>[^\"\n\t]+	{strncat(filename, yytext, yyleng);}
<FILESTR>\"\n   {   BEGIN(INITIAL); strncat(filename, "\0", 1);
                    //printf("Filename = %s\n", filename);
				}
<DIRECTIVE>{IDENTIFIER}     {;}
<DIRECTIVE>[^\"\n]+         {;}

<DIRECTIVE>\"\n {
                    BEGIN(INITIAL);
                }         
                
<INITIAL>\"	{   //Clear string buffer and go into STRING character accepting state;
				strcpy(buf, "");
				BEGIN(STRSTATE);
			}
<STRSTATE>\\[?]	{	//printf("Special escape sequence %s seen\n", yytext);
					strncat(buf, yytext+1, yyleng);
                }
<STRSTATE>\\['"\\]	{	//printf("Special escape sequence %s seen\n", yytext);
                        // Not sure why the beginning slash is kept for quotes and not the ?
						strncat(buf, yytext, yyleng);
					}
<STRSTATE>\\[abfnrtv]	{	//printf("Read a '/' or bell/backspace/formfeed/linefeed/carriagereturn/tab/vtab character in a string o_O\n");
						strncat(buf, yytext, yyleng);
					}
<STRSTATE>\\[0-7]{1,3}	{	//Octal escape sequence - max of 3 digits
                            unsigned int octesc;
                            sscanf(yytext+1, "%o", &octesc);
                            if (octesc > 255) {
                                // If oct escape sequence exceeds 255 (\377) , cap it off
                                octesc = 255;
                            }
                            if (octesc > 31 && octesc < 128) {
                                // ACII values that define character range from space to delete
                                strncat(buf, (char *)&octesc, 1);
                            }
                            else {
                                if (octesc == 0)
                                    strncat(buf, "\\0", 2);
                                else {
                                    char tmp[4];
                                    sprintf(tmp, "\\%03o", (unsigned char *) octesc);
                                    strncat(buf, tmp, strlen(tmp));
                                }
                            }
                        }
<STRSTATE>\\[xX][0-9a-fA-F]+	{   // Hexadecimal escape sequence
                                unsigned int hexesc;
                                sscanf(yytext+2, "%x", &hexesc);
                                if (hexesc > 255) {
                                    // If hex escape sequence exceeds 255 (\xff) , cap it off
                                    hexesc = 255;
                                }
                                if (hexesc > 31 && hexesc < 128) {
                                    // ACII values that define character range from space to delete
                                    strncat(buf, (char *)&hexesc, 1);
                                }
                                else {
                                    char tmp[4];
                                    sprintf(tmp, "\\%03o", (unsigned char *) hexesc);
                                    strncat(buf, tmp, strlen(tmp));
                                }
                            }
<STRSTATE>[^\"\n\\]+	{strncat(buf, yytext, yyleng);}
<STRSTATE>\"	{BEGIN(INITIAL); strncat(buf, "\0", 1); strcpy(yylval.stringval, buf); return STRING;}


<INITIAL>\'	{//Clear string buffer and go into CHARLIT character accepting state;
				strcpy(buf, "");
				BEGIN(CHARLITSTATE);
			}
<CHARLITSTATE>\\['"?\\]	{	//printf("Special escape sequence %s seen\n", yytext);
						strncat(buf, yytext, yyleng);
					}
<CHARLITSTATE>\\[abfnrtv]	{	//printf("Read a '/' or bell/backspace/formfeed/linefeed/carriagereturn/tab/vtab character in a string\n");
							strncat(buf, &yytext[0], yyleng);
						}
<CHARLITSTATE>\\[0-7]{1,3}	{	//Octal number
                            char tmp[3];
                            int oct = strtol(yytext, NULL, 8);
                            sprintf(tmp, "%c", oct);
							strncat(buf, tmp, strlen(tmp));
						}
<CHARLITSTATE>[^\'\n\\]+	{strncat(buf, &yytext[0], 1);}
<CHARLITSTATE>\'	{BEGIN(INITIAL); strncat(buf, "\0", 1); yylval.charval = buf[0]; return CHARLIT;}



auto		{return AUTO;}
bool		{return _BOOL;}
break		{return BREAK;}
case		{return CASE;}
char 		{return CHAR;}
const		{return CONST;}
continue	{return CONTINUE;}
default	    {return DEFAULT;}
do			{return DO;}
double	    {return DOUBLE;}
else		{return ELSE;}
enum		{return ENUM;}
extern	    {return EXTERN;}
float		{return FLOAT;}
for		    {return FOR;}
goto		{return GOTO;}
if			{return IF;}
inline	    {return INLINE;}
int		    {return INT;}
long		{return LONG;}
register	{return REGISTER;}
restrict	{return RESTRICT;}
return	    {return RETURN;}
short		{return SHORT;}
signed	    {return SIGNED;}
sizeof	    {return SIZEOF;}
static	    {return STATIC;}
struct	    {return STRUCT;}
switch	    {return SWITCH;}
typedef	    {return TYPEDEF;}
union		{return UNION;}
unsigned	{return UNSIGNED;}
void		{return VOID;}
volatile	{return VOLATILE;}
while		{return WHILE;}
_Bool		{return _BOOL;}
_Complex	{return _COMPLEX;}
_Imaginary	{return _IMAGINARY;}

"->"        {return INDSEL;}
"++"		{return PLUSPLUS;}
"--"		{return MINUSMINUS;}
"<<"        {return SHL;}
">>"        {return SHR;}
"<="        {return LTEQ;}
">="        {return GTEQ;}
"=="        {return EQEQ;}
"!="        {return NOTEQ;}
"&&"        {return LOGAND;}
"||"        {return LOGOR;}
"*="        {return TIMESEQ;}
"/="        {return DIVEQ;}
"%="        {return MODEQ;}
"+="        {return PLUSEQ;}
"-="        {return MINUSEQ;}
"<<="       {return SHLEQ;}
">>="       {return SHREQ;}
"&="        {return ANDEQ;}
"^="        {return XOREQ;}
"|="        {return OREQ;}
"..."		{return ELLIPSIS;}
\n			{linenum++;}




[0-9]*\.[0-9]*[fF]	{yylval.val_signed = TRUE; yylval.floatval = atof(yytext); return NUMBER;}
[0-9]*\.[0-9]*[lL]	{yylval.val_signed = TRUE; yylval.floatval = atof(yytext); return NUMBER;}
[0-9]*\.[0-9]+	    {yylval.val_signed = TRUE; yylval.floatval = atof(yytext); return NUMBER;}


{HEXDIGIT}{PEXPONENT}   {   long double number;
                            sscanf(yytext, "%Lf", &number);
                            //printf("%s\t%d\tNUMBER\tREAL\t%Lg\t", filename, linenum, number);
                            char c;
                            c = input();
                            if (c == 'f' || c == 'F') {
                                //printf("FLOAT\n");
                                fprintf(stderr, "Casting floating pt value into an int\n");
                                yylval.floatval = number;
                            }
                            else if (c == 'l' || c == 'L') {
                                //printf("LONG\n");
                                fprintf(stderr, "Casting long type number into an int\n");
                                yylval.longval = number;
                            }
                            else {
                                unput(c);
                                //printf("DOUBLE\n");
                            }
                            yylval.val_signed = TRUE;
                            yylval.intval = (int)number;
                            return NUMBER;
                        }

({DECIDIGIT}|{OCTAL}){EEXPONENT}        {long double number; yylval.val_signed = TRUE; 
                                        sscanf(yytext, "%Lf", &number);
                                        yylval.intval = (int) number; return NUMBER;}
({DECIDIGIT}|{OCTAL}){EEXPONENT}[fF]    {long double number; yylval.val_signed = TRUE; 
                                        sscanf(yytext, "%Lf", &number);
                                        fprintf(stderr, "Casting floating pt value into an int\n");
                                        yylval.intval = (int) number; return NUMBER;}
({DECIDIGIT}|{OCTAL}){EEXPONENT}[lL]    {long double number; yylval.val_signed = TRUE; 
                                        sscanf(yytext, "%Lf", &number);
                                        fprintf(stderr, "Casting long type number into an int\n");
                                        yylval.intval = (int) number; return NUMBER;}
                                                
{HEXDIGIT}(("ll")|("LL"))[uU]   {long long hexdec = strtoll(yytext, NULL, 16); yylval.val_signed = FALSE;
                                fprintf(stderr, "Casting long long type number into an int\n");
                                yylval.intval = (int) hexdec; return NUMBER;}
{HEXDIGIT}[uU](("ll")|("LL"))   {long long hexdec = strtoll(yytext, NULL, 16); yylval.val_signed = FALSE; 
                                fprintf(stderr, "Casting long long type number into an int\n");
                                yylval.intval = (int) hexdec; return NUMBER;}
{HEXDIGIT}[uU][lL]              {long hexdec = strtol(yytext, NULL, 16); yylval.val_signed = FALSE; 
                                fprintf(stderr, "Casting long type number into an int\n");
                                yylval.intval = (int) hexdec; return NUMBER;}
{HEXDIGIT}[lL][uU]              {long hexdec = strtol(yytext, NULL, 16); yylval.val_signed = FALSE; 
                                fprintf(stderr, "Casting long type number into an int\n");
                                yylval.intval = (int) hexdec; return NUMBER;}
{HEXDIGIT}("ll"|"LL")           {long long hexdec = strtoll(yytext, NULL, 16); yylval.val_signed = TRUE;
                                fprintf(stderr, "Casting long long type number into an int\n");
                                yylval.intval = (int) hexdec; return NUMBER;}
{HEXDIGIT}[lL]                  {long hexdec = strtol(yytext, NULL, 16); yylval.val_signed = TRUE;
                                fprintf(stderr, "Casting long type number into an int\n");
                                yylval.intval = (int) hexdec; return NUMBER;}
{HEXDIGIT}[uU]                  {long hexdec = strtol(yytext, NULL, 16); yylval.val_signed = FALSE;
                                yylval.intval = (int) hexdec; return NUMBER;}
{HEXDIGIT}                      {long hexdec = strtol(yytext, NULL, 16); yylval.val_signed = TRUE;
                                yylval.intval = (int) hexdec; return NUMBER;}


{OCTAL}(("ll")|("LL"))[uU]      {long long oct = strtoll(yytext, NULL, 8); yylval.val_signed = FALSE;
                                fprintf(stderr, "Casting long long type number into an int\n");
                                yylval.intval = (int) oct; return NUMBER;}
{OCTAL}[uU](("ll")|("LL"))      {long long oct = strtoll(yytext, NULL, 8); yylval.val_signed = FALSE;
                                fprintf(stderr, "Casting long long type number into an int\n");
                                yylval.intval = (int) oct; return NUMBER;}
{OCTAL}[uU][lL]                 {long oct = strtol(yytext, NULL, 8); yylval.val_signed = FALSE;
                                fprintf(stderr, "Casting long type number into an int\n");
                                yylval.intval = (int) oct; return NUMBER;}
{OCTAL}[lL][uU]                 {long oct = strtol(yytext, NULL, 8); yylval.val_signed = FALSE;
                                fprintf(stderr, "Casting long type number into an int\n");
                                yylval.intval = (int) oct; return NUMBER;}
{OCTAL}("ll"|"LL")              {long long oct = strtoll(yytext, NULL, 8); yylval.val_signed = TRUE;
                                fprintf(stderr, "Casting long long type number into an int\n");
                                yylval.intval = (int) oct; return NUMBER;}
{OCTAL}[lL]                     {long oct = strtol(yytext, NULL, 8); yylval.val_signed = TRUE;
                                fprintf(stderr, "Casting long type number into an int\n");
                                yylval.intval = (int) oct; return NUMBER;}
{OCTAL}[uU]                     {long oct = strtol(yytext, NULL, 8); yylval.val_signed = FALSE;
                                yylval.intval = (int) oct; return NUMBER;}
{OCTAL}                         {long oct = strtol(yytext, NULL, 8); yylval.val_signed = TRUE;
                                yylval.intval = (int) oct; return NUMBER;}

                         
{DECIDIGIT}+[uU](("ll")|("LL"))     {yylval.val_signed = FALSE; yylval.intval = atoi(yytext); return NUMBER;}
{DECIDIGIT}+(("ll")|("LL"))[uU]     {yylval.val_signed = FALSE; yylval.intval = atoi(yytext); return NUMBER;}
{DECIDIGIT}+[uU][lL]                {yylval.val_signed = FALSE; yylval.intval = atoi(yytext); return NUMBER;}
{DECIDIGIT}+[lL][uU]                {yylval.val_signed = FALSE; yylval.intval = atoi(yytext); return NUMBER;}
{DECIDIGIT}+("ll"|"LL")             {yylval.val_signed = TRUE; yylval.intval = atoi(yytext); return NUMBER;}
{DECIDIGIT}+[lL]                    {yylval.val_signed = TRUE; yylval.longval = atoi(yytext); return NUMBER;}
{DECIDIGIT}+[uU]                    {yylval.val_signed = FALSE; yylval.intval = atoi(yytext); return NUMBER;}
{DECIDIGIT}+                        {yylval.val_signed = TRUE; yylval.intval = atoi(yytext); return NUMBER;}


[\~\'\!\%\^\&\*\(\)\{\}\[\]\|\?\<\>\,\.\:\;\/\+\-\=]   {return (yytext[0]);}
{IDENTIFIER}    { yylval.stringval = strdup(yytext);
                    return IDENT;
                }

<<EOF>>     {return EOF;}

%%

/* Don't need this main for bison
main (int argc, char *argv) {
	
    // Until EOF encountered
	while (yylex() != EOF) {
		//yylex();
	}
}
*/
