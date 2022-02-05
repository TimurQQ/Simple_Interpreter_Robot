%{	
	#include <stdio.h>
	#include <stdlib.h>
	#include <stdarg.h>
	#include <string.h>
	#include "include/AST.h"
	#include "include/BaseOperations.h"
	
	int H, W;
	
	#define size_x 10
	#define size_y 10
	
	int int_vars[100] = {};
	Node* ptpos[100] = {};
	Node* funcPtr[100] = {};
	Array* arrays[100] = {};
	Array* attachFunctions[100] = {};
	char isUsed[100] = {};
	
	int robot_pos_X = 0;
	int robot_pos_Y = 0;
	
	char map[size_x][size_y];
	
	FILE* pTreeFile;
	FILE* path;
	
	int yylex(void);
	
	void printTree(char* prefix, const Node* p, char isLeft);
	void printBT(const Node* node);
	void findRandomPoint(int* x,int* y);
	void writeStep(FILE* f_ptr);
	
	typedef enum {
		IF,
		WHILE,
		GOTO,
		EXEC
	} NT;
%}

%union {
	int value;                 /* integer value */
	int id;					/* integer id   */
	char* str;
	Node* node_ptr;             /* node pointer */
	Tuple* tuple_ptr;
};

%token<value> INT
%token<id> VAR POINT INT_ARR BOOL_ARR FUNC_ARR FUNC
%token<str> STR
%left EQ NOR
%token ASSIGN END ATTACH DETACH
%token DOUBLE_OPEN DOUBLE_CLOSE
%token MV_FRONT MV_BACK MV_LEFT MV_RIGHT TELEPORT
%right INC DEC
%token DEBUG MSG
%token PASS PLEASE
%nonassoc UMINUS

%start program
%type <node_ptr> statement expression statementList function variable identifier
%type <tuple_ptr> dimens
%%

program
	: sentences
		{
			printf("Input accepted\n"); exit(0);
		}
	;
sentences
	: statementList END
		{
			printf("\nstatementList -> sentences\n");
			path = fopen("path.solution", "w");
			writeStep(path);
			execute($1);
			pTreeFile = fopen("outTree.txt", "w");
			printBT($1);
			fprintf(path, "\n");
			fclose(pTreeFile);
			fclose(path);
			printf("\nTree has been build\n")
		}
	| /* NULL */
	;
function
	: FUNC
		{
			$$ = createFuncNode($1);
		}
	| FUNC_ARR ':' dimens
		{
			printf("\nFUNC_ARR : dimens -> function\n");
			$$ = createArrElemNode($1, FuncElem, $3);
		}
	;
variable
	: VAR
		{
			$$ = createVarNode($1);
		}
	| INT_ARR ':' dimens
		{
			printf("\nINT_ARR : dimens -> variable\n");
			$$ = createArrElemNode($1, IntElem, $3);
		}
	| BOOL_ARR ':' dimens
		{
			printf("\nBOOL_ARR : dimens -> variable\n");
			$$ = createArrElemNode($1, BoolElem, $3);
		}
	;
identifier
	: function
		{
			$$ = $1;
		}
	| variable
		{
			$$ = $1;
		}
statement
	: expression
		{
			printf("\n expression -> statement\n");
			$$ = $1;
		}
	| DEBUG expression
		{
			$$ = createOpNode(DEBUG, 1, $2);
		}
	| MSG STR
		{
			$$ = createOpNode(MSG, 1, createStrNode($2));
		}
	| function ASSIGN statement
		{
			$$ = createOpNode(ASSIGN, 2, $1, $3);
		}
	| function ASSIGN function
		{
			$$ = createOpNode(ASSIGN, 2, $1, $3);
		}
	| variable ASSIGN expression
		{
			printf("\nvariable ASSIGN expression -> statement\n");
			$$ = createOpNode(ASSIGN, 2, $1, $3);
		}
	| identifier ATTACH function
		{
			printf("\nidentifier ATTACH function -> statement\n");
			$$ = createOpNode(ATTACH, 2, $1, $3);
		}
	| identifier DETACH function
		{
			$$ = createOpNode(DETACH, 2, $1, $3);
		}
	| function '(' ')'
		{
			$$ = createOpNode(EXEC, 1, $1);
		}
	| DOUBLE_OPEN expression DOUBLE_CLOSE statement
		{
			$$ = createOpNode(IF, 2, $2, $4);
		}
	| DOUBLE_OPEN expression DOUBLE_CLOSE PLEASE POINT
		{
			$$ = createOpNode(GOTO, 2, $2, createPointNode($5));
		}
	| '(' expression ')' statement 
		{
			$$ = createOpNode(WHILE, 2, $2, $4);
		}
	| '{' statementList '}'
		{
			$$ = $2;
		}
	| POINT statementList
		{	
			$$ = createOpNode(POINT, 2, createPointNode($1), $2);
		}
	;
