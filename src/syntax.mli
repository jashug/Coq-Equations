(**********************************************************************)
(* Equations                                                          *)
(* Copyright (c) 2009-2016 Matthieu Sozeau <matthieu.sozeau@inria.fr> *)
(**********************************************************************)
(* This file is distributed under the terms of the                    *)
(* GNU Lesser General Public License Version 2.1                      *)
(**********************************************************************)

open Constr
open Environ
open Names
open Equations_common
open Ltac_plugin

type 'a with_loc = Loc.t * 'a

(** User-level patterns *)
type generated = bool

type rec_annotation =
  | Nested
  | Struct

type user_rec_annot = (rec_annotation * Id.t with_loc option) option

type identifier = Names.Id.t

type user_pat =
    PUVar of identifier * generated
  | PUCstr of constructor * int * user_pats
  | PUInac of Constrexpr.constr_expr
and user_pats = user_pat located list


(** Globalized syntax *)

type rec_arg = int * Id.t with_loc option
    
type rec_annot =
  | StructuralOn of rec_arg
  | NestedOn of rec_arg option

type lhs = user_pats (* p1 ... pn *)
and 'a rhs =
    Program of Constrexpr.constr_expr * 'a where_clause list
  | Empty of identifier with_loc
  | Rec of Constrexpr.constr_expr * Constrexpr.constr_expr option *
             identifier with_loc option * 'a list
  | Refine of Constrexpr.constr_expr * 'a list
  | By of (Tacexpr.raw_tactic_expr, Tacexpr.glob_tactic_expr) Util.union *
      'a list
and prototype =
  identifier with_loc * user_rec_annot * Constrexpr.local_binder_expr list * Constrexpr.constr_expr

and 'a where_clause = prototype * 'a list
and program = (signature * clause list) list
and signature = identifier * rel_context * constr (* f : Π Δ. τ *)
and clause = Loc.t * lhs * clause rhs (* lhs rhs *)

val pr_user_pat : env -> user_pat located -> Pp.t
val pr_user_pats : env -> user_pats -> Pp.t

val pr_lhs : env -> user_pats -> Pp.t
val pplhs : user_pats -> unit
val pr_rhs : env -> clause rhs -> Pp.t
val pr_clause :
  env -> clause -> Pp.t
val pr_clauses :
  env -> clause list -> Pp.t
val ppclause : clause -> unit


(** Raw syntax *)
type pat_expr =
    PEApp of Libnames.reference Constrexpr.or_by_notation with_loc *
      pat_expr with_loc list
  | PEWildcard
  | PEInac of Constrexpr.constr_expr
  | PEPat of Constrexpr.cases_pattern_expr
type user_pat_expr = pat_expr with_loc
type input_pats =
    SignPats of (Id.t with_loc option * user_pat_expr) list
  | RefinePats of user_pat_expr list
type pre_equation =
    identifier with_loc option * input_pats * pre_equation rhs
type pre_equations = pre_equation where_clause list

type rec_type = 
  | Structural of (Id.t * rec_annot) list (* for mutual rec *)
  | Logical of logical_rec
and logical_rec =
  | LogicalDirect of Id.t with_loc
  | LogicalProj of rec_info
and rec_info = {
  comp : Names.Constant.t option;
  comp_app : constr;
  comp_proj : Constant.t;
  comp_recarg : int;
}
val is_structural : rec_type option -> bool
val is_rec_call : Evd.evar_map -> logical_rec -> EConstr.constr -> bool
val next_ident_away : Id.t -> Id.Set.t ref -> Id.t

type equation_option = 
  | OInd of bool | ORec of Id.t with_loc option 
  | OComp of bool 
  | OEquations of bool

type equation_user_option = equation_option

val pr_r_equation_user_option : 'a -> 'b -> 'c -> 'd -> Pp.t

type equation_options = equation_option list

val pr_equation_options : 'a -> 'b -> 'c -> 'd -> Pp.t

val translate_cases_pattern :
  'a -> Id.Set.t ref -> ?loc:Loc.t -> 'b Glob_term.cases_pattern_r -> user_pat located

val ids_of_pats : pat_expr with_loc list -> Id.Set.t

val interp_pat : Environ.env -> ?avoid:Id.Set.t ref ->
  user_pat_expr -> user_pat located

val interp_eqn :
  identifier ->
  rec_type option ->
  env ->
  Impargs.implicit_status list ->
  pre_equation ->
  clause
