%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <assert.h>

#include "asn1parser.h"

#define YYPARSE_PARAM	param
#define YYERROR_VERBOSE

int yylex(void);
int yyerror(const char *msg);
void asn1p_lexer_hack_push_opaque_state(void);
void asn1p_lexer_hack_enable_with_syntax(void);
#define	yylineno	asn1p_lineno
extern int asn1p_lineno;


static asn1p_value_t *
	_convert_bitstring2binary(char *str, int base);

#define	checkmem(ptr)	do {				\
		if(!(ptr))				\
		return yyerror("Memory failure");	\
	} while(0)

#define	CONSTRAINT_INSERT(root, constr_type, arg1, arg2) do {	\
		if(arg1->type != constr_type) {			\
			int __ret;				\
			root = asn1p_constraint_new(yylineno);	\
			checkmem(root);				\
			root->type = constr_type;		\
			__ret = asn1p_constraint_insert(root,	\
				arg1);				\
			checkmem(__ret == 0);			\
		} else {					\
			root = arg1;				\
		}						\
		if(arg2) {					\
			int __ret				\
			= asn1p_constraint_insert(root, arg2);	\
			checkmem(__ret == 0);			\
		}						\
	} while(0)

%}


/*
 * Token value definition.
 * a_*:   ASN-specific types.
 * tv_*:  Locally meaningful types.
 */
%union {
	asn1p_t			*a_grammar;
	asn1p_module_flags_e	 a_module_flags;
	asn1p_module_t		*a_module;
	asn1p_expr_type_e	 a_type;	/* ASN.1 Type */
	asn1p_expr_t		*a_expr;	/* Constructed collection */
	asn1p_constraint_t	*a_constr;	/* Constraint */
	enum asn1p_constraint_type_e	a_ctype;/* Constraint type */
	asn1p_xports_t		*a_xports;	/* IMports/EXports */
	asn1p_oid_t		*a_oid;		/* Object Identifier */
	asn1p_oid_arc_t		 a_oid_arc;	/* Single OID's arc */
	struct asn1p_type_tag_s	 a_tag;		/* A tag */
	asn1p_ref_t		*a_ref;		/* Reference to custom type */
	asn1p_wsyntx_t		*a_wsynt;	/* WITH SYNTAX contents */
	asn1p_wsyntx_chunk_t	*a_wchunk;	/* WITH SYNTAX chunk */
	struct asn1p_ref_component_s a_refcomp;	/* Component of a reference */
	asn1p_value_t		*a_value;	/* Number, DefinedValue, etc */
	struct asn1p_param_s	 a_parg;	/* A parameter argument */
	asn1p_paramlist_t	*a_plist;	/* A pargs list */
	enum asn1p_expr_marker_e a_marker;	/* OPTIONAL/DEFAULT */
	enum asn1p_constr_pres_e a_pres;	/* PRESENT/ABSENT/OPTIONAL */
	asn1_integer_t		 a_int;
	char	*tv_str;
	struct {
		char *buf;
		int len;
	}	tv_opaque;
	struct {
		char *name;
		struct asn1p_type_tag_s tag;
	} tv_nametag;
};

/*
 * Token types returned by scanner.
 */
%token			TOK_PPEQ	/* "::=", Pseudo Pascal EQuality */
%token	<tv_opaque>	TOK_opaque	/* opaque data (driven from .y) */
%token	<tv_str>	TOK_bstring
%token	<tv_opaque>	TOK_cstring
%token	<tv_str>	TOK_hstring
%token	<tv_str>	TOK_identifier
%token	<a_int>		TOK_number
%token	<a_int>		TOK_number_negative
%token	<tv_str>	TOK_typereference
%token	<tv_str>	TOK_objectclassreference	/* "CLASS1" */
%token	<tv_str>	TOK_typefieldreference		/* "&Pork" */
%token	<tv_str>	TOK_valuefieldreference		/* "&id" */

/*
 * Token types representing ASN.1 standard keywords.
 */
%token			TOK_ABSENT
%token			TOK_ABSTRACT_SYNTAX
%token			TOK_ALL
%token			TOK_ANY
%token			TOK_APPLICATION
%token			TOK_AUTOMATIC
%token			TOK_BEGIN
%token			TOK_BIT
%token			TOK_BMPString
%token			TOK_BOOLEAN
%token			TOK_BY
%token			TOK_CHARACTER
%token			TOK_CHOICE
%token			TOK_CLASS
%token			TOK_COMPONENT
%token			TOK_COMPONENTS
%token			TOK_CONSTRAINED
%token			TOK_CONTAINING
%token			TOK_DEFAULT
%token			TOK_DEFINITIONS
%token			TOK_DEFINED
%token			TOK_EMBEDDED
%token			TOK_ENCODED
%token			TOK_END
%token			TOK_ENUMERATED
%token			TOK_EXPLICIT
%token			TOK_EXPORTS
%token			TOK_EXTENSIBILITY
%token			TOK_EXTERNAL
%token			TOK_FALSE
%token			TOK_FROM
%token			TOK_GeneralizedTime
%token			TOK_GeneralString
%token			TOK_GraphicString
%token			TOK_IA5String
%token			TOK_IDENTIFIER
%token			TOK_IMPLICIT
%token			TOK_IMPLIED
%token			TOK_IMPORTS
%token			TOK_INCLUDES
%token			TOK_INSTANCE
%token			TOK_INTEGER
%token			TOK_ISO646String
%token			TOK_MAX
%token			TOK_MIN
%token			TOK_MINUS_INFINITY
%token			TOK_NULL
%token			TOK_NumericString
%token			TOK_OBJECT
%token			TOK_ObjectDescriptor
%token			TOK_OCTET
%token			TOK_OF
%token			TOK_OPTIONAL
%token			TOK_PATTERN
%token			TOK_PDV
%token			TOK_PLUS_INFINITY
%token			TOK_PRESENT
%token			TOK_PrintableString
%token			TOK_PRIVATE
%token			TOK_REAL
%token			TOK_RELATIVE_OID
%token			TOK_SEQUENCE
%token			TOK_SET
%token			TOK_SIZE
%token			TOK_STRING
%token			TOK_SYNTAX
%token			TOK_T61String
%token			TOK_TAGS
%token			TOK_TeletexString
%token			TOK_TRUE
%token			TOK_TYPE_IDENTIFIER
%token			TOK_UNIQUE
%token			TOK_UNIVERSAL
%token			TOK_UniversalString
%token			TOK_UTCTime
%token			TOK_UTF8String
%token			TOK_VideotexString
%token			TOK_VisibleString
%token			TOK_WITH

%left			'|' TOK_UNION
%left			'^' TOK_INTERSECTION
%left			TOK_EXCEPT

/* Misc tags */
%token			TOK_TwoDots		/* .. */
%token			TOK_ThreeDots		/* ... */
%token	<a_tag>		TOK_tag			/* [0] */


/*
 * Types defined herein.
 */
