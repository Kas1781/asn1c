/*-
 * Copyright (c) 2003, 2004 Lev Walkin <vlm@lionet.info>. All rights reserved.
 * Redistribution and modifications are permitted subject to BSD license.
 */
#ifndef	_CONSTR_TYPE_H_
#define	_CONSTR_TYPE_H_

#include <asn_types.h>		/* System-dependent types */
#include <ber_tlv_length.h>
#include <ber_tlv_tag.h>
#include <ber_decoder.h>
#include <der_encoder.h>
#include <constraints.h>

struct asn1_TYPE_descriptor_s;	/* Forward declaration */

/*
 * Free the structure according to its specification.
 * If (free_contents_only) is set, the wrapper structure itself (struct_ptr)
 * will not be freed. (It may be useful in case the structure is allocated
 * statically or arranged on the stack, yet its elements are allocated
 * dynamically.)
 */
typedef void (asn_struct_free_f)(
		struct asn1_TYPE_descriptor_s *type_descriptor,
		void *struct_ptr, int free_contents_only);

/*
 * Print the structure according to its specification.
 */
typedef int (asn_struct_print_f)(
		struct asn1_TYPE_descriptor_s *type_descriptor,
		const void *struct_ptr,
		int level,	/* Indentation level */
		asn_app_consume_bytes_f *callback, void *app_key);

/*
 * Return the outmost tag of the type.
 * If the type is untagged CHOICE, the dynamic operation is performed.
 * NOTE: This function pointer type is only useful internally.
 * Do not use it in your application.
 */
typedef ber_tlv_tag_t (asn_outmost_tag_f)(
		struct asn1_TYPE_descriptor_s *type_descriptor,
		const void *struct_ptr, int tag_mode, ber_tlv_tag_t tag);
/* The instance of the above function type */
asn_outmost_tag_f asn1_TYPE_outmost_tag;


/*
 * The definitive description of the destination language's structure.
 */
typedef struct asn1_TYPE_descriptor_s {
	char *name;	/* A name of the ASN.1 type */

	/*
	 * Generalized functions for dealing with the specific type.
	 * May be directly invoked by applications.
	 */
	asn_constr_check_f *check_constraints;	/* Constraints validator */
	ber_type_decoder_f *ber_decoder;	/* Free-form BER decoder */
	der_type_encoder_f *der_encoder;	/* Canonical DER encoder */
	asn_struct_print_f *print_struct;	/* Human readable output */
	asn_struct_free_f  *free_struct;	/* Free the structure */

	/*
	 * Functions used internally. Should not be used by applications.
	 */
	asn_outmost_tag_f  *outmost_tag;	/* <optional, internal> */

	/*
	 * Tags that are expected, with some of their vital properties.
	 */
	ber_tlv_tag_t *tags;	/* At least one tag must be specified */
	int tags_count;		/* Number of tags which are expected */
	int tags_impl_skip;	/* Tags to skip in implicit mode */
	int last_tag_form;	/* Acceptable form of the tag (prim, constr) */

	/*
	 * Additional information describing the type, used by appropriate
	 * functions above.
	 */
	void *specifics;
} asn1_TYPE_descriptor_t;

/*
 * BER tag to element number mapping.
 */
typedef struct asn1_TYPE_tag2member_s {
	ber_tlv_tag_t el_tag;	/* Outmost tag of the member */
	int el_no;		/* Index of the associated member, base 0 */
	int toff_first;		/* First occurence of the el_tag, relative */
	int toff_last;		/* Last occurence of the el_tag, relatvie */
} asn1_TYPE_tag2member_t;


/*
 * This function is a wrapper around (td)->print_struct, which prints out
 * the contents of the target language's structure (struct_ptr) into the
 * file pointer (stream) in human readable form.
 * RETURN VALUES:
 * 	 0: The structure is printed.
 * 	-1: Problem dumping the structure.
 */
int asn_fprint(FILE *stream,		/* Destination stream descriptor */
	asn1_TYPE_descriptor_t *td,	/* ASN.1 type descriptor */
	const void *struct_ptr);	/* Structure to be printed */

#endif	/* _CONSTR_TYPE_H_ */