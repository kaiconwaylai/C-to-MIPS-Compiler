%code requires{
  #include "ast.hpp"

  #include <cassert>

  extern const NodePtr g_root; // A way of getting the AST out
  extern FILE *yyin;

  //! This is to fix problems when generating C++
  // We are declaring the functions provided by Flex, so
  // that Bison generated code can call them.
  int yylex(void);
  void yyerror(const char *);
}

// Represents the value associated with any kind of
// AST node.
%union{
  NodePtr expr;
  NodeListPtr exprList;
  long number;
  std::string *string;
  yytokentype token;
}

%token IDENTIFIER INT_LITERAL SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN

%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR INT SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR CONTINUE BREAK RETURN

%type <expr> primary_expression postfix_expression unary_expression
%type <expr> multiplicative_expression additive_expression shift_expression
%type <expr> relational_expression equality_expression and_expression
%type <expr> exclusive_or_expression inclusive_or_expression logical_and_expression
%type <expr> logical_or_expression conditional_expression assignment_expression
%type <expr> expression constant_expression

%type <expr> declaration init_declarator
%type <expr> declaration_specifiers type_specifier
%type <expr> struct_specifier struct_declaration
%type <expr> specifier_qualifier_list struct_declarator declarator
%type <expr> enum_specifier enumerator direct_declarator pointer

%type <expr> parameter_declaration type_name abstract_declarator direct_abstract_declarator
%type <expr> initializer statement labeled_statement compound_statement
%type <expr> expression_statement selection_statement iteration_statement
%type <expr> jump_statement translation_unit external_declaration function_definition

%type <exprList> argument_expression_list init_declarator_list struct_declaration_list
%type <exprList> specifier_qualifier_list struct_declarator_list
%type <exprList> enumerator_list parameter_list
%type <exprList> identifier_list initializer_list declaration_list statement_list

%type <number> INT_LITERAL
%type <string> IDENTIFIER

%type <token> unary_operator assignment_operator

%start translation_unit

%%

// Top level entity
translation_unit
	: external_declaration { $$ = $1; }
	| translation_unit external_declaration { std::cerr << "TODO, multiple funcitons" << std::endl; }
	;

// Global declaration
external_declaration
	: function_definition { $$ = $1; }
	| declaration { $$ = $1; }
	;

// Function definition (duh)
function_definition
	: declaration_specifiers declarator compound_statement { $$ = new FunctionDefinition(new Declaration($1, $2), $3); }
	| declarator compound_statement { std::cerr << "Function with no type?, probs for calling a void function?" << std::endl; }
	;

// Name of something (variable, function, array)
declarator
	: pointer direct_declarator { std::cerr << "deal with pointers later" << std::endl; }
	| direct_declarator { $$ = $1; }
	;

// Bunch of different types of names, see declarator
direct_declarator
	: IDENTIFIER { $$ = new Declarator(*$1); delete $1; };
	| '(' declarator ')' { $$ = $2; }
	| direct_declarator '[' constant_expression ']' { std::cerr << "Array declarator" << std::endl; }
	| direct_declarator '[' ']' { std::cerr << "Array declarator" << std::endl; }
	| direct_declarator '(' parameter_list ')' { $$ = new FunctionDeclarator($1, *$3); delete $3; }
	| direct_declarator '(' identifier_list ')' { $$ = new FunctionDeclarator($1, *$3); delete $3; }
	| direct_declarator '(' ')' { $$ = new FunctionDeclarator($1); }
	;

// Function input parameters
parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration
	;

parameter_declaration
	: declaration_specifiers declarator
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

declaration
	: declaration_specifiers ';' { $$ = new Declaration($1); }
	| declaration_specifiers init_declarator_list ';'
	;

// Type of something (+ typedef)
declaration_specifiers
	: TYPEDEF { std::cerr << "deal with this shit later" << std::endl; }
	| TYPEDEF declaration_specifiers { std::cerr << "Not needed afaik since we only support TYPEDEF" << std::endl; }
	| type_specifier { $$ = $1; }
	| type_specifier declaration_specifiers { std::cerr << "I don't think we need this either" << std::endl; }
	;