%type	<a_grammar>		ModuleList
%type	<a_module>		ModuleSpecification
%type	<a_module>		ModuleSpecificationBody
%type	<a_module>		ModuleSpecificationElement
%type	<a_module>		optModuleSpecificationBody	/* Optional */
%type	<a_module_flags>	optModuleSpecificationFlags
%type	<a_module_flags>	ModuleSpecificationFlags	/* Set of FL */
%type	<a_module_flags>	ModuleSpecificationFlag		/* Single FL */
%type	<a_module>		ImportsDefinition
%type	<a_module>		ImportsBundleSet
%type	<a_xports>		ImportsBundle
%type	<a_xports>		ImportsList
%type	<a_xports>		ExportsDefinition
%type	<a_xports>		ExportsBody
%type	<a_expr>		ImportsElement
%type	<a_expr>		ExportsElement
%type	<a_expr>		DataTypeMember
%type	<a_expr>		ExtensionAndException
%type	<a_expr>		TypeDeclaration
%type	<a_ref>			ComplexTypeReference
%type	<a_ref>			ComplexTypeReferenceAmpList
%type	<a_refcomp>		ComplexTypeReferenceElement
%type	<a_refcomp>		ClassFieldIdentifier
%type	<a_refcomp>		ClassFieldName
%type	<a_expr>		ClassFieldList
%type	<a_expr>		ClassField
%type	<a_expr>		ClassDeclaration
%type	<a_expr>		ConstrainedTypeDeclaration
%type	<a_expr>		DataTypeReference	/* Type1 ::= Type2 */
%type	<a_expr>		DefinedTypeRef
%type	<a_expr>		ValueSetDefinition  /* Val INTEGER ::= {1|2} */
%type	<a_expr>		ValueDefinition		/* val INTEGER ::= 1*/
%type	<a_value>		optValueSetBody
%type	<a_value>		InlineOrDefinedValue
%type	<a_value>		DefinedValue
%type	<a_value>		SignedNumber
%type	<a_expr>		ConstructedType
%type	<a_expr>		ConstructedDataTypeDefinition
//%type	<a_expr>		optUniverationDefinition
%type	<a_expr>		UniverationDefinition
%type	<a_expr>		UniverationList
%type	<a_expr>		UniverationElement
%type	<tv_str>		TypeRefName
%type	<tv_str>		ObjectClassReference
%type	<tv_nametag>		TaggedIdentifier
%type	<tv_str>		Identifier
%type	<a_parg>		ParameterArgumentName
%type	<a_plist>		ParameterArgumentList
%type	<a_expr>		ActualParameter
%type	<a_expr>		ActualParameterList
%type	<a_oid>			ObjectIdentifier	/* OID */
%type	<a_oid>			optObjectIdentifier	/* Optional OID */
%type	<a_oid>			ObjectIdentifierBody
%type	<a_oid_arc>		ObjectIdentifierElement
%type	<a_expr>		BasicType
%type	<a_type>		BasicTypeId
%type	<a_type>		BasicTypeId_UniverationCompatible
%type	<a_type>		BasicString
%type	<tv_opaque>		Opaque
//%type	<tv_opaque>		StringValue
%type	<a_tag>			Tag		/* [UNIVERSAL 0] IMPLICIT */
%type	<a_tag>			optTag		/* [UNIVERSAL 0] IMPLICIT */
%type	<a_constr>		optConstraints
%type	<a_constr>		Constraints
%type	<a_constr>		SingleConstraint	/* (SIZE(2)) */
%type	<a_constr>		ConstraintElementSet	/* 1..2,...,3 */
%type	<a_constr>		ConstraintSubtypeElement /* 1..2 */
%type	<a_constr>		ConstraintElementIntersection
%type	<a_constr>		ConstraintElementException
%type	<a_constr>		ConstraintElementUnion
%type	<a_constr>		ConstraintElement
%type	<a_constr>		SimpleTableConstraint
%type	<a_constr>		TableConstraint
%type	<a_constr>		WithComponents
%type	<a_constr>		WithComponentsList
%type	<a_constr>		WithComponentsElement
%type	<a_constr>		ComponentRelationConstraint
%type	<a_constr>		AtNotationList
%type	<a_ref>			AtNotationElement
%type	<a_value>		ConstraintValue
%type	<a_ctype>		ConstraintSpec
%type	<a_ctype>		ConstraintRangeSpec
%type	<a_wsynt>		optWithSyntax
%type	<a_wsynt>		WithSyntax
%type	<a_wsynt>		WithSyntaxFormat
%type	<a_wchunk>		WithSyntaxFormatToken
%type	<a_marker>		optMarker Marker
%type	<a_int>			optUnique
%type	<a_pres>		optPresenceConstraint PresenceConstraint
%type	<tv_str>		ComponentIdList


%%


ParsedGrammar:
	ModuleList {
		*(void **)param = $1;
	}
	;

ModuleList:
	ModuleSpecification {
		$$ = asn1p_new();
		checkmem($$);
		TQ_ADD(&($$->modules), $1, mod_next);
	}
	| ModuleList ModuleSpecification {
		$$ = $1;
		TQ_ADD(&($$->modules), $2, mod_next);
	}
	;

/*
 * ASN module definition.
 * === EXAMPLE ===
 * MySyntax DEFINITIONS AUTOMATIC TAGS ::=
 * BEGIN
 * ...
 * END 
 * === EOF ===
 */

ModuleSpecification:
	TypeRefName optObjectIdentifier TOK_DEFINITIONS
		optModuleSpecificationFlags
		TOK_PPEQ TOK_BEGIN
		optModuleSpecificationBody
		TOK_END {

		if($7) {
			$$ = $7;
		} else {
			/* There's a chance that a module is just plain empty */
			$$ = asn1p_module_new();
		}
		checkmem($$);

		$$->Identifier = $1;
		$$->module_oid = $2;
		$$->module_flags = $4;
	}
	;

/*
 * Object Identifier Definition
 * { iso member-body(2) 3 }
 */
optObjectIdentifier:
	{ $$ = 0; }
	| ObjectIdentifier { $$ = $1; }
	;
	
ObjectIdentifier:
	'{' ObjectIdentifierBody '}' {
		$$ = $2;
	}
	| '{' '}' {
		$$ = 0;
	}
	;

ObjectIdentifierBody:
	ObjectIdentifierElement {
		$$ = asn1p_oid_new();
		asn1p_oid_add_arc($$, &$1);
		if($1.name)
			free($1.name);
	}
	| ObjectIdentifierBody ObjectIdentifierElement {
		$$ = $1;
		asn1p_oid_add_arc($$, &$2);
		if($2.name)
			free($2.name);
	}
	;

ObjectIdentifierElement:
	Identifier {					/* iso */
		$$.name = $1;
		$$.number = -1;
	}
	| Identifier '(' TOK_number ')' {		/* iso(1) */
		$$.name = $1;
		$$.number = $3;
	}
	| TOK_number {					/* 1 */
		$$.name = 0;
		$$.number = $1;
	}
	;
	
/*
 * Optional module flags.
 */
optModuleSpecificationFlags:
	{ $$ = MSF_NOFLAGS; }
	| ModuleSpecificationFlags {
		$$ = $1;
	}
	;

/*
 * Module flags.
 */
ModuleSpecificationFlags:
	ModuleSpecificationFlag {
		$$ = $1;
	}
	| ModuleSpecificationFlags ModuleSpecificationFlag {
		$$ = $1 | $2;
	}
	;

/*
 * Single module flag.
 */
ModuleSpecificationFlag:
	TOK_EXPLICIT TOK_TAGS {
		$$ = MSF_EXPLICIT_TAGS;
	}
	| TOK_IMPLICIT TOK_TAGS {
		$$ = MSF_IMPLICIT_TAGS;
	}
	| TOK_AUTOMATIC TOK_TAGS {
		$$ = MSF_AUTOMATIC_TAGS;
	}
	| TOK_EXTENSIBILITY TOK_IMPLIED {
		$$ = MSF_EXTENSIBILITY_IMPLIED;
	}
	;

