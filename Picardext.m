freeze;

/////////////////////////////////////////////////////
// Picard Group of orders in etale algebras over \Q
// Stefano Marseglia, Stockholm University, stefanom@math.su.se
// http://staff.math.su.se/stefanom/
/////////////////////////////////////////////////////

import "usefulfunctions.m": AllPossibilities;

/*
version 0.3->0.4 there is some problem with the function IsPrincipal. In the in-built IsPrincipal for maximal orders in NumberFields there was a bug that was giving false negatives. It seems that it is solved if we compute the ClassGroup before running IsPrincipal. This problem is not solved in Magma V2.23-11
version 0.2->0.3 new stuff has been moved in the various packages (nothing in this one).
                 IsPrincipal_prod, PicardGroup_prod and UnitGroup2_prod are now be internal functions only for maximal orders, not intrinsics.
                 cleaning of the code. publication on the webpage 13/04
version 0.1->0.2 '*' is over-written, the old version of the code is commented and IsFiniteEtale is required
*/
/* list of function
intrinsic ResidueRingUnits(S::AlgAssVOrd,I::AlgAssVOrdIdl) -> GrpAb,Map
residue_class_field_primitive_element := function(P)
residue_class_ring_unit_subgroup_generators:=function(S, F)
PicardGroup_prod_internal:=function(O)
intrinsic PicardGroup(S::AlgAssVOrd) -> GrpAb, Map
UnitGroup2_prod_internal:=function(O)
intrinsic UnitGroup2(S::AlgAssVOrd) -> GrpAb, Map
intrinsic IsPrincipal_prod(I::AlgAssVOrdIdl)->BoolElt, AlgAssElt
intrinsic IsPrincipal(I::AlgAssVOrdIdl)->BoolElt, AlgAssElt
*/

/*TODO:
-Discrete Log in ResidueRingUnits (is it necessary?)
-Discrete Log for PicardGroup (it seems that I have already implemented it for PicardGroup_prod)
*/

declare attributes AlgAssVOrd:PicardGroup;
declare attributes AlgAssVOrd:UnitGroup;

intrinsic ResidueRingUnits(S::AlgAssVOrd,I::AlgAssVOrdIdl) -> GrpAb,Map
{returns the group (S/I)^* and a map (S/I)^* -> S. It is required S to be maximal }
      require IsFiniteEtale(Algebra(S)): "the algebra of definition must be finite and etale over Q";
/*CODE TO be IMPROVEd. Dicrete log missing
  gens:=residue_class_ring_unit_subgroup_generators(S,I);
  F:=FreeAbelianGroup(#gens);
  rel:=[];
  for i in [1..#gens] do
      g:=gens[i];
      ord:=1;
      while g^ord - 1 not in I do ord:=ord+1; end while; //improve this line!!!
      Append(~rel,ord*F.i);
  end for;
  G,g:=quo<F|rel>;
  map:=<G -> Algebra(S) | x:->&*[gens[i]^Eltseq(x)[i] : i in [1..#gens]]
  return G, map;*/

