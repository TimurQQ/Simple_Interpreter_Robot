#include "AST.h"

long execute(Node* p);
extern Node* funcPtr[100];
extern Array* attachFunctions[100];
extern Array* arrays[100];
extern char isUsed[100];

void alloc_attaches(int id) {
	attachFunctions[id] = malloc(sizeof(Array));
	attachFunctions[id]->dimens = malloc(1 * sizeof(int));
	attachFunctions[id]->size = 1;
	attachFunctions[id]->n_dim = 1;
	attachFunctions[id]->dimens[0] = 1;
	attachFunctions[id]->functions = malloc(1 * sizeof(Node*));
	attachFunctions[id]->functions[0] = NULL;
}

void call_attach_functions(int id) {
	int i = 0;
	if (attachFunctions[id] == NULL) return;
	for (i = 0; i < attachFunctions[id]->size; ++i) {
		if (!isUsed[id]) {
			isUsed[id] = 1;
			execute(attachFunctions[id]->functions[i]);
			isUsed[id] = 0;
		}
	}
}

void detach(int id, Node* to_detach) {
	int i, index = 0;
	while (attachFunctions[id]->functions[index] != to_detach) {
		index++;
	}
	for (i = index; i < attachFunctions[id]->size - 1; ++i) {
		attachFunctions[id]->functions[i] = attachFunctions[id]->functions[i + 1];
	}
	int new_size = --(attachFunctions[id]->size);
	--(attachFunctions[id]->dimens[0]);
	if (new_size == 0)
		attachFunctions[id]->functions = NULL;
	else 
		attachFunctions[id]->functions = realloc(attachFunctions[id]->functions, new_size * sizeof(Node*));
}

void attach(int id, Node* to_attach) {
	int new_size = ++(attachFunctions[id]->size);
	++(attachFunctions[id]->dimens[0]);
	attachFunctions[id]->functions = realloc(attachFunctions[id]->functions, new_size * sizeof(Node*));
	attachFunctions[id]->functions[new_size - 1] = to_attach;
}

void alloc_array(int arr_id, ArrElemType type, int n_dim, Node** idxs) {
	int i, size = 1;
				
	for (i = 0; i < n_dim; ++i) {
		int idxsI = execute(idxs[i]);
		size *= (idxsI + 1);
	}
	arrays[arr_id] = malloc(sizeof(Array));
	arrays[arr_id]->dimens = malloc(n_dim * sizeof(int));
	arrays[arr_id]->size = size;
	arrays[arr_id]->n_dim = n_dim;
	for (i = 0; i < n_dim; ++i) {
		int idxsI = execute(idxs[i]);
		arrays[arr_id]->dimens[i] = idxsI + 1;
	}
	
	switch(type) {
		case IntElem: case BoolElem:
		{
			arrays[arr_id]->values = malloc(size * sizeof(int));
			
			for (i = 0; i < size; ++i) {
				arrays[arr_id]->values[i] = 0;
			}
			break;
		}
		case FuncElem:
		{
			arrays[arr_id]->functions = malloc(size * sizeof(Node*));
			for (i = 0; i < size; ++i) {
				arrays[arr_id]->functions[i] = NULL;
			}
			break;
		}
	}
}

void assign_arr_elem(Array* arr, int index, Node* operand_left, Node* operand_right) {
	switch (operand_left->arr.type) {
		case IntElem: case BoolElem:
		{
			arr->values[index] = execute(operand_right);
			break;
		}
		case FuncElem:
		{
			switch(operand_right->type) {
				case Operator:
					arr->functions[index] = operand_right;
					break;
				case Function:
					arr->functions[index] = funcPtr[operand_right->func.id];
					break;
				case ArrElem:
					arr->functions[index] = (Node*) execute(operand_right);
					break;
			}
			break;
		}
	}
}

long compare(Node* operand_left, Node* operand_right) {
	switch(operand_left->type) {
		case Function:
		{
			Node* funcPtr_1 = funcPtr[operand_left->func.id];
			switch(operand_right->type) {
				case Operator: return !funcPtr_1 || funcPtr_1->is_pass;
				case Function: 
				{
					Node* funcPtr_2 = funcPtr[operand_right->func.id];
					return funcPtr_1 == funcPtr_2;
				}
			}
		}
		case ArrElem:
		{
			switch(operand_left->arr.type) {
				case FuncElem:
				{
					Node* funcPtr_1 =  (Node*) execute(operand_left);
					switch(operand_right->type) {
						case Operator: return !funcPtr_1 || funcPtr_1->is_pass;
						case Function: 
						{
							Node* funcPtr_2 = funcPtr[operand_right->func.id];
							return funcPtr_1 == funcPtr_2;
						}
					}
				}
			}
			
		}
	}
	return execute(operand_left) == execute(operand_right);
}