/*
 * Optional module body.
 */
optModuleSpecificationBody:
	{ $$ = 0; }
	| ModuleSpecificationBody {
		assert($1);
		$$ = $1;
	}
	;

/*
 * ASN.1 Module body.
 */
ModuleSpecificationBody:
	ModuleSpecificationElement {
		$$ = $1;
	}
	| ModuleSpecificationBody ModuleSpecificationElement {
		$$ = $1;

#ifdef	MY_IMPORT
#error	MY_IMPORT DEFINED ELSEWHERE!
#endif
#define	MY_IMPORT(foo,field)	do {				\
		if(TQ_FIRST(&($2->foo))) {			\
			TQ_ADD(&($$->foo),			\
				TQ_REMOVE(&($2->foo), field),	\
				field);				\
			assert(TQ_FIRST(&($2->foo)) == 0);	\
		} } while(0)

		MY_IMPORT(imports, xp_next);
		MY_IMPORT(exports, xp_next);
		MY_IMPORT(members, next);
#undef	MY_IMPORT

	}
	;

/*
 * One of the elements of ASN.1 module specification.
 */
ModuleSpecificationElement:
	ImportsDefinition {
		$$ = $1;
	}
	| ExportsDefinition {
		$$ = asn1p_module_new();
		checkmem($$);
		if($1) {
			TQ_ADD(&($$->exports), $1, xp_next);
		} else {
			/* "EXPORTS ALL;" ? */
		}
	}
	| DataTypeReference {
		$$ = asn1p_module_new();
		checkmem($$);
		assert($1->expr_type != A1TC_INVALID);
		assert($1->meta_type != AMT_INVALID);
		TQ_ADD(&($$->members), $1, next);
	}
	| ValueDefinition {
		$$ = asn1p_module_new();
		checkmem($$);
		assert($1->expr_type != A1TC_INVALID);
		assert($1->meta_type != AMT_INVALID);
		TQ_ADD(&($$->members), $1, next);
	}
	/*
	 * Value set definition
	 * === EXAMPLE ===
	 * EvenNumbers INTEGER ::= { 2 | 4 | 6 | 8 }
	 * === EOF ===
	 */
	| ValueSetDefinition {
		$$ = asn1p_module_new();
		checkmem($$);
		assert($1->expr_type != A1TC_INVALID);
		assert($1->meta_type != AMT_INVALID);
		TQ_ADD(&($$->members), $1, next);
	}

	/*
	 * Erroneous attemps
	 */
	| BasicString {
		return yyerror(
			"Attempt to redefine a standard basic type, "
			"use -ftypesXY to switch back "
			"to older version of ASN.1 standard");
	}
	;

/*
 * === EXAMPLE ===
 * IMPORTS Type1, value FROM Module { iso standard(0) } ;
 * === EOF ===
 */
ImportsDefinition:
	TOK_IMPORTS ImportsBundleSet ';' {
		$$ = $2;
	}
	/*
	 * Some error cases.
	 */
	| TOK_IMPORTS TOK_FROM /* ... */ {
		return yyerror("Empty IMPORTS list");
	}
	;

ImportsBundleSet:
	ImportsBundle {
		$$ = asn1p_module_new();
		checkmem($$);
		TQ_ADD(&($$->imports), $1, xp_next);
	}
	| ImportsBundleSet ImportsBundle {
		$$ = $1;
		TQ_ADD(&($$->imports), $2, xp_next);
	}
	;

ImportsBundle:
	ImportsList TOK_FROM TypeRefName optObjectIdentifier {
		$$ = $1;
		$$->from = $3;
		$$->from_oid = $4;
		checkmem($$);
	}
	;

ImportsList:
	ImportsElement {
		$$ = asn1p_xports_new();
		checkmem($$);
		TQ_ADD(&($$->members), $1, next);
	}
	| ImportsList ',' ImportsElement {
		$$ = $1;
		TQ_ADD(&($$->members), $3, next);
	}
	;

ImportsElement:
	TypeRefName {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->Identifier = $1;
		$$->expr_type = A1TC_REFERENCE;
	}
	| Identifier {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->Identifier = $1;
		$$->expr_type = A1TC_REFERENCE;
	}
	;

ExportsDefinition:
	TOK_EXPORTS ExportsBody ';' {
		$$ = $2;
	}
	| TOK_EXPORTS TOK_ALL ';' {
		$$ = 0;
	}
	| TOK_EXPORTS ';' {
		/* Empty EXPORTS clause effectively prohibits export. */
		$$ = asn1p_xports_new();
		checkmem($$);
	}
	;

ExportsBody:
	ExportsElement {
		$$ = asn1p_xports_new();
		assert($$);
		TQ_ADD(&($$->members), $1, next);
	}
	| ExportsBody ',' ExportsElement {
		$$ = $1;
		TQ_ADD(&($$->members), $3, next);
	}
	;

ExportsElement:
	TypeRefName {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->Identifier = $1;
		$$->expr_type = A1TC_EXPORTVAR;
	}
	| Identifier {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->Identifier = $1;
		$$->expr_type = A1TC_EXPORTVAR;
	}
	;


ValueSetDefinition:
	TypeRefName DefinedTypeRef TOK_PPEQ '{' optValueSetBody '}' {
		$$ = $2;
		assert($$->Identifier == 0);
		$$->Identifier = $1;
		$$->meta_type = AMT_VALUESET;
		// take care of optValueSetBody 
	}
	;

DefinedTypeRef:
	ComplexTypeReference {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->reference = $1;
		$$->expr_type = A1TC_REFERENCE;
		$$->meta_type = AMT_TYPEREF;
	}
	| BasicTypeId {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->expr_type = $1;
		$$->meta_type = AMT_TYPE;
	}
	;

optValueSetBody:
	{ }
	| ConstraintElementSet {
	}
	;


/*
 * Data Type Reference.
 * === EXAMPLE ===
 * Type3 ::= CHOICE { a Type1,  b Type 2 }
 * === EOF ===
 */

DataTypeReference:
	/*
	 * Optionally tagged type definition.
	 */
	TypeRefName TOK_PPEQ optTag TOK_TYPE_IDENTIFIER {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->Identifier = $1;
		$$->tag = $3;
		$$->expr_type = A1TC_TYPEID;
		$$->meta_type = AMT_TYPE;
	}
	| TypeRefName TOK_PPEQ optTag ConstrainedTypeDeclaration {
		$$ = $4;
		$$->Identifier = $1;
		$$->tag = $3;
		assert($$->expr_type);
		assert($$->meta_type);
	}
	| TypeRefName TOK_PPEQ ClassDeclaration {
		$$ = $3;
		$$->Identifier = $1;
		assert($$->expr_type == A1TC_CLASSDEF);
		assert($$->meta_type == AMT_OBJECT);
	}
	/*
	 * Parametrized <Type> declaration:
	 * === EXAMPLE ===
	 *   SIGNED { ToBeSigned } ::= SEQUENCE {
	 *      toBeSigned  ToBeSigned,
	 *      algorithm   AlgorithmIdentifier,
	 *      signature   BIT STRING
	 *   }
	 * === EOF ===
	 */
	| TypeRefName '{' ParameterArgumentList '}'
		TOK_PPEQ ConstrainedTypeDeclaration {
		$$ = $6;
		assert($$->Identifier == 0);
		$$->Identifier = $1;
		$$->params = $3;
		$$->meta_type = AMT_PARAMTYPE;
	}
	;

