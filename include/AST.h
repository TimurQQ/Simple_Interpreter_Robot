#ifndef AST_H_INLUDED
#define AST_H_INLUDED

void yyerror(char* s);

typedef enum {
	Constant,
	Variable,
	Operator,
	Point,
	ArrElem,
	Function,
	String
} NodeType;

typedef enum {
	IntElem,
	BoolElem,
	FuncElem
} ArrElemType;

typedef struct {
	int value;
} ConstantNode;

typedef struct {
	int id;
} VarNode;

typedef struct {
	char* value;
} StrNode;

typedef struct {
	int id;
	int noperands;
	struct Node *operands[1];
} OpNode;

typedef struct {
	int id;
} PointNode;

typedef struct {
	ArrElemType type;
	int id;
	int n_dim;
	struct Node** idxs;
} ArrElemNode;

typedef struct {
	int id;
} FuncNode;

typedef struct {
	struct Node** values;
	int size;
} Tuple;

typedef struct {
	ArrElemType type;
	int* dimens;
	int size;
	int n_dim;
	union {
		int* values;
		struct Node** functions;
	};
} Array;

typedef struct Node {
	NodeType type;
	char is_pass;
	char has_goto;
	int attaches_count;

	union {
		ConstantNode constant;
		VarNode var;
		OpNode op;
		PointNode ptpos;
		ArrElemNode arr;
		FuncNode func;
		StrNode str;
	};
} Node;

Node* createConstantNode(int value) {
	Node* p;

	if ((p = malloc(sizeof(Node))) == NULL)
		yyerror("out of memory");

	p->type = Constant;
	p->is_pass = 0;
	p->attaches_count = 0;
	p->constant.value = value;
	return p;
}

Node* createStrNode(char* s) {
	Node* p;
	
	if ((p = malloc(sizeof(Node))) == NULL)
		yyerror("out of memory");
	
	int len = strlen(s);
	p->type = String;
	p->is_pass = 0;
	p->attaches_count = 0;
	p->str.value = malloc((len + 1) * sizeof(char));
	memcpy(p->str.value, s, len);
	p->str.value[len] = '\0';
	return p;
}

Node* createPointNode(int value) {
	Node* p;
	
	if ((p = malloc(sizeof(Node))) == NULL)
		yyerror("out of memory");
		
	p->type = Point;
	p->is_pass = 0;
	p->attaches_count = 0;
	p->ptpos.id = value;
	return p;
}

Node* createArrElemNode(int value, ArrElemType type, Tuple* dimens) {
	Node* p;
	int n_dim = dimens->size;
	
	if (
		(p = malloc(sizeof(Node))
		) == NULL)
		yyerror("out of memory");
	
	p->arr.idxs = malloc(n_dim * sizeof(int));
	p->type = ArrElem;
	p->arr.type = type;
	p->is_pass = 0;
	p->attaches_count = 0;
	p->arr.id = value;
	p->arr.n_dim = n_dim;
	memcpy(p->arr.idxs, dimens->values, n_dim * sizeof(Node*));
	return p;
}

Node* createFuncNode(int id) {
	Node* p;

	if ((p = malloc(sizeof(Node))) == NULL)
		yyerror("out of memory");

	p->type = Function;
	p->is_pass = 0;
	p->attaches_count = 0;
	p->func.id = id;
	return p;
}

Node* createVarNode(int id) {
	Node* p;

	if ((p = malloc(sizeof(Node))) == NULL)
		yyerror("out of memory");

	p->type = Variable;
	p->is_pass = 0;
	p->attaches_count = 0;
	p->var.id = id;
	return p;
}

Node* createOpNode(int opType, int noperands, ...) {

	va_list ap;
	Node* p;
	int i;
	
	if ((p = malloc(sizeof(Node) + (noperands - 1) * sizeof(Node*))) == NULL)
		yyerror("out of memory");

	p->type = Operator;
	p->op.id = opType;
	p->is_pass = 1;
	p->attaches_count = 0;
	p->op.noperands = noperands;
	va_start(ap, noperands);
	for (i = 0; i < noperands; i++) {
		p->op.operands[i] = va_arg(ap, Node*);
		p->is_pass = p->is_pass && p->op.operands[i]->is_pass;
	}

	va_end(ap);
	return p;
}
#endif // AST_H_INLUDED