statementList
	: statement
		{
			printf("\nstatement -> statementList\n");
			$$ = $1;
		}
	| statementList statement
		{
			printf("\nstatementList statement -> statementList\n");
			$$ = createOpNode(EXEC, 2, $1, $2);
		}
	;
dimens
	: expression 
		{
			printf("\nexpresion -> dimens\n");
			$$ = malloc(sizeof(Tuple));
			$$->values = malloc(1 * sizeof(Node*));
			$$->values[0] = $1;
			$$->size = 1;
		}
	| dimens '-' expression
		{
			int length = $1->size;
			$$ = $1;
			$$->values = realloc($$->values, (length + 1) * sizeof(Node*));
			$$->values[length] = $3;
			($$->size)++;
			printf("\ndimens - expression -> dimens\n");
		}
	;
expression
	: INT
		{
			printf("\nINT -> expression\n");
			$$ = createConstantNode($1);
		}
	| identifier
		{
			$$ = $1;
		}
	| '-' expression %prec UMINUS
		{
			$$ = createOpNode(UMINUS, 1, $2);
		}
	| PASS
		{
			printf("\nPASS -> expression\n");
			$$ = createOpNode(PASS, 0);
		}
	| INC INT
		{
			$$ = createOpNode(INC, 1, createVarNode($2));
		}
	| DEC INT
		{
			printf("\nDEC INT -> expression\n");
			$$ = createOpNode(DEC, 1, createVarNode($2));
		}
	| MV_FRONT
		{
			$$ = createOpNode(MV_FRONT, 0);
		}
	| MV_BACK
		{
			$$ = createOpNode(MV_BACK, 0);
		}
	| MV_LEFT
		{
			$$ = createOpNode(MV_LEFT, 0);
		}
	| MV_RIGHT
		{
			$$ = createOpNode(MV_RIGHT, 0);
		}
	| TELEPORT
		{
			$$ = createOpNode(TELEPORT, 0);
		}
	| NOR expression
		{
			$$ = createOpNode(NOR, 1, $2);
		}
	| NOR expression expression
		{
			$$ = createOpNode(NOR, 2, $2, $3);
		}
	| expression EQ expression
		{
			$$ = createOpNode(EQ, 2, $1, $3);
		}
	| '(' expression ')'          
		{
			$$ = $2;
		}
	;
%%

