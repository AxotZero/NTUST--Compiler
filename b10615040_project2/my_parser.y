%{

#include "SymbolTable.hpp"
#include "lex.yy.cpp"

bool debug = true;
#define Trace(t)       if(debug){ printf(t); cout << endl;}
SymbolTableList symbol_tables;

void yyerror(string msg);
void InsertSymbolTable(Symbol* s);
void SymbolNotFound(string symbol_name);
void VariablTypeInconsistant();


%}

%union {
    float 	fval;
    int 	ival;
    bool    bval;
    char    cval;
    string *sval;
    SingleValue* single_value;

    VarSymbol* arguement;
    vector<VarSymbol*>* arguments;
    VarType type;
}


/* tokens*/
// operator
%token OR AND LE EE GE NE
// keyword
%token  BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE

// Constant and identifier
%token  <sval>  ID
%token  <bval>  CONST_BOOL
%token  <ival>  CONST_INT
%token  <fval>  CONST_FLOAT
%token  <sval>  CONST_STR

/* define return type of non-terminal */
%type   <single_value> const_val expression
%type   <arguement> arg
%type   <arguments> args
%type   <type> var_type return_type

/* operator precedence */
%left OR
%left AND
%left '!'
%left '<' LE EE GE '>' NE
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%%

program: 
    OBJECT ID '{' const_var_decs  method_decs '}'
    {
        Trace("Reducing to program");
        InsertSymbolTable(new Symbol(*$2, Object));
        symbol_tables.dump();
        symbol_tables.pop();
    };

const_var_decs:
    const_dec const_var_decs
    | var_dec const_var_decs
    | /* empty */;

const_dec:
    VAL ID '=' expression
    {
        InsertSymbolTable(new VarSymbol(*$2, Constant, *$4));
    } |
    VAL ID ':' var_type '=' expression
    {
        if($4 != $6->type) VariablTypeInconsistant();
        InsertSymbolTable(new VarSymbol(*$2, Constant, *$6));
    };

var_dec:
    VAR ID ':' var_type '[' CONST_INT ']'
    {
        if($6 < 1) yyerror("Array length cannot less than 1");
        InsertSymbolTable(new ArraySymbol(*$2, Array, $4, $6));
    }|
    VAR ID ':' var_type '=' expression
    {
        if($4 != $6->type) VariablTypeInconsistant();
        InsertSymbolTable(new VarSymbol(*$2, Constant, *$6));
    }|
    VAR ID '=' expression
    {   
        InsertSymbolTable(new VarSymbol(*$2, Variable, *$4));
    }|
    VAR ID ':' var_type
    {
        InsertSymbolTable(new VarSymbol(*$2, Variable, $4));
    }
    ;

var_type:
    BOOLEAN
    {
        $$ = Boolean;
    }|
    STRING
    {
        $$ = String;
    }|
    INT
    {
        $$ = Integer;
    }|
    FLOAT
    {
        $$ = Float;
    };

const_val: 
    CONST_BOOL
    {
        SingleValue* s = new SingleValue(Boolean);
        s->set_boolean($1);
        $$ = s;
    } | 
    CONST_STR 
    {   
        SingleValue* s = new SingleValue(String);
        s->set_boolean($1);
        $$ = s;
    } | 
    CONST_INT
    {
        SingleValue* s = new SingleValue(Integer);
        s->set_int($1);
        $$ = s;
    } | 
    CONST_FLOAT {
        SingleValue* s= new SingleValue(Float);
        s->set_float($1);
        $$ = s;
    };

method_decs:
    method_dec method_decs
    | method_dec;

method_dec:
    DEF ID '(' args ')' return_type
    {
        // start to add Function to Global SymbolTable
        FuncSymbol* func = new FuncSymbol(*$2, Function);
        for(int i = 0; i < $4->size(); ++i)
        {
            func->add_input_type((*$4)[i]->get_type());
        }
        if($6 != None)
        {
            func->set_return_type($6);
        }
        InsertSymbolTable(func);
        // finish adding

        // add local SymbolTable
        symbol_tables.push();
        for(int i = 0; i < $4->size(); ++i)
        {
            InsertSymbolTable((*$4)[i]);
        }
    } '{' const_var_decs statements'}'
    {
        Trace("Reducing to method_dec");
        symbol_tables.dump();
        symbol_tables.pop();
    }
    ;

args:
    arg{
        vector<VarSymbol*>* vvs = new vector<VarSymbol*>();
        vvs->push_back($1);
        $$ = vvs;
    } |
    args ',' arg{
        $1->push_back($3);
        $$ = $1;
    } |
    /* empty */
    {
        $$ = new vector<VarSymbol*>();
    };

arg:
    ID ':' var_type
    {
        $$ = new VarSymbol(*$1, Variable, $3);
    };

return_type:
    ':' var_type
    {
        $$ = $2;
    } | 
    
    {
        $$ = None;
    };

statements:
    statement statements;
    |;

statement:
    ID '=' expression
    {
        Symbol* id = symbol_tables.lookup(*$1);
        if(id == NULL) SymbolNotFound(*$1);
        if(id->get_type() != $3->get_type()) VariablTypeInconsistant();
        
        id->set(*$3);
    };

expression:
    const_val
    {
        $$ = $1;
    }



%%

void InsertSymbolTable(Symbol* s)
{
    if(symbol_tables.insert(s) == -1){
        yyerror(string("ID: ") + s->get_id_name() + " is already in SymbolTables");
    }
}


void SymbolNotFound(string symbol_name){
    yyerror(string("Symbol:") + symbol_name + " not found");
}

void VariablTypeInconsistant(){
    yyerror("Variable Type inconsistant");
}

void yyerror(string msg)
{
    cout << msg << endl;
}

int main()
{
    yyparse();
    return 0;
}
