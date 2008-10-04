#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"
#include "mro_compat.h"

#if PERL_REVISION == 5 && PERL_VERSION >= 10
#define HAS_LEXICAL_HH
#endif


typedef OP* (*ck_t)(pTHX_ OP*);

#define MY_CXT_KEY "Scalar::Util::Ref::_guts" XS_VERSION

typedef struct{
	CV* universal_isa;

	UV ins_depth;
	ck_t ins_old_ck_left_shift;
} my_cxt_t;
START_MY_CXT;

typedef enum{
	T_NOT_REF,
	T_SV,
	T_AV,
	T_HV,
	T_CV,
	T_GV,
	T_IO,
	T_FM,
	T_RE,
	T_OBJECT
} my_ref_t;

static void*
has_amagic_converter(pTHX_ SV* const sv, const my_ref_t t){
	const AMT* const amt = (AMT*)mg_find((SV*)SvSTASH(SvRV(sv)), PERL_MAGIC_overload_table)->mg_ptr;
	int o = 0;

	assert(amt);
	assert(AMT_AMAGIC(amt));

	switch(t){
	case T_SV:
		o = to_sv_amg;
		break;
	case T_AV:
		o = to_av_amg;
		break;
	case T_HV:
		o = to_hv_amg;
		break;
	case T_CV:
		o = to_cv_amg;
		break;
	case T_GV:
		o = to_gv_amg;
		break;
	default:
		return NULL;
	}

	return amt->table[o];
}

static bool
my_ref_type(pTHX_ SV* const sv, const my_ref_t t){
	SvGETMAGIC(sv);

	if(!SvROK(sv)){
		return FALSE;
	}

	if(SvOBJECT(SvRV(sv))){
		if(SvAMAGIC(sv) && has_amagic_converter(aTHX_ sv, t)){
			return TRUE;
		}
		else if(t == T_RE && mg_find(SvRV(sv), PERL_MAGIC_qr)){
			return TRUE;
		}
		else{
			return FALSE;
		}
	}


	switch(SvTYPE(SvRV(sv))){
	case SVt_PVAV: return T_AV == t;
	case SVt_PVHV: return T_HV == t;
	case SVt_PVCV: return T_CV == t;
	case SVt_PVGV: return T_GV == t;
	case SVt_PVIO: return T_IO == t;
	case SVt_PVFM: return T_FM == t;
	default:       NOOP;
	}

	return T_SV == t;
}

/* returns &PL_sv_yes or &PL_sv_no */
static SV*
instance_of(pTHX_ SV* const x, SV* const klass){
	dVAR;
	/* from pp_bless() in pp.c */
	if( !SvOK(klass) || (!SvGMAGICAL(klass) && !SvAMAGIC(klass) && SvROK(klass)) ){
		Perl_croak(aTHX_ "%s supplied as a class name",
			!SvOK(klass)          ? "Uninitialized value" :
			SvOBJECT(SvRV(klass)) ? "Object reference"     : "Reference");
	}

	if( !(SvROK(x) && SvOBJECT(SvRV(x))) ){
		return &PL_sv_no;
	}

	{
		dSP;
		dMY_CXT;
		SV* retval;
		HV* stash;
		GV* isa;

		stash = SvSTASH(SvRV(x));
		isa = gv_fetchmeth_autoload(stash, "isa", sizeof("isa")-1, 0 /* special zero, not flags */);

		if(!isa){ /* UNIVERSAL::isa undefined */
			return &PL_sv_undef;
		}

		if(GvCV(isa) == MY_CXT.universal_isa){
			/*
				a faster implementation of sv_derived_from().
				see also universal.c and mro.c.
			*/
			const char* const klass_name = SvPV_nolen_const(klass);
			const char* const stash_name = HvNAME(stash);

			AV* stash_linear_isa;
			SV** svp;
			SV** end;

			if(strEQ(stash_name, klass_name)){
				return &PL_sv_yes;
			}

			stash_linear_isa = mro_get_linear_isa(stash);
			svp = AvARRAY(stash_linear_isa) + 1; /* skip this class */
			end = svp + AvFILLp(stash_linear_isa); /* start + 1 + last index */

			while(svp != end){
				if(strEQ(klass_name, SvPVX(*svp))){
					return &PL_sv_yes;
				}
				svp++;
			}

			if(strEQ(klass_name, "UNIVERSAL")){ /* It's a rare case. */
				return &PL_sv_yes;
			}

			return  &PL_sv_no;
		}

		/* call the specific isa() method */
		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		EXTEND(SP, 2);
		PUSHs(x);
		PUSHs(klass);
		PUTBACK;

		call_sv((SV*)isa, G_SCALAR);

		SPAGAIN;

		retval = POPs;
		retval = SvTRUE(retval) ? &PL_sv_yes : &PL_sv_no;

		PUTBACK;

		FREETMPS;
		LEAVE;

		return retval;
	}
}

/* implementation of the 'instanceof' operator */

#define HINT_KEY "instanceof"

#define my_SvNIOK(sv) (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVp_IOK|SVp_NOK))

static OP*
ins_pp_left_shift(pTHX){
	dVAR; dSP;
	SV* sv    = TOPm1s; /* lhs - top minus 1 scalar */
	SV* klass = TOPs;   /* rhs */

	SvGETMAGIC(klass);

	if( !my_SvNIOK(klass) ){

		SvGETMAGIC(sv);
		sv = instance_of(aTHX_ sv, klass);

		SP--;
		SETs( sv );
		RETURN;
	}

	return PL_ppaddr[OP_LEFT_SHIFT](aTHX);
}