long execute(Node* p) {
	if (!p) return 0;
	switch (p->type) {
	case Constant:  return p->constant.value;
	case Variable:  return int_vars[p->var.id];
	case Point: return p->ptpos.id;
	case Function:
		{
			int func_id = p->func.id;
			execute(funcPtr[func_id]);
			return 0L;
		}
	case ArrElem:
		{
			int i, arr_id = p->arr.id;
			int n_dim = p->arr.n_dim;
			if (arrays[arr_id] == NULL) {
				alloc_array(arr_id, p->arr.type, n_dim, p->arr.idxs);
			}
			Array* arr = arrays[arr_id];
			//compute index;
			int factor = 1;
			for (i = 0; i < arr->n_dim; ++i) {
				factor *= arr->dimens[i];
			}
			
			int index = 0;
			for (i = 0; i < n_dim; ++i) {
				factor /= arr->dimens[i];
				index += execute(p->arr.idxs[i]) * factor;
			}
			switch(p->arr.type) {
				case IntElem: case BoolElem:
					return (long)arrays[arr_id]->values[index];
				case FuncElem:
					return (long)arrays[arr_id]->functions[index];
			}
		}
	case Operator:
		switch (p->op.id) {
		case WHILE:
		{
			while (execute(p->op.operands[0]))
				execute(p->op.operands[1]);
			return 0L;
		}
		case IF:
		{
			if (execute(p->op.operands[0]))
				execute(p->op.operands[1]);
			return 0L;
		}
		case POINT:
		{
			execute(ptpos[p->op.operands[0]->ptpos.id] = p->op.operands[1]);
			return 0L;
		}
		case NOR:
		{
			switch(p->op.noperands) {
				case 1: return !execute(p->op.operands[0]);
				case 2: return !execute(p->op.operands[0]) && !execute(p->op.operands[1]);
			}
		}
		case GOTO:
		{
			if (execute(p->op.operands[0])) {
				execute(ptpos[execute(p->op.operands[1])]);
				return -1L;
			}
			return 0L;
		}
		case UMINUS:
		{
			return -execute(p->op.operands[0]);
		}
		case DEBUG:
		{
			switch(p->op.operands[0]->type) {
				case ArrElem: call_attach_functions(p->op.operands[0]->arr.id); break;
				case Variable: call_attach_functions(p->op.operands[0]->var.id); break;
				case Function: call_attach_functions(p->op.operands[0]->func.id); break;
			}
			
			printf("DEBUG:%ld\n", execute(p->op.operands[0]));
			return 0L;
		}
		case INC:
		{
			call_attach_functions(p->op.operands[0]->var.id);
			++(int_vars[p->op.operands[0]->var.id]);
			return 0L;
		}
		case DEC:
		{
			call_attach_functions(p->op.operands[0]->var.id);
			--(int_vars[p->op.operands[0]->var.id]);
			return 0L;
		}
		case MV_FRONT:
			{	
				printf("Current x_pos: %d\n", robot_pos_X);
				if (robot_pos_X > 0 && map[robot_pos_X - 1][robot_pos_Y] != 'X') {
					map[robot_pos_X][robot_pos_Y] = '1';
					robot_pos_X--;
					map[robot_pos_X][robot_pos_Y] = 'R';
					writeStep(path);
					return 1L;
				}
				return 0L;
			}
		case MV_BACK:
			{
				printf("Current x_pos: %d\n", robot_pos_X);
				if (robot_pos_X < H - 1 && map[robot_pos_X + 1][robot_pos_Y] != 'X') {
					map[robot_pos_X][robot_pos_Y] = '1';
					robot_pos_X++;
					map[robot_pos_X][robot_pos_Y] = 'R';
					writeStep(path);
					return 1L;
				}
				return 0L;
			}
		case MV_LEFT:
			{
				if (robot_pos_Y > 0 && map[robot_pos_X][robot_pos_Y - 1] != 'X') {
					map[robot_pos_X][robot_pos_Y] = '1';
					robot_pos_Y--;
					map[robot_pos_X][robot_pos_Y] = 'R';
					writeStep(path);
					return 1L;
				}
				return 0L;
			}
		case MV_RIGHT:
			{
				if (robot_pos_Y < W - 1 && map[robot_pos_X][robot_pos_Y + 1] != 'X') {
					map[robot_pos_X][robot_pos_Y] = '1';
					robot_pos_Y++;
					map[robot_pos_X][robot_pos_Y] = 'R';
					writeStep(path);
					return 1L;
				}
				return 0L;
			}
		case TELEPORT:
			{
				int x, y;
				findRandomPoint(&x, &y);
				if (x != -1 && y != -1) {
					map[robot_pos_X][robot_pos_Y] = '1';
					robot_pos_X = x;
					robot_pos_Y = y;
					map[x][y] = 'R';
					writeStep(path);
					printf("\nROBOT HAS BEEN TELEPORTED TO: %d %d\n", x, y);
					return 1L;
				}
				return 0L;
			}
		case PASS:
		{
			return 0L;
		}
		case MSG:
		{	
			printf("\nMESSAGE: %s\n", p->op.operands[0]->str.value);
			return 0L;
		}
		case EXEC:
		{
			switch(p->op.noperands) {
				case 1:
				{
					switch(p->op.operands[0]->type) {
						case ArrElem:
						{
							Node* funcPtr = (Node*) execute(p->op.operands[0]);
							execute(funcPtr);
							return 0L;
						}
						default:
							return execute(p->op.operands[0]);
					}
				}
				case 2:
				{
					if (execute(p->op.operands[0]) >= 0L && execute(p->op.operands[1]) >= 0L) {
						return 0L;
					} else {
						return -1L;
					}
				}
			}
		}
		case ATTACH:
		{
			int Id;
			switch(p->op.operands[0]->type) {
				case ArrElem: Id = p->op.operands[0]->arr.id; break;
				case Variable: Id = p->op.operands[0]->var.id; break;
				case Function: Id = p->op.operands[0]->func.id; break;
			}
			printf("\nATTACH\n");
			if (attachFunctions[Id] == NULL) {
				alloc_attaches(Id);
				attachFunctions[Id]->functions[0] = p->op.operands[1];
				printf("\n%p\n", attachFunctions[Id]->functions[0]);
				return 0L;
			}
			attach(Id, funcPtr[p->op.operands[1]->func.id]);
			return 0L;
		}
		case DETACH:
		{
			int Id;
			switch(p->op.operands[0]->type) {
				case ArrElem: Id = p->op.operands[0]->arr.id; break;
				case Variable: Id = p->op.operands[0]->var.id; break;
				case Function: Id = p->op.operands[0]->func.id; break;
			}
			detach(Id, funcPtr[p->op.operands[1]->func.id]);
			return 0L;
		}
		case ASSIGN:
			switch(p->op.operands[0]->type) {
				case Variable: 
				{
					int_vars[p->op.operands[0]->var.id] = execute(p->op.operands[1]);
					return 0L;
				}
				case Function:
				{	
					int funcId = p->op.operands[0]->func.id;
					switch(p->op.operands[1]->type) {
						case Operator: funcPtr[funcId] = p->op.operands[1]; break;
						case Function: funcPtr[funcId] = funcPtr[p->op.operands[1]->func.id]; break;
					}
					return 0L;
				}
				case ArrElem:
				{
					int index = 0, i = 0;
					int arr_id = p->op.operands[0]->arr.id;
					int n_dim = p->op.operands[0]->arr.n_dim;
					Array* arr = arrays[arr_id];
					int factor = 1;
					for (i = 0; i < arr->n_dim; ++i) {
						factor *= arr->dimens[i];
					}
					
					for (i = 0; i < n_dim; ++i) {
						factor /= arr->dimens[i];
						index += execute(p->op.operands[0]->arr.idxs[i]) * factor;
					}
					
					assign_arr_elem(arr, index, p->op.operands[0], p->op.operands[1]);
					
					return 0L;
				}
			}
		case EQ:
			{
				return compare(p->op.operands[0], p->op.operands[1]);
			}
		}
	}
	return 0L;
}