ParameterArgumentList:
	ParameterArgumentName {
		int ret;
		$$ = asn1p_paramlist_new(yylineno);
		checkmem($$);
		ret = asn1p_paramlist_add_param($$, $1.governor, $1.argument);
		checkmem(ret == 0);
		if($1.governor) asn1p_ref_free($1.governor);
		if($1.argument) free($1.argument);
	}
	| ParameterArgumentList ',' ParameterArgumentName {
		int ret;
		$$ = $1;
		ret = asn1p_paramlist_add_param($$, $3.governor, $3.argument);
		checkmem(ret == 0);
		if($3.governor) asn1p_ref_free($3.governor);
		if($3.argument) free($3.argument);
	}
	;
	
ParameterArgumentName:
	TypeRefName {
		$$.governor = NULL;
		$$.argument = $1;
	}
	| TypeRefName ':' Identifier {
		int ret;
		$$.governor = asn1p_ref_new(yylineno);
		ret = asn1p_ref_add_component($$.governor, $1, 0);
		checkmem(ret == 0);
		$$.argument = $3;
	}
	| BasicTypeId ':' Identifier {
		int ret;
		$$.governor = asn1p_ref_new(yylineno);
		ret = asn1p_ref_add_component($$.governor,
			ASN_EXPR_TYPE2STR($1), 1);
		checkmem(ret == 0);
		$$.argument = $3;
	}
	;

ActualParameterList:
	ActualParameter {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		TQ_ADD(&($$->members), $1, next);
	}
	| ActualParameterList ',' ActualParameter {
		$$ = $1;
		TQ_ADD(&($$->members), $3, next);
	}
	;

ActualParameter:
	TypeDeclaration {
		$$ = $1;
	}
	| Identifier {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->Identifier = $1;
		$$->expr_type = A1TC_REFERENCE;
		$$->meta_type = AMT_VALUE;
	}
	;

/*
 * A collection of constructed data type members.
 */
ConstructedDataTypeDefinition:
	DataTypeMember {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		TQ_ADD(&($$->members), $1, next);
	}
	| ConstructedDataTypeDefinition ',' DataTypeMember {
		$$ = $1;
		TQ_ADD(&($$->members), $3, next);
	}
	;

ClassDeclaration:
	TOK_CLASS '{' ClassFieldList '}' optWithSyntax {
		$$ = $3;
		checkmem($$);
		$$->with_syntax = $5;
		assert($$->expr_type == A1TC_CLASSDEF);
		assert($$->meta_type == AMT_OBJECT);
	}
	;

optUnique:
	{ $$ = 0; }
	| TOK_UNIQUE { $$ = 1; }
	;

ClassFieldList:
	ClassField {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->expr_type = A1TC_CLASSDEF;
		$$->meta_type = AMT_OBJECT;
		TQ_ADD(&($$->members), $1, next);
	}
	| ClassFieldList ',' ClassField {
		$$ = $1;
		TQ_ADD(&($$->members), $3, next);
	}
	;

ClassField:
	ClassFieldIdentifier optMarker {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->Identifier = $1.name;
		$$->expr_type = A1TC_CLASSFIELD;
		$$->meta_type = AMT_OBJECTFIELD;
		$$->marker = $2;
	}
	| ClassFieldIdentifier ConstrainedTypeDeclaration optUnique {
		$$ = $2;
		$$->Identifier = $1.name;
		$$->unique = $3;
	}
	| ClassFieldIdentifier ClassFieldIdentifier optMarker optUnique {
		int ret;
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->Identifier = $1.name;
		$$->reference = asn1p_ref_new(yylineno);
		checkmem($$->reference);
		ret = asn1p_ref_add_component($$->reference,
				$2.name, $2.lex_type);
		checkmem(ret == 0);
		$$->expr_type = A1TC_CLASSFIELD;
		$$->meta_type = AMT_OBJECTFIELD;
		$$->marker = $3;
		$$->unique = $4;
	}
	;

optWithSyntax:
	{ $$ = 0; }
	| WithSyntax {
		$$ = $1;
	}
	;

WithSyntax:
	TOK_WITH TOK_SYNTAX '{'
		{ asn1p_lexer_hack_enable_with_syntax(); }
		WithSyntaxFormat
		'}' {
		$$ = $5;
	}
	;

WithSyntaxFormat:
	WithSyntaxFormatToken {
		$$ = asn1p_wsyntx_new();
		TQ_ADD(&($$->chunks), $1, next);
	}
	| WithSyntaxFormat WithSyntaxFormatToken {
		$$ = $1;
		TQ_ADD(&($$->chunks), $2, next);
	}
	;

WithSyntaxFormatToken:
	TOK_opaque {
		$$ = asn1p_wsyntx_chunk_frombuf($1.buf, $1.len, 0);
	}
	| ClassFieldIdentifier {
		asn1p_ref_t *ref;
		int ret;
		ref = asn1p_ref_new(yylineno);
		checkmem(ref);
		ret = asn1p_ref_add_component(ref, $1.name, $1.lex_type);
		checkmem(ret == 0);
		$$ = asn1p_wsyntx_chunk_fromref(ref, 0);
	}
	;

/*
 * A data type member goes like this
 * ===
 * memb1 [0] Type1 { a(1), b(2) } (2)
 * ===
 * Therefore, we propose a split.
 * ^^^^^^^^^ ^^^^^^^^^^
 * ^TaggedIdentifier  ^TypeDeclaration
 * 				^ConstrainedTypeDeclaration
 */

/*
 * A member of a constructed data type ("a" or "b" in above example).
 */
DataTypeMember:
	TaggedIdentifier ConstrainedTypeDeclaration {
		$$ = $2;
		assert($$->Identifier == 0);
		$$->Identifier = $1.name;
		$$->tag = $1.tag;
	}
	| ExtensionAndException {
		$$ = $1;
	}
	;

ConstrainedTypeDeclaration:
	TypeDeclaration optConstraints optMarker {
		$$ = $1;
		$$->constraints = $2;
		$$->marker = $3;
	}
	;

ExtensionAndException:
	TOK_ThreeDots {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->Identifier = strdup("...");
		checkmem($$->Identifier);
		$$->expr_type = A1TC_EXTENSIBLE;
		$$->meta_type = AMT_TYPE;
	}
	| TOK_ThreeDots '!' DefinedValue {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->Identifier = strdup("...");
		checkmem($$->Identifier);
		$$->value = $3;
		$$->expr_type = A1TC_EXTENSIBLE;
		$$->meta_type = AMT_TYPE;
	}
	| TOK_ThreeDots '!' SignedNumber {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->Identifier = strdup("...");
		$$->value = $3;
		checkmem($$->Identifier);
		$$->expr_type = A1TC_EXTENSIBLE;
		$$->meta_type = AMT_TYPE;
	}
	;

