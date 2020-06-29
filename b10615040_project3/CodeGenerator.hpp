

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include "SymbolTable.hpp"

using namespace std;

class CodeGenerator{
private:
    ofstream output;
    string file_name;

    bool else_flag;
    int label_counter;
    vector<vector<string>> labels_list;

public:
    CodeGenerator(){
        file_name = "";
        label_counter = 0;
    }
    CodeGenerator(string f){
        file_name = f;
        output.open(file_name + ".jasm");
        label_counter = 0;
    }

    void push_labels(int num){
        vector<string> labels;
        for(int i = 0; i < num; ++i){
            labels.push_back("L" + to_string(label_counter + i));
        }
        labels_list.push_back(labels);
        label_counter += num;
    }
    void pop_labels(){
        labels_list.pop_back();
    }
    vector<string> get_labels(int num){
        return labels_list[labels_list.size() - num - 1];
    }

    void program_start(){
        output << "class " << file_name << endl;
        output << "{" << endl;
    }
    void program_end(){
        output << "}" << endl;
    }
    void dec_global_var(string id){
        output << "field static int " << id << endl;
    }
    void dec_global_var_with_value(string id, int value){
        output << "field static int " << id << " = " << value << endl;
    }
    void assign_global_var(string id){
        output << "putstatic int " << file_name << "." << id << endl;
    }
    void load_global_var(string id){
        output << "getstatic int " << file_name << "." << id << endl;
    }
    void assign_local_var(int id){
        output << "istore " << id << endl;
    }
    void load_const_int(int value){
        output << "sipush " << value << endl;
    }
    void load_const_str(string s){
        output << "ldc \"" << s << "\"" << endl;
    }
    void load_local_var(int id){
        output << "iload " << id << endl; 
    }
    void operation(char op){
        switch(op){
            case '+': output << "iadd" << endl; break;
            case '-': output << "isub" << endl; break;
            case '*': output << "imul" << endl; break;
            case '/': output << "idiv" << endl; break;
            case '%': output << "irem" << endl; break;
            case 'n': output << "ineg" << endl; break;
            case '&': output << "iand" << endl; break;
            case '|': output << "ior" << endl; break;
            case '!': output << "ixor" << endl; break;
        };
    }
    void dec_func_start(Symbol* s){
        vector<VarType> input_types = s->get_input_types();
        VarType return_type = s->get_return_type();
        string id = s->get_id_name();

        string stream_return_type = return_type == None? "void" : "int";
        
        output << "method public static " << stream_return_type << " " << id << "(";
        for(int i = 0; i < input_types.size(); ++i)
        {
            if(i >= 1) output << ", ";
            output << "int";
        }
        output << ")" << endl;
        output << "max_stack 15" << endl;
        output << "max_locals 15" << endl;
        output << "{" << endl; 
    }
    void def_func_end(VarType type){
        if(type == None) output << "return" << endl;
        else output << "ireturn" << endl; 
        output << "}" << endl;
    }
    void def_main_start(){
        output << "method public static void main(java.lang.String[])" << endl; 
        output << "max_stack 15" << endl; 
        output << "max_locals 15" << endl; 
        output << "{" << endl; 
    }
    void def_main_end(){
        output << "return" << endl;
        output << ")" << endl;
    }
    void func_call(Symbol* s){
        vector<VarType> input_types = s->get_input_types();
        VarType return_type = s->get_return_type();
        string id = s->get_id_name();
        string stream_return_type = return_type == None? "void" : "int";

        output << "invokestatic " << stream_return_type << " " << file_name << "." << id << "(";
        for(int i = 0; i < input_types.size(); ++i)
        {
            if(i >= 1) output << ", ";
            output << "int";
        } 
        output << ")" << endl;
    }
    void print_start(){
        output << "getstatic java.io.PrintStream java.lang.System.out" << endl;
    }
    void print_int_end(){
        output << "invokevirtual void java.io.PrintStream.print(int)" << endl;
    }
    void print_str_end(){
        output << "invokevirtual void java.io.PrintStream.print(java.lang.String)" << endl;
    }
    void println_int_end(){
        output << "invokevirtual void java.io.PrintStream.println(int)" << endl;
    }
    void println_str_end(){
        output << "invokevirtual void java.io.PrintStream.println(java.lang.String)" << endl;
    }
    void relation(string op){
        push_labels(2);
        vector<string>labels = get_labels(0);

        output << "isub" << endl;
        if(op == "<") {output << "iflt " << labels[0] << endl;}
        else if (op == ">") {output << "ifgt " << labels[0] << endl;}
        else if (op == "==") {output << "ifeq " << labels[0] << endl;}
        else if (op == "<=") {output << "ifle " << labels[0] << endl;}
        else if (op == ">=") {output << "ifge " << labels[0] << endl;}
        else if (op == "!=") {output << "ifne " << labels[0] << endl;}

        output << "iconst_0" << endl;
        output << "goto " << labels[1] << endl;

        output << labels[0] << ":" << endl;
        output << "nop" << endl;

        output << "iconst_1" << endl;
        output << labels[1] << ":" << endl;
        output << "nop" << endl;

        pop_labels();
    }
    void if_start(){
        else_flag = false;
        push_labels(1);
        vector<string> labels = get_labels(0);
        output << "ifeq " << labels[0] << endl;
    }
    void if_end(){
        vector<string> labels = get_labels(0);
        output << labels[0] << ":" << endl;
        output << "nop" << endl;
        pop_labels();

        if(else_flag == true)
            pop_labels();

        else_flag = false;
    }
    void else_start(){
        else_flag = true;
        vector<string> labels0 = get_labels(0);
        push_labels(1);
        vector<string> labels1 = get_labels(0);
        output << "goto " << labels1[0] << endl;
        output << labels0[0] << ":" << endl;
        output << "nop" << endl;
    }

    void while_start(){
        push_labels(1);
        vector<string> labels = get_labels(0);
        output << labels[0] << ":" << endl;
        output << "nop" << endl;
    }
    void while_end(){
        string exit = get_labels(0)[0];
        pop_labels();
        string begin = get_labels(0)[0];
        pop_labels();

        output << "goto " << begin << endl;
        output << exit << ":" << endl;
        output << "nop" << endl;
    }

};



