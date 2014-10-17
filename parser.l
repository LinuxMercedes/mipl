/*    hw5_parser.l
 
 	Specifications of tokens for HW #5, to be
      used with bison file hw5_parser.y
     
 */

/*
 *	Constant definitions
 */
%{

%}

/*
 *	Definitions of regular expressions
*/

NEWLINE         	[\n]
WSPACE		[ \t\r]+

NEG_INTCONST	"-"[0-9]+
POS_INTCONST	("+")?[0-9]+
INTCONST          {NEG_INTCONST}|{POS_INTCONST}

IDENT			[a-z]|[A-Z]
 
/*
 *	Tokens
*/
%%

"("			{
				if (DEBUG) printf("TOKEN: LPAREN    LEXEME: %s\n", yytext);
				return LPAREN;
			}
")"			{
				if (DEBUG) printf("TOKEN: RPAREN    LEXEME: %s\n", yytext);
				return RPAREN;
			}
"["			{
				if (DEBUG) printf("TOKEN: LBRACK	LEXEME: %s\n", yytext);
				return LBRACK;
			}
"]"			{
				if (DEBUG) printf("TOKEN: RBRACK	LEXEME: %s\n", yytext);
				return RBRACK;
			}
";"			{
				if (DEBUG) printf("TOKEN: SEMICOL   LEXEME: %s\n", yytext);
				return SEMICOL;
			}
"+"			{
				if (DEBUG) printf("TOKEN: ADD       LEXEME: %s\n", yytext);
				return ADD;
			}
"="			{
				if (DEBUG) printf("TOKEN: ASSIGN    LEXEME: %s\n", yytext);
				return ASSIGN;
			}
">"			{
				if (DEBUG) printf("TOKEN: GT		LEXEME: %s\n", yytext);
				return GT;
			}
"<"			{
				if (DEBUG) printf("TOKEN: LT		LEXEME: %s\n", yytext);
				return LT;
			}
"!="			{
				if (DEBUG) printf("TOKEN: NE		LEXEME: %s\n", yytext);
				return NE;
			}
">="			{
				if (DEBUG) printf("TOKEN: GE		LEXEME: %s\n", yytext);
				return GE;
			}
"<="			{
				if (DEBUG) printf("TOKEN: LE		LEXEME: %s\n", yytext);
				return LE;
			}
"=="			{
				if (DEBUG) printf("TOKEN: EQ		LEXEME: %s\n", yytext);
				return EQ;
			}
"var"			{
				if (DEBUG) printf("TOKEN: VAR     	LEXEME: %s\n", yytext);
                        return VAR;
			}
"{"			{
				if (DEBUG) printf("TOKEN: LCURLY    LEXEME: %s\n", yytext);
                        return LCURLY;
			}
"}"			{
				if (DEBUG) printf("TOKEN: RCURLY    LEXEME: %s\n", yytext);
                        return RCURLY;
			}
"if"			{
				if (DEBUG) printf("TOKEN: IF       	LEXEME: %s\n", yytext);
				return IF;
			}
"then"			{
				if (DEBUG) printf("TOKEN: THEN    	LEXEME: %s\n", yytext);
				return THEN;
			}
"else"		{
				if (DEBUG) printf("TOKEN: ELSE     	LEXEME: %s\n", yytext);
				return ELSE;
			}
"while"		{
				if (DEBUG) printf("TOKEN: WHILE     LEXEME: %s\n", yytext);
				return WHILE;
			}
"true"		{
				if (DEBUG) printf("TOKEN: TRUE     	LEXEME: %s\n", yytext);
				return TRUE;
			}
"false"		{
				if (DEBUG) printf("TOKEN: FALSE     LEXEME: %s\n", yytext);
				return FALSE;
			}
{INTCONST}	      {
                        if (DEBUG) printf("TOKEN: INTCONST  LEXEME: %s\n", yytext);
                        yylval.num = atoi(yytext);
				return INTCONST;
			}
{IDENT}		{
                        if (DEBUG) printf("TOKEN: IDENT     LEXEME: %s\n", yytext);
                        yylval.ch = yytext[0];
				return IDENT;
			}
{NEWLINE}   	{
                		lineNum++;
            	}
{WSPACE}		{ }
.			{
				if (DEBUG) printf("TOKEN: UNKNOWN     LEXEME: %s\n", yytext);
				return UNKNOWN;
			}

%%