TypeDeclaration:
	BasicType {
		$$ = $1;
	}
	| BasicString {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->expr_type = $1;
		$$->meta_type = AMT_TYPE;
	}
	| ConstructedType {
		$$ = $1;
		checkmem($$);
		assert($$->meta_type);
	}
	/*
	 * A parametrized assignment.
	 */
	| TypeRefName '{' ActualParameterList '}' {
		int ret;
		$$ = $3;
		assert($$->expr_type == 0);
		assert($$->meta_type == 0);
		assert($$->reference == 0);
		$$->reference = asn1p_ref_new(yylineno);
		checkmem($$->reference);
		ret = asn1p_ref_add_component($$->reference, $1, RLT_UNKNOWN);
		checkmem(ret == 0);
		free($1);
		$$->expr_type = A1TC_PARAMETRIZED;
		$$->meta_type = AMT_TYPE;
	}
	/*
	 * A DefinedType reference.
	 * "CLASS1.&id.&id2"
	 * or
	 * "Module.Type"
	 * or
	 * "Module.identifier"
	 * or
	 * "Type"
	 */
	| ComplexTypeReference {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->reference = $1;
		$$->expr_type = A1TC_REFERENCE;
		$$->meta_type = AMT_TYPEREF;
	}
	| TOK_INSTANCE TOK_OF ComplexTypeReference {
		$$ = asn1p_expr_new(yylineno);
		checkmem($$);
		$$->reference = $3;
		$$->expr_type = A1TC_INSTANCE;
		$$->meta_type = AMT_TYPE;
	}
	;

/*
 * A type name consisting of several components.
 * === EXAMPLE ===
 * === EOF ===
 */
ComplexTypeReference:
	TOK_typereference {
		int ret;
		$$ = asn1p_ref_new(yylineno);
		checkmem($$);
		ret = asn1p_ref_add_component($$, $1, RLT_UNKNOWN);
		checkmem(ret == 0);
		free($1);
	}
	| TOK_typereference '.' TypeRefName {
		int ret;
		$$ = asn1p_ref_new(yylineno);
		checkmem($$);
		ret = asn1p_ref_add_component($$, $1, RLT_UNKNOWN);
		checkmem(ret == 0);
		ret = asn1p_ref_add_component($$, $3, RLT_UNKNOWN);
		checkmem(ret == 0);
		free($1);
	}
	| TOK_typereference '.' Identifier {
		int ret;
		$$ = asn1p_ref_new(yylineno);
		checkmem($$);
		ret = asn1p_ref_add_component($$, $1, RLT_UNKNOWN);
		checkmem(ret == 0);
		ret = asn1p_ref_add_component($$, $3, RLT_lowercase);
		checkmem(ret == 0);
		free($1);
	}
	| ObjectClassReference {
		int ret;
		$$ = asn1p_ref_new(yylineno);
		checkmem($$);
		ret = asn1p_ref_add_component($$, $1, RLT_CAPITALS);
		free($1);
		checkmem(ret == 0);
	}
	| ObjectClassReference '.' ComplexTypeReferenceAmpList {
		int ret;
		$$ = $3;
		ret = asn1p_ref_add_component($$, $1, RLT_CAPITALS);
		free($1);
		checkmem(ret == 0);
		/*
		 * Move the last element infront.
		 */
		{
			struct asn1p_ref_component_s tmp_comp;
			tmp_comp = $$->components[$$->comp_count-1];
			memmove(&$$->components[1],
				&$$->components[0],
				sizeof($$->components[0])
				* ($$->comp_count - 1));
			$$->components[0] = tmp_comp;
		}
	}
	;

ComplexTypeReferenceAmpList:
	ComplexTypeReferenceElement {
		int ret;
		$$ = asn1p_ref_new(yylineno);
		checkmem($$);
		ret = asn1p_ref_add_component($$, $1.name, $1.lex_type);
		free($1.name);
		checkmem(ret == 0);
	}
	| ComplexTypeReferenceAmpList '.' ComplexTypeReferenceElement {
		int ret;
		$$ = $1;
		ret = asn1p_ref_add_component($$, $3.name, $3.lex_type);
		free($3.name);
		checkmem(ret == 0);
	}
	;

ComplexTypeReferenceElement:	ClassFieldName;
ClassFieldIdentifier:		ClassFieldName;

ClassFieldName:
	/* "&Type1" */
	TOK_typefieldreference {
		$$.lex_type = RLT_AmpUppercase;
		$$.name = $1;
	}
	/* "&id" */
	| TOK_valuefieldreference {
		$$.lex_type = RLT_Amplowercase;
		$$.name = $1;
	}
	;


/*
 * === EXAMPLE ===
 * value INTEGER ::= 1
 * === EOF ===
 */
ValueDefinition:
	Identifier DefinedTypeRef TOK_PPEQ InlineOrDefinedValue {
		$$ = $2;
		assert($$->Identifier == NULL);
		$$->Identifier = $1;
		$$->meta_type = AMT_VALUE;
		$$->value = $4;
	}
	;

InlineOrDefinedValue:
	'{' { asn1p_lexer_hack_push_opaque_state(); }
		Opaque /* '}' */ {
		$$ = asn1p_value_frombuf($3.buf, $3.len, 0);
		checkmem($$);
		$$->type = ATV_UNPARSED;
	}
	| TOK_bstring {
		$$ = _convert_bitstring2binary($1, 'B');
		checkmem($$);
	}
	| TOK_hstring {
		$$ = _convert_bitstring2binary($1, 'H');
		checkmem($$);
	}
	| TOK_cstring {
		$$ = asn1p_value_frombuf($1.buf, $1.len, 0);
		checkmem($$);
	}
	| SignedNumber {
		$$ = $1;
	}
	| DefinedValue {
		$$ = $1;
	}
	;

DefinedValue:
	Identifier {
		asn1p_ref_t *ref;
		int ret;
		ref = asn1p_ref_new(yylineno);
		checkmem(ref);
		ret = asn1p_ref_add_component(ref, $1, RLT_lowercase);
		checkmem(ret == 0);
		$$ = asn1p_value_fromref(ref, 0);
		checkmem($$);
		free($1);
	}
	| TypeRefName '.' Identifier {
		asn1p_ref_t *ref;
		int ret;
		ref = asn1p_ref_new(yylineno);
		checkmem(ref);
		ret = asn1p_ref_add_component(ref, $1, RLT_UNKNOWN);
		checkmem(ret == 0);
		ret = asn1p_ref_add_component(ref, $3, RLT_lowercase);
		checkmem(ret == 0);
		$$ = asn1p_value_fromref(ref, 0);
		checkmem($$);
		free($1);
		free($3);
	}
	;

Opaque:
	TOK_opaque {
		$$.len = $1.len + 2;
		$$.buf = malloc($$.len + 1);
		checkmem($$.buf);
		$$.buf[0] = '{';
		$$.buf[1] = ' ';
		memcpy($$.buf + 2, $1.buf, $1.len);
		$$.buf[$$.len] = '\0';
		free($1.buf);
	}
	| Opaque TOK_opaque {
		int newsize = $1.len + $2.len;
		char *p = malloc(newsize + 1);
		checkmem(p);
		memcpy(p         , $1.buf, $1.len);
		memcpy(p + $1.len, $2.buf, $2.len);
		p[newsize] = '\0';
		free($1.buf);
		free($2.buf);
		$$.buf = p;
		$$.len = newsize;
	}
	;

