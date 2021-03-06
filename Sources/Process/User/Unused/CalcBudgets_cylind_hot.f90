!======================================================================!
  subroutine CalcBudgets_hot(grid, n0, n1, n2)  
!----------------------------------------------------------------------!
!   Calculates time averaged velocity and velocity fluctuations.       !
!----------------------------------------------------------------------!
!------------------------------[Modules]-------------------------------!
  use all_mod
  use pro_mod
  use les_mod
  use par_mod
!----------------------------------------------------------------------!
  implicit none
!-----------------------------[Arguments]------------------------------!
  integer :: n0, n1, n2
!-------------------------------[Locals]-------------------------------!
  integer :: c1, c2, s, c, n, new, i, newhot
  real    :: VolDom, Lf, Lmix, Esgs, vol1
  real    :: Utan, Urad, Utan_mean, Urad_mean, R, Flux_mean, Us, Vs, Ws   
  real    :: Fim1, Fex1, Fim2, Fex2, Fim3, Fex3, Fim4, Fex4, Fim5, Fex5, Fim6, Fex6
  real    :: Fim7, Fex7, Fim8, Fex8, Fim9, Fex9, Fim10, Fex10 
  real    :: uu_s, vv_s, ww_s, uv_s, uw_s, vw_s, A0, R2, R1, PHIs1, PHIs2,PHIs3 
  real    :: ut_s, vt_s, wt_s, tt_s, A1, A2, CONc_s

  real    :: G1r, G1t, G2r, G2t, G3r, G3t, G4r, G4t, G5r, G5t 
  real    :: G6r, G6t, G7r, G7t, G8r, G8t, G9r, G9t, Gr, Gt 
  real    :: Gz, G1z, G2z, G3z, G4z, G5z, G6z, G7z, G8z, G9z
  real    :: G10r, G10t, G10z

  real,allocatable :: Puu(:), Pvv(:), Pww(:), Puv(:), Puw(:), Pvw(:)
  real,allocatable :: Put(:), Pvt(:), Pwt(:), Ptt(:)
  real,allocatable :: dUdr(:), dUdt(:), dUdz(:)
  real,allocatable :: dVdr(:), dVdt(:), dVdz(:)
  real,allocatable :: dWdr(:), dWdt(:), dWdz(:) 
  real,allocatable :: Diss_uu(:), Diss_vv(:), Diss_ww(:) 
  real,allocatable :: Diss_uv(:), Diss_uw(:), Diss_vw(:) 
  real,allocatable :: Diss_ut(:), Diss_vt(:), Diss_wt(:), Diss_tt(:) 
  real,allocatable :: C_uu(:), C_vv(:), C_ww(:) 
  real,allocatable :: C_uv(:), C_uw(:), C_vw(:) 
  real,allocatable :: C_ut(:), C_vt(:), C_wt(:), C_tt(:) 
  real,allocatable :: Difv_uu(:), Difv_vv(:), Difv_ww(:) 
  real,allocatable :: Difv_uv(:), Difv_uw(:), Difv_vw(:) 
  real,allocatable :: Difv_ut(:), Difv_vt(:), Difv_wt(:), Difv_tt(:) 
  real,allocatable :: Difv2_ut(:), Difv2_vt(:), Difv2_wt(:)
  real,allocatable :: Dift_uu(:), Dift_vv(:), Dift_ww(:) 
  real,allocatable :: Dift_uv(:), Dift_uw(:), Dift_vw(:) 
  real,allocatable :: Dift_ut(:), Dift_vt(:), Dift_wt(:), Dift_tt(:) 
  real,allocatable :: R_uu(:), R_vv(:), R_ww(:) 
  real,allocatable :: R_uv(:), R_uw(:), R_vw(:) 
  real,allocatable :: R_ut(:), R_vt(:), R_wt(:) 
  real,allocatable :: PD_uu(:), PD_vv(:), PD_ww(:) 
  real,allocatable :: PD_uv(:), PD_uw(:), PD_vw(:) 
  real,allocatable :: PD_ut(:), PD_vt(:), PD_wt(:) 
!======================================================================!
!   It is obsolete and should be replaced with a newer one.            !
!   See also: Processor                                                !
!----------------------------------------------------------------------!

  new = n1 - n0
  newhot = max(n1 - n2,0)
  new = 100
  newhot = 100
  if(new < 0) return 
  allocate (Puu(-NbC:NC)); Puu = 0.0
  allocate (Pvv(-NbC:NC)); Pvv = 0.0
  allocate (Pww(-NbC:NC)); Pww = 0.0
  allocate (Puv(-NbC:NC)); Puv = 0.0
  allocate (Puw(-NbC:NC)); Puw = 0.0
  allocate (Pvw(-NbC:NC)); Pvw = 0.0

  allocate (Put(-NbC:NC)); Put = 0.0
  allocate (Pvt(-NbC:NC)); Pvt = 0.0
  allocate (Pwt(-NbC:NC)); Pwt = 0.0
  allocate (Ptt(-NbC:NC)); Ptt = 0.0

  allocate (C_uu(-NbC:NC)); C_uu = 0.0
  allocate (C_vv(-NbC:NC)); C_vv = 0.0
  allocate (C_ww(-NbC:NC)); C_ww = 0.0
  allocate (C_uv(-NbC:NC)); C_uv = 0.0
  allocate (C_uw(-NbC:NC)); C_uw = 0.0
  allocate (C_vw(-NbC:NC)); C_vw = 0.0

  allocate (C_ut(-NbC:NC)); C_ut = 0.0
  allocate (C_vt(-NbC:NC)); C_vt = 0.0
  allocate (C_wt(-NbC:NC)); C_wt = 0.0
  allocate (C_tt(-NbC:NC)); C_tt = 0.0

  allocate (R_uu(-NbC:NC)); R_uu = 0.0
  allocate (R_vv(-NbC:NC)); R_vv = 0.0
  allocate (R_ww(-NbC:NC)); R_ww = 0.0
  allocate (R_uv(-NbC:NC)); R_uv = 0.0
  allocate (R_uw(-NbC:NC)); R_uw = 0.0
  allocate (R_vw(-NbC:NC)); R_vw = 0.0

  allocate (R_ut(-NbC:NC)); R_ut = 0.0
  allocate (R_vt(-NbC:NC)); R_vt = 0.0
  allocate (R_wt(-NbC:NC)); R_wt = 0.0

  allocate (dUdr(-NbC:NC)); dUdr = 0.0
  allocate (dUdt(-NbC:NC)); dUdt = 0.0
  allocate (dUdz(-NbC:NC)); dUdz = 0.0
  allocate (dVdr(-NbC:NC)); dVdr = 0.0
  allocate (dVdt(-NbC:NC)); dVdt = 0.0
  allocate (dVdz(-NbC:NC)); dVdz = 0.0
  allocate (dWdr(-NbC:NC)); dWdr = 0.0
  allocate (dWdt(-NbC:NC)); dWdt = 0.0
  allocate (dWdz(-NbC:NC)); dWdz = 0.0

  allocate (Diss_uu(-NbC:NC)); Diss_uu = 0.0
  allocate (Diss_vv(-NbC:NC)); Diss_vv = 0.0
  allocate (Diss_ww(-NbC:NC)); Diss_ww = 0.0
  allocate (Diss_uv(-NbC:NC)); Diss_uv = 0.0
  allocate (Diss_uw(-NbC:NC)); Diss_uw = 0.0
  allocate (Diss_vw(-NbC:NC)); Diss_vw = 0.0

  allocate (Diss_ut(-NbC:NC)); Diss_ut = 0.0
  allocate (Diss_vt(-NbC:NC)); Diss_vt = 0.0
  allocate (Diss_wt(-NbC:NC)); Diss_wt = 0.0
  allocate (Diss_tt(-NbC:NC)); Diss_tt = 0.0

  allocate (Difv_uu(-NbC:NC)); Difv_uu = 0.0
  allocate (Difv_vv(-NbC:NC)); Difv_vv = 0.0
  allocate (Difv_ww(-NbC:NC)); Difv_ww = 0.0
  allocate (Difv_uv(-NbC:NC)); Difv_uv = 0.0
  allocate (Difv_uw(-NbC:NC)); Difv_uw = 0.0
  allocate (Difv_vw(-NbC:NC)); Difv_vw = 0.0

  allocate (Difv_ut(-NbC:NC)); Difv_ut = 0.0
  allocate (Difv_vt(-NbC:NC)); Difv_vt = 0.0
  allocate (Difv_wt(-NbC:NC)); Difv_wt = 0.0
  allocate (Difv2_ut(-NbC:NC)); Difv2_ut = 0.0
  allocate (Difv2_vt(-NbC:NC)); Difv2_vt = 0.0
  allocate (Difv2_wt(-NbC:NC)); Difv2_wt = 0.0
  allocate (Difv_tt(-NbC:NC)); Difv_tt = 0.0

  allocate (Dift_uu(-NbC:NC)); Dift_uu = 0.0
  allocate (Dift_vv(-NbC:NC)); Dift_vv = 0.0
  allocate (Dift_ww(-NbC:NC)); Dift_ww = 0.0
  allocate (Dift_uv(-NbC:NC)); Dift_uv = 0.0
  allocate (Dift_uw(-NbC:NC)); Dift_uw = 0.0
  allocate (Dift_vw(-NbC:NC)); Dift_vw = 0.0

  allocate (Dift_ut(-NbC:NC)); Dift_ut = 0.0
  allocate (Dift_vt(-NbC:NC)); Dift_vt = 0.0
  allocate (Dift_wt(-NbC:NC)); Dift_wt = 0.0
  allocate (Dift_tt(-NbC:NC)); Dift_tt = 0.0

  allocate (PD_uu(-NbC:NC)); PD_uu = 0.0
  allocate (PD_vv(-NbC:NC)); PD_vv = 0.0
  allocate (PD_ww(-NbC:NC)); PD_ww = 0.0
  allocate (PD_uv(-NbC:NC)); PD_uv = 0.0
  allocate (PD_uw(-NbC:NC)); PD_uw = 0.0
  allocate (PD_vw(-NbC:NC)); PD_vw = 0.0

  allocate (PD_ut(-NbC:NC)); PD_ut = 0.0
  allocate (PD_vt(-NbC:NC)); PD_vt = 0.0
  allocate (PD_wt(-NbC:NC)); PD_wt = 0.0

  do c = 1, NC
    R     = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
    R1      = 1.0/R 
    R2      = 1.0/(R*R) 

    Ux(c) = U % mean(c) * xc(c) * R1  + V % mean(c) * yc(c) * R1  
    Vx(c) = -U % mean(c) * yc(c) * R1  + V % mean(c) * xc(c) * R1 

    uu % n(c) = uu % mean(c) - Ux(c) * Ux(c)
    vv % n(c) = vv % mean(c) - Vx(c) * Vx(c)
    ww % n(c) = ww % mean(c) - W % mean(c) * W % mean(c)

    uv % n(c) = uv % mean(c) - Ux(c) * Vx(c)    
    uw % n(c) = uw % mean(c) - Ux(c) * W % mean(c)    
    vw % n(c) = vw % mean(c) - Vx(c) * W % mean(c)    

    ut % n(c) = ut % mean(c) - Ux(c) * T % mean(c)    
    vt % n(c) = vt % mean(c) - Vx(c) * T % mean(c) 
    wt % n(c) = wt % mean(c) - W % mean(c) * T % mean(c)   
    tt % n(c) = tt % mean(c) - T % mean(c) * T % mean(c)   

    U % fluc(c) = U % n(c) * xc(c) * R1  + V % n(c) * yc(c) * R1 - Ux(c)
    V % fluc(c) = -U % n(c) * yc(c) * R1  + V % n(c) * xc(c) * R1 - Vx(c)
    W % fluc(c) = W % n(c) - W % mean(c)
    P % fluc(c) = P % n(c) - P % mean(c)
    T % fluc(c) = T % n(c) - T % mean(c)
  end do

  do c = -NbC, 1
    P % fluc(c) = P % n(c) - P % mean(c)
    T % fluc(c) = T % n(c) - T % mean(c)
    tt % n(c) = tt % mean(c) - T % mean(c) * T % mean(c)
  end do

    
  if(mod(n1,1) == 0) then   ! CHANGED