type_specifier
	: VOID
	| CHAR
	| INT { $$ = new PrimitiveType(PrimitiveType::Specifier::_int); }
	| FLOAT
	| DOUBLE
	| UNSIGNED
	| struct_specifier
	| enum_specifier
	;

// Pretty sure this isn't needed since comma seperated expressions aren't in the spec
init_declarator_list
	: init_declarator
	| init_declarator_list ',' init_declarator
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' constant_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' constant_expression ']'
	| '(' ')'
	| '(' parameter_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_list ')'
	;

declaration_list
	: declaration { /* initialze list */ }
	| declaration_list declaration { /* append to list */ }
	;

// Shit a function contains, (scope)
compound_statement
	: '{' '}' { $$ = new Scope(); }
	| '{' statement_list '}' { $$ = new Scope(*$2); delete $2; }
	| '{' declaration_list '}' { $$ = new Scope(*2); delete $2; }
	| '{' declaration_list statement_list '}' { std::cerr << "Think about this more" << std::endl; }
	;

statement_list
  : statement { /* initialze list */ }
	| statement_list statement { /* append to list */ }
	;

statement
	: labeled_statement { $$ = $1; } // Case
	| compound_statement { $$ = $1; } // New scope
	| expression_statement { $$ = $1; } // Simple shit
	| selection_statement	{ $$ = $1; } // if else switch
	| iteration_statement { $$ = $1; } // loops
	| jump_statement { $$ = $1; } // Continue / break / return
	;

// Case statements
labeled_statement
	: IDENTIFIER ':' statement
	| CASE constant_expression ':' statement
	| DEFAULT ':' statement
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: IF '(' expression ')' statement
	| IF '(' expression ')' statement ELSE statement
	| SWITCH '(' expression ')' statement
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| FOR '(' expression_statement expression_statement ')' statement
	| FOR '(' expression_statement expression_statement expression ')' statement
	;

jump_statement
	| CONTINUE ';' { std::cerr << "Extend AST" << std::endl; }
	| BREAK ';' { std::cerr << "Extend AST" << std::endl; }
	| RETURN ';' { $$ = new Return(); }
	| RETURN expression ';' { $$ = new Return($2); }
	;





primary_expression
  : IDENTIFIER { $$ = new Identifier(*$1); }
	| INT_LITERAL { $$ = new Integer($1); }
	| '(' expression ')' { $$ = $2; }
	;

postfix_expression
	: primary_expression { $$ = $1; }
	| postfix_expression '[' expression ']' { std::cerr << "element access (array)" << std::endl; }
	| postfix_expression '(' ')' { std::cerr << "Function call" << std::endl; }
	| postfix_expression '(' argument_expression_list ')' { std::cerr << "Function call" << std::endl; }
	| postfix_expression '.' IDENTIFIER { std::cerr << "member variable access" << std::endl; }
	| postfix_expression PTR_OP IDENTIFIER { std::cerr << "->" << std::endl; }
	| postfix_expression INC_OP { std::cerr << "Unsuported" << std::endl; }
	| postfix_expression DEC_OP { std::cerr << "Unsuported" << std::endl; }
	;

argument_expression_list
	: assignment_expression { std::cerr << "Unsuported" << std::endl; }
	| argument_expression_list ',' assignment_expression { std::cerr << "Unsuported" << std::endl; }
	;

unary_expression
	: postfix_expression { $$ = $1; }
	| INC_OP unary_expression { std::cerr << "Unsuported" << std::endl; }
	| DEC_OP unary_expression { std::cerr << "Unsuported" << std::endl; }
	| unary_operator unary_expression { std::cerr << "Unsuported" << std::endl; }
	| SIZEOF unary_expression { std::cerr << "Unsuported" << std::endl; }
	| SIZEOF '(' type_name ')' { std::cerr << "Unsuported" << std::endl; }
	;

unary_operator
	: '&' { std::cerr << "Unsuported" << std::endl; }
	| '*' { std::cerr << "Unsuported" << std::endl; }
	| '+' { std::cerr << "Unsuported" << std::endl; }
	| '-' { std::cerr << "Unsuported" << std::endl; }
	| '~' { std::cerr << "Unsuported" << std::endl; }
	| '!' { std::cerr << "Unsuported" << std::endl; }
	;