BasicTypeId:
	TOK_BOOLEAN { $$ = ASN_BASIC_BOOLEAN; }
	| TOK_NULL { $$ = ASN_BASIC_NULL; }
	| TOK_REAL { $$ = ASN_BASIC_REAL; }
	| BasicTypeId_UniverationCompatible { $$ = $1; }
	| TOK_OCTET TOK_STRING { $$ = ASN_BASIC_OCTET_STRING; }
	| TOK_OBJECT TOK_IDENTIFIER { $$ = ASN_BASIC_OBJECT_IDENTIFIER; }
	| TOK_RELATIVE_OID { $$ = ASN_BASIC_RELATIVE_OID; }
	| TOK_EXTERNAL { $$ = ASN_BASIC_EXTERNAL; }
	| TOK_EMBEDDED TOK_PDV { $$ = ASN_BASIC_EMBEDDED_PDV; }
	| TOK_CHARACTER TOK_STRING { $$ = ASN_BASIC_CHARACTER_STRING; }
	| TOK_UTCTime { $$ = ASN_BASIC_UTCTime; }
	| TOK_GeneralizedTime { $$ = ASN_BASIC_GeneralizedTime; }
	;

/*
 * A type identifier which may be used with "{ a(1), b(2) }" clause.
 */
BasicTypeId_UniverationCompatible:
	TOK_INTEGER { $$ = ASN_BASIC_INTEGER; }
	| TOK_ENUMERATED { $$ = ASN_BASIC_ENUMERATED; }
	| TOK_BIT TOK_STRING { $$ = ASN_BASIC_BIT_STRING; }
	;

BasicType:
	BasicTypeId {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->expr_type = $1;
		$$->meta_type = AMT_TYPE;
	}
	| BasicTypeId_UniverationCompatible UniverationDefinition {
		if($2) {
			$$ = $2;
		} else {
			$$ = asn1p_expr_new(asn1p_lineno);
			checkmem($$);
		}
		$$->expr_type = $1;
		$$->meta_type = AMT_TYPE;
	}
	;

BasicString:
	TOK_BMPString { $$ = ASN_STRING_BMPString; }
	| TOK_GeneralString {
		$$ = ASN_STRING_GeneralString;
		return yyerror("GeneralString is not supported");
	}
	| TOK_GraphicString {
		$$ = ASN_STRING_GraphicString;
		return yyerror("GraphicString is not supported");
	}
	| TOK_IA5String { $$ = ASN_STRING_IA5String; }
	| TOK_ISO646String { $$ = ASN_STRING_ISO646String; }
	| TOK_NumericString { $$ = ASN_STRING_NumericString; }
	| TOK_PrintableString { $$ = ASN_STRING_PrintableString; }
	| TOK_T61String {
		$$ = ASN_STRING_T61String;
		return yyerror("T61String not implemented yet");
	}
	| TOK_TeletexString { $$ = ASN_STRING_TeletexString; }
	| TOK_UniversalString { $$ = ASN_STRING_UniversalString; }
	| TOK_UTF8String { $$ = ASN_STRING_UTF8String; }
	| TOK_VideotexString {
		$$ = ASN_STRING_VideotexString;
		return yyerror("VideotexString is no longer supported");
	}
	| TOK_VisibleString { $$ = ASN_STRING_VisibleString; }
	| TOK_ObjectDescriptor { $$ = ASN_STRING_ObjectDescriptor; }
	;

ConstructedType:
	TOK_CHOICE '{' ConstructedDataTypeDefinition '}'	{
		$$ = $3;
		assert($$->expr_type == A1TC_INVALID);
		$$->expr_type = ASN_CONSTR_CHOICE;
		$$->meta_type = AMT_TYPE;
	}
	| TOK_SEQUENCE '{' ConstructedDataTypeDefinition '}'	{
		$$ = $3;
		assert($$->expr_type == A1TC_INVALID);
		$$->expr_type = ASN_CONSTR_SEQUENCE;
		$$->meta_type = AMT_TYPE;
	}
	| TOK_SET '{' ConstructedDataTypeDefinition '}'		{
		$$ = $3;
		assert($$->expr_type == A1TC_INVALID);
		$$->expr_type = ASN_CONSTR_SET;
		$$->meta_type = AMT_TYPE;
	}
	| TOK_SEQUENCE optConstraints TOK_OF TypeDeclaration {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->constraints = $2;
		$$->expr_type = ASN_CONSTR_SEQUENCE_OF;
		$$->meta_type = AMT_TYPE;
		TQ_ADD(&($$->members), $4, next);
	}
	| TOK_SET optConstraints TOK_OF TypeDeclaration {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->constraints = $2;
		$$->expr_type = ASN_CONSTR_SET_OF;
		$$->meta_type = AMT_TYPE;
		TQ_ADD(&($$->members), $4, next);
	}
	| TOK_ANY 						{
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->expr_type = ASN_CONSTR_ANY;
		$$->meta_type = AMT_TYPE;
	}
	| TOK_ANY TOK_DEFINED TOK_BY Identifier			{
		int ret;
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->reference = asn1p_ref_new(yylineno);
		ret = asn1p_ref_add_component($$->reference,
			$4, RLT_lowercase);
		checkmem(ret == 0);
		$$->expr_type = ASN_CONSTR_ANY;
		$$->meta_type = AMT_TYPE;
	}
	;

/*
 * Data type constraints.
 */
optConstraints:
	{ $$ = 0; }
	| Constraints { $$ = $1; }
	;

Union:		'|' | TOK_UNION;
Intersection:	'^' | TOK_INTERSECTION;
Except:		      TOK_EXCEPT;

Constraints:
	TOK_SIZE '('  ConstraintElementSet ')' {
		/*
		 * This is a special case, for compatibility purposes.
		 * It goes without parenthesis.
		 */
		int ret;
		$$ = asn1p_constraint_new(yylineno);
		checkmem($$);
		$$->type = ACT_CT_SIZE;
		ret = asn1p_constraint_insert($$, $3);
		checkmem(ret == 0);
	}
	| SingleConstraint {
		CONSTRAINT_INSERT($$, ACT_CA_SET, $1, 0);
	}
	| Constraints SingleConstraint {
		CONSTRAINT_INSERT($$, ACT_CA_SET, $1, $2);
	}
	;

SingleConstraint:
	'(' ConstraintElementSet ')' {
		$$ = $2;
	}
	;

ConstraintElementSet:
	ConstraintElement {
		$$ = $1;
	}
	| ConstraintElement ',' TOK_ThreeDots {
		asn1p_constraint_t *ct;
		ct = asn1p_constraint_new(yylineno);
		checkmem(ct);
		ct->type = ACT_EL_EXT;
		CONSTRAINT_INSERT($$, ACT_CA_CSV, $1, ct);
	}
	| ConstraintElement ',' TOK_ThreeDots ',' ConstraintElement {
		asn1p_constraint_t *ct;
		ct = asn1p_constraint_new(yylineno);
		checkmem(ct);
		ct->type = ACT_EL_EXT;
		CONSTRAINT_INSERT($$, ACT_CA_CSV, $1, ct);
		CONSTRAINT_INSERT($$, ACT_CA_CSV, $1, $5);
	}
	| TOK_ThreeDots {
		$$ = asn1p_constraint_new(yylineno);
		checkmem($$);
		$$->type = ACT_EL_EXT;
	}
	| TOK_ThreeDots ',' ConstraintElement {
		asn1p_constraint_t *ct;
		ct = asn1p_constraint_new(yylineno);
		checkmem(ct);
		ct->type = ACT_EL_EXT;
		CONSTRAINT_INSERT($$, ACT_CA_CSV, ct, $3);
	}
	;

