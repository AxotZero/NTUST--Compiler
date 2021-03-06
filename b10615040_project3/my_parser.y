%{

#include "SymbolTable.hpp"
#include "lex.yy.cpp"
#include "CodeGenerator.hpp"

bool y_debug = false;
#define Trace(t)       if(y_debug){ printf(t); cout << endl;}

SymbolTableList ST;
CodeGenerator CG;

 /* utilities function */
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
// define two char operator
%token OR AND LE EE GE NE

// define keyword
%token  BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE READ

// define Constant and identifier type
%token  <sval>  ID
%token  <bval>  CONST_BOOL
%token  <ival>  CONST_INT
%token  <fval>  CONST_FLOAT
%token  <sval>  CONST_STR
%token  <cval>  CONST_CHAR

// define return type of non-terminal
%type   <single_value> const_val expression
%type   <func_dec_arg> arg
%type   <func_dec_args> args
%type   <func_call_args> comma_separated_expressions
%type   <type> var_type return_type func_call

// define operator precedence
%left OR
%left AND
%left '!'
%left '<' LE EE GE '>' NE
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%start program
%%

program: 
    OBJECT ID 
    {
        InsertSymbolTable(new Symbol(*$2, Object));

        CG.program_start();

    } '{' const_var_decs  method_decs '}'
    {
        Trace("Reducing to program");
        ST.pop();

        CG.program_end();
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
        InsertSymbolTable(new ArraySymbol(*$2, $4, $6));
    }|
    VAR ID ':' var_type '=' expression
    {
        if($4 != $6->type) VariablTypeInconsistant();
        InsertSymbolTable(new VarSymbol(*$2, Variable, *$6));

        if(ST.get_top() == 0){
            CG.dec_global_var_with_value(*$2, $6->ival);
        }
        else{
            CG.assign_local_var(ST.get_index(*$2));
        }
    }|
    VAR ID '=' expression
    {   
        InsertSymbolTable(new VarSymbol(*$2, Variable, *$4));

        if(ST.get_top() == 0){
            CG.dec_global_var_with_value(*$2, $4->ival);
        }
        else{
            CG.assign_local_var(ST.get_index(*$2));
        }

    }|
    VAR ID ':' var_type
    {
        InsertSymbolTable(new VarSymbol(*$2, Variable, $4));

        if(ST.get_top() == 0){
            CG.dec_global_var(*$2);
        }
    };

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
    }|
    CHAR
    {
        $$ = Char;
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
        s->set_string($1);
        $$ = s;
    } | 
    CONST_INT
    {
        SingleValue* s = new SingleValue(Integer);
        s->set_int($1);
        $$ = s;
    } | 
    CONST_FLOAT 
    {
        SingleValue* s = new SingleValue(Float);
        s->set_float($1);
        $$ = s;
    }|
    CONST_CHAR
    {
        SingleValue* s = new SingleValue(Char);
        s->set_char($1);
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
        ST.push();
        for(int i = 0; i < $4->size(); ++i)
        {
            InsertSymbolTable((*$4)[i]);
        }

        if(*$2 == "main") CG.def_main_start();
        else CG.dec_func_start(func);

    } '{' const_var_decs empty_or_more_statements '}'
    {
        Trace("Reducing to method_dec");
        ST.pop();

        CG.def_func_end($6);
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
    /* empty */
    {
        $$ = None;
    };

empty_or_more_statements:
    /* empty */
    |statements empty_or_more_statements;

statements:
    simple_statement
    |block
    |if_condition
    |loop
    |func_call
    {
        if($1 != None) yyerror("procedure invocation should not have return value");
    };

simple_statement:
    ID '=' expression
    {
        Symbol* id = ST.lookup(*$1);
        if(id == NULL) SymbolNotFound(*$1);
        if(id->get_declaration() != Variable){ yyerror(string("Symbol:") + id->get_id_name() + " is not an varaible");}
        if(id->get_type() != $3->get_type()) VariablTypeInconsistant();
        id->set_value(*$3);


        int get_index = ST.get_index(*$1);
        if(get_index == -2){
            CG.assign_global_var(*$1);
        }
        else{
            CG.assign_local_var(get_index);
        }
    }|
    ID '[' expression ']' '=' expression
    {
        if($3->get_type() != Integer) yyerror("Array Index must be integer");
        Symbol* id = ST.lookup(*$1);
        if(id == NULL) SymbolNotFound(*$1);
        if(id->get_type() != $3->get_type()) VariablTypeInconsistant();

        if($6->dirty == true){
            id->assign_value(*$6, $3->ival);
        }
        
    }|
    PRINT {
        CG.print_start();
    } '(' expression ')' {
        if($4->get_type() == String){
            CG.print_str_end();
        }
        else{
            CG.print_int_end();
        }
    }
    | PRINTLN {
        CG.print_start();
    }'(' expression ')'{
        if($4->get_type() == String){
            CG.println_str_end();
        }
        else{
            CG.println_int_end();
        }
    }
    | READ ID
    {
        Symbol* id = ST.lookup(*$2);
        if(id == NULL) SymbolNotFound(*$2);
    }
    | RETURN
    | RETURN expression;

expression:
    const_val
    {
        $$ = $1;

        if(ST.get_top() != 0){
            if($1->get_type() == String){
                CG.load_const_str(*($1->sval));
            }
            else{
                CG.load_const_int($1->ival);
            }
        }
    }|
    ID
    {
        Symbol* id = ST.lookup(*$1);
        if(id == NULL) {SymbolNotFound(*$1);}
        $$ = id->get_value();

        if(ST.get_top() != 0 && id->get_declaration() == Constant){
            if(id->get_type() == String){
                CG.load_const_str(*(id->get_value()->sval));
            }
            else{
                CG.load_const_int(id->get_value()->ival);
            }
        }
        else{
            int get_index = ST.get_index(*$1);
            if(get_index == -2){
                CG.load_global_var(*$1);
            }
            else{
                CG.load_local_var(get_index);
            }
        }
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


        CG.operation('n');
    }|
    '!' expression
    {
        if($2->get_type() != Boolean)
        {
            yyerror("Value after operator'!' can only be Boolean");
        }
        $2->bval = !$2->bval;
        $$ = $2;


        CG.operation('!');
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


        CG.operation('|');
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


        CG.operation('&');
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


        CG.operation('+');
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


        CG.operation('-');
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


        CG.operation('*');
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


        CG.operation('/');
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


        CG.relation("<");
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


        CG.relation(">");
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


        CG.relation("<=");
    }|
    expression EE expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        SingleValue s = *$1 == *$3;
        $$ = &s;


        CG.relation("==");
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


        CG.relation(">=");
    }|
    expression NE expression
    {
        if($1->get_type() != $3->get_type()) VariablTypeInconsistant();
        SingleValue s = *$1 != *$3;
        $$ = &s;


        CG.relation("!=");
    }|
    ID '[' expression ']'
    {
        if($3->get_type() != Integer) yyerror("Array Index must be integer");

        Symbol* id = ST.lookup(*$1);
        if(id == NULL) {SymbolNotFound(*$1);}
        if(id->get_declaration() != Array){ yyerror(string("Symbol:") + id->get_id_name() + " is not an array");}

        if($3->dirty == false){
            $$ = id->get_value(0);
        }
        else
        {
            $$ = id->get_value($3->ival);
        }
    } |
    func_call
    {
        SingleValue s = SingleValue($1);
        $$ = &s;
    };

