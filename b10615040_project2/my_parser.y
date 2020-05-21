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

    VarSymbol* func_dec_arg;
    vector<VarSymbol*>* func_dec_args;
    vector<SingleValue*>* func_call_args;
    VarType type;
}


/* tokens*/
// operator
%token OR AND LE EE GE NE
// keyword
%token  BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE READ

// Constant and identifier
%token  <sval>  ID
%token  <bval>  CONST_BOOL
%token  <ival>  CONST_INT
%token  <fval>  CONST_FLOAT
%token  <sval>  CONST_STR

/* define return type of non-terminal */
%type   <single_value> const_val expression
%type   <func_dec_arg> arg
%type   <func_dec_args> args
%type   <func_call_args> comma_separated_expressions
%type   <type> var_type return_type func_call

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
        InsertSymbolTable(new VarSymbol(*$2, Variable, *$6));
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
    } '{' const_var_decs empty_or_more_statements'}'
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

empty_or_more_statements:
    /* empty */
    |statements empty_or_more_statements;

statements:
    simple_statement
    |block
    |conditional
    |loop
    |func_call
    {
        if($1 != None) yyerror("procedure invocation should not have return value"); 
    };

simple_statement:
    ID '=' expression
    {
        Symbol* id = symbol_tables.lookup(*$1);
        if(id == NULL) SymbolNotFound(*$1);
        if(id->get_declaration() != Variable){ yyerror(string("Symbol:") + id->get_id_name() + " is not an varaible");}
        if(id->get_type() != $3->get_type()) VariablTypeInconsistant();
        id->set_value(*$3);
    }|
    ID '[' expression ']' '=' expression
    {
        if($3->get_type() != Integer) yyerror("Array Index must be integer");
        Symbol* id = symbol_tables.lookup(*$1);
        if(id == NULL) SymbolNotFound(*$1);
        if(id->get_type() != $3->get_type()) VariablTypeInconsistant();
        id->assign_value(*$6, $3->ival);
    }|
    PRINT '(' expression ')'
    | PRINTLN '(' expression ')'
    | READ ID
    {
        Symbol* id = symbol_tables.lookup(*$2);
        if(id == NULL) SymbolNotFound(*$2);
    }
    | RETURN
    | RETURN expression;

