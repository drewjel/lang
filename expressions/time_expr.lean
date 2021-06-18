import .expr_base
import ...phys.time.time
import .scalar_expr

namespace lang.time

universes u

--@[protected]
--abbreviation scalar := ℚ



structure time_frame_var extends var 


inductive time_frame_expr : Type 1 --{f : fm scalar T}
| lit (f : time_frame) : time_frame_expr
| var (v : time_frame_var) : time_frame_expr


abbreviation time_frame_env :=
  time_frame_var → time_frame
abbreviation time_frame_eval :=
  time_frame_env → time_frame_expr → time_frame

def default_frame_env : time_frame_env := 
  λv, time_std_frame
def default_frame_eval : time_frame_eval := λenv_, λexpr_, 
  begin
    cases expr_,
    exact expr_,
    exact (default_frame_env expr_)
  end

def static_frame_eval : time_frame_eval 
| env_ (time_frame_expr.lit f) := f
| env_ (time_frame_expr.var v) := env_ v

def time_frame_expr.value (expr_ : time_frame_expr) : time_frame :=
  (static_frame_eval) (default_frame_env) expr_

structure time_space_var (f : time_frame_expr) extends var

inductive time_space_expr (f : time_frame_expr) : Type 1
| lit (sp : time_space f.value) : time_space_expr
| var (v : time_space_var f) : time_space_expr
| mk : time_space_expr

abbreviation time_space_env := Π(f : time_frame_expr),
  time_space_var f → time_space f.value
abbreviation time_space_eval := Π(f : time_frame_expr),
  time_space_env → time_space_expr f → time_space f.value


def default_space_env : time_space_env := 
  λf, λv, mk_space f.value
def default_space_eval : time_space_eval := λf, λenv_, λexpr_, 
  begin
    cases expr_,
    exact expr_,
    exact (default_space_env f expr_),
    exact mk_space f.value
  end

def static_space_eval : time_space_eval 
| f env_ (time_space_expr.lit sp) := sp
| f env_ (time_space_expr.var v) := env_ f v
| f env_ (time_space_expr.mk) := mk_space f.value

def time_space_expr.value {f : time_frame_expr} (expr_ : time_space_expr f)  : time_space f.value :=
  (static_space_eval f) (default_space_env) expr_

/-
Transform
-/
structure transform_var  
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2) extends var

inductive time_transform_expr
  --{f1 : time_frame} {f2 : time_frame} (sp1 : time_space f1) (sp2:=sp1 : time_space f2) 
 -- (sp1 : Σf1 : time_frame, time_space f1)  (sp2 : Σf2 : time_frame, time_space f2 := sp1)
  : Π {f1 : time_frame_expr} (sp1 : time_space_expr f1), Π {f2 : time_frame_expr} (sp2 : time_space_expr f2), Type 1
| lit {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame_expr} {sp2 : time_space_expr f2} (p : time_transform sp1.value sp2.value) : time_transform_expr sp1 sp2
| var {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame_expr} {sp2 : time_space_expr f2} (v : transform_var sp1 sp2) : time_transform_expr sp1 sp2
| compose_lit {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame} {sp2 : time_space f2} (t1 : time_transform sp1.value sp2) 
  {f3 : time_frame_expr} {sp3 : time_space_expr f3}  (t2 : time_transform sp2 sp3.value) : time_transform_expr sp1 sp3
| inv_lit {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame_expr} {sp2 : time_space_expr f2} (t : time_transform sp2.value sp1.value) : time_transform_expr sp1 sp2
| compose 
  {f1 : time_frame_expr} {sp1 : time_space_expr f1}
  {f2 : time_frame_expr} {sp2 : time_space_expr f2}
  {f3 : time_frame_expr} {sp3 : time_space_expr f3}
  (t1 : time_transform_expr sp1 sp3) (t2 : time_transform_expr sp3 sp2) : time_transform_expr sp1 sp2
