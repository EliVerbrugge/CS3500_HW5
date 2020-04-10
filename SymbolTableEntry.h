#ifndef SYMBOL_TABLE_ENTRY_H
#define SYMBOL_TABLE_ENTRY_H

#include <string>
using namespace std;

#define UNDEFINED  -1

typedef struct 
{ 
	int type;       // one of the above type codes 
	int numParams;  //numParams and returnType only applicableif type == FUNCTION
	int returnType;    
  char *value;
} TYPE_INFO;

class SYMBOL_TABLE_ENTRY 
{
private:
  // Member variables
  string name;
  int typeCode;  
  char* entryValue;

public:
  // Constructors
  SYMBOL_TABLE_ENTRY( ) { name = ""; typeCode = UNDEFINED; }

  SYMBOL_TABLE_ENTRY(const string theName, const int theType) 
  {
    name = theName;
    typeCode = theType;
  }

   SYMBOL_TABLE_ENTRY(const string theName, const int theType, char* value) 
  {
    name = theName;
    typeCode = theType;
    entryValue = value;
  }


  // Accessors
  string getName() const { return name; }
  int getTypeCode() const { return typeCode; }
  char* getValue() const { return entryValue; }


};

#endif  // SYMBOL_TABLE_ENTRY_H
