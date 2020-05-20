%{

#include <string>
#include <map>

using std::string;
using std::map;

#define LIST     strcat(buf,yytext)
#define token(t) { LIST; printf("<%s>\n", t); }
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n", t, i);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n", t, s);}

#define MAX_LINE_LENG 256




int linenum = 1;
char buf[MAX_LINE_LENG];

class SymbolTable{
private:
	map<int, string> hash_table;
	map<string, int> inverse_hash_table;

public:

	int get_hash_index(string s){
		const int p = 31;
	    const int m = 1e9 + 9;
	    int hash_value = -1;
	    int p_pow = 1;
	    while(hash_value <= 0){
	    	for (char c : s) {
		        hash_value = (hash_value + (c - 'a' + 1) * p_pow) % m;
		        p_pow = (p_pow * p) % m;
	    	}
	    }
	    return hash_value;
	}

    int lookup(string s){
		if (inverse_hash_table.find(s) != inverse_hash_table.end()) {
		    return inverse_hash_table[s];
		}
		else {
		    return -1;
		}
    }

    int insert(string s){
		if (inverse_hash_table.find(s) != inverse_hash_table.end()) {
			return -1;
		}
		else {
			int hash_index = get_hash_index(s);

			hash_table[hash_index] = s;
			inverse_hash_table[s] = hash_index;
			return hash_index;
		}
    }

    void dump(){
    	printf("\nSymbol Table:\n");
    	for(auto p : hash_table){
    		printf("\t%s\n", p.second.c_str());
    	}
    }
};

SymbolTable* symbol_table;

%}


DILIMETER		[,:.;()\[\]\{\}]
ARITHMETIC		[+\-*/%=]
LOGICAL			("&&"|"||"|"!")
RELATOINAL		(>|>=|<|<=|==|!=)
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
boolean			{token("BOOLEAN");}
break			{token("BREAK");}
char			{token("CHAR");}
case			{token("CASE");}
class			{token("CLASS");}
continue		{token("CONTINUE");}
def				{token("DEF");}
do				{token("DO");}
else			{token("ELSE");}
exit			{token("EXIT");}
false			{token("FALSE");}
float			{token("FLOAT");}
for				{token("FOR");}
if				{token("IF");}
int				{token("INT");}
null			{token("NULL");}
object			{token("OBJECT");}
print			{token("PRINT");}
println			{token("PRINTLN");}
repeat			{token("REPEAT");}
return			{token("RETURN");}
string			{token("STRING");}
to				{token("TO");}
true			{token("TRUE");}
type			{token("TYPE");}
val				{token("VAL");}
var				{token("VAR");}
while			{token("WHILE");}


	/* operator */
{LOGICAL}	 |	
{DILIMETER}	 |	
{ARITHMETIC} |	
{RELATOINAL}	{token(("'" + string(yytext) + "'").c_str());}


	/* variable */
{IDENTIFIER}	{
					symbol_table->insert(yytext);
					tokenString("id", yytext);
				}

{INTEGER}		{tokenInteger("integer", atoi(yytext));}
{REAL}			{tokenString("real", yytext);}

{STRING}		{
					string s = "";

					for(int i = 1; i < yyleng - 1; ++i){
						if(yytext[i] == '"') ++i;
						s += yytext[i];
					}
					tokenString("string", s.c_str());
				}


	/* comment */
{SINGLE_COMMENT}        { LIST; }

{START_COMMENT}         {
                          LIST;
                          BEGIN COMMENT;
                        }

<COMMENT>[^\n]          {
                          LIST;
                        }

<COMMENT>\n             {
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

void create(){
	symbol_table = new SymbolTable();
}


int main()
{
  create();
  yylex();
  symbol_table->dump();
}
