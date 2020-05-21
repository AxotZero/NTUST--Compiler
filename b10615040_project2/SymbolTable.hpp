#include <string>
#include <map>
#include <vector>
#include <iostream>

using namespace std;


enum SymbolDeclaration{
	Constant,
	Variable,
	Function,
	Array,
	Object
};


enum VarType{
	Integer,
	Float,
	Char,
	String,
	Boolean,
	None
};

string VarTypePrint(VarType type){
	string print_type;
	switch(type){
		case Integer: print_type = "Integer"; break;
		case Float: print_type = "Float"; break;
		case Char: print_type = "Char"; break;
		case String: print_type = "String"; break;
		case Boolean: print_type = "Boolean"; break;
		case None: print_type = "None"; break;
	}
	return print_type;
}

class SingleValue{
public:
	union{
		int		ival;
		float	fval;
		bool	bval;
		char	cval;
		string*	sval;
	};
	VarType type;
	bool dirty = true;
	VarType get_type(){return type;}
	SingleValue(): type(Integer){dirty = false;}
	SingleValue(VarType t): type(t){dirty = false;}

	void set_string(string* s){sval = s; dirty = true;}
	void set_int(int s){ival = s; dirty = true;}
	void set_boolean(bool s){bval = s; dirty = true;}
	void set_char(char s){cval = s; dirty = true;}
	void set_float(float s){fval = s; dirty = true;}
};

// operator overloading

ostream& operator<<(ostream& os, const SingleValue& dt)
{
	switch(dt.type){
		case Integer: os << dt.ival; break;
		case Float: os << dt.fval; break;
		case String: os << *dt.sval; break;
		case Boolean: os << dt.bval; break;
		case Char: os << dt.cval; break;
	}
    return os;
}


SingleValue operator + (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(lhs.get_type());
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(s.get_type())
	{
		case Integer: s.set_int(lhs.ival + rhs.ival); break;
		case Float: s.set_float(lhs.fval + rhs.fval); break;
	}
	return s;
}

SingleValue operator - (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(lhs.get_type());
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(s.get_type())
	{
		case Integer: s.set_int(lhs.ival - rhs.ival); break;
		case Float: s.set_float(lhs.fval - rhs.fval); break;
	}
	return s;
}

SingleValue operator * (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(lhs.get_type());
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(s.get_type())
	{
		case Integer: s.set_int(lhs.ival * rhs.ival); break;
		case Float: s.set_float(lhs.fval * rhs.fval); break;
	}
	return s;
}

SingleValue operator / (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(lhs.get_type());
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(s.get_type())
	{
		case Integer: s.set_int(lhs.ival / rhs.ival); break;
		case Float: s.set_float(lhs.fval / rhs.fval); break;
	}
	return s;
}

SingleValue operator < (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(Boolean);
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(lhs.get_type())
	{
		case Integer: s.set_boolean(lhs.ival < rhs.ival); break;
		case Float: s.set_boolean(lhs.fval < rhs.fval); break;
		case Boolean: s.set_boolean(lhs.bval < rhs.bval); break;
	}
	
	return s;
}

SingleValue operator > (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(Boolean);
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(lhs.get_type())
	{
		case Integer: s.set_boolean(lhs.ival > rhs.ival); break;
		case Float: s.set_boolean(lhs.fval > rhs.fval); break;
		case Boolean: s.set_boolean(lhs.bval > rhs.bval); break;
	}
	return s;
}

SingleValue operator <= (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(Boolean);
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(lhs.get_type())
	{
		case Integer: s.set_boolean(lhs.ival <= rhs.ival); break;
		case Float: s.set_boolean(lhs.fval <= rhs.fval); break;
		case Boolean: s.set_boolean(lhs.bval <= rhs.bval); break;
	}
	return s;
}

SingleValue operator == (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(Boolean);
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(lhs.get_type())
	{
		case Integer: s.set_boolean(lhs.ival == rhs.ival); break;
		case Float: s.set_boolean(lhs.fval == rhs.fval); break;
		case Boolean: s.set_boolean(lhs.bval == rhs.bval); break;
	}
	return s;
}

SingleValue operator >= (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(Boolean);
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(lhs.get_type())
	{
		case Integer: s.set_boolean(lhs.ival >= rhs.ival); break;
		case Float: s.set_boolean(lhs.fval >= rhs.fval); break;
		case Boolean: s.set_boolean(lhs.bval >= rhs.bval); break;
	}
	return s;
}