| inv
  {f1 : time_frame_expr} {sp1 : time_space_expr f1}
  {f2 : time_frame_expr} {sp2 : time_space_expr f2}
  (tr : time_transform_expr sp2 sp1) : time_transform_expr sp1 sp2

class time_transform_has_lit 
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2) := 
  (cast : time_transform sp1.value sp2.value → time_transform_expr sp1 sp2)
notation `|`tlit`|` := time_transform_has_lit.cast tlit

instance time_transform_lit 
  {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame_expr} {sp2 : time_space_expr f2} : time_transform_has_lit sp1 sp2 := 
  ⟨λt, time_transform_expr.lit t⟩

abbreviation transform_env 
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2)  := 
  transform_var sp1 sp2 → time_transform sp1.value sp2.value

abbreviation transform_eval 
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2) := 
  transform_env sp1 sp2 → time_transform_expr sp1 sp2 → time_transform sp1.value sp2.value


def default_transform_env 
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2) : transform_env sp1 sp2:=
    λv, sp1.value.mk_time_transform_to sp2.value

def default_transform_eval 
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2) : transform_eval sp1 sp2 :=
  λenv_, λexpr_,  sp1.value.mk_time_transform_to sp2.value

def static_transform_eval 
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2) : transform_eval sp1 sp2 
| env_ (time_transform_expr.lit tr) := tr
| env_ (time_transform_expr.var v) := env_ v
| env_ (time_transform_expr.compose_lit t1 t2) := ⟨⟨t1.1.1.trans t2.1.1⟩⟩
| env_ (time_transform_expr.inv_lit t) := ⟨⟨(t.1.1).symm⟩⟩
| env_ expr_ := default_transform_eval sp1 sp2 (default_transform_env sp1 sp2) expr_

def time_transform_expr.value {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame_expr} {sp2 : time_space_expr f2}
  (expr_ : time_transform_expr sp1 sp2) : time_transform sp1.value sp2.value :=
  ((static_transform_eval sp1 sp2) (default_transform_env sp1 sp2) expr_)


--INVERSE CANNOT BE DEEPLY EMBEDDED - IT HAS A DIFFERENT TYPE

/-
class transform_has_inv 
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2) := 
  (inv : time_transform_expr sp1 sp2 → time_transform_expr sp2 sp1)
notation tr⁻¹:= transform_has_inv.inv tr

instance transform_inv {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame_expr} {sp2 : time_space_expr f2} 
  : transform_has_inv sp1 sp2 := ⟨λt,
    begin
      let lit := t.value,
      let ftr := lit.1,
      let mtr := ftr.1.symm,
      let invlit : time_transform sp2.value sp1.value := ⟨⟨mtr⟩⟩,
      exact [invlit]
    end
-/
class transform_has_inv 
  {f1 : time_frame_expr} (sp1 : time_space_expr f1) {f2 : time_frame_expr} (sp2 : time_space_expr f2) := 
  (inv : time_transform_expr sp1 sp2 → time_transform_expr sp2 sp1)
notation tr⁻¹:= transform_has_inv.inv tr

instance transform_inv {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame_expr} {sp2 : time_space_expr f2} 
  : transform_has_inv sp1 sp2 := ⟨λt,
    begin
      let lit := t.value,
     -- let ftr := lit.1,
     -- let mtr := ftr.1.symm,
     -- let invlit : time_transform sp2.value sp1.value := ⟨⟨mtr⟩⟩,
     exact (time_transform_expr.inv_lit lit),
    end⟩


def time_transform_expr.trans 
  {f1 : time_frame_expr} {sp1 : time_space_expr f1} {f2 : time_frame_expr} {sp2 : time_space_expr f2}
 {f3 : time_frame_expr} {sp3 : time_space_expr f3} (expr_ : time_transform_expr sp1 sp2) : time_transform_expr sp2 sp3 → time_transform_expr sp1 sp3 
 := λt2,
 time_transform_expr.compose_lit expr_.value t2.value