//the following code works only for maximal orders
      require IsMaximal(S): "implemented only for the maximal order";
      test,I_asProd:=IsProductOfIdeals(I);
      assert test;
      A:=Algebra(S);
      n:=#I_asProd;
      ray_res_rings:=[];
      ray_res_rings_maps:=[**];
      for i in [1..n] do
	IL:=I_asProd[i];
        OL:=Order(IL);
        assert IsMaximal(OL);
	R,r:=RayResidueRing(IL);
	Append(~ray_res_rings,R);
	Append(~ray_res_rings_maps,r);
      end for;
      D,mRD,mDR:=DirectSum(ray_res_rings);
      map_ResRing_S:=function(x)
          return &+[A`NumberFields[i,2](ray_res_rings_maps[i](mDR[i](x))) : i in [1..n]];
      end function;
      map_S_ResRing:=function(y)
	  if not y in S then error "the element is not in the order"; end if;
	  comp:=Components(y);
          assert #ray_res_rings_maps eq #comp;
assert forall{i : i in [1..n] | comp[i] in Codomain(ray_res_rings_maps[i])};
          return &+[mRD[i](comp[i]@@ray_res_rings_maps[i]) : i in [1..n]];
      end function;
      map:=map<D -> A | x:->map_ResRing_S(x) , y:->map_S_ResRing(y) >;
      assert forall{ gen: gen in Generators(D) | (map(gen))@@map eq gen };
      return D,map;
end intrinsic;

residue_class_field_primitive_element := function(P)
//given a maximal ideal P in S, returns a generator of (S/P)* as an element of S;
    S:=Order(P);
    Q,m:=ResidueRing(S,P);
    ord:=#Q-1; //ord = #(S/P)-1;
assert #Factorization(ord+1) eq 1; // #(S/P) must be a prime power
    proper_divisors_ord:=Exclude(Divisors(ord),ord);
    repeat
	repeat 
	    a:=Random(Q);
	until a ne Zero(Q);
    until forall{f : f in proper_divisors_ord | m((a@@m)^f) ne m(One(Algebra(S)))};
    return a@@m;
end function;

residue_class_ring_unit_subgroup_generators:=function(S, F)
// determine generators of the subgroup of (S/F)^* as elements of A=Algebra(S)
  
  A:=Algebra(S);
  O:=MaximalOrder(A);
  Fm:=ideal<O| ZBasis(F)>;
  l:=Factorization(Fm);
  l2:=[<ideal<S|ZBasis(x[1])> meet S,x[2]>: x in l]; 
  primes:={x[1]:x in l2};
  primes:=[<x, Maximum([y[2]: y in l2 |y[1] eq x])>:x in primes];
  elts:={};
  for a in primes do
    idp:=a[1];
    rest:=ideal<S|One(S)>;
    for b in primes do
      if b[1] ne idp then
         rest:=rest*(b[1]^b[2]);
      end if;
    end for;
    //Compute primitive elt for residue field
    c:=residue_class_field_primitive_element(idp);
    c:=ChineseRemainderTheorem(a[1]^a[2],rest,c,One(A));
    Include(~elts,c);
    b:=1;
    while b lt a[2] do
      M:=ZBasis(idp);
      M:=[1+x:x in M];
      for elt in M do
        c:=ChineseRemainderTheorem((a[1]^a[2]),rest,elt,One(A));
        Include(~elts,c);
      end for;
      b:=b*2;idp:=idp^2;
    end while;
  end for;
  assert forall{x : x in elts | x in S and not x in F};
  return elts;
end function;

PicardGroup_prod_internal:=function(O)
//computes the PicardGroup of a product of order in a product of number fields and returns the group (as a direct product) and a sequence of representatives
  if assigned O`PicardGroup then return O`PicardGroup[1],O`PicardGroup[2]; end if;
  A:=Algebra(O);
  assert IsMaximal(O); // this function should be used only for maximal orders
  test,O_asProd:=IsProductOfOrders(O);
  assert test; //O must be a product of orders
  assert #A`NumberFields eq #O_asProd;
  groups_maps_fields_maps:=[**];
  for i in [1..#O_asProd] do
    L:=A`NumberFields[i];
    OL:=O_asProd[i];
    GL,gL:=PicardGroup(OL);
if #GL ne 1 then assert forall{y : y in [gL(z) : z in GL] | MultiplicatorRing(y) eq OL}; end if; //this is a detector for bugs for the PicardGroup function. It might be better with a require or assert2.
    Append(~groups_maps_fields_maps,<GL,gL,L[1],L[2]>);
  end for;
  assert #groups_maps_fields_maps eq #A`NumberFields;
  G,g,Gproj:=DirectSum([T[1] : T in groups_maps_fields_maps]);
  
  if #G eq 1 then
      from_G_to_ideals:=function(x)
	  return ideal<O|One(O)>;
      end function;
      from_ideals_to_G:=function(y)
	  assert IsInvertible(y);
	  return Zero(G);
      end function;
      codomain:=Parent(ideal<O|One(O)>);
      return G,map<G -> codomain | x:-> from_G_to_ideals(x) , y:->from_ideals_to_G(y) >;
  else
      zerosinO:=[ ideal<O|[ T[4](y) : y in Basis(T[2](Zero(T[1])),T[3])]> : T in groups_maps_fields_maps];
      assert &+zerosinO eq ideal<O|One(O)>;
      geninO:=[]; //this will contain the the ideals of O corresponding to the generators of G
      for i in [1..#Generators(G)] do
	  gen:=G.i;
	  gens_inA:=[];
	  for i in [1..#groups_maps_fields_maps] do
	      T:=groups_maps_fields_maps[i];
	      gLi:=T[2];
	      idLi:=gLi(Gproj[i](gen));
	      gens_inA:=gens_inA cat[T[4](g) : g in Basis(idLi,T[3])];
	  end for;
          gen_O:=ideal<O|gens_inA>;
	  Append(~geninO,gen_O);
      end for;
      assert #geninO eq #Generators(G);      
      rep_idinA:= function(x)
	coeff:=Eltseq(x);
	id:=&*[geninO[i]^coeff[i] : i in [1..#coeff]];
	return id;
      end function;
      
      inverse_map:=function(id)
	    _,d:=IsIntegral(id);
            id:=d*id;
	    test,id_asprod:=IsProductOfIdeals(id);
	    assert test;
	    return &+[g[i](id_asprod[i]@@groups_maps_fields_maps[i,2]) : i in [1..#id_asprod]];
      end function;

      Codomain:=Parent(rep_idinA(Zero(G)));
      mapGtoO:=map<G -> Codomain | rep:-> rep_idinA(rep) , y:->inverse_map(y) >; 
      assert forall{a : a in Generators(G)| (mapGtoO(a))@@mapGtoO eq a};
      O`PicardGroup:=<G,mapGtoO>;
      return G,mapGtoO;
  end if;
end function;

intrinsic PicardGroup(S::AlgAssVOrd) -> GrpAb, Map
{return the PicardGroup of the order S, which is not required to be maximal, and a map from the PicardGroup to a set of representatives of the ideal classes}
    if assigned S`PicardGroup then return S`PicardGroup[1],S`PicardGroup[2]; end if;
    if IsMaximal(S) then return PicardGroup_prod_internal(S); end if;
    require IsFiniteEtale(Algebra(S)): "the algebra of definition must be finite and etale over Q";
    A:=Algebra(S);
    O:=MaximalOrder(A);
    GO,gO:=PicardGroup_prod_internal(O);
    F:=Conductor(S);
    FO:=ideal<O|ZBasis(F)>;
    gens_GO_in_S:=[]; //coprime with FO, in S and then meet S   
    gens_GO_in_O:=[]; //coprime with FO, in O
    if #GO gt 1 then
        for i in [1..#Generators(GO)] do
          I:=gO(GO.i);
          c:=CoprimeRepresentative(I,FO);
          cI:=c*I;
          Append(~gens_GO_in_S,ideal<S|ZBasis(cI)> meet S);
          Append(~gens_GO_in_O,cI);
        end for;
    
        mGO_to_S:=function(rep)  
            coeff:=Eltseq(rep);
            idS:=&*[(gens_GO_in_S[i])^coeff[i] : i in [1..#coeff] ];
            return idS;
        end function;
    else
        GO:=FreeAbelianGroup(0);
        gens_GO_in_S:=[];
        mGO_to_S:=function(rep)
               idS:=ideal<S|One(A)>;
          return idS;
        end function;
    end if;

    R,r:=ResidueRingUnits(O,FO);
    Sgens:=residue_class_ring_unit_subgroup_generators(S,F);
    UO,uO:=UnitGroup2(O);

    H:=FreeAbelianGroup(#Generators(GO));
    D, mRD, mHD, mDR, mDH := DirectSum(R,H);    
    relDresidue:=[mRD(x@@r) : x in Sgens];
    relDunits:=[mRD(uO(x)@@r)  : x in Generators(UO)];
    // glue R and GO
    relDglue := [];   
    assert #gens_GO_in_S eq #InvariantFactors(GO);
    for i in [1..#gens_GO_in_S] do
      is_princ, gen := IsPrincipal(gens_GO_in_O[i]^InvariantFactors(GO)[i]);
      assert is_princ;
      Append(~relDglue,-mRD(gen@@r)+mHD(H.i*InvariantFactors(GO)[i]));
    end for;
    
    P, mDP := quo<D|relDresidue cat relDunits cat relDglue>;
    gens_P_in_D:=[P.i@@mDP : i in [1..#Generators(P)]];
    if #P gt 1 then
        generators_ideals:=[];
        for gen in gens_P_in_D do
	    id1:=ideal<S|ZBasis(ideal<O|r(mDR(gen))>)> meet S;
            id2:=mGO_to_S(mDH(gen)); //something wrong here!
            gen_inS:=id1*id2;
            Append(~generators_ideals,gen_inS);
       end for;
    else
       return P,map<P->[ideal<S|One(S)>] | rep:->ideal<S|One(S)>>;
    end if;

    representative_picard_group := function(rep)
	repseq := Eltseq(rep);
	return &*[generators_ideals[i]^repseq[i]:i in [1..#generators_ideals]];
    end function;
    
//ADD the discete log!
    Codomain:=Parent(representative_picard_group(Zero(P)));
    p:=map<P -> Codomain | id:->representative_picard_group(id)>;
    S`PicardGroup:=<P,p>;
    return P,p;    
end intrinsic;

UnitGroup2_prod_internal:=function(O)
//returns the UnitGroup of a order which is a produc of orders
  if assigned O`UnitGroup then return O`UnitGroup[1],O`UnitGroup[2]; end if;
  assert IsMaximal(O); //this function should be used only for maximal orders
  test,O_asProd:=IsProductOfOrders(O);
  assert test; //the order must be a product
  A:=Algebra(O);
  idemA:=OrthogonalIdempotents(A);
  U_asProd:=[];
  u_asProd:=[**];
  for OL in O_asProd do
    U,u:=UnitGroup(OL);
    Append(~U_asProd,U);
    Append(~u_asProd,u);
  end for;
  Udp,udp,proj_Udp:=DirectSum(U_asProd);
  gensinA:=[&+[A`NumberFields[j,2](u_asProd[j](proj_Udp[j](Udp.i))) : j in [1..#U_asProd]] : i in [1..#Generators(Udp)] ];

  rep_inA:=function(rep)
     coeff:=Eltseq(rep);
     return &*[gensinA[i]^coeff[i] : i in [1..#coeff]];
  end function;
  
  disc_log:=function(x)
     comp_x:=Components(A ! x);
     x_in_Udp:=&*[ udp[i](comp_x[i]@@u_asProd[i]) : i in [1..#comp_x] ];
     return x_in_Udp;
  end function;

  maptoA:=map<Udp -> O | rep :-> rep_inA(rep) , y :-> disc_log(y) >;
  O`UnitGroup:=<Udp,maptoA>;
  return Udp,maptoA;
end function;

intrinsic UnitGroup2(S::AlgAssVOrd) -> GrpAb, Map
{return the unit group of a order in a etale algebra}
    if assigned S`UnitGroup then return S`UnitGroup[1],S`UnitGroup[2]; end if;
    if IsMaximal(S) then return UnitGroup2_prod_internal(S); end if;
    require IsFiniteEtale(Algebra(S)): "the algebra of definition must be finite and etale over Q";
    A:=Algebra(S);
    require assigned A`NumberFields: "the order must lie in a product of number fields";
    O:=MaximalOrder(S);
    UO,uO:=UnitGroup2_prod_internal(O);
    F:=Conductor(S);
    FO:=ideal<O|ZBasis(F)>;
    
    //Let's build B=(O/FO)^*/(S/F)^*
    R,r:=ResidueRingUnits(O,FO);
    gens_SF:=residue_class_ring_unit_subgroup_generators(S,F);
    B,b:=quo<R| [ a@@r : a in gens_SF ]>;
    
    img_gensUO_in_B:=[ b(uO(UO.i)@@r) : i in [1..#Generators(UO)] ];
    m:=hom<UO -> B | img_gensUO_in_B >;
    P:=Kernel(m);
    gens_P_in_A:=[uO(UO ! P.i) : i in [1..#Generators(P)] ];
    p_codomain:=Parent(gens_P_in_A[1]);
    
    map_P_to_S:=function(rep)
	coeff:=Eltseq(rep);
	assert #coeff eq #gens_P_in_A;
	elt:=&*[gens_P_in_A[i]^coeff[i] : i in [1..#coeff]];
	return elt;
    end function;
    
    map_S_to_P:=function(y)
	elt := P ! (y@@uO);
	return elt;
    end function;
    
    p:=map<P -> p_codomain | x:->map_P_to_S(x), y:->map_S_to_P(y)  >;
    
    S`UnitGroup:=<P,p>;
    return P,p;
end intrinsic;

IsPrincipal_prod_internal:=function(I)
//returns if the argument is a principal ideal; if so the function returns also the generator. It works only for products of ideals
  assert IsMaximal(Order(I)); //this function should be called only for ideals of the maximal order
  test,I_asProd:=IsProductOfIdeals(I);
  assert test; //this function should be called only for ideals of the maximal order, hence I is a product
  S:=Order(I);
  A:=Algebra(S);
  gen:=Zero(A);
  for i in [1..#I_asProd] do
	IL:=I_asProd[i];
        L:=A`NumberFields[i];
OL,oL:=PicardGroup(Order(IL)); //this is to prevent a bug of the in-built function IsPrincipal (see the changelog)       
        testL,genL:=IsPrincipal(IL);
assert (Zero(OL) eq (IL@@oL)) eq testL;
        if not testL then return false,_; end if;
        gen:=gen+L[2](L[1] ! genL);
  end for;
  assert ideal<S|gen> eq I;
  return true,gen;
end function;

intrinsic IsPrincipal(I1::AlgAssVOrdIdl)->BoolElt, AlgAssElt
{return if the argument is a principal ideal; if so the function returns also the generator.}
    require IsFiniteEtale(Algebra(I1)): "the algebra of definition must be finite and etale over Q";
    if not IsInvertible(I1) then return false,_; end if;
    S:=Order(I1);    
    if IsMaximal(S) then return IsPrincipal_prod_internal(I1); end if;
    A:=Algebra(S);
    O:=MaximalOrder(A);
    F:=Conductor(S);
    FO:=ideal<O|ZBasis(F)>;
    cop:=CoprimeRepresentative(I1,F);
    I:=cop*I1;
    IO:=ideal<O|ZBasis(I)>; 
    is_princ_IO,gen_IO:=IsPrincipal_prod_internal(IO);
    if not is_princ_IO then return false,_; end if;
    R,r:=ResidueRingUnits(O,FO);
    if Order(R) eq 1 then
        assert ideal<S|gen_IO> eq I;
	return true, gen_IO*cop^-1;
    end if;
    UO,uO:=UnitGroup2(O);
    Sgens:=residue_class_ring_unit_subgroup_generators(S,F);
    B,b:=quo<R|[gen@@r : gen in Sgens]>;
    gens_UO_inB:=[ b(uO(UO.i)@@r) : i in [1..#Generators(UO)]  ];
    h:=hom<UO -> B | gens_UO_inB >;
    hUO:=Image(h);
    if not b(gen_IO@@r) in hUO then return false,_; end if;
//now we know that I is principal. let's find a generator
    UQ,qQ:=quo<UO|Kernel(h)>;  //UQ = O*/S*
    alpha:=hom<UQ -> B | [UQ.i@@qQ @uO @@r @b : i in [1..#Generators(UQ)]]>;
    is_princ , elt :=HasPreimage(gen_IO@@r@b,alpha);
    if is_princ then
        gen_I:=gen_IO*(elt@@qQ@uO)^-1;
        gen_I1:=gen_I*cop^-1;
        assert ideal<S|gen_I1> eq I1;
        return true , gen_I1;
    else
        return false, _;
    end if;  
end intrinsic;
