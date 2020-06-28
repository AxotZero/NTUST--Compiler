#pragma once

/*
This file defines the class and function of each symbols and symboltable.
*/

#include <string>
#include <map>
#include <utility>
#include <vector>
#include <iostream>
#include "SingleValue.hpp"

using namespace std;

enum SymbolDeclaration{
	Constant,
	Variable,
	Function,
	Array,
	Object
};

class Symbol{
private:
    string id_name;
    SymbolDeclaration declaration;
    
public:
    Symbol(string id, SymbolDeclaration declaration):id_name(id), declaration(declaration){}
    
    string get_id_name(){ return id_name; }
	SymbolDeclaration get_declaration(){return declaration;}
    
	// for VarSymbol
	virtual bool is_dirty(){return false;}
	virtual VarType get_type(){return None;}
	virtual void set_value(SingleValue t) {}
	virtual SingleValue* get_value(){return NULL;}

	// for ArraySymbol
	virtual void assign_value(SingleValue value, int index){}
	virtual void assign_array(SingleValue* value){}
	virtual SingleValue* get_value(int index){return NULL;}


	// for FuncSymbol
	virtual bool check_input_types(vector<SingleValue*>* input){return false;}
	virtual VarType get_return_type(){return None;}
	virtual vector<VarType> get_input_types() { return vector<VarType>();}

	// for all
    virtual void print_info(){
		string print_declaration = "Constant";
		switch(declaration){
			case Variable: print_declaration = "Variable"; break;
			case Function: print_declaration = "Function"; break;
			case Object: print_declaration = "Object"; break;
			case Array: print_declaration = "Array"; break;
		}
		cout << "id: " << id_name << ", declaration: " << print_declaration;
	}
};

class VarSymbol: public Symbol{
private:
    SingleValue content;
public:
	VarSymbol(string id, SymbolDeclaration declaration, VarType type): Symbol(id, declaration), content(type)
	{}
	VarSymbol(string id, SymbolDeclaration declaration, SingleValue s): Symbol(id, declaration), content(s)
	{}

	bool is_dirty(){return content.dirty;}
	VarType get_type(){return content.get_type();}
	void set_value(SingleValue t) {content = t;}
	SingleValue* get_value(){ return &content; }

    void print_info(){
        Symbol::print_info();
        cout << ", type: " << VarTypePrint(content.type);
		if(is_dirty()) cout << ", value: " << content; 
    }
};

class ArraySymbol: public Symbol{
private:
    SingleValue* content;
	VarType type;
	int length;
public:
	ArraySymbol(string id, VarType type, int length): Symbol(id, Array), type(type), length(length){
		content = new SingleValue[length];
	}

	void assign_value(SingleValue value, int index){
		content[index] = value;
	}

	void assign_array(SingleValue* value){
		content = value;
	}

	SingleValue* get_value(int index){
		return &content[index];
	}

	VarType get_type(){return type;}
	
	void print_info(){
        Symbol::print_info();
        cout << ", type: " << VarTypePrint(type);
		cout << ", length: " << length;
		cout << ", value: {";
		for(int i = 1; i < length; ++i){
			if(content[i].dirty){
				cout << " " << i << ":" << content[i] << ",";
			}
		}
		cout << "}";
	}
};

class FuncSymbol: public Symbol{
private:
    vector<VarType> input_types; 
	VarType return_type;
public:
	FuncSymbol(string id, SymbolDeclaration declaration): Symbol(id, declaration){ return_type = None;}

	void add_input_type(VarType vt){
		input_types.push_back(vt);
	}

	void set_return_type(VarType vt){
		return_type = vt;
	}

	VarType get_return_type(){return return_type;}
	vector<VarType> get_input_types() { return input_types; }

	bool check_input_types(vector<SingleValue*>* input){
		if(input->size() != input_types.size()) return false;
		for(int i = 0; i < input->size(); ++i){
			if((*input)[i]->get_type() != input_types[i]){
				cout << i << ":"<< (*input)[i]->get_type() << " " << input_types[i] << endl;
				return false;
			}
		}
		return true;
	}

    void print_info(){
        Symbol::print_info();
        cout << ", input_types: {";
		for(int i = 0; i < input_types.size(); ++i){
			if(i > 0) cout << ", ";
			cout << VarTypePrint(input_types[i]);
		}
		cout << "}" << ", return_type: " << VarTypePrint(return_type);
    }
};

class SymbolTable{
private:
	map<string, pair<int, Symbol*>> table;
public:
	int last_index;
	SymbolTable(){ last_index = 0;}

    Symbol* lookup(string s){
		if (table.find(s) != table.end()) {
		    return table[s].second;
		}
		else {
		    return NULL;
		}
    }

	int get_index(string s){
		if (table.find(s) != table.end()) {
		    return table[s].first;
		}
		else {
		    return -1;
		}
	}

    int insert(Symbol* s){
		if (table.find(s->get_id_name()) != table.end()) {
			return -1;
		}
		else {
			if(s->get_declaration() == Variable){
				table[s->get_id_name()] = pair<int, Symbol*>(last_index, s);
				++last_index;
			}
			else{
				table[s->get_id_name()] = pair<int, Symbol*>(-1, s);
			}
			return 1;
		}
    }

    // void dump(){
    // 	for(auto p : table){
    // 		p.second->print_info();
    // 		cout << endl;
    // 	}
    // }
};

class SymbolTableList{
private:
	vector<SymbolTable> tables;
	int top;
public:
	SymbolTableList(){ 
		top = -1; 
		push(); 
	}
	int get_top(){
		return top;
	}
	void push(){
		++top;
		tables.push_back(SymbolTable());
	}
	void pop(){
		--top;
		tables.pop_back();
	}
	int insert(Symbol* s){
		return tables[top].insert(s);
	}
	int get_index(string s){
		for(int i = top; top >= 0; --i){
			int index = tables[i].get_index(s);
			if(index != -1){
				if(i == 0) return -2;
				else return index;
			}
		}
		return -1;
	}

	Symbol* lookup(string s){
		for(int i = top; top >= 0; --i){
			Symbol* t = tables[i].lookup(s);
			if(t != NULL){
				return t;
			}
		}
		return NULL;
	}
	// void dump(){
	// 	cout << "================= Start of SymbolTable List ================ " << endl;
	// 	for(int i = top; i >= 0; --i){
	// 		cout << "**********"<< "SymbolTable Index: " << i << " ************" << endl;
	// 		tables[i].dump();
	// 		cout << "*************************************" << endl;
	// 	}
	// 	cout << "=================  End of SymbolTableList   ================= " << endl;
	// }
};