multiplicative_expression
	: unary_expression { $$ = $1; }
	| multiplicative_expression '*' unary_expression { std::cerr << "Unsuported" << std::endl; }
	| multiplicative_expression '/' unary_expression { std::cerr << "Unsuported" << std::endl; }
	| multiplicative_expression '%' unary_expression { std::cerr << "Unsuported" << std::endl; }
	;

additive_expression
	: multiplicative_expression { $$ = $1; }
	| additive_expression '+' multiplicative_expression { std::cerr << "Unsuported" << std::endl; }
	| additive_expression '-' multiplicative_expression { std::cerr << "Unsuported" << std::endl; }
	;

shift_expression
	: additive_expression {$$ = $1; }
	| shift_expression LEFT_OP additive_expression { std::cerr << "Unsuported" << std::endl; }
	| shift_expression RIGHT_OP additive_expression { std::cerr << "Unsuported" << std::endl; }
	;

relational_expression
	: shift_expression { $$ = $1; }
	| relational_expression '<' shift_expression { std::cerr << "Unsuported" << std::endl; }
	| relational_expression '>' shift_expression { std::cerr << "Unsuported" << std::endl; }
	| relational_expression LE_OP shift_expression { std::cerr << "Unsuported" << std::endl; }
	| relational_expression GE_OP shift_expression { std::cerr << "Unsuported" << std::endl; }
	;

equality_expression
	: relational_expression { $$ = $1; }
	| equality_expression EQ_OP relational_expression { std::cerr << "Unsuported" << std::endl; }
	| equality_expression NE_OP relational_expression { std::cerr << "Unsuported" << std::endl; }
	;

and_expression
	: equality_expression { $$ = $1; }
	| and_expression '&' equality_expression { std::cerr << "Unsuported" << std::endl; }
	;

exclusive_or_expression
	: and_expression { $$ = $1; }
	| exclusive_or_expression '^' and_expression { std::cerr << "Unsuported" << std::endl; }
	;

inclusive_or_expression
	: exclusive_or_expression { $$ = $1; }
	| inclusive_or_expression '|' exclusive_or_expression { std::cerr << "Unsuported" << std::endl; }
	;

logical_and_expression
	: inclusive_or_expression { $$ = $1; }
	| logical_and_expression AND_OP inclusive_or_expression { std::cerr << "Unsuported" << std::endl; }
	;

logical_or_expression
	: logical_and_expression { $$ = $1; }
	| logical_or_expression OR_OP logical_and_expression { std::cerr << "Unsuported" << std::endl; }
	;

conditional_expression
	: logical_or_expression { $$ = $1; }
	| logical_or_expression '?' expression ':' conditional_expression { std::cerr << "Unsuported" << std::endl; }
	;

assignment_expression
	: conditional_expression { $$ = $1; }
	| unary_expression assignment_operator assignment_expression { std::cerr << "Unsuported" << std::endl; }
	;

assignment_operator
	: '=' { std::cerr << "Unsuported" << std::endl; }
	| MUL_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| DIV_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| MOD_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| ADD_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| SUB_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| LEFT_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| RIGHT_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| AND_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| XOR_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	| OR_ASSIGN { std::cerr << "Unsuported" << std::endl; }
	;

expression
	: assignment_expression { $$ = $1; }
	| expression ',' assignment_expression { std::cerr << "Not assessed by spec (?)" << std::endl; }
	;

constant_expression
	: conditional_expression { $$ = $1; }
	;



init_declarator
	: declarator
	| declarator '=' initializer
	;



struct_specifier
	: STRUCT IDENTIFIER '{' struct_declaration_list '}'
	| STRUCT '{' struct_declaration_list '}'
	| STRUCT IDENTIFIER
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expression
	| declarator ':' constant_expression
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM IDENTIFIER
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression
	;





pointer
	: '*'
	| '*' pointer
	;





identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;



initializer
	: assignment_expression
	| '{' initializer_list '}'
	| '{' initializer_list ',' '}'
	;

initializer_list
	: initializer
	| initializer_list ',' initializer
	;

%%

NodePtr g_root;

NodePtr parseAST()
{
  g_root = 0;
  yyparse();
  return g_root;
}
