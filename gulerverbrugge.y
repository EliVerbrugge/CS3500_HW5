/*

//------------------------------------------
//------------------------------------------
//------------------------------------------
//------------------------------------------
//------------------------------------------
//------------------------------------------
//------------------------------------------
//------------------------------------------

      gulerverbrugge.y
	  created by Eli Verbrugge and Timur Guler
 	Specifications for the MFPL language, YACC input file.

      To create syntax analyzer:

        flex mfpl.l
        bison mfpl.y
        g++ mfpl.tab.c -o mfpl_parser
        mfpl_parser < inputFileName
 */

/*
 *	Declaration section.
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <cstring>
#include <stack>
#include <ctype.h>
#include "SymbolTable.h"
using namespace std;

int lineNum = 1; 	// line # being processed
int numExpressions = 0;
stack<SYMBOL_TABLE> scopeStack;    // stack of scope hashtables

#define UNDEFINED  -1   // Type codes
#define FUNCTION 				   0
#define INT 1					//01
#define STR 2					//10  $2.type | $3.type.. $2.type is int and $3.type is str so 01 | 10 = 11
#define INT_OR_STR 3			//11
#define BOOL 4				   //100
#define INT_OR_BOOL 5		   //101
#define STR_OR_BOOL 6		   //110
#define INT_OR_STR_OR_BOOL 7   //111

#define ARITHMETIC_OP 97
#define LOGICAL_OP 98
#define RELATIONAL_OP 99

#define NOT_APPLICABLE -1

void beginScope();
void endScope();
void cleanUp();
void prepareToTerminate();
void bail();
TYPE_INFO findEntryInAnyScope(const string theName);

char NIL[] = "nil";
char TRUE[] = "t";

void printRule(const char*, const char*);
int yyerror(const char* s) 
{
  printf("Line %d: %s\n", lineNum, s);
  bail();
}

extern "C" 
{
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

%}

%union 
{
  char* text;
  TYPE_INFO typeInfo;
};

/*
 *	Token declarations
*/
%token  T_LPAREN T_RPAREN 
%token  T_IF T_LETSTAR T_LAMBDA T_PRINT T_INPUT T_PROGN T_EXIT
%token  T_ADD  T_SUB  T_MULT  T_DIV
%token  T_LT T_GT T_LE T_GE T_EQ T_NE T_AND T_OR T_NOT	 
%token  T_INTCONST T_STRCONST T_T T_NIL T_IDENT T_UNKNOWN

%type <text> T_IDENT T_INTCONST T_STRCONST T_T T_NIL T_LT T_GT T_LE T_GE T_EQ T_NE T_AND T_OR T_NOT T_ADD T_SUB T_MULT T_DIV T_PROGN
%type <typeInfo> N_EXPR N_CONST N_PRINT_EXPR N_PARENTHESIZED_EXPR N_ARITHLOGIC_EXPR N_ACTUAL_PARAMS N_IF_EXPR N_LET_EXPR N_ID_EXPR_LIST N_FUNCT_NAME N_PROGN_OR_USERFUNCTCALL N_INPUT_EXPR N_EXPR_LIST N_BIN_OP N_ARITH_OP N_LOG_OP N_REL_OP

/*
 *	Starting point.
 */
%start  N_START

/*
 *	Translation rules.
 */
%%
N_START		: // epsilon 
			{
			}
			| N_START N_EXPR
			{
			printRule("START", "START EXPR");
			printf("\n---- Completed parsing ----\n\n");
 			printf("\nValue of the expression is: ");
			}
			;
N_EXPR		: N_CONST
			{
			$$.type = $1.type; 
			$$.value = $1.value;
			}
            | T_IDENT
            {
			TYPE_INFO found = findEntryInAnyScope(string($1));
			if (found.type == NOT_APPLICABLE) 
				yyerror("Undefined identifier");
			$$.type = found.type; 
			$$.value = found.value;
			}
            | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
            {
			$$.type = $2.type; 
			$$.value = $2.value;
			}
			;
N_CONST		: T_INTCONST
			{
			$$.type = INT;
			$$.value = $1;
			}
            | T_STRCONST
			{
			$$.type = STR;
			$$.value = $1;
			}
            | T_T
            {
			$$.type = BOOL;
			$$.value = $1;
			}
            | T_NIL
            {
			$$.type = BOOL;
			$$.value = $1;
			}
			;
N_PARENTHESIZED_EXPR	: N_ARITHLOGIC_EXPR 
				{
				$$.type = $1.type;
				$$.value = $1.value;
				}
            	| N_IF_EXPR 
				{
				$$.type = $1.type;
				$$.value = $1.value;
				}
            	| N_LET_EXPR 
				{
				$$.type = $1.type;
				$$.value = $1.value;
				}
                | N_PRINT_EXPR 
				{
				$$.type = $1.type;
				$$.value = $1.value;
				}
                | N_INPUT_EXPR 
				{
				$$.type = $1.type;
				$$.value = $1.value;
				}
            	| N_PROGN_OR_USERFUNCTCALL 
				{
				$$.type = $1.type;
				$$.value = $1.value;
				}
				| T_EXIT
				{
				bail();
				}
				;