SingleValue operator != (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(Boolean);
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(lhs.get_type())
	{
		case Integer: s.set_boolean(lhs.ival != rhs.ival); break;
		case Float: s.set_boolean(lhs.fval != rhs.fval); break;
		case Boolean: s.set_boolean(lhs.bval != rhs.bval); break;
	}
	return s;
}

SingleValue operator && (SingleValue lhs, const SingleValue& rhs)
{
	SingleValue s = SingleValue(Boolean);
	if(lhs.dirty == false || rhs.dirty == false)
		return s;

	switch(lhs.get_type())
	{
		case Integer: s.set_boolean(lhs.ival != rhs.ival); break;
		case Float: s.set_boolean(lhs.fval != rhs.fval); break;
		case Boolean: s.set_boolean(lhs.bval != rhs.bval); break;
	}
	return s;
}

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
	virtual SingleValue get_value(){return SingleValue();}

	// for ArraySymbol
	virtual void assign_value(SingleValue value, int index){}
	virtual void assign_array(SingleValue* value){}
	virtual SingleValue get_value(int index){return SingleValue();}


	// for FuncSymbol
	virtual bool check_input_types(vector<SingleValue*>* input){return false;}
	virtual VarType get_return_type(){return None;}

	// for all
    virtual void print_info(){
		string print_declaration = "Constant";
		switch(declaration){
			case Variable: print_declaration = "Variable"; break;
			case Function: print_declaration = "Function"; break;
			case Object: print_declaration = "Object"; break;
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
	SingleValue get_value(){ return content; }

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
	ArraySymbol(string id, SymbolDeclaration declaration, VarType type, int length): Symbol(id, declaration), type(type), length(length){
		content = new SingleValue[length];
	}

	void assign_value(SingleValue value, int index){
		content[index] = value;
	}

	void assign_array(SingleValue* value){
		content = value;
	}

	SingleValue get_value(int index){
		return content[index];
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

	bool check_input_types(vector<SingleValue*>* input){
		if(input->size() != input_types.size()) return false;
		for(int i = 0; i < input->size(); ++i){
			if((*input)[i]->get_type() != input_types[i])
				return false;
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
	map<string, Symbol*> table;
	
public:

    Symbol* lookup(string s){
		if (table.find(s) != table.end()) {
		    return table[s];
		}
		else {
		    return NULL;
		}
    }

    int insert(Symbol* s){
		if (table.find(s->get_id_name()) != table.end()) {
			return -1;
		}
		else {
			table[s->get_id_name()] = s;
			return 1;
		}
    }

    void dump(){
    	for(auto p : table){
    		p.second->print_info();
    		cout << endl;
    	}
    }
};



class SymbolTableList{
private:
	vector<SymbolTable> tables;
	int top;

public:
	SymbolTableList(){ top = -1; push(); }
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
	Symbol* lookup(string s){
		for(int i = top; top >= 0; --i){
			Symbol* t = tables[i].lookup(s);
			if(t != NULL){
				return t;
			}
		}
		return NULL;
	}
	void dump(){
		for(int i = top; i >= 0; --i){
			cout << "Symbol Index" << i << endl;
			tables[i].dump();
		}
	}
};

// void test(){
// 	ArraySymbol arr_int = ArraySymbol("arr_int", Array, Integer, 20);
// 	ArraySymbol arr_string = ArraySymbol("arr_string", Array, String, 100);

// 	FuncSymbol func_arr = FuncSymbol("func", Function);
// 	func_arr.add_input_type(Integer);
// 	func_arr.add_input_type(Boolean);
// 	func_arr.set_return_type(String);

// 	VarSymbol var_real = VarSymbol("var_real", Variable, Real);

// 	VarSymbol const_string = VarSymbol("const_string", Constant, String);

// 	SingleValue a = SingleValue(String);
// 	a.sval = new string("yayayayay");
// 	const_string.set(a);

// 	SymbolTable table;
// 	table.insert(&arr_int);
// 	table.insert(&arr_string);
// 	table.insert(&func_arr);
// 	table.insert(&var_real);
// 	table.insert(&const_string);
// 	table.dump();
// }