%option yylineno
%{
	#include <stdio.h>
	void yyerror(char *);
	void insert(char* yytext,char type);
%}

number (0|[1-9][0-9]*)
boolean (T|F)

%%

<INITIAL>{
{number} {yylval.value = atoi(yytext); insert(yytext, 'c'); return INT;}
{boolean} {yylval.value = ((*yytext == 'T') ? 1 : 0); insert(yytext, 'c'); return INT;}
\,{number} {yylval.id = atoi(++yytext); insert(--yytext, 'v'); return VAR;}
\.{number} {yylval.id = atoi(++yytext); insert(--yytext, 'v'); return VAR;}
\~{number} {yylval.id = atoi(++yytext); insert(--yytext, 'g'); return POINT;}
\${number} {yylval.id = atoi(++yytext); insert(--yytext, 'f'); return FUNC;}
\.{number}/\: {yylval.id = atoi(++yytext); insert(--yytext, 'm'); return INT_ARR;}
\,{number}/\: {yylval.id = atoi(++yytext); insert(--yytext, 'm'); return BOOL_ARR;}
\${number}/\: {yylval.id = atoi(++yytext); insert(--yytext, 'm'); return FUNC_ARR;}
"please" {insert(yytext, 'o'); return PLEASE;}
"DEBUG"  {insert(yytext, 'o'); return DEBUG;}
"MSG" {insert(yytext, 'o'); return MSG;}
\"[ 1-9a-zA-Z]*\" {yylval.str = yytext; insert(yytext, 'c'); return STR;}
"mf" {return MV_FRONT;}
"mb" {return MV_BACK;}
"mr" {return MV_RIGHT;}
"ml" {return MV_LEFT;}
"tp" {return TELEPORT;}
"eq" {insert(yytext, 'o'); return EQ;}
"np" {insert(yytext, 'o'); return PASS;}
"\.\#" {insert(yytext, 'o'); return NOR;}
"\<\-" {insert(yytext, 'o'); return ASSIGN;}
"\[\[" {insert(yytext, 'o'); return DOUBLE_OPEN;}
"\]\]" {insert(yytext, 'o'); return DOUBLE_CLOSE;}
[ \t\n]+ {;} /* ignore whitespace */
"\@" {insert(yytext, 'o'); return ATTACH;}
"\%" {insert(yytext, 'o'); return DETACH;}
[\(\)\{\}\:\-] {insert(yytext, 'p'); return *yytext;}
"\,\#" {insert(yytext, 'o'); return INC;}
"\,\*" {insert(yytext, 'o'); return DEC;}
<<EOF>> {return END;}
. {yyerror("Unknown character");}	
}

%%

void insert(char* yytext,char type)
{
	
	switch(type)
	{
		case 'v':
				printf("\t%s\t\t\tIdentifier\t\t\t\n",yytext);
				break;
		case 'c':
				printf("\t%s\t\t\tConstant\t\t\t\n",yytext);
				break;
		case 'p':
			printf("\t%s\t\t\tPunctuation\t\t\t\n",yytext);
			break;
		case 'o':
				printf("\t%s\t\t\tOperator\t\t\t\n",yytext);
				break;
		case 'k':
				printf("\t%s\t\t\tKeyword\t\t\t\n",yytext);
				break;
		case 'g':
			printf("\t%s\t\t\tGotoPoint\t\t\t\n",yytext);
			break;
		case 'f':
			printf("\t%s\t\t\tFunction\t\t\t\n",yytext);
			break;
		case 'm':
			printf("\t%s\t\t\tArray\t\t\t\n",yytext);
			break;
	}
	
}

int yywrap() {
	return 1;
}

