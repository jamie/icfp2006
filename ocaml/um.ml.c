#include <caml/config.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

#include <string.h>

unsigned long *icfp_alloc_private(unsigned long size) {
	unsigned long *p;
	p = (unsigned long *)caml_stat_alloc((size+1) * 4);
	memset(p, 0, (size+1) * 4);
	p[0] = size;
	return p;
}

CAMLprim value icfp_alloc(value size) {
	unsigned long sz, *p;
	sz = Int32_val(size);
	p = icfp_alloc_private(sz);
	return caml_copy_int32((unsigned long)p);
}

CAMLprim value icfp_free(value addr) {
	unsigned long *p;
	p = (unsigned long *)Int32_val(addr);
	if ( p ) caml_stat_free(p);
	return Val_unit;
}

CAMLprim value icfp_get(value addr, value off) {
	unsigned long result, *p, o;
	p = (unsigned long *)Int32_val(addr);
	o = Int32_val(off);
	result = p[o + 1];
	return caml_copy_int32(result);
}

CAMLprim value icfp_set(value addr, value off, value val) {
	unsigned long *p, o, v;
	p = (unsigned long *)Int32_val(addr);
	o = Int32_val(off);
	v = Int32_val(val);
	p[o + 1] = v;
	return Val_unit;
}

CAMLprim value icfp_copy(value addr) {
	unsigned long *p1, *p2; int sz, i;
	p1 = (unsigned long *)Int32_val(addr);
	sz = p1[0];
	p2 = icfp_alloc_private(sz);
	for ( i = 1; i <= sz; ++i ) {
		p2[i] = p1[i];
	}
	return caml_copy_int32((unsigned long)p2);
}	

CAMLprim value icfp_udiv(value x, value y) {
	return caml_copy_int32((unsigned long)((unsigned long)Int32_val(x)) / ((unsigned long)Int32_val(y)));
}

CAMLprim value icfp_nand(value x, value y) {
	return caml_copy_int32((unsigned long)(~(Int32_val(x) & Int32_val(y))));
}