/-
Duration
-/
structure duration_var {f : time_frame_expr} (sp : time_space_expr f) extends var 

/-
Time
-/
structure time_var  {f : time_frame_expr} (sp : time_space_expr f) extends var
set_option trace.app_builder true --need to fix scalar for this to work

mutual inductive duration_expr, time_expr {f : time_frame_expr} (sp : time_space_expr f)
with duration_expr : Type 1
| zero : duration_expr
| one : duration_expr 
| lit (v : duration sp.value) : duration_expr
| var (v : duration_var sp) : duration_expr
| add_dur_dur (d1 : duration_expr) (d2 : duration_expr) : duration_expr
| neg_dur (d : duration_expr) : duration_expr
| sub_dur_dur (d1 : duration_expr) (d2 : duration_expr) : duration_expr
| sub_time_time (t1 : time_expr) (t2 : time_expr) : duration_expr
| smul_dur (k : scalar_expr) (d : duration_expr) : duration_expr
| apply_duration_lit {f2 : time_frame_expr} {sp2 : time_space_expr f2} (v : time_transform_expr sp2 sp) 
    (d : duration sp2.value) : duration_expr
with time_expr : Type 1
| lit (p : time sp.value) : time_expr
| var (v : time_var sp) : time_expr
| add_dur_time (d : duration_expr) (t : time_expr) : time_expr
| apply_time_lit {f2 : time_frame_expr} {sp2 : time_space_expr f2} (v : time_transform_expr sp2 sp) 
    (t : time sp2.value) : time_expr


abbreviation duration_env {f : time_frame_expr} (sp : time_space_expr f) := 
  duration_var sp → duration sp.value

attribute [elab_as_eliminator] 
abbreviation time_env {f : time_frame_expr} (sp : time_space_expr f) :=
  time_var sp → time sp.value

abbreviation duration_eval := Π{f : time_frame_expr} (sp : time_space_expr f),
  time_env sp → duration_env sp → duration_expr sp → duration sp.value

abbreviation time_eval := Π{f : time_frame_expr} (sp : time_space_expr f), 
  time_env sp → duration_env sp → time_expr sp → time sp.value

def default_duration_env {f : time_frame_expr} (sp : time_space_expr f) : duration_env sp := λv, (mk_duration sp.value 1)
def default_duration_eval : duration_eval  
  := λf sp, λtenv_, λdenv_, λexpr_, 
  begin
    --cases expr_,
    --exact expr_,
    --exact default_duration_env sp expr_,
    repeat {exact (mk_duration sp.value 1)}
  end

--this needs to get fixed, perhaps eval should not depend on env but use a global one *shrug*
--OR, a point evaluator needs to depend on a vector environment, and vice versa? may be acceptable
def default_time_env {f : time_frame_expr} (sp : time_space_expr f) : time_env sp 
  := (λv, (mk_time sp.value 1))


set_option eqn_compiler.max_steps 8192
mutual def static_duration_eval, static_time_eval 
with static_duration_eval : duration_eval 
| f sp tenv_ denv_ (duration_expr.zero) := 0
| f sp tenv_ denv_ (duration_expr.one) := mk_duration sp.value 1
| f sp tenv_ denv_ (duration_expr.lit d) := d
| f sp tenv_ denv_ (duration_expr.var v) := denv_ v
| f sp tenv_ denv_ (duration_expr.add_dur_dur d1 d2) := (static_duration_eval sp tenv_ denv_ d1) +ᵥ (static_duration_eval sp tenv_ denv_ d2)
| f sp tenv_ denv_ (duration_expr.neg_dur d) := -(static_duration_eval sp tenv_ denv_ d)
| f sp tenv_ denv_ (duration_expr.sub_dur_dur d1 d2) := (static_duration_eval sp tenv_ denv_ d1) -ᵥ (static_duration_eval sp tenv_ denv_ d2)
| f sp tenv_ denv_ (duration_expr.sub_time_time t1 t2) := (static_time_eval sp tenv_ denv_ t1) -ᵥ (static_time_eval sp tenv_ denv_ t2)
| f sp tenv_ denv_ (duration_expr.smul_dur s d) := (static_scalar_eval default_scalar_env s)•(static_duration_eval sp tenv_ denv_ d)
| f sp tenv_ denv_ (duration_expr.apply_duration_lit t d) := t.value.transform_duration d
with static_time_eval : time_eval
| f sp tenv_ denv_ (time_expr.lit p) := p
| f sp tenv_ denv_ (time_expr.var v) := tenv_ v
| f sp tenv_ denv_ (time_expr.add_dur_time d t) := (static_duration_eval sp tenv_ denv_ d) +ᵥ (static_time_eval sp tenv_ denv_ t)
| f sp tenv_ denv_ (time_expr.apply_time_lit tr t) := tr.value.transform_time t