!----------------------------------------!
!  PRODUCTION OF STRESSES COMPONENTS
!----------------------------------------!
    call GraPhi(Ux,1,PHIx, .TRUE.)  
    call GraPhi(Ux,2,PHIy, .TRUE.)
    call GraPhi(Ux,3,PHIz, .TRUE.)
    call GraPhi(Vx,1,PHI1x, .TRUE.)  
    call GraPhi(Vx,2,PHI1y, .TRUE.)  
    call GraPhi(Vx,3,PHI1z, .TRUE.)  
    call GraPhi(W % mean,1,PHI2x, .TRUE.) 
    call GraPhi(W % mean,2,PHI2y, .TRUE.) 
    call GraPhi(W % mean,3,PHI2z, .TRUE.) 
    call GraPhi(T % mean,1,PHI3x, .TRUE.) 
    call GraPhi(T % mean,2,PHI3y, .TRUE.) 
    call GraPhi(T % mean,3,PHI3z, .TRUE.) 

    do c = 1, NC
      R       = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny 
      R1      = 1.0/R 
      R2      = 1.0/(R*R) 

      dUdr(c) = PHIx(c) * xc(c) * R1  + PHIy(c) * yc(c) * R1 
      dUdt(c) = -PHIx(c) * yc(c) * R1  + PHIy(c) * xc(c) * R1
      dUdz(c) = PHIz(c)

      dVdr(c) = PHI1x(c) * xc(c) * R1  + PHI1y(c) * yc(c) * R1
      dVdt(c) = -PHI1x(c) * yc(c) * R1  + PHI1y(c) * xc(c) * R1
      dVdz(c) = PHI1z(c)

      dWdr(c) = PHI2x(c) * xc(c) * R1  + PHI2y(c) * yc(c) * R1
      dWdt(c) = -PHI2x(c) * yc(c) * R1  + PHI2y(c) * xc(c) * R1
      dWdz(c) = PHI2z(c)

          G1r = PHI3x(c) * xc(c) * R1  + PHI3y(c) * yc(c) * R1
          G1t = -PHI3x(c) * yc(c) * R1  + PHI3y(c) * xc(c) * R1
          G1z = PHI3z(c)

      Puv(c) = Ux(c) * dUdr(c) + Vx(c)/R *  dUdt(c) + W % mean(c)*dUdz(c) - Vx(c)*Vx(c)/R     

      Puu(c) = 2.0*uu % n(c)*dUdr(c) + 2.0*uv % n(c)*R1*dUdt(c) + 2.0*uw % n(c)*dUdz(c) & 
             - 2.0*Vx(c)*R1*uv % n(c)     
      Pvv(c) = 2.0*uv % n(c) * dVdr(c) + 2.0*vv % n(c) * R1 * dVdt(c) + 2.0*vw % n(c) * dVdz(c)  &
             + 2.0*Ux(c) * R1 * vv % n(c)        
      Pww(c) = 0.0  & 
             + 2.0*uw % n(c) * dWdr(c) + 2.0*vw % n(c) * R1 * dWdt(c) + 2.0*ww % n(c) * dWdz(c) 

!      Puv(c) = 0.0 + uv % n(c) * dUdr(c) + vv % n(c) * R1 * dUdt(c) + vw % n(c) * dUdz(c)  &
!             + uu % n(c) * dVdr(c) + uv % n(c) * R1 * dVdt(c) + uw % n(c) * dVdz(c)  &
!             - Vx(c) * R1 * vv % n(c) + Ux(c) * R1 * uv % n(c)
      Puw(c) = 0.0 + uw % n(c) * dUdr(c) + vw % n(c) * R1 * dUdt(c) + ww % n(c) * dUdz(c) &
             + uu % n(c) * dWdr(c) + uv % n(c) * R1 * dWdt(c) + uw % n(c) * dWdz(c)   &
             - Vx(c) * R1 * vw % n(c)  
      Pvw(c) = 0.0 + uw % n(c) * dVdr(c) + vw % n(c) * R1 * dVdt(c) + ww % n(c) * dVdz(c)  &
             + uv % n(c) * dWdr(c) + vv % n(c) * R1 * dWdt(c) + vw % n(c) * dWdz(c)   &
             + Ux(c) * R1 * vw % n(c) 

!      Puw(c) = 0.5*(2.0*uv % n(c)*R1*dUdt(c) + 2.0*uw % n(c)*dUdz(c)  - 2.0*Vx(c)*R1*uv % n(c) + &
!                    2.0*uv % n(c) * dVdr(c) + 2.0*vw % n(c) * dVdz(c) + 2.0*uw % n(c) * dWdr(c) + &
!                    2.0*vw % n(c) * R1 * dWdt(c))
!      Puu(c) = 0.5*(2.0*uu % n(c)*dUdr(c) + 2.0*vv % n(c) * R1 * dVdt(c)  + 2.0*Ux(c) * R1 * vv % n(c)+ &
!                    2.0*ww % n(c) * dWdz(c)) 

      Put(c) = ut % n(c)*dUdr(c) + R1*vt % n(c)*dUdt(c) + wt % n(c)*dUdz(c) + &
               uu % n(c)*G1r + R1*uv % n(c)*G1t + uw % n(c)*G1z - R1*Vx(c)*vt % n(c)
      Pvt(c) = ut % n(c)*dVdr(c) + R1*vt % n(c)*dVdt(c) + wt % n(c)*dVdz(c) + &
               uv % n(c)*G1r + R1*vv % n(c)*G1t + vw % n(c)*G1z + R1*Ux(c)*vt % n(c)
      Pwt(c) = ut % n(c)*dWdr(c) + R1*vt % n(c)*dWdt(c) + wt % n(c)*dWdz(c) + &
               uw % n(c)*G1r + R1*vw % n(c)*G1t + ww % n(c)*G1z
      Ptt(c) = 2.0*ut % n(c)*G1r + 2.0*R1*vt % n(c)*G1t + 2.0*wt % n(c)*G1z 

      C_uu(c)=C_uu(c) + 2.0*R1*Vx(c)*uv % n(c)*volume(c) 
      C_vv(c)=C_vv(c) - 2.0*R1*Vx(c)*uv % n(c)*volume(c)
      C_uv(c)=C_uv(c) + R1*Vx(c)*vv % n(c)*volume(c) + R1*Vx(c)*uu % n(c)*volume(c)
      C_uw(c)=C_uw(c) + R1*Vx(c)*vw % n(c)*volume(c)
      C_vw(c)=C_vw(c) - R1*Vx(c)*uw % n(c)*volume(c)

      C_ut(c)=C_ut(c) + R1*Vx(c)*vt % n(c)*volume(c)
      C_vt(c)=C_vt(c) - R1*Ux(c)*vt % n(c)*volume(c)
    end do    ! c 