expression:
    const_val
    {
        $$ = $1;
    }|
    ID
    {
        Symbol* id = symbol_tables.lookup(*$1);
        if(id == NULL) {SymbolNotFound(*$1);}
        SingleValue s = id->get_value();
        $$ = &s;
    }|
    '-' expression %prec UMINUS
    {
        VarType temp_type = $2->get_type();
        if(temp_type == Integer)
        {
            $2->ival *= -1;
            $$ = $2;
        } 
        else if(temp_type == Float)
        {
            $2->fval *= -1;
            $$ = $2;
        }
        else
        {
            yyerror("Value after Unary operator '-' can only be Integer or Float");
        }
    }|
    '!' expression
    {
        if($2->get_type() != Boolean)
        {
            yyerror("Value after operator'!' can only be Boolean");
        }
        $2->bval = !$2->bval;
        $$ = $2;
    } |
    expression OR expression
    {
        if($1->get_type() != Boolean || $3->get_type() != Boolean)
        {
            yyerror("Value between operator '||' can only be Boolean");
        }
        SingleValue* s = new SingleValue(Boolean);
        s->set_boolean($1->bval || $3->bval);
        $$ = s;
    } |
    expression AND expression
    {
        if($1->get_type() != Boolean || $3->get_type() != Boolean)
        {
            yyerror("Value between operator '&&' can only be Boolean");
        }
        SingleValue* s = new SingleValue(Boolean);
        s->set_boolean($1->bval && $3->bval);
        $$ = s;
    } |
    expression '+' expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float)
        {
            SingleValue s = *$1 + *$3;
            $$ = &s;
        }
        else
        {
            yyerror("Values between operator '+' can only be Integer or Float");
        }
    } |
    expression '-' expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float)
        {
            SingleValue s = *$1 - *$3;
            $$ = &s;
        }
        else
        {
            yyerror("Values between operator '-' can only be Integer or Float");
        }
    }|
    expression '*' expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float)
        {
            SingleValue s = *$1 * *$3;
            $$ = &s;
        }
        else
        {
            yyerror("Values between operator '*' can only be Integer or Float");
        }
    }|
    expression '/' expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float)
        {
            SingleValue s = *$1 / *$3;
            $$ = &s;
        }
        else
        {
            yyerror("Values between operator '/' can only be Integer or Float");
        }
    }|
    expression '<' expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float || $1->get_type() == Boolean)
        {
            
            SingleValue s = *$1 < *$3;
            $$ = &s;
        }
        else
        {
            yyerror("Values between operator '<' can only be Integer, Float, or Boolean");
        }
    }|
    expression '>' expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float || $1->get_type() == Boolean)
        {
            SingleValue s = *$1 > *$3;
            $$ = &s;
        }
        else
        {
            yyerror("Values between operator '>' can only be Integer, Float, or Boolean");
        }
    }|
    expression LE expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float || $1->get_type() == Boolean)
        {
            SingleValue s = *$1 <= *$3;
            $$ = &s;
        }
        else
        {
            yyerror("Values between operator '<=' can only be Integer, Float, or Boolean");
        }
    }|
    expression EE expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float || $1->get_type() == Boolean)
        {
            SingleValue s = *$1 == *$3;
            $$ = &s;
        }
        else
        {
             yyerror("Values between operator '==' can only be Integer, Float, or Boolean");
        }
    }|
    expression GE expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float || $1->get_type() == Boolean)
        {
            SingleValue s = *$1 >= *$3;
            $$ = &s;
        }
        else
        {
             yyerror("Values between operator '>=' can only be Integer, Float, or Boolean");
        }
    }|
    expression NE expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        if($1->get_type() == Integer || $1->get_type() == Float || $1->get_type() == Boolean)
        {
            SingleValue s = *$1 != *$3;
            $$ = &s;
        }
        else
        {
             yyerror("Values between operator '!=' can only be Integer, Float, or Boolean");
        }
    }|
    ID '[' expression ']'
    {
        if($3->get_type() != Integer) yyerror("Array Index must be integer");

        Symbol* id = symbol_tables.lookup(*$1);
        if(id == NULL) {SymbolNotFound(*$1);}
        if(id->get_declaration() != Function){ yyerror(string("Symbol:") + id->get_id_name() + " is not an array");}
        SingleValue s = id->get_value($3->ival);
        $$ = &s;
    } |
    func_call
    {
        SingleValue s = SingleValue($1);
        $$ = &s;
    };

func_call:
    ID '(' comma_separated_expressions ')'
    {
        Symbol* func = symbol_tables.lookup(*$1);
        
        if(func == NULL) { SymbolNotFound(*$1);}
        if(func->get_declaration() != Function){ yyerror(string("Symbol:") + func->get_id_name() + " is not a function");}
        if(func->check_input_types($3) == false){ yyerror("Function arguments does not match");}
        if(func->get_return_type() == None){ yyerror(string("Function:") + func->get_id_name() + " has no return type");}
        $$ = func->get_return_type();
    };

comma_separated_expressions:
    expression
    {
        vector<SingleValue*>* vsv = new vector<SingleValue*>();
        vsv->push_back($1);
        $$ = vsv;
    } |
    comma_separated_expressions ',' expression{
        $1->push_back($3);
        $$ = $1;
    } |
    /* empty */
    {
        $$ = new vector<SingleValue*>();
    };

block:
    '{' const_var_decs statements empty_or_more_statements '}';

block_or_statement:
    block
    | empty_or_more_statements;

conditional:
    IF '(' expression ')' block_or_statement
    {
        
        if($3->get_type() != Boolean) yyerror("Conditional statement should be boolean value");
    }|
    IF '(' expression ')' block_or_statement ELSE block_or_statement
    {
        cout << "if type:" << VarTypePrint($3->get_type()) << endl;
        if($3->get_type() != Boolean) yyerror("Conditional statement should be boolean value");
    };

loop:
    WHILE '(' expression ')' block_or_statement
    {
        if($3->get_type() != Boolean) yyerror("while statement should be boolean value");
    } |
    FOR '(' ID '<' '-' CONST_INT TO CONST_INT ')' block_or_statement
    {
        Symbol* id = symbol_tables.lookup(*$3);
        if(id == NULL) {SymbolNotFound(*$3);}
        if(id->get_declaration() != Variable){ yyerror(string("Symbol:") + id->get_id_name() + " is not an varaible");}
        if(id->get_type() != Integer) yyerror("Variable in for loop should be integer");
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