def default_time_eval : time_eval := λf sp, λtenv_, λdenv_, λexpr_, 
  begin
    cases expr_,
    exact expr_,
    exact default_time_env sp expr_,
    repeat {exact (mk_time sp.value 1)}
  end

#check time_env
#check default_time_env

def time_expr.value {f : time_frame_expr} {sp : time_space_expr f} (expr_ : time_expr sp) : time sp.value :=
  (static_time_eval sp) (default_time_env sp) (default_duration_env sp) expr_

def duration_expr.value {f : time_frame_expr} {sp : time_space_expr f} (expr_ : duration_expr sp) : duration sp.value :=
  (static_duration_eval sp) (default_time_env sp) (default_duration_env sp) expr_


--not working -- lean doesn't play nice with notation and dependent types
--notation `|`flit`|` := time_frame_expr.lit flit
--notation `|`slit`|` := time_space_expr.lit slit
--instance {scalar : Type u} [field scalar] [inhabited scalar] {f : time_frame} {sp : time_space f} : has_coe (time sp) (time_expr sp) := ⟨λt, time_expr.lit t⟩
--instance {scalar : Type u} [field scalar] [inhabited scalar] {f : time_frame} {sp : time_space f} : has_coe (duration sp) (duration_expr sp) := ⟨λt, duration_expr.lit t⟩
--instance {scalar : Type u} [field scalar] [inhabited scalar] : has_coe (time_frame) (time_frame_expr scalar) := ⟨λf, time_frame_expr.lit f⟩
--instance {scalar : Type u} [field scalar] [inhabited scalar] {f : time_frame} : has_coe (time_space f) (time_space_expr scalar) := ⟨λs, time_space_expr.lit s⟩

/-
class has_lit (t1 : Type 0) (t2 : Type 1) :=
  (cast : t1 → t2)
notation `|`lit`|` := has_lit.cast lit
instance time_lit {f : time_frame_expr} {sp : time_space_expr f } : has_lit (time sp.value) (time_expr sp) :=
  ⟨λt, time_expr.lit t⟩
instance duration_lit {f : time_frame_expr} {sp : time_space_expr f } : has_lit (duration sp.value) (duration_expr sp) :=
  ⟨λd, duration_expr.lit d⟩
instance time_space_lit {f : time_frame_expr} : has_lit (time_space f.value) (time_space_expr f) :=
  ⟨λs, time_space_expr.lit s⟩
instance time_frame_lit : has_lit (time_frame) (time_frame_expr) :=
  ⟨λf, time_frame_expr.lit f⟩
-/

class time_has_lit {f : time_frame_expr} (sp : time_space_expr f) := 
  (cast : time sp.value → time_expr sp)
notation `|`tlit`|` := time_has_lit.cast tlit

instance time_lit {f : time_frame_expr} (sp : time_space_expr f) : time_has_lit  sp := 
  ⟨λt : time sp.value, time_expr.lit t⟩

class duration_has_lit {f : time_frame_expr} (sp : time_space_expr f) := 
  (cast : duration sp.value → duration_expr sp)