!----------------------------------------!
!  CONVECTION & VISCOUS DIFFUSION
!----------------------------------------!

    call GraPhi(uu % n,1,PHIx, .TRUE.) 
    call GraPhi(uu % n,2,PHIy, .TRUE.) 
    call GraPhi(uu % n,3,PHIz, .TRUE.) 

    call GraPhi(vv % n,1,PHI1x, .TRUE.) 
    call GraPhi(vv % n,2,PHI1y, .TRUE.) 
    call GraPhi(vv % n,3,PHI1z, .TRUE.) 

    call GraPhi(ww % n,1,PHI2x, .TRUE.) 
    call GraPhi(ww % n,2,PHI2y, .TRUE.) 
    call GraPhi(ww % n,3,PHI2z, .TRUE.) 

    call GraPhi(uv % n,1,PHI3x, .TRUE.) 
    call GraPhi(uv % n,2,PHI3y, .TRUE.) 
    call GraPhi(uv % n,3,PHI3z, .TRUE.) 

    call GraPhi(uw % n,1,PHI4x, .TRUE.) 
    call GraPhi(uw % n,2,PHI4y, .TRUE.) 
    call GraPhi(uw % n,3,PHI4z, .TRUE.) 

    call GraPhi(vw % n,1,PHI5x, .TRUE.) 
    call GraPhi(vw % n,2,PHI5y, .TRUE.) 
    call GraPhi(vw % n,3,PHI5z, .TRUE.) 

    if(newhot > 0) then
    call GraPhi(ut % n,1,PHI6x, .TRUE.) 
    call GraPhi(ut % n,2,PHI6y, .TRUE.) 
    call GraPhi(ut % n,3,PHI6z, .TRUE.) 

    call GraPhi(vt % n,1,PHI7x, .TRUE.) 
    call GraPhi(vt % n,2,PHI7y, .TRUE.) 
    call GraPhi(vt % n,3,PHI7z, .TRUE.) 

    call GraPhi(wt % n,1,PHI8x, .TRUE.) 
    call GraPhi(wt % n,2,PHI8y, .TRUE.) 
    call GraPhi(wt % n,3,PHI8z, .TRUE.) 

    call GraPhi(tt % n,1,PHI9x, .TRUE.) 
    call GraPhi(tT % n,2,PHI9y, .TRUE.) 
    call GraPhi(tt % n,3,PHI9z, .TRUE.) 
    end if
    do s=1,NS

      c1=SideC(1,s)
      c2=SideC(2,s)

      uu_s =f(s)*uu % n(c1) + (1.0-f(s))*uu % n(c2)
      vv_s =f(s)*vv % n(c1) + (1.0-f(s))*vv % n(c2)
      ww_s =f(s)*ww % n(c1) + (1.0-f(s))*ww % n(c2)
      uv_s =f(s)*uv % n(c1) + (1.0-f(s))*uv % n(c2)
      uw_s =f(s)*uw % n(c1) + (1.0-f(s))*uw % n(c2)
      vw_s =f(s)*vw % n(c1) + (1.0-f(s))*vw % n(c2)
      ut_s =f(s)*ut % n(c1) + (1.0-f(s))*ut % n(c2)
      vt_s =f(s)*vt % n(c1) + (1.0-f(s))*vt % n(c2)
      wt_s =f(s)*wt % n(c1) + (1.0-f(s))*wt % n(c2)
      tt_s =f(s)*tt % n(c1) + (1.0-f(s))*tt % n(c2)
      Us   =f(s)*U % mean(c1) + (1.0-f(s))*U % mean(c2)
      Vs   =f(s)*V % mean(c1) + (1.0-f(s))*V % mean(c2)
      Ws   =f(s)*W % mean(c1) + (1.0-f(s))*W % mean(c2)
      Flux_mean = Us*Sx(s) + Vs*Sy(s) + Ws*Sz(s)
      CONc_s = f(s)*CONc(material(c1)) + (1.0-f(s))*CONc(material(c2))      

      A0 = VISc * Scoef(s)
      A1 = 0.5*(VISc + CONc_s)*Scoef(s)
      A2 = CONc_s*Scoef(s)

      G1r = fF(s)*PHIx(c1) + (1.0-fF(s))*PHIx(c2) 
      G1t = fF(s)*PHIy(c1) + (1.0-fF(s))*PHIy(c2) 
      G1z = fF(s)*PHIz(c1) + (1.0-fF(s))*PHIz(c2) 

      G2r = fF(s)*PHI1x(c1) + (1.0-fF(s))*PHI1x(c2) 
      G2t = fF(s)*PHI1y(c1) + (1.0-fF(s))*PHI1y(c2) 
      G2z = fF(s)*PHI1z(c1) + (1.0-fF(s))*PHI1z(c2) 

      G3r = fF(s)*PHI2x(c1) + (1.0-fF(s))*PHI2x(c2) 
      G3t = fF(s)*PHI2y(c1) + (1.0-fF(s))*PHI2y(c2) 
      G3z = fF(s)*PHI2z(c1) + (1.0-fF(s))*PHI2z(c2) 

      G4r = fF(s)*PHI3x(c1) + (1.0-fF(s))*PHI3x(c2) 
      G4t = fF(s)*PHI3y(c1) + (1.0-fF(s))*PHI3y(c2) 
      G4z = fF(s)*PHI3z(c1) + (1.0-fF(s))*PHI3z(c2) 

      G5r = fF(s)*PHI4x(c1) + (1.0-fF(s))*PHI4x(c2) 
      G5t = fF(s)*PHI4y(c1) + (1.0-fF(s))*PHI4y(c2) 
      G5z = fF(s)*PHI4z(c1) + (1.0-fF(s))*PHI4z(c2) 

      G6r = fF(s)*PHI5x(c1) + (1.0-fF(s))*PHI5x(c2) 
      G6t = fF(s)*PHI5y(c1) + (1.0-fF(s))*PHI5y(c2) 
      G6z = fF(s)*PHI5z(c1) + (1.0-fF(s))*PHI5z(c2) 

      G7r = fF(s)*PHI6x(c1) + (1.0-fF(s))*PHI6x(c2) 
      G7t = fF(s)*PHI6y(c1) + (1.0-fF(s))*PHI6y(c2) 
      G7z = fF(s)*PHI6z(c1) + (1.0-fF(s))*PHI6z(c2) 

      G8r = fF(s)*PHI7x(c1) + (1.0-fF(s))*PHI7x(c2) 
      G8t = fF(s)*PHI7y(c1) + (1.0-fF(s))*PHI7y(c2) 
      G8z = fF(s)*PHI7z(c1) + (1.0-fF(s))*PHI7z(c2) 

      G9r = fF(s)*PHI8x(c1) + (1.0-fF(s))*PHI8x(c2) 
      G9t = fF(s)*PHI8y(c1) + (1.0-fF(s))*PHI8y(c2) 
      G9z = fF(s)*PHI8z(c1) + (1.0-fF(s))*PHI8z(c2) 

      G10r = fF(s)*PHI9x(c1) + (1.0-fF(s))*PHI9x(c2) 
      G10t = fF(s)*PHI9y(c1) + (1.0-fF(s))*PHI9y(c2) 
      G10z = fF(s)*PHI9z(c1) + (1.0-fF(s))*PHI9z(c2) 

      Fim1 =  VISc*( G1r*Sx(s) + G1t*Sy(s) + G1z*Sz(s) )
      Fex1 = ( G1r*Dx(s) + G1t*Dy(s) + G1z*Dz(s))*A0 
 
      Fim2 =  VISc*( G2r*Sx(s) + G2t*Sy(s) + G2z*Sz(s) )
      Fex2 = ( G2r*Dx(s) + G2t*Dy(s) + G2z*Dz(s))*A0 

      Fim3 =  VISc*( G3r*Sx(s) + G3t*Sy(s) + G3z*Sz(s) )
      Fex3 = ( G3r*Dx(s) + G3t*Dy(s) + G3z*Dz(s))*A0 
 
      Fim4 =  VISc*( G4r*Sx(s) + G4t*Sy(s) + G4z*Sz(s) )
      Fex4 = ( G4r*Dx(s) + G4t*Dy(s) + G4z*Dz(s))*A0 
 
      Fim5 =  VISc*( G5r*Sx(s) + G5t*Sy(s) + G5z*Sz(s) )
      Fex5 = ( G5r*Dx(s) + G5t*Dy(s) + G5z*Dz(s))*A0 
 
      Fim6 =  VISc*( G6r*Sx(s) + G6t*Sy(s) + G6z*Sz(s) )
      Fex6 = ( G6r*Dx(s) + G6t*Dy(s) + G6z*Dz(s))*A0 
 
      Fim7 =  0.5*(VISc + CONc_s)*( G7r*Sx(s) + G7t*Sy(s) + G7z*Sz(s) )
      Fex7 = ( G7r*Dx(s) + G7t*Dy(s) + G7z*Dz(s))*A1 
 
      Fim8 =  0.5*(VISc + CONc_s)*( G8r*Sx(s) + G8t*Sy(s) + G8z*Sz(s) )
      Fex8 = ( G8r*Dx(s) + G8t*Dy(s) + G8z*Dz(s))*A1 
 
      Fim9 =  0.5*(VISc + CONc_s)*( G9r*Sx(s) + G9t*Sy(s) + G9z*Sz(s) )
      Fex9 = ( G9r*Dx(s) + G9t*Dy(s) + G9z*Dz(s))*A1 
 
      Fim10=  CONc_s*( G10r*Sx(s) + G10t*Sy(s) + G10z*Sz(s) )
      Fex10= ( G10r*Dx(s) + G10t*Dy(s) + G10z*Dz(s))*A2 
 
      if(c2  > 0) then
        C_uu(c1)=C_uu(c1)-Flux_mean*uu_s
        C_uu(c2)=C_uu(c2)+Flux_mean*uu_s

        C_vv(c1)=C_vv(c1)-Flux_mean*vv_s
        C_vv(c2)=C_vv(c2)+Flux_mean*vv_s

        C_ww(c1)=C_ww(c1)-Flux_mean*ww_s
        C_ww(c2)=C_ww(c2)+Flux_mean*ww_s

        C_uv(c1)=C_uv(c1)-Flux_mean*uv_s
        C_uv(c2)=C_uv(c2)+Flux_mean*uv_s

        C_uw(c1)=C_uw(c1)-Flux_mean*uw_s
        C_uw(c2)=C_uw(c2)+Flux_mean*uw_s

        C_vw(c1)=C_vw(c1)-Flux_mean*vw_s
        C_vw(c2)=C_vw(c2)+Flux_mean*vw_s

        C_ut(c1)=C_ut(c1)-Flux_mean*ut_s
        C_ut(c2)=C_ut(c2)+Flux_mean*ut_s

        C_vt(c1)=C_vt(c1)-Flux_mean*vt_s
        C_vt(c2)=C_vt(c2)+Flux_mean*vt_s

        C_wt(c1)=C_wt(c1)-Flux_mean*wt_s
        C_wt(c2)=C_wt(c2)+Flux_mean*wt_s

        C_tt(c1)=C_tt(c1)-Flux_mean*tt_s
        C_tt(c2)=C_tt(c2)+Flux_mean*tt_s

        Difv_uu(c1)=Difv_uu(c1) + (uu % n(c2)-uu % n(c1))*A0  + Fex1 - Fim1
        Difv_uu(c2)=Difv_uu(c2) - (uu % n(c2)-uu % n(c1))*A0  + Fex1 - Fim1

        Difv_vv(c1)=Difv_vv(c1) + (vv % n(c2)-vv % n(c1))*A0  + Fex2 - Fim2
        Difv_vv(c2)=Difv_vv(c2) - (vv % n(c2)-vv % n(c1))*A0  + Fex2 - Fim2

        Difv_ww(c1)=Difv_ww(c1) + (ww % n(c2)-ww % n(c1))*A0  + Fex3 - Fim3
        Difv_ww(c2)=Difv_ww(c2) - (ww % n(c2)-ww % n(c1))*A0  + Fex3 - Fim3

        Difv_uv(c1)=Difv_uv(c1) + (uv % n(c2)-uv % n(c1))*A0  + Fex4 - Fim4
        Difv_uv(c2)=Difv_uv(c2) - (uv % n(c2)-uv % n(c1))*A0  + Fex4 - Fim4
  
        Difv_uw(c1)=Difv_uw(c1) + (uw % n(c2)-uw % n(c1))*A0  + Fex5 - Fim5
        Difv_uw(c2)=Difv_uw(c2) - (uw % n(c2)-uw % n(c1))*A0  + Fex5 - Fim5

        Difv_vw(c1)=Difv_vw(c1) + (vw % n(c2)-vw % n(c1))*A0  + Fex6 - Fim6
        Difv_vw(c2)=Difv_vw(c2) - (vw % n(c2)-vw % n(c1))*A0  + Fex6 - Fim6
  
        Difv_ut(c1)=Difv_ut(c1) + (ut % n(c2)-ut % n(c1))*A1  + Fex7 - Fim7
        Difv_ut(c2)=Difv_ut(c2) - (ut % n(c2)-ut % n(c1))*A1  + Fex7 - Fim7
  
        Difv_vt(c1)=Difv_vt(c1) + (vt % n(c2)-vt % n(c1))*A1  + Fex8 - Fim8
        Difv_vt(c2)=Difv_vt(c2) - (vt % n(c2)-vt % n(c1))*A1  + Fex8 - Fim8
  
        Difv_wt(c1)=Difv_wt(c1) + (wt % n(c2)-wt % n(c1))*A1  + Fex9 - Fim9
        Difv_wt(c2)=Difv_wt(c2) - (wt % n(c2)-wt % n(c1))*A1  + Fex9 - Fim9
  
        Difv_tt(c1)=Difv_tt(c1) + (tt % n(c2)-tt % n(c1))*A2  + Fex10 - Fim10
        Difv_tt(c2)=Difv_tt(c2) - (tt % n(c2)-tt % n(c1))*A2  + Fex10 - Fim10
      else
        C_uu(c1)=C_uu(c1)-Flux_mean*uu_s
        C_vv(c1)=C_vv(c1)-Flux_mean*vv_s
        C_ww(c1)=C_ww(c1)-Flux_mean*ww_s
        C_uv(c1)=C_uv(c1)-Flux_mean*uv_s
        C_uw(c1)=C_uw(c1)-Flux_mean*uw_s
        C_vw(c1)=C_vw(c1)-Flux_mean*vw_s
        C_ut(c1)=C_ut(c1)-Flux_mean*ut_s
        C_vt(c1)=C_vt(c1)-Flux_mean*vt_s
        C_wt(c1)=C_wt(c1)-Flux_mean*wt_s
        C_tt(c1)=C_tt(c1)-Flux_mean*tt_s

