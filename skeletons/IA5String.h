/*-
 * Copyright (c) 2003 Lev Walkin <vlm@lionet.info>. All rights reserved.
 * Redistribution and modifications are permitted subject to BSD license.
 */
#ifndef	_IA5String_H_
#define	_IA5String_H_

#include <constr_TYPE.h>
#include <OCTET_STRING.h>

typedef OCTET_STRING_t IA5String_t;  /* Implemented in terms of OCTET STRING */

/*
 * IA5String ASN.1 type definition.
 */
extern asn1_TYPE_descriptor_t asn1_DEF_IA5String;

asn_constr_check_f IA5String_constraint;

#endif	/* _IA5String_H_ */