void printTree(char* prefix, const Node* p, char isLeft)
{
    if( p != NULL )
    {
        fprintf(pTreeFile, "%s", prefix);
		char* newPrefix = malloc(strlen(prefix) + 5);
		memcpy(newPrefix, prefix, strlen(prefix));
		if (isLeft) {
			fprintf(pTreeFile,"|--");
			memcpy(newPrefix + strlen(prefix), "|   ", 5);
		} else {
			fprintf(pTreeFile, "\\__");
			memcpy(newPrefix + strlen(prefix), "    ", 5);
		}
		
		char *s;
		int nops = 0;
		char word[20];
		strcpy (word, "???");
		s = word;
		switch (p->type) {
			case Constant: sprintf(word, "c(%d)", p->constant.value); break;
			case Variable: sprintf(word, "id(%d)", p->var.id); break;
			case Point: sprintf(word, "pt(%d)", p->ptpos.id); break;
			case Function: sprintf(word, "func(id:%d)", p->func.id); break;
			case String: sprintf(word, "%s", p->str.value); break;
			case ArrElem:
			{
				int i = 0, j = 0;
				j = sprintf(word, "arr(%d)[%ld", p->arr.id, execute(p->arr.idxs[0]));
				for (i = 1; i < p->arr.n_dim; ++i) {
					j += sprintf(word + j, "-%ld", execute(p->arr.idxs[i]));
				}
				sprintf(word + j, "]");
				break;
			}
			case Operator:
				nops = p->op.noperands;
				switch (p->op.id) {
					case WHILE: s = "while"; break;
					case IF: s = "if"; break;
					case EXEC: s = "[exec]"; break;
					case GOTO: s = "[goto]"; break;
					case ASSIGN: s = "[<-]"; break;
					case EQ: s = "[eq]"; break;
					case INC: s = "[inc]"; break;
					case DEC: s = "[dec]"; break;
					case ATTACH: s = "[attach]"; break;
					case MSG: s = "[msg]"; break;
					case DETACH: s = "[detach]"; break;
					case MV_FRONT: s = "[mf]"; break;
					case MV_BACK: s = "[mb]"; break;
					case MV_LEFT: s = "[ml]"; break;
					case MV_RIGHT: s = "[mr]"; break;
					case TELEPORT: s = "[tp]"; break;
					case NOR: s = "[nor]"; break;
					case UMINUS: s = "[uminus]"; break;
					case PASS: s = "[pass]"; break;
					case DEBUG: s = "[print]"; break;
					case POINT: s = "[createPt]"; break;
				}
				break;
		}
		switch(nops) {
			case 0:
				fprintf(pTreeFile, "%s\n", s);
				break;
			case 1:
				fprintf(pTreeFile, "%s\n", s);
				printTree( newPrefix, p->op.operands[0], 1);
				break;
			case 2:
				fprintf(pTreeFile, "%s\n", s);
				printTree( newPrefix, p->op.operands[0], 1);
				printTree( newPrefix, p->op.operands[1], 0);
				break;
		}
    }
}

