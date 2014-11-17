/*
      oal.l

 	Specifications of tokens for the OAL language.
 	CS 356
 */

/*
 *	Constant definitions
 */
%{

%}

/*
 *	Definitions of regular expressions
*/

NEWLINE         	\n
WSPACE		[ \t\v\r]+

NEG_INTCONST	"-"[0-9]+
POS_INTCONST	[0-9]+

LABEL			"L."[0-9]+

/*
 *	Tokens
*/
%%

"#"			{
				/* checking for comment -- if so, skip until eoln. */
				ignoreComment();
			}
","			{
				if (DEBUG) printf("CLASS: T_COMMA    TOKEN: %s\n", yytext);
				return T_COMMA;
			}
":"			{
				if (DEBUG) printf("CLASS: T_COLON    TOKEN: %s\n", yytext);
				return T_COLON;
			}
"jp"			{
				if (DEBUG) printf("CLASS: T_JP       TOKEN: %s\n", yytext);
				return T_JP;
			}
"jf"			{
				if (DEBUG) printf("CLASS: T_JF       TOKEN: %s\n", yytext);
				return T_JF;
			}
"jt"			{
				if (DEBUG) printf("CLASS: T_JT       TOKEN: %s\n", yytext);
				return T_JT;
			}
"js"			{
				if (DEBUG) printf("CLASS: T_JS       TOKEN: %s\n", yytext);
				return T_JS;
			}
"ji"			{
				if (DEBUG) printf("CLASS: T_JI       TOKEN: %s\n", yytext);
				return T_JI;
			}
"bss"			{
				if (DEBUG) printf("CLASS: T_BSS      TOKEN: %s\n", yytext);
				return T_BSS;
			}
"asp"			{
				if (DEBUG) printf("CLASS: T_ASP      TOKEN: %s\n", yytext);
				return T_ASP;
			}
"push"		{
				if (DEBUG) printf("CLASS: T_PUSH     TOKEN: %s\n", yytext);
				return T_PUSH;
			}
"pop"			{
				if (DEBUG) printf("CLASS: T_POP      TOKEN: %s\n", yytext);
				return T_POP;
			}
"save" 		{
				if (DEBUG) printf("CLASS: T_SAVE     TOKEN: %s\n", yytext);
				return T_SAVE;
			}
"lc"			{
				if (DEBUG) printf("CLASS: T_LC       TOKEN: %s\n", yytext);
				return T_LC;
			}
"lv"			{
				if (DEBUG) printf("CLASS: T_LV       TOKEN: %s\n", yytext);
				return T_LV;
			}
"la"			{
				if (DEBUG) printf("CLASS: T_LA       TOKEN: %s\n", yytext);
				return T_LA;
			}
"deref"		{
				if (DEBUG) printf("CLASS: T_DEREF    TOKEN: %s\n", yytext);
				return T_DEREF;
			}
"st"			{
				if (DEBUG) printf("CLASS: T_ST       TOKEN: %s\n", yytext);
				return T_ST;
			}
"add"			{
				if (DEBUG) printf("CLASS: T_ADD      TOKEN: %s\n", yytext);
				return T_ADD;
			}
"sub"			{
				if (DEBUG) printf("CLASS: T_SUB      TOKEN: %s\n", yytext);
				return T_SUB;
			}
"mult"		{
				if (DEBUG) printf("CLASS: T_MULT     TOKEN: %s\n", yytext);
				return T_MULT;
			}
"div"			{
				if (DEBUG) printf("CLASS: T_DIV      TOKEN: %s\n", yytext);
				return T_DIV;
			}
"mod"			{
				if (DEBUG) printf("CLASS: T_MOD     TOKEN: %s\n", yytext);
				return T_MOD;
			}
"and"			{
				if (DEBUG) printf("CLASS: T_AND      TOKEN: %s\n", yytext);
				return T_AND;
			}
"or"			{
				if (DEBUG) printf("CLASS: T_OR       TOKEN: %s\n", yytext);
				return T_OR;
			}
".eq."		{
				if (DEBUG) printf("CLASS: T_EQ       TOKEN: %s\n", yytext);
				return T_EQ;
			}
".ne."		{
				if (DEBUG) printf("CLASS: T_NE       TOKEN: %s\n", yytext);
				return T_NE;
			}
".lt."		{
				if (DEBUG) printf("CLASS: T_LT       TOKEN: %s\n", yytext);
				return T_LT;
			}
".le."		{
				if (DEBUG) printf("CLASS: T_LE       TOKEN: %s\n", yytext);
				return T_LE;
			}
".gt."		{
				if (DEBUG) printf("CLASS: T_GT       TOKEN: %s\n", yytext);
				return T_GT;
			}
".ge."		{
				if (DEBUG) printf("CLASS: T_GE       TOKEN: %s\n", yytext);
				return T_GE;
			}
"neg"			{
				if (DEBUG) printf("CLASS: T_NEG      TOKEN: %s\n", yytext);
				return T_NEG;
			}
"not"	 		{
				if (DEBUG) printf("CLASS: T_NOT      TOKEN: %s\n", yytext);
				return T_NOT;
			}
"cread"		{
				if (DEBUG) printf("CLASS: T_CREAD    TOKEN: %s\n", yytext);
				return T_CREAD;
			}
"iread"		{
				if (DEBUG) printf("CLASS: T_IREAD    TOKEN: %s\n", yytext);
				return T_IREAD;
			}
"cwrite"		{
				if (DEBUG) printf("CLASS: T_CWRITE   TOKEN: %s\n", yytext);
				return T_CWRITE;
			}
"iwrite"		{
				if (DEBUG) printf("CLASS: T_IWRITE   TOKEN: %s\n", yytext);
				return T_IWRITE;
			}
"init"		{
				if (DEBUG) printf("CLASS: T_INIT     TOKEN: %s\n", yytext);
				return T_INIT;
			}
"halt"		{
				if (DEBUG) printf("CLASS: T_HALT     TOKEN: %s\n", yytext);
				return T_HALT;
			}
"end"			{
				if (DEBUG) printf("CLASS: T_END      TOKEN: %s\n", yytext);
				return T_END;
			}
{NEG_INTCONST}	{
				if (DEBUG) printf("CLASS: T_NCONST   TOKEN: %s\n", yytext);
                        yylval.num = atoi(yytext);
				return T_NCONST;
			}
{POS_INTCONST}	{
				if (DEBUG) printf("CLASS: T_PCONST   TOKEN: %s\n", yytext);
                        yylval.num = atoi(yytext);
				return T_PCONST;
			}
{LABEL}		{
				yylval.text = strdup(yytext);
				if (entryLabel != 0 && !strcmp(yytext, entryLabel))
					{
					if (DEBUG) printf("CLASS: T_ENTRY    TOKEN: %s\n", yytext);
					return T_ENTRY;
					}
				else
					{
					if (DEBUG) printf("CLASS: T_LABEL    TOKEN: %s\n", yytext);
					return T_LABEL;
					}
			}
{NEWLINE}   	{
                		++lineNum;
            	}
{WSPACE}		{ }
.			{
				if (DEBUG) printf("CLASS: UNKNOWN    TOKEN: %s\n", yytext);
				return T_UNKNOWN;
			}

%%




