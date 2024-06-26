open Core
open AbstractSyntaxTree
open Type
open Identifier
open Common

let indent = "    "

let header =
"#![allow(non_snake_case)]
#![allow(non_camel_case_types)]
use rustymappl::*;
"
;;

let footer = ""

let k_cont = "k"
let log_sum_exp = "log_sum_exp"
let dummy = "_dummy"

(* ' cannot be used in Rust identifiers and _ is reserved for pattern matching *)
let primer varname =
  if String.equal varname "_"
  then dummy
  (* quirk of the cached crate, if an arg is named "key" then it fails *)
  else if String.equal varname "key" then "key_"
  else (
    let lse = Str.regexp "LogSumExp" in
    let r = Str.regexp "'" in
    let torch_lse = Str.global_replace lse log_sum_exp varname in
    Str.global_replace r "_prime" torch_lse)
;;

let memoize_decider func_name =
  if String.is_prefix ~prefix:"lambda" func_name then "#[emit_struct]\n#[cached]\n" else ""
;;

let is_discrete dist =
  match dist with
  | D_ber _ | D_bin (_, _) | D_cat _ -> true
  | _ -> false
;;

let logpr_decider exp =
  match exp.exp_desc with
  | E_dist dist -> if is_discrete dist then "log_pr", "u8" else "log_prc", "f64"
  | _ -> failwith "first argument to LogPr was not a distribution"
;;

(* Make a lot of ostensibly different types the same, otherwise Rust being
   static and monomorphic makes it annoying to work with sometimes *)
let dump_prim_ty prim_ty =
  match prim_ty with
  | Pty_unit -> "()"
  | Pty_bool -> "bool"
  | Pty_ureal -> "f64"
  | Pty_preal -> "f64"
  | Pty_real -> "f64"
  | Pty_fnat _ -> "i32"
  | Pty_nat -> "i32"
  | Pty_int -> "i32"
;;

let dump_binop binop =
  match binop.txt with
  | Bop_add -> "+"
  | Bop_sub -> "-"
  | Bop_mul -> "*"
  | Bop_div -> "/"
  | Bop_eq -> "=="
  | Bop_ne -> "!="
  | Bop_lt -> "<"
  | Bop_le -> "<="
  | Bop_gt -> ">"
  | Bop_ge -> ">="
  | Bop_and -> "&&"
  | Bop_or -> "||"
;;

let rec dump_base_ty fmt bty =
  match bty.bty_desc with
  | Bty_prim pty -> Format.fprintf fmt "%s" (dump_prim_ty pty)
  | Bty_var var -> Format.fprintf fmt "%s" (primer var.txt)
  | Bty_sum (tyv1, tyv2) ->
    Format.fprintf fmt "%a + %a" dump_base_ty tyv1 dump_base_ty tyv2
  | Bty_prod (tyv1, tyv2) ->
    Format.fprintf fmt "%a * %a" dump_base_ty tyv1 dump_base_ty tyv2
  | Bty_arrow (tyv1, tyv2) ->
    Format.fprintf fmt "fn(%a) -> %a" dump_base_ty tyv1 dump_base_ty tyv2
  | Bty_dist tyv -> Format.fprintf fmt "%a" dump_base_ty tyv
  | Bty_array (size, arr) -> Format.fprintf fmt "%d%a" size dump_base_ty arr
;;

let rec dump_exp fmt exp =
  match exp.exp_desc with
  | E_var var_name -> let name = primer var_name.txt in
    (* To pass a continuation, which can't implement Copy *)
    if String.equal k_cont name then
      Format.fprintf fmt "%s.clone()" name
    else 
      Format.fprintf fmt "%s" name
  | E_triv -> Format.fprintf fmt "()"
  | E_bool b -> Format.fprintf fmt "%B" b
  (* Extra precision so Categorical dists sum to 1 *)
  | E_real r -> Format.fprintf fmt "%.11f" r
  | E_nat n -> Format.fprintf fmt "%d" n
  | E_inf -> Format.fprintf fmt "f64::INFINITY"
  | E_ninf -> Format.fprintf fmt "f64::NEG_INFINITY"
  | E_cond (cond, tbranch, fbranch) ->
    Format.fprintf
      fmt
      "@[<hv>if %a {@;<1 4>@[%a@]@;} else {@;<1 4>@[%a@]@;}@]"
      dump_exp
      cond
      dump_exp
      tbranch
      dump_exp
      fbranch
  | E_binop (bop, lhs, rhs) ->
    Format.fprintf
      fmt
      "@[<hv>@[%a@] %s@;@[%a@]@]"
      dump_exp
      lhs
      (dump_binop bop)
      dump_exp
      rhs
  | E_dist d -> dump_dist fmt d
  | E_abs (arg_name, arg_type, body) ->
    Format.fprintf
      fmt
      "@[Rc::new(move |%s: %a| {@;<1 4>@[%a@]@;})@]"
      (primer arg_name.txt)
      dump_base_ty
      arg_type
      dump_exp
      body
  | E_app (rator, rand) -> Format.fprintf fmt "%a(%a)" dump_exp rator dump_exp rand
  | E_call (func_id, args) -> emit_call fmt func_id args
  (* TODO: find a way to implement log_pr with trait dispatch (RFC 1210-impl-specialization?) *)
  (* logpr_decider also returns the type to cast to *)
  | E_logPr (dist, v) ->
    let func, ty = logpr_decider dist in
    Format.fprintf fmt "%s(%a, (%a) as %s)" func dump_exp dist dump_exp v ty
  | E_let (ev, v, e) ->
    Format.fprintf
      fmt
      "@[{@;<1 4>@[let %s = %a;@\n%a@]@;}@]"
      (primer v.txt)
      dump_exp
      ev
      dump_exp
      e
  | E_pair (exp1, exp2) -> Format.fprintf fmt "%a, %a" dump_exp exp1 dump_exp exp2
  | E_array array -> Format.fprintf fmt "@[[%a]@]" (print_list ~f:dump_exp) array
  | E_field (_, _) -> failwith "TODO: E_field"
  | E_case (_, _, _, _, _) -> failwith "TODO: E_case"
  | E_inl _ -> failwith "TODO: E_inl"
  | E_inr _ -> failwith "TODO: E_inr"
  | E_logML _ ->
    failwith "Rust backend does not support inference on continuous latent variables"

and emit_ref_exp fmt exp = Format.fprintf fmt "&%a" dump_exp exp

(* Is the call a partial application of a hoisted lambda? *)
and emit_call fmt func_id args =
  let func_name = primer func_id.txt in
  if String.is_prefix ~prefix:"lambda" func_name
  then
    (* TODO: partial application through a global context telling how many params a func takes,
       currently we assume all partial applications return unary functions *)
    (* TODO: also a global context issue, need to know the type of the final argument
       to know which constructor of Continuation to call *)
    Format.fprintf
      fmt
      "Continuation::cl_i32(@;<0 4>Box::new(@;<0 4>move |%s| %s(%a%s%s)@;<0>)@;<0>)"
      dummy
      func_name
      (print_list ~f:dump_exp)
      args
      (if List.length args = 0 then "" else ", ")
      dummy
  else if String.equal log_sum_exp func_name then
    Format.fprintf fmt "%s(%a)" func_name (print_list ~f:emit_ref_exp) args
  else if String.equal k_cont func_name then
    Format.fprintf fmt "%s.call(%a)" func_name (print_list ~f:emit_ref_exp) args
  else
    Format.fprintf fmt "%s(%a)" func_name (print_list ~f:dump_exp) args

and dump_dist fmt d =
  match d with
  | D_ber e -> Format.fprintf fmt "Bernoulli::new(%a.into())" dump_exp e
  | D_normal (e1, e2) ->
    Format.fprintf fmt "Gaussian::new(%a.into(), %a.into())" dump_exp e1 dump_exp e2
  | D_cat lst -> Format.fprintf fmt "Categorical::new(@;<0 4>@[&%a@]@;<0>)" dump_exp lst
  | _ -> failwith "Unsupported dist"
;;

let rec dump_bty fmt bty =
  match bty.bty_desc with
  | Bty_prim prim_ty -> Format.fprintf fmt "%s" (dump_prim_ty prim_ty)
  | Bty_var type_id -> Format.fprintf fmt "%s" (primer type_id.txt)
  | Bty_sum (left, right) | Bty_prod (left, right) ->
    Format.fprintf fmt "%a !! %a" dump_bty left dump_bty right
  | Bty_arrow (left, right) ->
    Format.fprintf fmt "@[fn(%a) -> %a@]" dump_bty left dump_bty right
  | Bty_dist base_ty -> dump_base_ty fmt base_ty
  | Bty_array (size, arr) -> Format.fprintf fmt "%d%a" size dump_bty arr

and nest_fn fmt bty =
  match bty.bty_desc with
  | Bty_arrow (left, right) ->
    Format.fprintf fmt "fn(%a) -> %a" dump_bty left dump_bty right
  | _ -> dump_bty fmt bty
;;

(* This is a wrapper for dump_exp which is the workhorse,
   this function only retrieves the argument of the first lambda *)
let fetch_first_arg_type fmt exp =
  match exp.exp_desc with
  | E_abs (_, arg_type, _) -> Format.fprintf fmt "%a" dump_base_ty arg_type
  (* If the body is an eta-reduction *)
  | E_var var -> Format.fprintf fmt "%s(%s)" (primer var.txt) dummy
  | _ -> failwith "Impossible"
;;

let emit_param fmt = function
  | id, bty -> let name = primer id.txt in
    if String.equal k_cont name then
      Format.fprintf fmt "%s: Continuation" name
    else
      Format.fprintf fmt "%s: %a" name dump_bty bty
;;

let emit_sig fmt sign =
  Format.fprintf
    fmt
    "(%a) -> %a"
    (print_list ~f:emit_param)
    sign.psig_arg_tys
    dump_base_ty
    sign.psig_ret_ty
;;

let dump_top_level fmt = function
  | Top_pure (name, bty, body) ->
    Format.fprintf
      fmt
      "@[pub fn %s()@;<1 4>-> %a@;{@\n%s@[%a@]@\n}@]@."
      (primer name.txt)
      dump_bty
      bty
      indent
      dump_exp
      body
  | Top_func (id, func) ->
    Format.fprintf
      fmt
      "@[%spub fn %s%a {@\n%s@[%a@]@.}@.@]"
      (memoize_decider id.txt)
      (primer id.txt)
      emit_sig
      func.func_sig
      indent
      dump_exp
      func.func_body
  | Top_proc (_, _) -> failwith "Probabilistic functions are not allowed"
  (* type, external_type, external_pure defined in external library *)
  | _ -> Format.fprintf fmt ""
;;

let dump_rust fmt prog =
  Format.fprintf
    fmt
    "@[%s@.%a%s@]"
    header
    (Format.pp_print_list dump_top_level)
    prog
    footer
;;