static OP*
ins_ck_left_shift(pTHX_ OP* o){
	dMY_CXT;
	SV* sv;
#ifdef HAS_LEXICAL_HH
	/* fetch from lexical %^H */
	sv = Perl_refcounted_he_fetch(aTHX_
				PL_curcop->cop_hints_hash, Nullsv,
				HINT_KEY, sizeof(HINT_KEY)-1, FALSE, 0);
#else
	SV** svp = hv_fetchs(GvHV(PL_hintgv), HINT_KEY, FALSE);
	if(svp){
		sv = *svp;
	}
	else{
		sv = NULL;
	}
#endif

	if( sv && SvTRUE(sv) ){
	//	o->op_flags |= OPf_SPECIAL;
		o->op_ppaddr = ins_pp_left_shift;
	}

	return MY_CXT.ins_old_ck_left_shift(aTHX_ o);
}

MODULE = Scalar::Util::Ref		PACKAGE = Scalar::Util::Ref

PROTOTYPES: DISABLE

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.universal_isa = get_cv("UNIVERSAL::isa", GV_ADD);
	SvREFCNT_inc_simple_void_NN(MY_CXT.universal_isa);
}

void
CLONE(...)
CODE:
	MY_CXT_CLONE;
	MY_CXT.universal_isa = get_cv("UNIVERSAL::isa", GV_ADD);
	SvREFCNT_inc_simple_void_NN(MY_CXT.universal_isa);
	PERL_UNUSED_VAR(items);

void
is_scalar_ref(x)
	SV* x
ALIAS:
	is_scalar_ref = T_SV
	is_array_ref  = T_AV
	is_hash_ref   = T_HV
	is_code_ref   = T_CV
	is_glob_ref   = T_GV
	is_regex_ref  = T_RE
PPCODE:
	ST(0) = my_ref_type(aTHX_ x, (my_ref_t)ix) ?&PL_sv_yes : &PL_sv_no;
	XSRETURN(1);

void
scalar_ref(x)
	SV* x
ALIAS:
	scalar_ref = T_SV
	array_ref  = T_AV
	hash_ref   = T_HV
	code_ref   = T_CV
	glob_ref   = T_GV
	regex_ref  = T_RE
PPCODE:
	if(my_ref_type(aTHX_ x, (my_ref_t)ix)){
		XSRETURN(1); /* return the first value */
	}
	else{
		if(SvROK(x)){
			Perl_croak(aTHX_ "Unmatched reftype for %s: %s", GvNAME(CvGV(cv)), sv_reftype(SvRV(x), FALSE));
		}
		else if(SvOK(x)){
			Perl_croak(aTHX_ "No reference for %s", GvNAME(CvGV(cv)));
		}
		else{
			Perl_croak(aTHX_ "Uninitialized value for %s", GvNAME(CvGV(cv)));
		}
	}

void
is_instance(x, klass)
	SV* x
	SV* klass
PPCODE:
	SvGETMAGIC(x);
	SvGETMAGIC(klass);
	if( instance_of(aTHX_ x, klass) == &PL_sv_yes ){
		/* ST(0) = x; */
		XSRETURN(1);
	}

void
instance(x, klass)
	SV* x
	SV* klass
PPCODE:
	SvGETMAGIC(x);
	SvGETMAGIC(klass);
	if( instance_of(aTHX_ x, klass) == &PL_sv_yes ){
		/* ST(0) = x; */
		XSRETURN(1);
	}
	/* else */
	if(SvROK(x)){
		if( SvOBJECT(SvRV(x)) ){
			Perl_croak(aTHX_ "Unmatched class for %" SVf, klass);
		}
		else{
			Perl_croak(aTHX_ "Unblessed reference for %" SVf, klass);
		}
	}
	else if(SvOK(x)){
		Perl_croak(aTHX_ "No object reference for %" SVf, klass);
	}
	else{
		Perl_croak(aTHX_ "Uninitialized value for %" SVf, klass);
	}


SV*
gen_sref(referent = undef)
CODE:
	RETVAL = newRV_noinc(items == 0 ? newSV(0) : newSVsv(ST(0)));
OUTPUT:
	RETVAL



MODULE = Scalar::Util::Ref	PACKAGE = instanceof

SV*
_enter(...)
PREINIT:
	dMY_CXT;
CODE:
	PERL_UNUSED_ARG(items);
	if(MY_CXT.ins_depth == 0){
		MY_CXT.ins_old_ck_left_shift = PL_check[OP_LEFT_SHIFT];
		PL_check[OP_LEFT_SHIFT] = ins_ck_left_shift;
	}
	MY_CXT.ins_depth++;
	RETVAL = newSV(0);
	sv_setref_uv(RETVAL, HINT_KEY, MY_CXT.ins_depth);
OUTPUT:
	RETVAL

void
DESTROY(...)
PREINIT:
	dMY_CXT;
CODE:
	PERL_UNUSED_ARG(items);
	if(MY_CXT.ins_depth == 1){
		PL_check[OP_LEFT_SHIFT] = MY_CXT.ins_old_ck_left_shift;
	}
	if(MY_CXT.ins_depth > 0){
		MY_CXT.ins_depth--;
	}