!        Difv_uu(c1)=Difv_uu(c1) + (uu % n(c2)-uu % n(c1))*A0 - (Fex1 - Fim1)
!        Difv_vv(c1)=Difv_vv(c1) + (vv % n(c2)-vv % n(c1))*A0 - (Fex2 - Fim2)
!        Difv_ww(c1)=Difv_ww(c1) + (ww % n(c2)-ww % n(c1))*A0 - (Fex3 - Fim3)
!        Difv_uv(c1)=Difv_uv(c1) + (uv % n(c2)-uv % n(c1))*A0 - (Fex4 - Fim4)
!        Difv_uw(c1)=Difv_uw(c1) + (uw % n(c2)-uw % n(c1))*A0 - (Fex5 - Fim5)
!        Difv_vw(c1)=Difv_vw(c1) + (vw % n(c2)-vw % n(c1))*A0 - (Fex6 - Fim6)

        Difv_ut(c1)=Difv_ut(c1) + (ut % n(c2)-ut % n(c1))*A1  + Fex7 - Fim7
        Difv_vt(c1)=Difv_vt(c1) + (vt % n(c2)-vt % n(c1))*A1  + Fex8 - Fim8
        Difv_wt(c1)=Difv_wt(c1) + (wt % n(c2)-wt % n(c1))*A1  + Fex9 - Fim9
        Difv_tt(c1)=Difv_tt(c1) + (tt % n(c2)-tt % n(c1))*A2  + Fex10 - Fim10
      endif
    end do 

