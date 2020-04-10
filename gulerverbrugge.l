/*    
      gulerverbrugge.l
	  created by Eli Verbrugge and Timur Guler

 	Specifications of tokens for the MFPL language.
 */

%{

%}

/*
 *	Definitions of regular expressions
*/

WSPACE		[ \t\r]+
NEWLINE          \n
LO_ALPHA		[a-z]
HI_ALPHA		[A-Z]
ALPHA			{LO_ALPHA}|{HI_ALPHA}
DIGIT            [0-9]
ALPHANUM		{ALPHA}|{DIGIT}
UNDERSCORE		_

IDENT			({UNDERSCORE}|{ALPHA})({ALPHANUM}|{UNDERSCORE})*

NEG_INTCONST	"-"[0-9]+
POS_INTCONST	("+")?[0-9]+
INTCONST        {NEG_INTCONST}|{POS_INTCONST}

DOUBLE_QUOTE      \"
STRCONST         {DOUBLE_QUOTE}[^\"\n]*{DOUBLE_QUOTE} 

COMMENT           ";".*$      
/*
 *	Tokens
*/
%%

"("			{
			return T_LPAREN;
			}
")"			{
			return T_RPAREN;
			}
"+"			{
			yylval.text = strdup(yytext);
			return T_ADD;
			}
"-"			{
			yylval.text = strdup(yytext);
			return T_SUB;
			}
"*"			{
			yylval.text = strdup(yytext);
			return T_MULT;
			}
"/"			{
			yylval.text = strdup(yytext);
			return T_DIV;
			}
">"			{
			yylval.text = strdup(yytext);
			return T_GT;
			}
">="		{
			yylval.text = strdup(yytext);
			return T_GE;
			}
"<"			{
			yylval.text = strdup(yytext);
			return T_LT;
			}
"<="		{
			yylval.text = strdup(yytext);
			return T_LE;
			}
"="			{
			yylval.text = strdup(yytext);
			return T_EQ;
			}
"/="		{
			yylval.text = strdup(yytext);
			return T_NE;
			}
"progn"		{
			yylval.text = strdup(yytext);
			return T_PROGN;
			}
"let*"		{
			beginScope();
			yylval.text = strdup(yytext);
			return T_LETSTAR;
			}
"if"		{
			yylval.text = strdup(yytext);
			return T_IF;
			}
"lambda"	{
			beginScope();
			yylval.text = strdup(yytext);
			return T_LAMBDA;
			}
"print"		{
			yylval.text = strdup(yytext);
			return T_PRINT;
			}
"input"		{
			yylval.text = strdup(yytext);
			return T_INPUT;
			}
"t"			{
			yylval.text = strdup(yytext);
			return T_T;
			}
"nil"		{
			yylval.text = strdup(yytext);
			return T_NIL;
			}
"and"		{
			yylval.text = strdup(yytext);
			return T_AND;
			}
"or"		{
			yylval.text = strdup(yytext);
			return T_OR;
			}
"not"		{
			yylval.text = strdup(yytext);
			return T_NOT;
			}
"exit"		{
			yylval.text = strdup(yytext);
			return T_EXIT;
			}
{INTCONST}	{
			yylval.text = strdup(yytext);
			return T_INTCONST;
			}
{STRCONST}	{
			yylval.text = strdup(yytext);
			return T_STRCONST;
			}
{IDENT}		{
			yylval.text = strdup(yytext);
			return T_IDENT;
			}
{WSPACE}		{ }
{NEWLINE}       {
                 lineNum++;
                }
{COMMENT}		{ }
.			{
			return T_UNKNOWN;
			}

%%