func_call:
    ID '(' comma_separated_expressions ')'
    {
        Symbol* func = ST.lookup(*$1);
        
        if(func == NULL) { SymbolNotFound(*$1);}
        
        if(func->get_declaration() != Function){ yyerror(string("Symbol:") + func->get_id_name() + " is not a function");}

        if(func->check_input_types($3) == false){ yyerror("Function arguments does not match");}
        
        
        $$ = func->get_return_type();

        CG.func_call(func);
    };

comma_separated_expressions:
    expression
    {
        $$ = new vector<SingleValue*>();
        $$->push_back($1);
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
    '{' 
    {
        ST.push_block();
    } const_var_decs statements empty_or_more_statements '}'
    {
        Trace("Reducing to block")
        ST.pop();
    };

block_or_statement:
    block
    | simple_statement;

if_condition:
    IF '(' expression ')'
    {
        CG.if_start();
        if($3->get_type() != Boolean) yyerror("Conditional statement should be boolean value");
    } block_or_statement else_condition
    {
        Trace("Reducing to IF condition");
        CG.if_end();
    }
    ;

else_condition:
    /* empty */
    | ELSE 
    {
        CG.else_start();
    } block_or_statement

loop:
    WHILE
    {
        CG.while_start();
    } '(' expression ')'
    {
        if($4->get_type() != Boolean) yyerror("while statement should be boolean value");

        CG.if_start();
    } block_or_statement
    {
        Trace("Reducing to WHILE-LOOP");

        CG.while_end();
    } |
    FOR '(' ID '<' '-' CONST_INT TO CONST_INT ')'
    {
        Symbol* id = ST.lookup(*$3);
        if(id == NULL) {SymbolNotFound(*$3);}
        if(id->get_declaration() != Variable){ yyerror(string("Symbol:") + id->get_id_name() + " is not an varaible");}
        if(id->get_type() != Integer) yyerror("Variable in for loop should be integer");
        
    } block_or_statement
    {
        Trace("Reducing to FOR-LOOP");
    }


%%

void InsertSymbolTable(Symbol* s)
{
    if(ST.insert(s) == -1){
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
    exit(1);
}


int main(int argc, char **argv) {
  yyin = fopen(argv[1], "r");
  string source = string(argv[1]);
  int dot = source.find(".");
  string filename = source.substr(0, dot);
  CG = CodeGenerator(filename);

  yyparse();
  return 0;
}