!-------------------------------------------------!
!  EXTRA TERMS IN VISCOUS DIFFUSION 
!-------------------------------------------------!

    do c = 1, NC
      R       = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
      R1      = 1.0/R 
      R2      = 1.0/(R*R) 
      dUdr(c) = -PHI3x(c)  * yc(c) * R1  + PHI3y(c) * xc(c) * R1
      dUdt(c) = -PHI1x(c) * yc(c) * R1  + PHI1y(c) * xc(c) * R1 
      dVdr(c) = -PHIx(c) * yc(c) * R1  + PHIy(c) * xc(c) * R1
      dVdt(c) = -PHI5x(c) * yc(c) * R1  + PHI5y(c) * xc(c) * R1
      dWdt(c) = -PHI4x(c) * yc(c) * R1  + PHI4y(c) * xc(c) * R1

      Difv_uu(c)=Difv_uu(c) + VISc*volume(c)*(-2.0*R2*uu % n(c) + 2.0*R2*vv % n(c) - 4.0*R2*dUdr(c)) 
      Difv_vv(c)=Difv_vv(c) + VISc*volume(c)*(2.0*R2* uu % n(c) - 2.0*R2*vv % n(c) + 4.0*R2*dUdr(c)) 
      Difv_uv(c)=Difv_uv(c) + VISc*volume(c)*(-4.0*R2*uv % n(c) -2.0*R2*dUdt(c)+ 2.0*R2*dVdr(c))
      Difv_uw(c)=Difv_uw(c) + VISc*volume(c)*(-2.0*R2*dVdt(c) - R2*uw % n(c))
      Difv_vw(c)=Difv_vw(c) + VISc*volume(c)*(2.0*R2*dWdt(c) - R2*vw % n(c))

      Puu_mean(c) = Puu(c) 
      Pvv_mean(c) = Pvv(c)
      Pww_mean(c) = Pww(c) 
      Puv_mean(c) = Puv(c) 
      Puw_mean(c) = Puw(c) 
      Pvw_mean(c) = Pvw(c) 

      C_uu_mean(c) = C_uu(c) - 2.0*R1*Vx(c)*uv % n(c)*volume(c) 
      C_vv_mean(c) = C_vv(c) + 2.0*R1*Vx(c)*uv % n(c)*volume(c)
      C_ww_mean(c) = C_ww(c) 
      C_uv_mean(c) = C_uv(c) + (R1*Vx(c)*uu % n(c) - R1*Vx(c)*vv %n(c))*volume(c)
      C_uw_mean(c) = C_uw(c) - R1*Vx(c)*vw % n(c)*volume(c)
      C_vw_mean(c) = C_vw(c) + R1*Vx(c)*uw % n(c)*volume(c)
      
      Difv_uu_mean(c) = Difv_uu(c)
      Difv_vv_mean(c) = Difv_vv(c) 
      Difv_ww_mean(c) = Difv_ww(c) 
      Difv_uv_mean(c) = Difv_uv(c) 
      Difv_uw_mean(c) = Difv_uw(c) 
      Difv_vw_mean(c) = Difv_vw(c) 

      Put_mean(c) = Put(c) 
      Pvt_mean(c) = Pvt(c)
      Pwt_mean(c) = Pwt(c) 
      Ptt_mean(c) = Ptt(c) 

      C_ut_mean(c) = C_ut(c) - R1*Vx(c)*vt % n(c)*volume(c)
      C_vt_mean(c) = C_vt(c) + R1*Vx(c)*ut % n(c)*volume(c)
      C_wt_mean(c) = C_wt(c) 
      C_tt_mean(c) = C_tt(c) 
      Difv_tt_mean(c) = Difv_tt(c) 
      Difv_ut_tot(c) = Difv_ut(c) 
      Difv_vt_tot(c) = Difv_vt(c) 
      Difv_wt_tot(c) = Difv_wt(c) 
    end do
  end if   !end mod(1,0)
!----------------------------------------!
!  DISSIPATION & PRESSURE REDISTRIBUTION
!----------------------------------------!
  call GraPhi(U % fluc,1,PHIx, .TRUE.) 
  call GraPhi(U % fluc,2,PHIy, .TRUE.) 
  call GraPhi(U % fluc,3,PHIz, .TRUE.) 

  call GraPhi(V % fluc,1,PHI1x, .TRUE.)
  call GraPhi(V % fluc,2,PHI1y, .TRUE.) 
  call GraPhi(V % fluc,3,PHI1z, .TRUE.) 

  call GraPhi(W % fluc,1,PHI2x, .TRUE.) 
  call GraPhi(W % fluc,2,PHI2y, .TRUE.) 
  call GraPhi(W % fluc,3,PHI2z, .TRUE.) 
  if(newhot > 0) then
  call GraPhi(T % fluc,1,PHI3x, .TRUE.) 
  call GraPhi(T % fluc,2,PHI3y, .TRUE.) 
  call GraPhi(T % fluc,3,PHI3z, .TRUE.) 
  end if
  do c = 1, NC
    R       = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
    R1      = 1.0/R 
    R2      = 1.0/(R*R) 

    dUdr(c) =  PHIx(c) * xc(c) * R1   + PHIy(c) * yc(c) * R1
    dUdt(c) = -PHIx(c) * yc(c) * R1   + PHIy(c) * xc(c) * R1
    dUdz(c) =  PHIz(c)

    dVdr(c) =  PHI1x(c) * xc(c) * R1  + PHI1y(c) * yc(c) * R1
    dVdt(c) = -PHI1x(c) * yc(c) * R1  + PHI1y(c) * xc(c) * R1
    dVdz(c) =  PHI1z(c)       

    dWdr(c) =  PHI2x(c) * xc(c) * R1  + PHI2y(c) * yc(c) * R1
    dWdt(c) = -PHI2x(c) * yc(c) * R1  + PHI2y(c) * xc(c) * R1
    dWdz(c) =  PHI2z(c)       

    G1r = PHI3x(c) * xc(c) * R1  + PHI3y(c) * yc(c) * R1
    G1t = -PHI3x(c) * yc(c) * R1  + PHI3y(c) * xc(c) * R1
    G1z = PHI3z(c)

    PHI4x(c) = dUdr(c)   
    PHI4y(c) = dUdt(c)   
    PHI4z(c) = dUdz(c)   
    PHI5x(c) = dVdr(c)   
    PHI5y(c) = dVdt(c)   
    PHI5z(c) = dVdz(c)   
    PHI6x(c) = dWdr(c)   
    PHI6y(c) = dWdt(c)   
    PHI6z(c) = dWdz(c)   
    PHI7x(c) = G1r 
    PHI7y(c) = G1t
    PHI7z(c) = G1z

    Diss_uu(c) = Diss_uu(c) - 2*VISc*(dUdr(c)*dUdr(c) + dUdt(c)*dUdt(c) * R2  &
               + dUdz(c)*dUdz(c) + vv % n(c) * R2 - 2.0 * R2 * V % fluc(c)*dUdt(c) )

    Diss_vv(c) = Diss_vv(c) - 2*VISc*(dVdr(c)*dVdr(c) + dVdt(c)*dVdt(c) * R2  &
               + dVdz(c)*dVdz(c) + uu % n(c) * R2 + 2.0 * R2 * U % fluc(c)*dVdt(c) ) 
    
    Diss_ww(c) = Diss_ww(c) - 2*VISc*(dWdr(c)*dWdr(c) + dWdt(c)*dWdt(c)*R2 + dWdz(c)*dWdz(c))

    Diss_uv(c) = Diss_uv(c) - 2.0*VISc*( dUdr(c)*dVdr(c) + dUdt(c)*dVdt(c)*R2  &
               + dUdz(c)*dVdz(c) - uv % n(c)*R2 - V % fluc(c)*dVdt(c)*R2 + U % fluc(c)*dUdt(c)*R2)

    Diss_uw(c) = DiSs_uw(c) - 2.0*VISc*( dUdr(c)*dWdr(c) + dUdt(c)*dWdt(c)*R2  &
               + dUdz(c)*dWdz(c) - V % fluc(c)*dWdt(c)*R2 )

    Diss_vw(c) = Diss_vw(c) - 2.0*VISc*( dVdr(c)*dWdr(c) + dVdt(c)*dWdt(c)*R2  &
               + dVdz(c)*dWdz(c) + U % fluc(c)*dWdt(c)*R2 )

    Diss_ut(c) = Diss_ut(c) - (VISc+CONc(material(c)))*(dUdr(c)*G1r + R2*dUdt(c)*G1t + dUdz(c)*G1z &
                 - R2*G1t*V % fluc(c)) 

    Diss_vt(c) = Diss_vt(c) - (VISc+CONc(material(c)))*(dVdr(c)*G1r + R2*dVdt(c)*G1t + dVdz(c)*G1z &
                 + R2*G1t*U % fluc(c)) 

    Diss_wt(c) = (VISc+CONc(material(c)))*(dWdr(c)*G1r + R2*dWdt(c)*G1t + dWdz(c)*G1z)

    Diss_tt(c) = Diss_tt(c) - 2.0*CONc(material(c))*(G1r*G1r + R2*G1t*G1t + G1z*G1z) 

    R_uu(c)=R_uu(c) + 2.0*P % fluc(c)*dUdr(c) 
    R_vv(c)=R_vv(c) + 2.0*P % fluc(c)*dVdt(c)*R1 + 2.0*R1*P % fluc(c)*U % fluc(c) 
    R_ww(c)=R_ww(c) + 2.0*P % fluc(c)*dWdz(c) 
    R_uv(c)=R_uv(c) + P % fluc(c)*( R1*dUdt(c) + dVdr(c) - R1*V % fluc(c))
    R_uw(c)=R_uw(c) + P % fluc(c)*( dUdz(c) + dWdr(c) )
    R_vw(c)=R_vw(c) + P % fluc(c)*( dVdz(c) + R1*dWdt(c) ) 
    R_ut(c)=R_ut(c) + P % fluc(c)*( G1r ) 
    R_vt(c)=R_vt(c) + P % fluc(c)*( G1t ) * R1
    R_wt(c)=R_wt(c) + P % fluc(c)*( G1z ) 
