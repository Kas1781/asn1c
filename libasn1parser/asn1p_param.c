#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>

#include "asn1parser.h"

/*
 * Construct a new empty parameters list.
 */
asn1p_paramlist_t *
asn1p_paramlist_new(int _lineno) {
	asn1p_paramlist_t *pl;

	pl = calloc(1, sizeof *pl);
	if(pl) {
		pl->_lineno = _lineno;
	}

	return pl;
}

void
asn1p_paramlist_free(asn1p_paramlist_t *pl) {
	if(pl) {
		if(pl->params) {
			int i = pl->params_count;
			while(i--) {
				if(pl->params[i].governor)
					asn1p_ref_free(pl->params[i].governor);
				if(pl->params[i].argument)
					free(pl->params[i].argument);
				pl->params[i].governor = 0;
				pl->params[i].argument = 0;
			}
			free(pl->params);
			pl->params = 0;
		}

		free(pl);
	}
}

int
asn1p_paramlist_add_param(asn1p_paramlist_t *pl, asn1p_ref_t *gov, char *arg) {

	if(!pl || !arg) {
		errno = EINVAL;
		return -1;
	}

	/*
	 * Make sure there's enough space to insert a new element.
	 */
	if(pl->params_count == pl->params_size) {
		int newsize = pl->params_size?pl->params_size<<2:4;
		void *p;
		p = realloc(pl->params,
			newsize * sizeof(pl->params[0]));
		if(p) {
			pl->params = p;
			pl->params_size = newsize;
		} else {
			return -1;
		}

	}

	if(gov) {
		pl->params[pl->params_count].governor = asn1p_ref_clone(gov);
		if(pl->params[pl->params_count].governor == NULL) {
			return -1;
		}
	} else {
		pl->params[pl->params_count].governor = 0;
	}

	pl->params[pl->params_count].argument = strdup(arg);
	if(pl->params[pl->params_count].argument) {
		pl->params_count++;
		return 0;
	} else {
		if(pl->params[pl->params_count].governor)
			asn1p_ref_free(pl->params[pl->params_count].governor);
		return -1;
	}
}

asn1p_paramlist_t *
asn1p_paramlist_clone(asn1p_paramlist_t *pl) {
	asn1p_paramlist_t *newpl;

	newpl = asn1p_paramlist_new(pl->_lineno);
	if(newpl) {
		int i;
		for(i = 0; i < pl->params_count; i++) {
			if(asn1p_paramlist_add_param(newpl,
				pl->params[i].governor,
				pl->params[i].argument
			)) {
				asn1p_paramlist_free(newpl);
				newpl = NULL;
				break;
			}
		}
	}

	return newpl;
}