notation `|`tlit`|` := duration_has_lit.cast tlit

instance duration_lit {f : time_frame_expr} (sp : time_space_expr f) : duration_has_lit  sp := 
  ⟨λt : duration sp.value, duration_expr.lit t⟩

class time_frame_has_lit := 
  (cast : time_frame → time_frame_expr)
notation `|`flit`|` := time_frame_has_lit.cast flit

instance time_frame_lit : time_frame_has_lit := 
  ⟨λf, time_frame_expr.lit f⟩

class time_space_has_lit (f : time_frame_expr ) := 
  (cast : time_space f.value  → time_space_expr f)
notation `|`slit`|` := time_space_has_lit.cast slit

instance time_space_lit {f : time_frame_expr} : time_space_has_lit f := 
  ⟨λs, time_space_expr.lit s⟩


variables  {f : time_frame_expr} {sp : time_space_expr f} 


/-
Analogous methods provided at math layer
-/
#check mk_frame

#check mk_frame
def mk_time_frame_expr {f : time_frame_expr} {sp : time_space_expr f} (o : time_expr sp) (b : duration_expr sp) : time_frame_expr :=
  |(mk_time_frame o.value b.value)|
/-
4/7
WRITE THIS FUNCTION LATER. 
YOU NEED TO GET THE VALUE OUT OF THE f PARAMETER TO INCLUDE IT IN THE TYPE
AND THEN USE IT IN THE CONSTRUCTOR
-/
#check mk_space 
def mk_time_space_expr (f : time_frame_expr) : time_space_expr f :=
  time_space_expr.mk



def add_dur_expr_dur_expr (v1 v2 : duration_expr sp) : duration_expr sp := 
  duration_expr.add_dur_dur v1 v2

def smul_dur_expr (k : scalar_expr) (v : duration_expr sp) : duration_expr sp := 
    duration_expr.smul_dur k v

def neg_dur_expr (v : duration_expr sp) : duration_expr sp := 
    duration_expr.neg_dur v

def sub_dur_expr_dur_expr (v1 v2 : duration_expr sp) : duration_expr sp :=    -- v1-v2
    duration_expr.sub_dur_dur v1 v2

-- See unframed file for template for proving module
instance has_one_dur_expr : has_one (duration_expr sp) := ⟨duration_expr.one⟩

instance has_add_dur_expr : has_add (duration_expr sp) := ⟨ add_dur_expr_dur_expr ⟩

/-
THIS IS UNPROVABLE
-/
lemma add_assoc_dur_expr : ∀ a b c : duration_expr sp, a + b + c = a + (b + c) :=
begin
    intros,
    cases a,
    { 

    },
    { 

    },
    { 

    },
    { 

    },
    { 

    },
    { 

    },
    { 

    },
    { 

    },
    { 

    },
    { 
      
    }
end

instance add_semigroup_dur_expr : add_semigroup (duration_expr sp) := ⟨ add_dur_expr_dur_expr, add_assoc_dur_expr⟩ 

def dur_expr_zero : duration_expr sp := duration_expr.zero--duration_expr.lit (mk_duration sp.value 0)
instance has_zero_dur_expr : has_zero (duration_expr sp) := ⟨dur_expr_zero⟩

lemma zero_add_dur_expr : ∀ a : duration_expr sp, 0 + a = a := sorry
lemma add_zero_dur_expr : ∀ a : duration_expr sp, a + 0 = a := sorry
instance add_monoid_dur_expr : add_monoid (duration_expr sp) := sorry/-⟨ 
    -- add_semigroup
    add_dur_expr_dur_expr, 
    add_assoc_dur_expr, 
    -- has_zero
    dur_expr_zero,
    -- new structure 
    sorry,--@zero_add_dur_expr _ _ f sp, 
    add_zero_dur_expr
⟩-/