N_PROGN_OR_USERFUNCTCALL : N_FUNCT_NAME N_ACTUAL_PARAMS
				{
				//epsilon N_ACTUAL_PARAMS		
				if($2.type == NOT_APPLICABLE)
				{
					$$.type = BOOL;
					$$.value = $2.value;
				}
				else
				{
					$$.type = $2.type;
					$$.value = NIL;
				}
				}
				;
N_FUNCT_NAME	: T_PROGN
				{
				$$.type = NOT_APPLICABLE;
				$$.value = $1;
				}
                ;
N_ARITHLOGIC_EXPR	: N_UN_OP N_EXPR
				{
				//just invert, as not is the only unary operator
				const char* expr=$2.value;
				if(std::strcmp(expr, NIL)==0)
					$2.value=TRUE;
				else
					$2.value=NIL;
				}
				| N_BIN_OP N_EXPR N_EXPR
				{
					if($1.type == ARITHMETIC_OP)
					{
							if(!($2.type & INT))
							{
								yyerror("Arg 1 must be integer");
							}
							else if(!($3.type & INT))
							{
								yyerror("Arg 2 must be integer");
							}
							else
							{
								$$.type = INT;

								const char* op = $1.value;
								int num1 = atoi($2.value);
								int num2 = atoi($3.value);
								if(std::strcmp(op, "+")==0)
								{
									int val = num1+num2;
									sprintf($$.value, "%d", val);
								}
								else if(std::strcmp(op, "-")==0)
								{
									int val = num1-num2;
									sprintf($$.value, "%d", val);
								}
								else if(std::strcmp(op, "*")==0)
								{
									int val = num1*num2;
									sprintf($$.value, "%d", val);
								}
								else if(std::strcmp(op, "/")==0)
								{
									if(num2 == 0)
									{
										yyerror("Attempted division by 0");
									}
									int val = num1/num2;
									sprintf($$.value, "%d", val);
								}

							}
					}
					else if($1.type == LOGICAL_OP)
					{
						if($2.type == FUNCTION)
						{
							yyerror("Arg 1 cannot be a function");
						}
						else if($3.type == FUNCTION)
						{
							yyerror("Arg 2 cannot be a function");
						}
						else
						{
							$$.type = BOOL;

							const char* op = $1.value;

							if($2.type = INT)
							{
								$2.value = TRUE;
							}
							else if($2.type == STR)
							{
								if(std::strcmp($2.value, NIL)==0)
									$2.value=NIL;
								else
									$2.value=TRUE;
							}

							if($3.type = INT)
							{
								$3.value = TRUE;
							}
							else if($3.type == STR)
							{
								if(std::strcmp($3.value, NIL)==0)
									$3.value=NIL;
								else
									$3.value=TRUE;
							}

							if(std::strcmp(op, "and")==0)
							{
								if((std::strcmp($2.value, TRUE)==0) && (std::strcmp($3.value, TRUE)==0))
									$$.value=TRUE;
								else
									$$.value=NIL;
							}
							else if(std::strcmp(op, "or")==0)
							{
								if((std::strcmp($2.value, TRUE)==0) || (std::strcmp($3.value, TRUE)==0))
									$$.value=TRUE;
								else
									$$.value=NIL;
							}
						}
					}
					else if($1.type == RELATIONAL_OP)
					{
						if($2.type == FUNCTION || $2.type == BOOL)
						{
							yyerror("Arg 1 must be integer or string");
						}
						else if(($2.type & INT) && !($3.type & INT))
						{
							yyerror("Arg 2 must be integer or string");
						}
						else if(($2.type & STR) && !($3.type & STR))
						{
							yyerror("Arg 2 must be integer or string");
						}
						else
						{
							$$.type = BOOL;

							if($2.type == INT)
							{
								int num1 = atoi($2.value);
								int num2 = atoi($3.value);
								const char* op = $1.value;

								if(std::strcmp(op, "<")==0)
								{
									if(num1 < num2)
										$$.value=TRUE;
									else
										$$.value = NIL;
								}
								else if(std::strcmp(op,">")==0)
								{
									if(num1 > num2)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
								else if(std::strcmp(op,"<=")==0)
								{
									if(num1 <= num2)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
								else if(std::strcmp(op,">=")==0)
								{
									if(num1 >= num2)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
								else if(std::strcmp(op,"=")==0)
								{
									if(num1 == num2)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
								else if(std::strcmp(op,"/=")==0)
								{
									if(num1 != num2)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
							}
							else
							{
								const char* str1 = $2.value;
								const char* str2 = $3.value;
								const char* op = $1.value;

								if(std::strcmp(op, "<")==0)
								{
									if(str1 < str2)
										$$.value=TRUE;
									else
										$$.value = NIL;
								}
								else if(std::strcmp(op,">")==0)
								{
									if(str1 > str2)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
								else if(std::strcmp(op,"<=")==0)
								{
									if(str1 <= str2)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
								else if(std::strcmp(op,">=")==0)
								{
									if(str1 >= str2)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
								else if(std::strcmp(op,"=")==0)
								{
									if(std::strcmp(str1, str2)==0)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
								else if(std::strcmp(op,"/=")==0)
								{
									if(std::strcmp(str1, str2)!=0)
										$$.value=TRUE;
									else
										$$.value=NIL;
								}
							}
						}
					}
				}
                     	;
N_IF_EXPR   : T_IF N_EXPR N_EXPR N_EXPR
			{			
				if($2.value == NIL)
				{
					$$.type = $4.type;
					$$.value = $4.value;
				}
				else
				{
					$$.type = $3.type;
					$$.value = $3.value;
				}		
			}
			;
N_LET_EXPR  : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN N_EXPR
			{
			$$.type = $5.type;
			$$.value = $5.value;
			endScope();
			}
			;
N_ID_EXPR_LIST  : 
			{
			}
            | N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN 
			{
			string lexeme = string($3);
			bool success = scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(lexeme,
																		$4.type, $4.value));
			if (!success) 
				yyerror("Multiply defined identifier");
			}
			;
N_PRINT_EXPR    : T_PRINT N_EXPR
			{
			$$.type = $2.type;
			$$.value = $2.value;

			printf("%s", $2.value);
			printf("\n");
			}
			;
N_INPUT_EXPR    : T_INPUT
			{
			std::cin.getline($$.value, 256);
			if($$.value[0] == '+' || $$.value[0] == '+' || isdigit($$.value[0]))
			{
				$$.type = INT;
			}
			else
			{
				$$.type = STR;
			}
			}
			;
N_EXPR_LIST : N_EXPR N_EXPR_LIST  
			{
			numExpressions += 1;
			$$.type = $2.type;
			$$.value = $2.value;
			}
            | N_EXPR
			{
			numExpressions = 1;
			$$.type = $1.type;
			$$.value = $1.value;
			}
			;
N_BIN_OP	: N_ARITH_OP
			{
			$$.type = ARITHMETIC_OP;
			$$.value=$1.value;
			}
			|
			N_LOG_OP
			{
			$$.type = LOGICAL_OP;
			$$.value=$1.value;
			}
			|
			N_REL_OP
			{
			$$.type = RELATIONAL_OP;
			$$.value=$1.value;
			}
			;
N_ARITH_OP	: T_ADD
			{
			$$.value=$1;
			}
            | T_SUB
			{
			$$.value=$1;
			}
			| T_MULT
			{
			$$.value=$1;
			}
			| T_DIV
			{
			$$.value=$1;
			}
			;
N_REL_OP	: T_LT
			{
			$$.value=$1;
			}	
			| T_GT
			{
			$$.value=$1;
			}	
			| T_LE
			{
			$$.value=$1;
			}	
			| T_GE
			{
			$$.value=$1;
			}	
			| T_EQ
			{
			$$.value=$1;
			}	
			| T_NE
			{
			$$.value=$1;
			}
			;	
N_LOG_OP	: T_AND
			{
			$$.value=$1;
			}	
			| T_OR
			{
			$$.value=$1;
			}
			;
N_UN_OP	     : T_NOT
			{
			}
			;
N_ACTUAL_PARAMS	: //epsilon
				{
				$$.type = NOT_APPLICABLE;
				$$.value = NIL;
				}
				| N_EXPR_LIST
				{
				$$.type = $1.type;
				$$.value = $1.value;
				}
				;
%%

#include "lex.yy.c"
extern FILE *yyin;

void printRule(const char* lhs, const char* rhs) 
{
  return;
}

void beginScope() 
{
  scopeStack.push(SYMBOL_TABLE());
}

void endScope() 
{
  scopeStack.pop();
}

TYPE_INFO findEntryInAnyScope(const string theName) 
{
  TYPE_INFO info = {UNDEFINED, UNDEFINED, UNDEFINED};
  if (scopeStack.empty( )) return(info);
  info = scopeStack.top().findEntry(theName);
  if (info.type != UNDEFINED)
    return(info);
  else 
  { // check in "next higher" scope
    SYMBOL_TABLE symbolTable = scopeStack.top( );
    scopeStack.pop( );
    info = findEntryInAnyScope(theName);
    scopeStack.push(symbolTable); // restore the stack
    return(info);
  }
}

void cleanUp() 
{
  if (scopeStack.empty()) 
    return;
  else 
  {
    scopeStack.pop();
    cleanUp();
  }
}

void prepareToTerminate()
{
  cleanUp();
  cout << endl << "Bye!" << endl;
}

void bail()
{
  prepareToTerminate();
  exit(1);
}

int main(int argc, char** argv)
{
 if (argc < 2)
 {
 printf("You must specify a file in the command line!\n");
 exit(1);
 }
 yyin = fopen(argv[1], "r");
 do
 {
 	yyparse();
 }while (!feof(yyin));
 return 0;
}