!!!
!!! EXTRA TERMS FOR VISCOUS DIFFUSION OF TURBULENT HEAT FLUX
!!! 
    Difv2_ut(c) = Difv2_ut(c) - volume(c)*VISc*R2*( U % fluc(c)*T % fluc(c) + &
                 V % fluc(c)*G1t + 2.0*T % fluc(c)*dVdt(c) )      & 
                 - R2*CONc(material(c))*volume(c)*V % fluc(c)*G1t 
    Difv2_vt(c) = Difv2_vt(c) + volume(c)*VISc*R2*( - V % fluc(c)*T % fluc(c) + &
                 U % fluc(c)*G1t + 2.0*T % fluc(c)*dUdt(c) ) + &
                 R2*CONc(material(c))*volume(c)*U % fluc(c)*G1t 
  end do 

  if(newhot > 0) then
  call GraPhi(PHI4x,1,PHIx, .TRUE.) 
  call GraPhi(PHI4x,2,PHIy, .TRUE.) 

  call GraPhi(PHI4y,1,PHI1x, .TRUE.) 
  call GraPhi(PHI4y,2,PHI1y, .TRUE.) 
  call GraPhi(PHI4z,3,PHI1z, .TRUE.) 

  call GraPhi(PHI5x,1,PHI2x, .TRUE.) 
  call GraPhi(PHI5x,2,PHI2y, .TRUE.) 

  call GraPhi(PHI5y,1,PHI3x, .TRUE.) 
  call GraPhi(PHI5y,2,PHI3y, .TRUE.) 
  call GraPhi(PHI5z,3,PHI3z, .TRUE.) 

  call GraPhi(PHI6x,1,PHI8x, .TRUE.) 
  call GraPhi(PHI6x,2,PHI8y, .TRUE.) 

  call GraPhi(PHI6y,1,PHI9x, .TRUE.) 
  call GraPhi(PHI6y,2,PHI9y, .TRUE.) 
  call GraPhi(PHI6z,3,PHI9z, .TRUE.) 

  call GraPhi(PHI7x,1,PHI5x, .TRUE.) 
  call GraPhi(PHI7x,2,PHI5y, .TRUE.) 

  call GraPhi(PHI7y,1,PHI4x, .TRUE.) 
  call GraPhi(PHI7y,2,PHI4y, .TRUE.) 
  call GraPhi(PHI7z,3,PHI4z, .TRUE.) 


  do c = 1, NC
    R       = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
    R1      = 1.0/R
    R2      = 1.0/(R*R)
    Gr =  PHIx(c) * xc(c) * R1   + PHIy(c) * yc(c) * R1
    Gt = -PHI1x(c) * yc(c) * R1   + PHI1y(c) * xc(c) * R1
    Gz =  PHI1z(c)

    G1r =  PHI2x(c) * xc(c) * R1   + PHI2y(c) * yc(c) * R1
    G1t = -PHI3x(c) * yc(c) * R1   + PHI3y(c) * xc(c) * R1
    G1z =  PHI3z(c)

    G2r =  PHI8x(c) * xc(c) * R1   + PHI8y(c) * yc(c) * R1
    G2t = -PHI9x(c) * yc(c) * R1   + PHI9y(c) * xc(c) * R1
    G2z =  PHI9z(c)

    G3r =  PHI5x(c) * xc(c) * R1   + PHI5y(c) * yc(c) * R1
    G3t = -PHI4x(c) * yc(c) * R1   + PHI4y(c) * xc(c) * R1
    G3z =  PHI4z(c)

    Difv2_ut(c) = Difv2_ut(c) + ( 0.5*(VISc-CONc(material(c)))*T % fluc(c)*(Gr + R2*Gt + Gz) &
                 - 0.5*(VISc-CONc(material(c)))*U % fluc(c)*(G3r + R2*G3t + G3z) )*volume(c)
    Difv2_vt(c) = Difv2_vt(c) + ( 0.5*(VISc-CONc(material(c)))*T % fluc(c)*(G1r + R2*G1t + G1z) &
                 - 0.5*(VISc-CONc(material(c)))*V % fluc(c)*(G3r + R2*G3t + G3z) )*volume(c)
    Difv2_wt(c) = Difv2_wt(c) + ( 0.5*(VISc-CONc(material(c)))*T % fluc(c)*(G2r + R2*G2t + G2z) &
                 - 0.5*(VISc-CONc(material(c)))*W % fluc(c)*(G3r + R2*G3t + G3z) )*volume(c)
  end do
  end if

!----------------------------------------!
!  TURBULENT DIFFUSION
!----------------------------------------!

  do c = 1, NC
    Ux(c)     = U % fluc(c) * U % fluc(c) * U % fluc(c)
    Uy(c)     = U % fluc(c) * U % fluc(c) * V % fluc(c)
    Uz(c)     = U % fluc(c) * U % fluc(c) * W % fluc(c)

    Vx(c)     = U % fluc(c) * V % fluc(c) * V % fluc(c)
    Vy(c)     = V % fluc(c) * V % fluc(c) * V % fluc(c)
    Vz(c)     = V % fluc(c) * V % fluc(c) * W % fluc(c)

    Wx(c)     = U % fluc(c) * W % fluc(c) * W % fluc(c)
    Wy(c)     = V % fluc(c) * W % fluc(c) * W % fluc(c)
    Wz(c)     = W % fluc(c) * W % fluc(c) * W % fluc(c)
   
    Kx(c)     = U % fluc(c) * V % fluc(c) * W % fluc(c)
  end do

  call GraPhi(Ux,1,PHIx, .TRUE.)  
  call GraPhi(Ux,2,PHIy, .TRUE.)  
  call GraPhi(Ux,3,PHIz, .TRUE.)  

  call GraPhi(Uy,1,PHI1x, .TRUE.)  
  call GraPhi(Uy,2,PHI1y, .TRUE.)  
  call GraPhi(Uy,3,PHI1z, .TRUE.)  

  call GraPhi(Uz,1,PHI2x, .TRUE.)  
  call GraPhi(Uz,2,PHI2y, .TRUE.)  
  call GraPhi(Uz,3,PHI2z, .TRUE.)  
 
  call GraPhi(Vx,1,PHI3x, .TRUE.)  
  call GraPhi(Vx,2,PHI3y, .TRUE.)  
  call GraPhi(Vx,3,PHI3z, .TRUE.)  

  call GraPhi(Vy,1,PHI4x, .TRUE.)  
  call GraPhi(Vy,2,PHI4y, .TRUE.)  
  call GraPhi(Vy,3,PHI4z, .TRUE.)  

  call GraPhi(Vz,1,PHI5x, .TRUE.)  
  call GraPhi(Vz,2,PHI5y, .TRUE.)  
  call GraPhi(Vz,3,PHI5z, .TRUE.)  

  call GraPhi(Wx,1,PHI6x, .TRUE.)  
  call GraPhi(Wx,2,PHI6y, .TRUE.)  
  call GraPhi(Wx,3,PHI6z, .TRUE.)  

  call GraPhi(Wy,1,PHI7x, .TRUE.)  
  call GraPhi(Wy,2,PHI7y, .TRUE.)  
  call GraPhi(Wy,3,PHI7z, .TRUE.)  

  call GraPhi(Wz,1,PHI8x, .TRUE.)  
  call GraPhi(Wz,2,PHI8y, .TRUE.)  
  call GraPhi(Wz,3,PHI8z, .TRUE.)  

  call GraPhi(Kx,1,PHI9x, .TRUE.)  
  call GraPhi(Kx,2,PHI9y, .TRUE.)  
  call GraPhi(Kx,3,PHI9z, .TRUE.)  


  do c = 1, NC
    R       = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
    R1      = 1.0/R
    R2      = 1.0/(R*R)

    Gr =  PHIx(c) * xc(c) * R1   + PHIy(c) * yc(c) * R1
    Gt = -PHIx(c) * yc(c) * R1   + PHIy(c) * xc(c) * R1
    Gz =  PHIz(c)

    G1r =  PHI1x(c) * xc(c) * R1   + PHI1y(c) * yc(c) * R1
    G1t = -PHI1x(c) * yc(c) * R1   + PHI1y(c) * xc(c) * R1
    G1z =  PHI1z(c)

    G2r =  PHI2x(c) * xc(c) * R1   + PHI2y(c) * yc(c) * R1
    G2t = -PHI2x(c) * yc(c) * R1   + PHI2y(c) * xc(c) * R1
    G2z =  PHI2z(c)

    G3r =  PHI3x(c) * xc(c) * R1   + PHI3y(c) * yc(c) * R1
    G3t = -PHI3x(c) * yc(c) * R1   + PHI3y(c) * xc(c) * R1
    G3z =  PHI3z(c)

    G4r =  PHI4x(c) * xc(c) * R1   + PHI4y(c) * yc(c) * R1
    G4t = -PHI4x(c) * yc(c) * R1   + PHI4y(c) * xc(c) * R1
    G4z =  PHI4z(c)

    G5r =  PHI5x(c) * xc(c) * R1   + PHI5y(c) * yc(c) * R1
    G5t = -PHI5x(c) * yc(c) * R1   + PHI5y(c) * xc(c) * R1
    G5z =  PHI5z(c)

    G6r =  PHI6x(c) * xc(c) * R1   + PHI6y(c) * yc(c) * R1
    G6t = -PHI6x(c) * yc(c) * R1   + PHI6y(c) * xc(c) * R1
    G6z =  PHI6z(c)

    G7r =  PHI7x(c) * xc(c) * R1   + PHI7y(c) * yc(c) * R1
    G7t = -PHI7x(c) * yc(c) * R1   + PHI7y(c) * xc(c) * R1
    G7z =  PHI7z(c)

    G8r =  PHI8x(c) * xc(c) * R1   + PHI8y(c) * yc(c) * R1
    G8t = -PHI8x(c) * yc(c) * R1   + PHI8y(c) * xc(c) * R1
    G8z =  PHI8z(c)

    G9r =  PHI9x(c) * xc(c) * R1   + PHI9y(c) * yc(c) * R1
    G9t = -PHI9x(c) * yc(c) * R1   + PHI9y(c) * xc(c) * R1
    G9z =  PHI9z(c)

    Dift_uu(c)=Dift_uu(c) + Gr  + R1*G1t + G2z - 2.0*R1*Vx(c) + R1*Ux(c)  
    Dift_vv(c)=Dift_vv(c) + G3r + R1*G4t + G5z + 2.0*R1*Vx(c) + R1*Vx(c)
    Dift_ww(c)=Dift_ww(c) + G6r + R1*G7t + G8z +                R1*Wx(c)
    Dift_uv(c)=Dift_uv(c) + G1r + R1*G3t + G9z + 2.0*R1*Uy(c) + R1*Vy(c)
    Dift_uw(c)=Dift_uw(c) + G2r + R1*G9t + G6z -     R1*Vz(c) + R1*Uz(c)  
    Dift_vw(c)=Dift_vw(c) + G9r + R1*G5t + G7z + 2.0*R1*Kx(c) 

    Ux(c) = P % fluc(c) * U % fluc(c) 
    Uy(c) = P % fluc(c) * V % fluc(c) 
    Uz(c) = P % fluc(c) * W % fluc(c) 
  end do 

