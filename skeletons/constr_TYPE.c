/*-
 * Copyright (c) 2003, 2004 Lev Walkin <vlm@lionet.info>. All rights reserved.
 * Redistribution and modifications are permitted subject to BSD license.
 */
#include <constr_TYPE.h>
#include <errno.h>

static asn_app_consume_bytes_f _print2fp;

/*
 * Return the outmost tag of the type.
 */
ber_tlv_tag_t
asn1_TYPE_outmost_tag(asn1_TYPE_descriptor_t *type_descriptor,
		const void *struct_ptr, int tag_mode, ber_tlv_tag_t tag) {

	if(tag_mode)
		return tag;

	if(type_descriptor->tags_count)
		return type_descriptor->tags[0];

	return type_descriptor->outmost_tag(type_descriptor, struct_ptr, 0, 0);
}

/*
 * Print the target language's structure in human readable form.
 */
int
asn_fprint(FILE *stream, asn1_TYPE_descriptor_t *td, const void *struct_ptr) {
	if(!stream) stream = stdout;
	if(!td || !struct_ptr) {
		errno = EINVAL;
		return -1;
	}

	/* Invoke type-specific printer */
	if(td->print_struct(td, struct_ptr, 4, _print2fp, stream))
		return -1;

	/* Terminate the output */
	if(_print2fp("\n", 1, stream))
		return -1;

	return fflush(stream);
}

/* Dump the data into the specified stdio stream */
static int
_print2fp(const void *buffer, size_t size, void *app_key) {
	FILE *stream = app_key;

	if(fwrite(buffer, 1, size, stream) != size)
		return -1;

	return 0;
}