ConstraintElement: ConstraintElementUnion { $$ = $1; } ;

ConstraintElementUnion:
	ConstraintElementIntersection { $$ = $1; }
	| ConstraintElementUnion Union ConstraintElementIntersection {
		CONSTRAINT_INSERT($$, ACT_CA_UNI, $1, $3);
	}
	;

ConstraintElementIntersection:
	ConstraintElementException { $$ = $1; }
	| ConstraintElementIntersection Intersection
		ConstraintElementException {
		CONSTRAINT_INSERT($$, ACT_CA_INT, $1, $3);
	}
	;

ConstraintElementException:
	ConstraintSubtypeElement { $$ = $1; }
	| ConstraintElementException Except ConstraintSubtypeElement {
		CONSTRAINT_INSERT($$, ACT_CA_EXC, $1, $3);
	}
	;

ConstraintSubtypeElement:
	ConstraintValue {
		$$ = asn1p_constraint_new(yylineno);
		checkmem($$);
		$$->type = ACT_EL_VALUE;
		$$->value = $1;
	}
	| ConstraintValue ConstraintRangeSpec ConstraintValue {
		$$ = asn1p_constraint_new(yylineno);
		checkmem($$);
		$$->type = $2;
		$$->range_start = $1;
		$$->range_stop = $3;
	}
	| ConstraintSpec '(' ConstraintElementSet ')' {
		int ret;
		$$ = asn1p_constraint_new(yylineno);
		checkmem($$);
		$$->type = $1;
		ret = asn1p_constraint_insert($$, $3);
		checkmem(ret == 0);
	}
	| TableConstraint {
		$$ = $1;
	}
	| WithComponents {
		$$ = $1;
	}
	;

ConstraintRangeSpec:
	TOK_TwoDots		{ $$ = ACT_EL_RANGE; }
	| TOK_TwoDots '<'	{ $$ = ACT_EL_RLRANGE; }
	| '<' TOK_TwoDots	{ $$ = ACT_EL_LLRANGE; }
	| '<' TOK_TwoDots '<'	{ $$ = ACT_EL_ULRANGE; }
	;

ConstraintSpec:
	TOK_SIZE {
		$$ = ACT_CT_SIZE;
	}
	| TOK_FROM {
		$$ = ACT_CT_FROM;
	}
	;

ConstraintValue:
	SignedNumber {
		$$ = $1;
	}
	| Identifier {
		asn1p_ref_t *ref;
		int ret;
		ref = asn1p_ref_new(yylineno);
		checkmem(ref);
		ret = asn1p_ref_add_component(ref, $1, RLT_lowercase);
		checkmem(ret == 0);
		$$ = asn1p_value_fromref(ref, 0);
		checkmem($$);
		free($1);
	}
	| TOK_cstring {
		$$ = asn1p_value_frombuf($1.buf, $1.len, 0);
		checkmem($$);
	}
	| TOK_MIN {
		$$ = asn1p_value_fromint(123);
		checkmem($$);
		$$->type = ATV_MIN;
	}
	| TOK_MAX {
		$$ = asn1p_value_fromint(321);
		checkmem($$);
		$$->type = ATV_MAX;
	}
	| TOK_FALSE {
		$$ = asn1p_value_fromint(0);
		checkmem($$);
		$$->type = ATV_FALSE;
	}
	| TOK_TRUE {
		$$ = asn1p_value_fromint(1);
		checkmem($$);
		$$->type = ATV_TRUE;
	}
	;

WithComponents:
	TOK_WITH TOK_COMPONENTS '{' WithComponentsList '}' {
		CONSTRAINT_INSERT($$, ACT_CT_WCOMPS, $4, 0);
	}
	;

WithComponentsList:
	WithComponentsElement {
		$$ = $1;
	}
	| WithComponentsList ',' WithComponentsElement {
		CONSTRAINT_INSERT($$, ACT_CT_WCOMPS, $1, $3);
	}
	;

WithComponentsElement:
	TOK_ThreeDots {
		$$ = asn1p_constraint_new(yylineno);
		checkmem($$);
		$$->type = ACT_EL_EXT;
	}
	| Identifier optConstraints optPresenceConstraint {
		$$ = asn1p_constraint_new(yylineno);
		checkmem($$);
		$$->type = ACT_EL_VALUE;
		$$->value = asn1p_value_frombuf($1, strlen($1), 0);
		$$->presence = $3;
	}
	;

/*
 * presence constraint for WithComponents
 */
optPresenceConstraint:
	{ $$ = ACPRES_DEFAULT; }
	| PresenceConstraint { $$ = $1; }
	;

PresenceConstraint:
	TOK_PRESENT {
		$$ = ACPRES_PRESENT;
	}
	| TOK_ABSENT {
		$$ = ACPRES_ABSENT;
	}
	| TOK_OPTIONAL {
		$$ = ACPRES_OPTIONAL;
	}
	;

TableConstraint:
	SimpleTableConstraint {
		$$ = $1;
	}
	| ComponentRelationConstraint {
		$$ = $1;
	}
	;

/*
 * "{ExtensionSet}"
 */
SimpleTableConstraint:
	'{' TypeRefName '}' {
		asn1p_ref_t *ref = asn1p_ref_new(yylineno);
		asn1p_constraint_t *ct;
		int ret;
		ret = asn1p_ref_add_component(ref, $2, 0);
		checkmem(ret == 0);
		ct = asn1p_constraint_new(yylineno);
		checkmem($$);
		ct->type = ACT_EL_VALUE;
		ct->value = asn1p_value_fromref(ref, 0);
		CONSTRAINT_INSERT($$, ACT_CA_CRC, ct, 0);
	}
	;

ComponentRelationConstraint:
	SimpleTableConstraint '{' AtNotationList '}' {
		CONSTRAINT_INSERT($$, ACT_CA_CRC, $1, $3);
	}
	;

AtNotationList:
	AtNotationElement {
		$$ = asn1p_constraint_new(yylineno);
		checkmem($$);
		$$->type = ACT_EL_VALUE;
		$$->value = asn1p_value_fromref($1, 0);
	}
	| AtNotationList ',' AtNotationElement {
		asn1p_constraint_t *ct;
		ct = asn1p_constraint_new(yylineno);
		checkmem(ct);
		ct->type = ACT_EL_VALUE;
		ct->value = asn1p_value_fromref($3, 0);
		CONSTRAINT_INSERT($$, ACT_CA_CSV, $1, ct);
	}
	;

/*
 * @blah
 */
AtNotationElement:
	'@' ComponentIdList {
		char *p = malloc(strlen($2) + 2);
		int ret;
		*p = '@';
		strcpy(p + 1, $2);
		$$ = asn1p_ref_new(yylineno);
		ret = asn1p_ref_add_component($$, p, 0);
		checkmem(ret == 0);
		free(p);
		free($2);
	}
	| '@' '.' ComponentIdList {
		char *p = malloc(strlen($3) + 3);
		int ret;
		p[0] = '@';
		p[1] = '.';
		strcpy(p + 2, $3);
		$$ = asn1p_ref_new(yylineno);
		ret = asn1p_ref_add_component($$, p, 0);
		checkmem(ret == 0);
		free(p);
		free($3);
	}
	;