!----------------------------------------!
!  PRESSURE DIFFUSION
!----------------------------------------!
  do c = -NbC, NC 
    PHI3x(c) = P % fluc(c) * T % fluc(c) 
  end do

  call GraPhi(Ux,1,PHIx, .TRUE.)  
  call GraPhi(Ux,2,PHIy, .TRUE.)  
  call GraPhi(Ux,3,PHIz, .TRUE.)  

  call GraPhi(Uy,1,PHI1x, .TRUE.)  
  call GraPhi(Uy,2,PHI1y, .TRUE.)  
  call GraPhi(Uy,3,PHI1z, .TRUE.)  

  call GraPhi(Uz,1,PHI2x, .TRUE.)  
  call GraPhi(Uz,2,PHI2y, .TRUE.)  
  call GraPhi(Uz,3,PHI2z, .TRUE.)  
  
  call GraPhi(PHI3x,1,PHI4x, .TRUE.)  
  call GraPhi(PHI3x,2,PHI4y, .TRUE.)  
  call GraPhi(PHI3x,3,PHI4z, .TRUE.)  

  do c = 1, NC
    R       = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
    R1      = 1.0/R
    R2      = 1.0/(R*R)
    Gr =  PHIx(c) * xc(c) * R1   + PHIy(c) * yc(c) * R1
    Gt = -PHIx(c) * yc(c) * R1   + PHIy(c) * xc(c) * R1
    Gz =  PHIz(c)

    G1r =  PHI1x(c) * xc(c) * R1   + PHI1y(c) * yc(c) * R1
    G1t = -PHI1x(c) * yc(c) * R1   + PHI1y(c) * xc(c) * R1
    G1z =  PHI1z(c)

    G2r =  PHI2x(c) * xc(c) * R1   + PHI2y(c) * yc(c) * R1
    G2t = -PHI2x(c) * yc(c) * R1   + PHI2y(c) * xc(c) * R1
    G2z =  PHI2z(c)

    G3r =  PHI4x(c) * xc(c) * R1   + PHI4y(c) * yc(c) * R1
    G3t = -PHI4x(c) * yc(c) * R1   + PHI4y(c) * xc(c) * R1
    G3z =  PHI4z(c)

    PD_uu(c)=PD_uu(c) + 2.0*Gr
    PD_vv(c)=PD_vv(c) + 2.0*R1*G1t + 2.0*R1*P % fluc(c)*U % fluc(c)
    PD_ww(c)=PD_ww(c) + 2.0*G2z
    PD_uv(c)=PD_uv(c) + G1r + R1*Gt - R1*P % fluc(c)*V % fluc(c)
    PD_uw(c)=PD_uw(c) + G2r + Gz
    PD_vw(c)=PD_vw(c) + R1*G2t + G1z
    PD_ut(c)=PD_ut(c) + G3r
    PD_vt(c)=PD_ut(c) + R1*G3t
    PD_wt(c)=PD_wt(c) + G3z
  end do