instance has_neg_dur_expr : has_neg (duration_expr sp) := ⟨neg_dur_expr⟩
instance has_sub_dur_expr : has_sub (duration_expr sp) := ⟨ sub_dur_expr_dur_expr⟩ 
lemma sub_eq_add_neg_dur_expr : ∀ a b : duration_expr sp, a - b = a + -b := sorry
instance sub_neg_monoid_dur_expr : sub_neg_monoid (duration_expr sp) :=sorry /-⟨ 
    add_dur_expr_dur_expr, add_assoc_dur_expr, dur_expr_zero, 
    zero_add_dur_expr, 
    add_zero_dur_expr, -- add_monoid
    neg_dur_expr,                                                                  -- has_neg
    sub_dur_expr_dur_expr,                                                              -- has_sub
    sub_eq_add_neg_dur_expr,                                                       -- new
⟩ -/

lemma add_left_neg_dur_expr : ∀ a : duration_expr sp, -a + a = 0 := sorry
instance : add_group (duration_expr sp) := sorry/-⟨
    -- sub_neg_monoid
    add_dur_expr_dur_expr, add_assoc_dur_expr, dur_expr_zero, zero_add_dur_expr, add_zero_dur_expr, -- add_monoid
    neg_dur_expr,                                                                  -- has_neg
    sub_dur_expr_dur_expr,                                                              -- has_sub
    sub_eq_add_neg_dur_expr, 
    -- new
    add_left_neg_dur_expr,
⟩ -/

lemma add_comm_dur_expr : ∀ a b : duration_expr sp, a + b = b + a := sorry
instance add_comm_semigroup_dur_expr : add_comm_semigroup (duration_expr sp) := ⟨
    -- add_semigroup
    add_dur_expr_dur_expr, 
    add_assoc_dur_expr,
    add_comm_dur_expr,
⟩

instance add_comm_monoid_dur_expr : add_comm_monoid (duration_expr sp) := sorry/-⟨
-- add_monoid
    -- add_semigroup
    add_dur_expr_dur_expr, 
    add_assoc_dur_expr, 
    -- has_zero
    dur_expr_zero,
    -- new structure 
    zero_add_dur_expr, 
    add_zero_dur_expr,
-- add_comm_semigroup (minus repeats)
    add_comm_dur_expr,
⟩-/

instance has_scalar_dur_expr : has_scalar scalar_expr (duration_expr sp) := ⟨
smul_dur_expr,
⟩
instance : has_one scalar_expr := sorry
instance : monoid scalar_expr := sorry
instance : has_zero scalar_expr := sorry

lemma one_smul_dur_expr : ∀ b : duration_expr sp, (1 : scalar_expr) • b = b := sorry
lemma mul_smul_dur_expr : ∀ (x y : scalar_expr) (b : duration_expr sp), (x * y) • b = x • y • b := sorry
instance mul_action_dur_expr : mul_action scalar_expr (duration_expr sp) := sorry /-⟨
one_smul_dur_expr,
mul_smul_dur_expr,
⟩ -/

lemma smul_add_dur_expr : ∀(r : scalar_expr) (x y : duration_expr sp), r • (x + y) = r • x + r • y := sorry
lemma smul_zero_dur_expr : ∀(r : scalar_expr), r • (0 : duration_expr sp) = 0 := sorry
instance distrib_mul_action_K_dur_exprKx : distrib_mul_action scalar_expr (duration_expr sp) := sorry/-⟨
smul_add_dur_expr,
smul_zero_dur_expr,
⟩ -/

-- renaming vs template due to clash with name "s" for prevailing variable
lemma add_smul_dur_expr : ∀ (a b : scalar_expr) (x : duration_expr sp), (a + b) • x = a • x + b • x := sorry
lemma zero_smul_dur_expr : ∀ (x : duration_expr sp), (0 : scalar_expr) • x = 0 := sorry
instance module_K_durationK : module scalar_expr (duration_expr sp) := sorry--⟨ add_smul_dur_expr, zero_smul_dur_expr ⟩ 