/* identifier "." ... */
ComponentIdList:
	Identifier {
		$$ = $1;
	}
	| ComponentIdList '.' Identifier {
		int l1 = strlen($1);
		int l3 = strlen($3);
		$$ = malloc(l1 + 1 + l3 + 1);
		memcpy($$, $1, l1);
		$$[l1] = '.';
		memcpy($$ + l1 + 1, $3, l3);
		$$[l1 + 1 + l3] = '\0';
	}
	;



/*
 * MARKERS
 */

optMarker:
	{ $$ = EM_NOMARK; }
	| Marker { $$ = $1; }
	;

Marker:
	TOK_OPTIONAL {
		$$ = EM_OPTIONAL;
	}
	| TOK_DEFAULT DefaultValue {
		$$ = EM_DEFAULT;
		/* FIXME: store DefaultValue somewhere */
	}
	;

DefaultValue:
	ConstraintValue {
	}
	| BasicTypeId {
	}
	| '{' { asn1p_lexer_hack_push_opaque_state(); } Opaque /* '}' */ {
	}
	;

/*
 * Universal enumeration definition to use in INTEGER and ENUMERATED.
 * === EXAMPLE ===
 * Gender ::= ENUMERATED { unknown(0), male(1), female(2) }
 * Temperature ::= INTEGER { absolute-zero(-273), freezing(0), boiling(100) }
 * === EOF ===
 */
/*
optUniverationDefinition:
	{ $$ = 0; }
	| UniverationDefinition {
		$$ = $1;
	}
	;
*/

UniverationDefinition:
	'{' '}' {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
	}
	| '{' UniverationList '}' {
		$$ = $2;
	}
	;

UniverationList:
	UniverationElement {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		TQ_ADD(&($$->members), $1, next);
	}
	| UniverationList ',' UniverationElement {
		$$ = $1;
		TQ_ADD(&($$->members), $3, next);
	}
	;

UniverationElement:
	Identifier {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->expr_type = A1TC_UNIVERVAL;
		$$->meta_type = AMT_VALUE;
		$$->Identifier = $1;
	}
	| Identifier '(' SignedNumber ')' {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->expr_type = A1TC_UNIVERVAL;
		$$->meta_type = AMT_VALUE;
		$$->Identifier = $1;
		$$->value = $3;
	}
	| Identifier '(' DefinedValue ')' {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->expr_type = A1TC_UNIVERVAL;
		$$->meta_type = AMT_VALUE;
		$$->Identifier = $1;
		$$->value = $3;
	}
	| SignedNumber {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->expr_type = A1TC_UNIVERVAL;
		$$->meta_type = AMT_VALUE;
		$$->value = $1;
	}
	| TOK_ThreeDots {
		$$ = asn1p_expr_new(asn1p_lineno);
		checkmem($$);
		$$->Identifier = strdup("...");
		checkmem($$->Identifier);
		$$->expr_type = A1TC_EXTENSIBLE;
		$$->meta_type = AMT_VALUE;
	}
	;

SignedNumber:
	TOK_number {
		$$ = asn1p_value_fromint($1);
		checkmem($$);
	}
	| TOK_number_negative {
		$$ = asn1p_value_fromint($1);
		checkmem($$);
	}
	;

/*
 * SEQUENCE definition.
 * === EXAMPLE ===
 * Struct1 ::= SEQUENCE {
 * 	memb1 Struct2,
 * 	memb2 SEQUENCE OF {
 * 		memb2-1 Struct 3
 * 	}
 * }
 * === EOF ===
 */



/*
 * SET definition.
 * === EXAMPLE ===
 * Person ::= SET {
 * 	name [0] PrintableString (SIZE(1..20)),
 * 	country [1] PrintableString (SIZE(1..20)) DEFAULT default-country,
 * }
 * === EOF ===
 */

optTag:
	{ memset(&$$, 0, sizeof($$)); }
	| Tag { $$ = $1; }
	;

Tag:
	TOK_tag {
		$$ = $1;
		$$.tag_mode = TM_DEFAULT;
	}
	| TOK_tag TOK_IMPLICIT {
		$$ = $1;
		$$.tag_mode = TM_IMPLICIT;
	}
	| TOK_tag TOK_EXPLICIT {
		$$ = $1;
		$$.tag_mode = TM_EXPLICIT;
	}
	;

TypeRefName:
	TOK_typereference {
		checkmem($1);
		$$ = $1;
	}
	| TOK_objectclassreference {
		checkmem($1);
		$$ = $1;
	}
	;

ObjectClassReference:
	TOK_objectclassreference {
		checkmem($1);
		$$ = $1;
	}
	;

Identifier:
	TOK_identifier {
		checkmem($1);
		$$ = $1;
	}
	;

TaggedIdentifier:
	Identifier {
		memset(&$$, 0, sizeof($$));
		$$.name = $1;
	}
	| Identifier Tag {
		$$.name = $1;
		$$.tag = $2;
	}
	;


%%


/*
 * Convert Xstring ('0101'B or '5'H) to the binary vector.
 */
static asn1p_value_t *
_convert_bitstring2binary(char *str, int base) {
	asn1p_value_t *val;
	int slen;
	int memlen;
	int baselen;
	int bits;
	uint8_t *binary_vector;
	uint8_t *bv_ptr;
	uint8_t cur_val;

	assert(str);
	assert(str[0] == '\'');

	switch(base) {
	case 'B':
		baselen = 1;
		break;
	case 'H':
		baselen = 4;
		break;
	default:
		assert(base == 'B' || base == 'H');
		errno = EINVAL;
		return NULL;
	}

	slen = strlen(str);
	assert(str[slen - 1] == base);
	assert(str[slen - 2] == '\'');

	memlen = slen / (8 / baselen);	/* Conservative estimate */

	bv_ptr = binary_vector = malloc(memlen + 1);
	if(bv_ptr == NULL)
		/* ENOMEM */
		return NULL;

	cur_val = 0;
	bits = 0;
	while(*(++str) != '\'') {
		switch(baselen) {
		case 1:
			switch(*str) {
			case '1':
				cur_val |= 1 << (7 - (bits % 8));
			case '0':
				break;
			default:
				assert(!"_y UNREACH1");
			case ' ': case '\r': case '\n':
				continue;
			}
			break;
		case 4:
			switch(*str) {
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				cur_val |= (*str - '0') << (4 - (bits % 8));
				break;
			case 'A': case 'B': case 'C':
			case 'D': case 'E': case 'F':
				cur_val |= ((*str - 'A') + 10)
					<< (4 - (bits % 8));
				break;
			default:
				assert(!"_y UNREACH2");
			case ' ': case '\r': case '\n':
				continue;
			}
			break;
		}

		bits += baselen;
		if((bits % 8) == 0) {
			*bv_ptr++ = cur_val;
			cur_val = 0;
		}
	}

	*bv_ptr = cur_val;
	assert((bv_ptr - binary_vector) <= memlen);

	val = asn1p_value_frombits(binary_vector, bits, 0);
	if(val == NULL) {
		free(binary_vector);
	}

	return val;
}

extern char *asn1p_text;

int
yyerror(const char *msg) {
	fprintf(stderr,
		"ASN.1 grammar parse error "
		"near line %d (token \"%s\"): %s\n",
		asn1p_lineno, asn1p_text, msg);
	return -1;
}

