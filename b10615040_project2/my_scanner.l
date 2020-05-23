%{

#include "y.tab.hpp"

bool Debug = false; 
#define LIST     strcat(buf,yytext)
#define token(t) { LIST; if(Debug) printf("<%s>\n", #t); return t;}
#define tokenSingleOperator(t) { LIST; if(Debug) printf("<'%c'>\n", t);}
#define tokenDoubleOperator(t) { LIST; if(Debug) printf("<'%s'>\n", t);}
#define tokenInteger(t,i) {LIST; if(Debug) printf("<%s:%d>\n", t, i);}
#define tokenString(t,s) {LIST; if(Debug) printf("<%s:%s>\n", t, s);}

#define MAX_LINE_LENG 256


int linenum = 1;
char buf[MAX_LINE_LENG];
%}

DILIMETER		[,:.;\(\)\[\]\{\}]
ARITHMETIC		[+\-*/%=]
LOGICAL			("!")
RELATOINAL		(>|<)
IDENTIFIER		[A-Za-z][A-Za-z0-9]*
INTEGER 		[0-9]+
REAL			{INTEGER}\.{INTEGER}?([Ee][+-]?{INTEGER})?
STRING 			\"(\"\"|[^\"\n])*\"
SINGLE_COMMENT	"//"[^\n]*
START_COMMENT	(\/\*)
END_COMMENT		(\*\/)

%x COMMENT

%%

	/* keyword */
boolean		{token(BOOLEAN);}
break			{token(BREAK);}
char			{token(CHAR);}
case			{token(CASE);}
class			{token(CLASS);}
continue	{token(CONTINUE);}
def				{token(DEF);}
do				{token(DO);}
else			{token(ELSE);}
exit			{token(EXIT);}
float			{token(FLOAT);}
for				{token(FOR);}
if				{token(IF);}
int				{token(INT);}
object		{token(OBJECT);}
print			{token(PRINT);}
println		{token(PRINTLN);}
repeat		{token(REPEAT);}
return		{token(RETURN);}
string		{token(STRING);}
to				{token(TO);}
type			{token(TYPE);}
val				{token(VAL);}
var				{token(VAR);}
while			{token(WHILE);}
read      {token(READ);}


  /* double operator*/
"=="      { tokenDoubleOperator("=="); return EE; }
"<="      {tokenDoubleOperator("<="); return LE;}
">="      {tokenDoubleOperator(">="); return GE;}
"!="      {tokenDoubleOperator("!="); return NE;}
"||"      {tokenDoubleOperator("||"); return OR;}
"&&"      {tokenDoubleOperator("&&"); return AND;}

	/* single operator */
{LOGICAL}    |	
{DILIMETER}	 |	
{ARITHMETIC} |	
{RELATOINAL}	{ 
  tokenSingleOperator(yytext[0]); 
  return yytext[0];
}


  /* boolean */ 
true			{
  tokenString("boolean", yytext);
  yylval.bval = true;
  return CONST_BOOL;
}

false			{
  tokenString("boolean", yytext);
  yylval.bval = false;
  return CONST_BOOL;
}


	/* variable */
{IDENTIFIER}	{
  yylval.sval = new string(yytext);
  tokenString("ID", yytext);
  return ID;
}

{INTEGER} { 
  int value = atoi(yytext);
  tokenInteger("integer", value);
  yylval.ival = value;
  return CONST_INT;
}

{REAL}  {
  tokenString("float", yytext);
  yylval.fval = atof(yytext);
  return CONST_FLOAT;
}

{STRING}  {
  string s = "";
  for(int i = 1; i < yyleng - 1; ++i){
    if(yytext[i] == '"') ++i;
    s += yytext[i];
  }
  yylval.sval = new string(s);
	tokenString("CONST_STR", s.c_str());
  return CONST_STR;
}


	/* comment */
{SINGLE_COMMENT} { LIST; }

{START_COMMENT} { 
  LIST;
  BEGIN COMMENT;
}

<COMMENT>[^\n]  {
  LIST;
}

<COMMENT>\n {
  LIST;
   printf("%d: %s", linenum, buf);
   linenum++;
   buf[0] = '\0';
}

<COMMENT>{END_COMMENT}  {
  LIST;
  BEGIN INITIAL;
}

\n      {
        LIST;
        printf("%d: %s", linenum++, buf);
        buf[0] = '\0';
        }

[ \t]*  {LIST;}

.       {
        LIST;
        printf("%d:%s\n", linenum+1, buf);
        printf("bad character:'%s'\n",yytext);
        exit(-1);
        }

%%