instance add_comm_group_dur_expr : add_comm_group (duration_expr sp) := sorry/-⟨
-- add_group
    add_dur_expr_dur_expr, add_assoc_dur_expr, dur_expr_zero, zero_add_dur_expr, add_zero_dur_expr, -- add_monoid
    neg_dur_expr,                                                                  -- has_neg
    sub_dur_expr_dur_expr,                                                              -- has_sub
    sub_eq_add_neg_dur_expr, 
    add_left_neg_dur_expr,
-- commutativity
    add_comm_dur_expr,
⟩-/


instance : module scalar (duration_expr sp) := sorry


/-
    ********************
    *** Affine space ***
    ********************
-/


/-
Affine operations
-/
instance : has_add (duration_expr sp) := ⟨add_dur_expr_dur_expr⟩
instance : has_zero (duration_expr sp) := ⟨dur_expr_zero⟩
instance : has_neg (duration_expr sp) := ⟨neg_dur_expr⟩

/-
Lemmas needed to implement affine space API
-/

def sub_time_expr_time_expr {f : time_frame_expr} {sp : time_space_expr f}  (p1 p2 : time_expr sp) : duration_expr sp := 
    duration_expr.sub_time_time p1 p2
def add_time_expr_dur_expr {f : time_frame_expr} {sp : time_space_expr f}  (p : time_expr sp) (v : duration_expr sp) : time_expr sp := 
    time_expr.add_dur_time v p
def add_dur_expr_time_expr {f : time_frame_expr} {sp : time_space_expr f}  (v : duration_expr sp) (p : time_expr sp) : time_expr sp := 
    time_expr.add_dur_time v p

def aff_dur_expr_group_action {f : time_frame_expr} {sp : time_space_expr f} : duration_expr sp → time_expr sp → time_expr sp := add_dur_expr_time_expr
instance {f : time_frame_expr} {sp : time_space_expr f} : has_vadd (duration_expr sp) (time_expr sp) := ⟨λd, λt, time_expr.add_dur_time d t⟩

def spf : (time_space_expr (|time_std_frame|)) := |(time_std_space)|

variables (d d2 : duration_expr spf) (t : time_expr spf) (df : duration_expr spf)

#check time_expr.add_dur_time d t

lemma zero_dur_expr_vadd'_a1 {f : time_frame_expr} {sp : time_space_expr f} : ∀ p : time_expr sp, (0 : duration_expr sp) +ᵥ p = p := sorry
lemma dur_expr_add_assoc'_a1 : ∀ (g1 g2 : duration_expr sp) (p : time_expr sp), g1 +ᵥ (g2 +ᵥ p) = (g1 + g2) +ᵥ p := sorry
instance dur_expr_add_action: add_action (duration_expr sp) (time_expr sp) := 
sorry--⟨ aff_dur_expr_group_action, zero_dur_expr_vadd'_a1, dur_expr_add_assoc'_a1 ⟩ 

def aff_time_expr_group_sub : time_expr sp → time_expr sp → duration_expr sp := sub_time_expr_time_expr
instance time_expr_has_vsub : has_vsub (duration_expr sp) (time_expr sp) := ⟨ aff_time_expr_group_sub ⟩ 


instance : nonempty (time_expr sp) := ⟨time_expr.lit (mk_time sp.value  0)⟩

lemma time_expr_vsub_vadd_a1 : ∀ (p1 p2 : (time_expr sp)), (p1 -ᵥ p2) +ᵥ p2 = p1 := sorry
lemma time_expr_vadd_vsub_a1 : ∀ (g : duration_expr sp) (p : time_expr sp), g +ᵥ p -ᵥ p = g := sorry
instance aff_time_expr_torsor : add_torsor (duration_expr sp) (time_expr sp) := sorry

notation t+ᵥv := add_dur_expr_time_expr v t
notation d•k :=  smul_dur_expr k d
notation tr⬝d := duration_expr.apply_duration_lit tr d
notation tr⬝t := time_expr.apply_time_lit tr t

end lang.time