void findRandomPoint(int* x,int* y) {
	for (int i = 0; i < H; ++i) {
		for (int j = 0; j < W; ++j) {
			if (map[i][j] == '0') {
				*x = i;
				*y = j;
				return;
			}
		}
	}
	*x = *y = -1;
}

void writeStep(FILE* f_ptr) {
	fprintf(f_ptr, "%s", "\n\n");
	for (int i = 0; i < H; ++i) {
		for (int j = 0; j < W; ++j) {
			fprintf(f_ptr, "%c", map[i][j]);
		}
		fprintf(f_ptr, "\n");
	}
}

void printBT(const Node* node)
{
	char* prefix = malloc(1);
	prefix[0] = '\0';
    printTree(prefix, node, 0);    
}

void yyerror(char* s) {
	fprintf(stdout, "%s\n", s);
}

#include "lex.yy.c"

int main(int argc, char* argv[])
{
	if (argc > 2)// если передаем аргументы, то argc будет больше 1(в зависимости от кол-ва аргументов)
	{
		if (strcmp(argv[1], "--graphics") == 0) {
			FILE* file = fopen(argv[2], "r");
			fscanf(file, "%d", &H);
			fscanf(file, "%d", &W);
			
			printf("H:%d, W:%d", H, W);
			fgetc(file);
			for (int i = 0; i < H; ++i) {
				fgetc(file);
				for (int j = 0; j < W; ++j) {
					fscanf(file, "%c", &(map[i][j]));
				}
				fgetc(file);
			}
			fclose(file);
			
			for (int i = 0; i < H; ++i) {
				for (int j = 0; j < W; ++j) {
					if (map[i][j] == 'R') {
						robot_pos_X = i;
						robot_pos_Y = j;
					}
				}
			}
			printf("coords: %d %d", robot_pos_X, robot_pos_Y);
		}
	}
	yyparse();
	return 0;
}
