!======================================================================!
  subroutine ConvScheme(phi_f, s,                            &
                        Phi,                                &
                        dPhidi, dPhidj, dPhidk, Di, Dj, Dk, &
                        blenda) 
!----------------------------------------------------------------------!
! Computes the value at the cell face using different convective       !
! schemes. In this subroutine I try to follow the nomenclature from    !
! Basara's and Przulj's AIAA paper.                                    !
!----------------------------------------------------------------------!
!------------------------------[Modules]-------------------------------!
  use all_mod
  use pro_mod
!----------------------------------------------------------------------!
  implicit none
!-----------------------------[Arguments]------------------------------!
  real          :: phi_f
  integer       :: s
  real          :: Phi(-NbC:NC)
  real          :: dPhidi(-NbC:NC), dPhidj(-NbC:NC), dPhidk(-NbC:NC)
  real          :: Di(NS),          Dj(NS),          Dk(NS)
  integer       :: blenda
!-------------------------------[Locals]-------------------------------!
  integer       :: c1, c2, C, D
  real          :: fj ! flow oriented interpolation factor
  real          :: gD, gU, alfa, beta1, beta2 
  real          :: Phij, PhiU, PhiUstar, rj, sign, GammaC, Beta
!======================================================================!
!
!               Flux > 0
!   +---------+---------+---------+---------+
!   |         |         |         |         |
!   |         |   c1    |   c2    |         |
!   |    o    |    o  ==s=>  o    |    o    |----> xi
!   |    U    |    C    |    D    |         |
!   |         |         |         |         |
!   +---------+---------+---------+---------+   
!
!
!               Flux < 0
!   +---------+---------+---------+---------+
!   |         |         |         |         |
!   |         |   c1    |   c2    |         |
!   |    o    |    o  <=s==  o    |    o    |----> xi
!   |         |    D    |    C    |    U    |
!   |         |         |         |         |
!   +---------+---------+---------+---------+   
!
!----------------------------------------------------------------------!

  c1 = SideC(1,s)
  c2 = SideC(2,s)

  if(Flux(s) > 0.0) then ! goes from c1 to c2
    fj   = 1.0 - f(s)
    C    = c1
    D    = c2
    sign = +1.0
  else ! Flux(s) < 0.0   ! goes from c2 to c1
    fj = f(s)
    C    = c2
    D    = c1
    sign = -1.0
  end if

  if(Flux(s) > 0.0) then
    PhiUstar = Phi(D) - 2.0 * ( dPhidi(C)*Di(s) &
                               +dPhidj(C)*Dj(s) &
                               +dPhidk(C)*Dk(s) )
  else
    PhiUstar = Phi(D) + 2.0 * ( dPhidi(C)*Di(s) &
                               +dPhidj(C)*Dj(s) &
                               +dPhidk(C)*Dk(s) )
  end if

  PhiU = max( phi_min(C), min(PhiUstar, phi_max(C)) )

  rj = ( Phi(C) - PhiU ) / ( Phi(D)-Phi(C) + 1.0e-16 )

  gD = 0.5 * fj * (1.0+fj)
  gU = 0.5 * fj * (1.0-fj)

  if(blenda == CDS) then
    Phij = fj
  else if(blenda == QUICK) then
    rj = ( Phi(C) - PhiU ) / ( Phi(D)-Phi(C) + 1.0e-12 )
    alfa = 0.0
    Phij = (gD - alfa) + (gU + alfa) * rj
  else if(blenda == LUDS) then
    alfa = 0.5 * fj * (1+fj)
    Phij = (gD - alfa) + (gU + alfa) * rj
  else if(blenda == MINMOD) then
    Phij = fj * max(0.0, min(rj,1.0))
  else if(blenda == SMART) then
    beta1 = 3.0
    beta2 = 1.0
    Phij = max( 0.0, min( (beta1-1.0)*rj, gD+gU*rj, beta2 ) )
  else if(blenda == AVL_SMART) then
    beta1 = 1.0 + fj*(2.0+fj) 
    beta2 = fj*(2.0-fj) 
    Phij = max( 0.0, min( (beta1-1.0)*rj, gD+gU*rj, beta2 ) )
  else if(blenda == SUPERBEE) then
    Phij = 0.5 * max( 0.0, min( 2.0*rj,1.0 ), min( rj,2.0 ) )
  else if(blenda == YES) then
    return
  end if

  phi_f = Phi(C) + Phij * sign * (Phi(c2)-Phi(c1))

  if(blenda == GAMMA) then
    Beta = 0.1

    if(Flux(s) > 0.0) then
      PhiUstar = 1.0 - (Phi(D) - Phi(C))/(2.0 * ( dPhidi(C)*Di(s) &
                                 +dPhidj(C)*Dj(s) &
                                 +dPhidk(C)*Dk(s)))
    else
      PhiUstar = 1.0 + (Phi(D) - Phi(C))/(2.0 * ( dPhidi(C)*Di(s) &
                                 +dPhidj(C)*Dj(s) &
                                 +dPhidk(C)*Dk(s)))
    end if

    GammaC = PhiUstar/Beta

    if(PhiUstar < Beta.and.PhiUstar > 0.0) then
      phi_f = (1.0 - GammaC*(1.0 - f(s)))*Phi(C) + GammaC*(1.0 - f(s))*Phi(D)
    else if(PhiUstar < 1.0.and.PhiUstar >= Beta) then
       phi_f = f(s)*Phi(C) + (1.0 - f(s))*Phi(D)
    else
      phi_f = Phi(C)
    end if
  end if 

  RETURN 

  end subroutine ConvScheme