!----------------------------------------!
!  TURBULENT DIFFUSION FOR HEAT FLUX
!----------------------------------------!
  if(newhot>0) then
  do c = 1, NC
    Ux(c)     = U % fluc(c) * U % fluc(c) * T % fluc(c)
    Uy(c)     = U % fluc(c) * V % fluc(c) * T % fluc(c)
    Uz(c)     = U % fluc(c) * W % fluc(c) * T % fluc(c)

    Vx(c)     = V % fluc(c) * V % fluc(c) * T % fluc(c)
    Vy(c)     = V % fluc(c) * W % fluc(c) * T % fluc(c)
    Vz(c)     = W % fluc(c) * W % fluc(c) * T % fluc(c)

    Wx(c)     = U % fluc(c) * T % fluc(c) * T % fluc(c)
    Wy(c)     = V % fluc(c) * T % fluc(c) * T % fluc(c)
    Wz(c)     = W % fluc(c) * T % fluc(c) * T % fluc(c)
  end do

  call GraPhi(Ux,1,PHIx, .TRUE.)  
  call GraPhi(Ux,2,PHIy, .TRUE.)  
  call GraPhi(Ux,3,PHIz, .TRUE.)  

  call GraPhi(Uy,1,PHI1x, .TRUE.)  
  call GraPhi(Uy,2,PHI1y, .TRUE.)  
  call GraPhi(Uy,3,PHI1z, .TRUE.)  

  call GraPhi(Uz,1,PHI2x, .TRUE.)  
  call GraPhi(Uz,2,PHI2y, .TRUE.)  
  call GraPhi(Uz,3,PHI2z, .TRUE.)  
 
  call GraPhi(Vx,1,PHI3x, .TRUE.)  
  call GraPhi(Vx,2,PHI3y, .TRUE.)  
  call GraPhi(Vx,3,PHI3z, .TRUE.)  

  call GraPhi(Vy,1,PHI4x, .TRUE.)  
  call GraPhi(Vy,2,PHI4y, .TRUE.)  
  call GraPhi(Vy,3,PHI4z, .TRUE.)  

  call GraPhi(Vz,1,PHI5x, .TRUE.)  
  call GraPhi(Vz,2,PHI5y, .TRUE.)  
  call GraPhi(Vz,3,PHI5z, .TRUE.)  

  call GraPhi(Wx,1,PHI6x, .TRUE.)  
  call GraPhi(Wx,2,PHI6y, .TRUE.)  
  call GraPhi(Wx,3,PHI6z, .TRUE.)  

  call GraPhi(Wy,1,PHI7x, .TRUE.)  
  call GraPhi(Wy,2,PHI7y, .TRUE.)  
  call GraPhi(Wy,3,PHI7z, .TRUE.)  

  call GraPhi(Wz,1,PHI8x, .TRUE.)  
  call GraPhi(Wz,2,PHI8y, .TRUE.)  
  call GraPhi(Wz,3,PHI8z, .TRUE.)  

  do c = 1, NC
    R       = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
    R1      = 1.0/R
    R2      = 1.0/(R*R)

    Gr =  PHIx(c) * xc(c) * R1   + PHIy(c) * yc(c) * R1
    Gt = -PHIx(c) * yc(c) * R1   + PHIy(c) * xc(c) * R1
    Gz =  PHIz(c)

    G1r =  PHI1x(c) * xc(c) * R1   + PHI1y(c) * yc(c) * R1
    G1t = -PHI1x(c) * yc(c) * R1   + PHI1y(c) * xc(c) * R1
    G1z =  PHI1z(c)

    G2r =  PHI2x(c) * xc(c) * R1   + PHI2y(c) * yc(c) * R1
    G2t = -PHI2x(c) * yc(c) * R1   + PHI2y(c) * xc(c) * R1
    G2z =  PHI2z(c)

    G3r =  PHI3x(c) * xc(c) * R1   + PHI3y(c) * yc(c) * R1
    G3t = -PHI3x(c) * yc(c) * R1   + PHI3y(c) * xc(c) * R1
    G3z =  PHI3z(c)

    G4r =  PHI4x(c) * xc(c) * R1   + PHI4y(c) * yc(c) * R1
    G4t = -PHI4x(c) * yc(c) * R1   + PHI4y(c) * xc(c) * R1
    G4z =  PHI4z(c)

    G5r =  PHI5x(c) * xc(c) * R1   + PHI5y(c) * yc(c) * R1
    G5t = -PHI5x(c) * yc(c) * R1   + PHI5y(c) * xc(c) * R1
    G5z =  PHI5z(c)

    G6r =  PHI6x(c) * xc(c) * R1   + PHI6y(c) * yc(c) * R1
    G6t = -PHI6x(c) * yc(c) * R1   + PHI6y(c) * xc(c) * R1
    G6z =  PHI6z(c)

    G7r =  PHI7x(c) * xc(c) * R1   + PHI7y(c) * yc(c) * R1
    G7t = -PHI7x(c) * yc(c) * R1   + PHI7y(c) * xc(c) * R1
    G7z =  PHI7z(c)

    G8r =  PHI8x(c) * xc(c) * R1   + PHI8y(c) * yc(c) * R1
    G8t = -PHI8x(c) * yc(c) * R1   + PHI8y(c) * xc(c) * R1
    G8z =  PHI8z(c)

    Dift_ut(c)=Dift_ut(c) + Gr  + R1*G1t + G2z - Vx(c)
    Dift_vt(c)=Dift_vt(c) + G1r + R1*G3t + G4z + Uy(c)
    Dift_wt(c)=G2r + R1*G4t + G5z + Uz(c)*R1 
    Dift_tt(c)=Dift_tt(c) + G6r + R1*G7t + G8z
  end do 
  end if  

  if(new  > -1) then
    do c=1 ,NC
      R       = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
      Diss_uu_mean(c) = ( Diss_uu_mean(c) * (1.*new) + Diss_uu(c) ) / (1.*(new+1))
      Diss_vv_mean(c) = ( Diss_vv_mean(c) * (1.*new) + Diss_vv(c) ) / (1.*(new+1))
      Diss_ww_mean(c) = ( Diss_ww_mean(c) * (1.*new) + Diss_ww(c) ) / (1.*(new+1))
      Diss_uv_mean(c) = ( Diss_uv_mean(c) * (1.*new) + Diss_uv(c) ) / (1.*(new+1))
      Diss_uw_mean(c) = ( Diss_uw_mean(c) * (1.*new) + Diss_uw(c) ) / (1.*(new+1))
      Diss_vw_mean(c) = ( Diss_vw_mean(c) * (1.*new) + Diss_vw(c) ) / (1.*(new+1))

      Dift_uu_mean(c) = ( Dift_uu_mean(c) * (1.*new) + Dift_uu(c) ) / (1.*(new+1))
      Dift_vv_mean(c) = ( Dift_vv_mean(c) * (1.*new) + Dift_vv(c) ) / (1.*(new+1))
      Dift_ww_mean(c) = ( Dift_ww_mean(c) * (1.*new) + Dift_ww(c) ) / (1.*(new+1))
      Dift_uv_mean(c) = ( Dift_uv_mean(c) * (1.*new) + Dift_uv(c) ) / (1.*(new+1))
      Dift_uw_mean(c) = ( Dift_uw_mean(c) * (1.*new) + Dift_uw(c) ) / (1.*(new+1))
      Dift_vw_mean(c) = ( Dift_vw_mean(c) * (1.*new) + Dift_vw(c) ) / (1.*(new+1))

      PR_uu_mean(c) = ( PR_uu_mean(c) * (1.*new) + R_uu(c) ) / (1.*(new+1))
      PR_vv_mean(c) = ( PR_vv_mean(c) * (1.*new) + R_vv(c) ) / (1.*(new+1))
      PR_ww_mean(c) = ( PR_ww_mean(c) * (1.*new) + R_ww(c) ) / (1.*(new+1))
      PR_uv_mean(c) = ( PR_uv_mean(c) * (1.*new) + R_uv(c) ) / (1.*(new+1))
      PR_uw_mean(c) = ( PR_uw_mean(c) * (1.*new) + R_uw(c) ) / (1.*(new+1))
      PR_vw_mean(c) = ( PR_vw_mean(c) * (1.*new) + R_vw(c) ) / (1.*(new+1))

      PD_uu_mean(c) = ( PD_uu_mean(c) * (1.*new) + PD_uu(c) ) / (1.*(new+1))
      PD_vv_mean(c) = ( PD_vv_mean(c) * (1.*new) + PD_vv(c) ) / (1.*(new+1))
      PD_ww_mean(c) = ( PD_ww_mean(c) * (1.*new) + PD_ww(c) ) / (1.*(new+1))
      PD_uv_mean(c) = ( PD_uv_mean(c) * (1.*new) + PD_uv(c) ) / (1.*(new+1))
      PD_uw_mean(c) = ( PD_uw_mean(c) * (1.*new) + PD_uw(c) ) / (1.*(new+1))
      PD_vw_mean(c) = ( PD_vw_mean(c) * (1.*new) + PD_vw(c) ) / (1.*(new+1))

      Difv_ut_mean(c) = ( Difv_ut_mean(c) * (1.*newhot) + Difv2_ut(c) ) / (1.*(newhot+1))
      Difv_vt_mean(c) = ( Difv_vt_mean(c) * (1.*newhot) + Difv2_vt(c) ) / (1.*(newhot+1))
      Difv_wt_mean(c) = ( Difv_wt_mean(c) * (1.*newhot) + Difv2_wt(c) ) / (1.*(newhot+1))

      Diss_ut_mean(c) = ( Diss_ut_mean(c) * (1.*newhot) + Diss_ut(c) ) / (1.*(newhot+1))
      Diss_vt_mean(c) = ( Diss_vt_mean(c) * (1.*newhot) + Diss_vt(c) ) / (1.*(newhot+1))
      Diss_wt_mean(c) = ( Diss_wt_mean(c) * (1.*newhot) + Diss_wt(c) ) / (1.*(newhot+1))
      Diss_tt_mean(c) = ( Diss_tt_mean(c) * (1.*newhot) + Diss_tt(c) ) / (1.*(newhot+1))

      Dift_ut_mean(c) = ( Dift_ut_mean(c) * (1.*newhot) + Dift_ut(c) ) / (1.*(newhot+1))
      Dift_vt_mean(c) = ( Dift_vt_mean(c) * (1.*newhot) + Dift_vt(c) ) / (1.*(newhot+1))
      Dift_wt_mean(c) = ( Dift_wt_mean(c) * (1.*newhot) + Dift_wt(c) ) / (1.*(newhot+1))
      Dift_tt_mean(c) = ( Dift_tt_mean(c) * (1.*newhot) + Dift_tt(c) ) / (1.*(newhot+1))
     
      PD_ut_mean(c) = ( PD_ut_mean(c) * (1.*newhot) + PD_ut(c) ) / (1.*(newhot+1))
      PD_vt_mean(c) = ( PD_vt_mean(c) * (1.*newhot) + PD_vt(c) ) / (1.*(newhot+1))
      PD_wt_mean(c) = ( PD_wt_mean(c) * (1.*newhot) + PD_wt(c) ) / (1.*(newhot+1))

      PR_ut_mean(c) = ( PR_ut_mean(c) * (1.*newhot) + R_ut(c) ) / (1.*(newhot+1))
      PR_vt_mean(c) = ( PR_vt_mean(c) * (1.*newhot) + R_vt(c) ) / (1.*(newhot+1))
      PR_wt_mean(c) = ( PR_wt_mean(c) * (1.*newhot) + R_wt(c) ) / (1.*(newhot+1))
    end do
  end if

  RETURN 

  end subroutine CalcBudgets_hot
