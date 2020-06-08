/*
This file defines the basic value unit "SingleValue" and its function.
*/

#include <string>
#include <iostream>
using namespace std;
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
		case String: os << *(dt.sval); break;
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
		case String: s.set_boolean(*(lhs.sval) == *(rhs.sval)); break;
		case Char: s.set_boolean(lhs.cval == rhs.cval); break;
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
		case String: s.set_boolean(*(lhs.sval) != *(rhs.sval)); break;
		case Char: s.set_boolean(lhs.cval != rhs.cval); break;
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
