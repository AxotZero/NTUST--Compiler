#pragma once

#include <iostream>
#include <fstream>
#include <stack>
#include <string>
#include "SymbolTable.hpp"

using namespace std;

class CodeGenerator{
private:
    ofstream output;
    string file_name;
    int label_counter;
    vector<string> labels;

public:
    CodeGenerator(){
        file_name = "example";
        output.open(file_name + ".jasm");
        label_counter = 0;
    }
    CodeGenerator(string f){
        file_name = f;
        output.open(file_name + ".jasm");
        label_counter = 0;
    }

    vector<string> new_labels(int num){
        labels = vector<string>();
        for(int i = 0; i < num; ++i){
            labels.push_back("L" + to_string(label_counter + i));
        }
        label_counter += num;
        return labels;
    }

    void program_start(string object_name){
        output << "class " << object_name << "{" << endl;
    }
    void program_end(){
        output << "}" << endl;
    }
    void dec_global_var(string id){
        output << "field static int " << id << endl;
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
        
        output << "method public static" << stream_return_type << " " << id << "(";
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
        string id = s->get_id_name();

        output << "invokestatic int " << file_name << "." << id << "(";
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
        output << "invokevirtual void java.io.PrintStream.println(java.lang.String)" << endl;
    }
    void relation(string op){
        new_labels(2);

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
        output << "iconst_1" << endl;
        output << labels[1] << ":" << endl;
    }
    void if_start(){
        new_labels(1);
        output << "ifeq " << labels[0];
    }
    void if_end(){
        output << labels[0] << ":" << endl;
    }
    void else_start(){
        string label = labels[0];
        new_labels(1);

        output << "goto " << labels[0];
        output << labels[0] << ":" << endl;
    }
};



