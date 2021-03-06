!==============================================================================!
  subroutine Source_Hanjalic_Jakirlic(grid, name_phi)
!------------------------------------------------------------------------------!
!   Calculate source terms for transport equations for Re stresses and         !
!   dissipation for Hanjalic-Jakirlic model.                                   !  
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use all_mod
  use pro_mod
  use rans_mod
  use Grid_Mod
  use Work_Mod, only: l_sc_x => r_cell_01,  &
                      l_sc_y => r_cell_02,  &
                      l_sc_z => r_cell_03,  &
                      kin_x  => r_cell_04,  &
                      kin_y  => r_cell_05,  &
                      kin_z  => r_cell_06,  &
                      kin_xx => r_cell_07,  &
                      kin_yy => r_cell_08,  &
                      kin_zz => r_cell_09,  &
                      ui_xx  => r_cell_10,  &
                      ui_yy  => r_cell_11,  &
                      ui_zz  => r_cell_12,  &
                      ui_xy  => r_cell_13,  &
                      ui_xz  => r_cell_14,  &
                      ui_yz  => r_cell_15,  &
                      kin_e  => r_cell_16,  &
                      diss1  => r_cell_17    
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type)  :: grid
  character(len=*) :: name_phi
!-----------------------------------[Locals]-----------------------------------!
  integer :: c, s, c1, c2, i, icont
  real    :: mag
  real    :: a11, a22, a33, a12, a13, a21, a31, a23, a32
  real    :: n1,n2,n3,AA2,AA3,AA,Ret,ff2,fd,FF1,CC,C1W,C2W,fw,uu_nn
  real    :: e11,e12,e13,e21,e22,e23,e31,e32,e33
  real    :: Eps11,Eps12,Eps13,Eps21,Eps22,Eps23,Eps31,Eps32,Eps33
  real    :: Feps, phi2_nn
  real    :: fss,E2,E3,EE,CC1,CC2
  real    :: Uxx, Uyy, Uzz, Uxy, Uxz, Uyz, Uyx, Uzx, Uzy
  real    :: Vxx, Vyy, Vzz, Vxy, Vxz, Vyz
  real    :: Wxx, Wyy, Wzz, Wxy, Wxz, Wyz
  real    :: r13, r23
  real    :: S11, S22, S33, S12, S13, S21, S31, S23, S32
  real    :: V11, V22, V33, V12, V13, V21, V31, V23, V32
  real    :: a_lk_s_lk, a_mn_a_mn
  real    :: VAR1w_11, VAR1w_22, VAR1w_33, VAR1w_12, VAR1w_13, VAR1w_23
  real    :: VAR2w_11, VAR2w_22, VAR2w_33, VAR2w_12, VAR2w_13, VAR2w_23
  real    :: VAR1_11, VAR1_22, VAR1_33, VAR1_12, VAR1_13, VAR1_23
  real    :: VAR2_11, VAR2_22, VAR2_33, VAR2_12, VAR2_13, VAR2_23
  real    :: P11, P22, P33, P12, P13, P23, Eps1, Eps2
  real    :: duu_dx,duu_dy,duu_dz,dvv_dx,dvv_dy,dvv_dz,dww_dx,dww_dy,dww_dz
  real    :: duv_dx,duv_dy,duv_dz,duw_dx,duw_dy,duw_dz,dvw_dx,dvw_dy,dvw_dz
  real    :: dUdx, dUdy, dUdz, dVdx, dVdy, dVdz, dWdx, dWdy, dWdz 
!==============================================================================!

  diss1 = 0.0

  EE = 0.5
  AA = 0.5

  do c = 1, grid % n_cells
    Kin % n(c) = max(0.5*(uu % n(c) + vv % n(c) + ww % n(c)), 1.0e-7)
    Lsc(c)=  (Kin % n(c))**1.5/Eps % n(c)
    Tsc(c)=  Kin % n(c)/Eps % n(c)
  end do

  call GraPhi(grid, Kin % n, 1, kin_x, .TRUE.)  ! dK/dx
  call GraPhi(grid, Kin % n, 2, kin_y, .TRUE.)  ! dK/dy
  call GraPhi(grid, Kin % n, 3, kin_z, .TRUE.)  ! dK/dz

  call GraPhi(grid, kin_x, 1, kin_xx, .TRUE.)  ! d^2 K / dx^2
  call GraPhi(grid, kin_y, 2, kin_yy, .TRUE.)  ! d^2 K / dy^2
  call GraPhi(grid, kin_z, 3, kin_zz, .TRUE.)  ! d^2 K / dz^2

  do c = 1, grid % n_cells
    Eps_tot(c) = Eps % n(c) + 0.5 * VISc * (kin_xx(c) + kin_yy(c) + kin_zz(c))
  end do

! !---------------------------------------------------!
! !   Below is one of versions of Hanjalic-Jakirlic   !
! !      model that required much more memory         !
! !---------------------------------------------------!
! if(name_phi == "23") then
!   call GraPhi(grid, uu % n, 1, VAR3x, .TRUE.) ! duu/dx  
!   call GraPhi(grid, uu % n, 2, VAR3y, .TRUE.) ! duu/dy  
!   call GraPhi(grid, uu % n, 3, VAR3z, .TRUE.) ! duu/dz  
!
!   call GraPhi(grid, vv % n, 1, VAR4x, .TRUE.) ! duw/dx  
!   call GraPhi(grid, vv % n, 2, VAR4y, .TRUE.) ! duw/dy  
!   call GraPhi(grid, vv % n, 3, VAR4z, .TRUE.) ! duw/dz  
!
!   call GraPhi(grid, ww % n, 1, VAR5x, .TRUE.) ! duw/dx  
!   call GraPhi(grid, ww % n, 2, VAR5y, .TRUE.) ! duw/dy  
!   call GraPhi(grid, ww % n, 3, VAR5z, .TRUE.) ! duw/dz  
!
!   call GraPhi(grid, uv % n, 1, VAR6x, .TRUE.) ! duv/dx  
!   call GraPhi(grid, uv % n, 2, VAR6y, .TRUE.) ! duv/dy  
!   call GraPhi(grid, uv % n, 3, VAR6z, .TRUE.) ! duv/dz  
!
!   call GraPhi(grid, uw % n, 1, kin_x, .TRUE.) ! duw/dx  
!   call GraPhi(grid, uw % n, 2, kin_y, .TRUE.) ! duw/dy  
!   call GraPhi(grid, uw % n, 3, kin_z, .TRUE.) ! duw/dz  
!
!   call GraPhi(grid, vw % n, 1, VAR8x, .TRUE.) ! duw/dx  
!   call GraPhi(grid, vw % n, 2, VAR8y, .TRUE.) ! duw/dy  
!   call GraPhi(grid, vw % n, 3, VAR8z, .TRUE.) ! duw/dz  
!
!   call GraPhi(grid, u % x, 1, VAR1x, .TRUE.)  ! d2U/dxdx
!   call GraPhi(grid, u % y, 2, VAR1y, .TRUE.)  ! d2U/dydy
!   call GraPhi(grid, u % z, 3, VAR1z, .TRUE.)  ! d2U/dzdz
!   call GraPhi(grid, u % x, 2, VAR2x, .TRUE.)  ! d2U/dxdy
!   call GraPhi(grid, u % x, 3, VAR2y, .TRUE.)  ! d2U/dxdz
!   call GraPhi(grid, u % y, 3, VAR2z, .TRUE.)  ! d2U/dydz
!
!   call GraPhi(grid, v % x, 1, VAR9x, .TRUE.)  ! d2V/dxdx
!   call GraPhi(grid, v % y, 2, VAR9y, .TRUE.)  ! d2V/dydy
!   call GraPhi(grid, v % z, 3, VAR9z, .TRUE.)  ! d2V/dzdz
!   call GraPhi(grid, v % x, 2, VAR10x, .TRUE.)  ! d2V/dxdy
!   call GraPhi(grid, v % x, 3, VAR10y, .TRUE.)  ! d2V/dxdz
!   call GraPhi(grid, v % y, 3, VAR10z, .TRUE.)  ! d2V/dydz
!
!   call GraPhi(grid, w % x, 1, VAR11x, .TRUE.)  ! d2W/dxdx
!   call GraPhi(grid, w % y, 2, VAR11y, .TRUE.)  ! d2W/dydy
!   call GraPhi(grid, w % z, 3, VAR11z, .TRUE.)  ! d2W/dzdz
!   call GraPhi(grid, w % x, 2, VAR12x, .TRUE.)  ! d2W/dxdy
!   call GraPhi(grid, w % x, 3, VAR12y, .TRUE.)  ! d2W/dxdz
!   call GraPhi(grid, w % y, 3, VAR12z, .TRUE.)  ! d2W/dydz
!
!   do c = 1, grid % n_cells
!     Uxx = VAR1x(c)
!     Uyy = VAR1y(c)
!     Uzz = VAR1z(c)
!     Uxy = VAR2x(c)
!     Uxz = VAR2y(c)
!     Uyz = VAR2z(c)
!     Vxx = VAR9x(c)
!     Vyy = VAR9y(c)
!     Vzz = VAR9z(c)
!     Vxy = VAR10x(c)
!     Vxz = VAR10y(c)
!     Vyz = VAR10z(c)
!     Wxx = VAR11x(c)
!     Wyy = VAR11y(c)
!     Wzz = VAR11z(c)
!     Wxy = VAR12x(c)
!     Wxz = VAR12y(c)
!     Wyz = VAR12z(c)
!     dUdx= u % x(c) 
!     dUdy= u % y(c) 
!     dUdz= u % z(c) 
!     dVdx= v % x(c) 
!     dVdy= v % y(c) 
!     dVdz= v % z(c) 
!     dWdx= w % x(c) 
!     dWdy= w % y(c) 
!     dWdz= w % z(c) 
!     duu_dx = VAR3x(c)  
!     duu_dy = VAR3y(c)  
!     duu_dz = VAR3z(c)  
!     dvv_dx = VAR4x(c)  
!     dvv_dy = VAR4y(c)  
!     dvv_dz = VAR4z(c)  
!     dww_dx = VAR5x(c)  
!     dww_dy = VAR5y(c)  
!     dww_dz = VAR5z(c)  
!     duv_dx = VAR6x(c)  
!     duv_dy = VAR6y(c)  
!     duv_dz = VAR6z(c)  
!     duw_dx = kin_x(c)  
!     duw_dy = kin_y(c)  
!     duw_dz = kin_z(c)  
!     dvw_dx = VAR8x(c)  
!     dvw_dy = VAR8y(c)  
!     dvw_dz = VAR8z(c)  
!
!     Diss1(c) = duu_dx*Uxx + duv_dy*Uyy + duw_dz*Uzz   &
!              + Uxy*(duv_dx + duu_dy)                  &
!              + Uxz*(duw_dx + duu_dz)                  &
!              + Uyz*(duw_dy + duv_dz)                  &
!              + duv_dx*Vxx + dvv_dy*Vyy + dvw_dz*Vzz   &
!              + Vxy*(dvv_dx + duv_dy)                  &
!              + Vxz*(dvw_dx + duv_dz)                  &
!              + Vyz*(dvw_dy + dvv_dz)                  &
!              + duw_dx*Wxx + dvw_dy*Wyy + dww_dz*Wzz   &
!              + Wxy*(dvw_dx + duw_dy)                  &
!              + Wxz*(dww_dx + duw_dy)                  &
!              + Wyz*(dww_dy + dvw_dz)                  &
!              + 0.32 * Kin%n(c) / Eps%n(c)  *  &
!                (Uxx    * (duu_dx*dUdx  + duv_dx*dUdy  + duw_dx*dUdz ) + & 
!                 Uyy    * (duv_dy*dUdx  + dvv_dy*dUdy  + dvw_dy*dUdz ) + & 
!                 Uzz    * (duw_dz*dUdx  + dvw_dz*dUdy  + dww_dz*dUdz ) + & 
!                 Uxy    * (duu_dy*dUdx  + duv_dy*dUdy  + duw_dy*dUdz   + &
!                           duv_dx*dUdx  + dvv_dx*dUdy  + dvw_dx*dUdz ) + & 
!                 Uxz    * (duu_dz*dUdx  + duv_dz*dUdy  + duw_dz*dUdz   + &
!                           duw_dx*dUdx  + dvw_dx*dUdy  + dww_dx*dUdz ) + &
!                 Uyz    * (duv_dz*dUdx  + dvv_dz*dUdy  + dvw_dz*dUdz   + &
!                           duw_dy*dUdx  + dvw_dy*dUdy  + dww_dy*dUdz ) + &
!                 Vxx    * (duu_dx*dVdx  + duv_dx*dVdy  + duw_dx*dVdz ) + & 
!                 Vyy    * (duv_dy*dVdx  + dvv_dy*dVdy  + dvw_dy*dVdz ) + & 
!                 Vzz    * (duw_dz*dVdx  + dvw_dz*dVdy  + dww_dz*dVdz ) + & 
!                 Vxy    * (duu_dy*dVdx  + duv_dy*dVdy  + duw_dy*dVdz   + &
!                           duv_dx*dVdx  + dvv_dx*dVdy  + dvw_dx*dVdz ) + & 
!                 Vxz    * (duu_dz*dVdx  + duv_dz*dVdy  + duw_dz*dVdz   + &
!                           duw_dx*dVdx  + dvw_dx*dVdy  + dww_dx*dVdz ) + &
!                 Vyz    * (duv_dz*dVdx  + dvv_dz*dVdy  + dvw_dz*dVdz   + &
!                           duw_dy*dVdx  + dvw_dy*dVdy  + dww_dy*dVdz ) + &
!                 Wxx    * (duu_dx*dWdx  + duv_dx*dWdy  + duw_dx*dWdz ) + & 
!                 Wyy    * (duv_dy*dWdx  + dvv_dy*dWdy  + dvw_dy*dWdz ) + & 
!                 Wzz    * (duw_dz*dWdx  + dvw_dz*dWdy  + dww_dz*dWdz ) + & 
!                 Wxy    * (duu_dy*dWdx  + duv_dy*dWdy  + duw_dy*dWdz   + &
!                           duv_dx*dWdx  + dvv_dx*dWdy  + dvw_dx*dWdz ) + & 
!                 Wxz    * (duu_dz*dWdx  + duv_dz*dWdy  + duw_dz*dWdz   + &
!                           duw_dx*dWdx  + dvw_dx*dWdy  + dww_dx*dWdz ) + &
!                 Wyz    * (duv_dz*dWdx  + dvv_dz*dWdy  + dvw_dz*dWdz   + &
!                           duw_dy*dWdx  + dvw_dy*dWdy  + dww_dy*dWdz ))  
!     Diss1(c) =  -2.0 * VISc * Diss1(c)
!   end do
! end if

  if(name_phi == 'EPS') then
  do i=1,3
    if(i == 1) then
      call GraPhi(grid, U % x, 1, ui_xx, .TRUE.)  ! d2U/dxdx
      call GraPhi(grid, U % x, 2, ui_xy, .TRUE.)  ! d2U/dxdy
      call GraPhi(grid, U % x, 3, ui_xz, .TRUE.)  ! d2U/dxdz
      call GraPhi(grid, U % y, 2, ui_yy, .TRUE.)  ! d2U/dydy
      call GraPhi(grid, U % y, 3, ui_yz, .TRUE.)  ! d2U/dydz
      call GraPhi(grid, U % z, 3, ui_zz, .TRUE.)  ! d2U/dzdz
    end if
    if(i == 2) then
      call GraPhi(grid, V % x, 1, ui_xx, .TRUE.)  ! d2V/dxdx
      call GraPhi(grid, V % x, 2, ui_xy, .TRUE.)  ! d2V/dxdy
      call GraPhi(grid, V % x, 3, ui_xz, .TRUE.)  ! d2V/dxdz
      call GraPhi(grid, V % y, 2, ui_yy, .TRUE.)  ! d2V/dydy
      call GraPhi(grid, V % y, 3, ui_yz, .TRUE.)  ! d2V/dydz
      call GraPhi(grid, V % z, 3, ui_zz, .TRUE.)  ! d2V/dzdz
    end if
    if(i == 3) then
      call GraPhi(grid, W % x, 1, ui_xx, .TRUE.)  ! d2W/dxdx
      call GraPhi(grid, W % x, 2, ui_xy, .TRUE.)  ! d2W/dxdy
      call GraPhi(grid, W % x, 3, ui_xz, .TRUE.)  ! d2W/dxdz
      call GraPhi(grid, W % y, 2, ui_yy, .TRUE.)  ! d2W/dydy
      call GraPhi(grid, W % y, 3, ui_yz, .TRUE.)  ! d2W/dydz
      call GraPhi(grid, W % z, 3, ui_zz, .TRUE.)  ! d2W/dzdz
    end if

    do c = 1, grid % n_cells
      if(i == 1) then
        Uxx = ui_xx(c)
        Uxy = ui_xy(c)
        Uyx = Uxy
        Uxz = ui_xz(c)
        Uzx = Uxz
        Uyy = ui_yy(c)
        Uyz = ui_yz(c)
        Uzy = Uyz
        Uzz = ui_zz(c)
        Diss1(c) =                                    &
                2.0*0.25*VISc*Kin%n(c)/Eps_tot(c)  *  &
               (uu % n(c)*(Uxx*Uxx+Uxy*Uxy+Uxz*Uxz)+  &
                uv % n(c)*(Uxx*Uyx+Uxy*Uyy+Uxz*Uyz)+  &
                uw % n(c)*(Uxx*Uzx+Uxy*Uzy+Uxz*Uzz)+  &
                uv % n(c)*(Uyx*Uxx+Uyy*Uxy+Uyz*Uxz)+  &
                vv % n(c)*(Uyx*Uyx+Uyy*Uyy+Uyz*Uyz)+  &
                vw % n(c)*(Uyx*Uzx+Uyy*Uzy+Uyz*Uzz)+  &
                uw % n(c)*(Uzx*Uxx+Uzy*Uxy+Uzz*Uxz)+  &
                vw % n(c)*(Uzx*Uyx+Uzy*Uyy+Uzz*Uyz)+  &
                ww % n(c)*(Uzx*Uzx+Uzy*Uzy+Uzz*Uzz))
      end if
      if(i == 2) then
        Uxx = ui_xx(c)
        Uxy = ui_xy(c)
        Uyx = Uxy
        Uxz = ui_xz(c)
        Uzx = Uxz
        Uyy = ui_yy(c)
        Uyz = ui_yz(c)
        Uzy = Uyz
        Uzz = ui_zz(c)
        Diss1(c) = Diss1(c) +                         &
                2.0*0.25*VISc*Kin%n(c)/Eps_tot(c)  *  &
               (uu % n(c)*(Uxx*Uxx+Uxy*Uxy+Uxz*Uxz)+  &
                uv % n(c)*(Uxx*Uyx+Uxy*Uyy+Uxz*Uyz)+  &
                uw % n(c)*(Uxx*Uzx+Uxy*Uzy+Uxz*Uzz)+  &
                uv % n(c)*(Uyx*Uxx+Uyy*Uxy+Uyz*Uxz)+  &
                vv % n(c)*(Uyx*Uyx+Uyy*Uyy+Uyz*Uyz)+  &
                vw % n(c)*(Uyx*Uzx+Uyy*Uzy+Uyz*Uzz)+  &
                uw % n(c)*(Uzx*Uxx+Uzy*Uxy+Uzz*Uxz)+  &
                vw % n(c)*(Uzx*Uyx+Uzy*Uyy+Uzz*Uyz)+  &
                ww % n(c)*(Uzx*Uzx+Uzy*Uzy+Uzz*Uzz))
      end if
      if(i == 3) then
        Uxx = ui_xx(c)
        Uxy = ui_xy(c)
        Uyx = Uxy
        Uxz = ui_xz(c)
        Uzx = Uxz
        Uyy = ui_yy(c)
        Uyz = ui_yz(c)
        Uzy = Uyz
        Uzz = ui_zz(c)
        Diss1(c) = Diss1(c) +                         &
                2.0*0.25*VISc*Kin%n(c)/Eps_tot(c)  *  &
               (uu % n(c)*(Uxx*Uxx+Uxy*Uxy+Uxz*Uxz)+  &
                uv % n(c)*(Uxx*Uyx+Uxy*Uyy+Uxz*Uyz)+  &
                uw % n(c)*(Uxx*Uzx+Uxy*Uzy+Uxz*Uzz)+  &
                uv % n(c)*(Uyx*Uxx+Uyy*Uxy+Uyz*Uxz)+  &
                vv % n(c)*(Uyx*Uyx+Uyy*Uyy+Uyz*Uyz)+  &
                vw % n(c)*(Uyx*Uzx+Uyy*Uzy+Uyz*Uzz)+  &
                uw % n(c)*(Uzx*Uxx+Uzy*Uxy+Uzz*Uxz)+  &
                vw % n(c)*(Uzx*Uyx+Uzy*Uyy+Uzz*Uyz)+  &
                ww % n(c)*(Uzx*Uzx+Uzy*Uzy+Uzz*Uzz))
      end if
    end do
  end do  ! i
  end if                               

  call GraPhi(grid, Lsc, 1, l_sc_x,.TRUE.) 
  call GraPhi(grid, Lsc, 2, l_sc_y,.TRUE.) 
  call GraPhi(grid, Lsc, 3, l_sc_z,.TRUE.) 

  r13 = ONE_THIRD
  r23 = TWO_THIRDS
  do  c = 1, grid % n_cells
    Pk(c) = max( &
          - (  uu % n(c)*u % x(c) + uv % n(c)*u % y(c) + uw % n(c)*u % z(c)    &
             + uv % n(c)*v % x(c) + vv % n(c)*v % y(c) + vw % n(c)*v % z(c)    &
             + uw % n(c)*w % x(c) + vw % n(c)*w % y(c) + ww % n(c)*w % z(c)),  &
               1.0e-10)
  
    mag = max(0.0, sqrt(l_sc_x(c)**2 + l_sc_y(c)**2 + l_sc_z(c)**2), 1.0e-10)       

    n1 = l_sc_x(c) / mag 
    n2 = l_sc_y(c) / mag
    n3 = l_sc_z(c) / mag

    a11 = uu % n(c)/Kin % n(c) - r23 
    a22 = vv % n(c)/Kin % n(c) - r23
    a33 = ww % n(c)/Kin % n(c) - r23
    a12 = uv % n(c)/Kin % n(c)   
    a21 = a12
    a13 = uw % n(c)/Kin % n(c)    
    a31 = a13
    a23 = vw % n(c)/Kin % n(c)    
    a32 = a23
    
    S11 = u % x(c)
    S22 = v % y(c)
    S33 = w % z(c)
    S12 = 0.5*(u % y(c)+v % x(c))
    S21 = S12
    S13 = 0.5*(u % z(c)+w % x(c))
    S31 = S13
    S23 = 0.5*(v % z(c)+w % y(c))
    S32 = S23

    V11 = 0.0
    V22 = 0.0
    V33 = 0.0
    V12 = 0.5*(u % y(c)-v % x(c)) - omegaZ
    V21 = -V12 + omegaZ
    V13 = 0.5*(u % z(c)-w % x(c)) + omegaY
    V31 = -V13 - omegaY
    V23 = 0.5*(v % z(c)-w % y(c)) - omegaX
    V32 = -V23 + omegaX

    AA2 = (a11**2)+(a22**2)+(a33**2)+2*((a12**2)+(a13**2)+(a23**2))

    AA3 = a11**3 + a22**3 + a33**3 +                 &
          3*a12**2*(a11+a22) + 3*a13**2*(a11+a33) +  &
          3*a23**2*(a22+a33) + 6*a12*a13*a23

    AA=1.0 - (9.0/8.0)*(AA2-AA3)
    AA=max(AA,0.0)
    AA=min(AA,1.0)
 
    uu_nn = (uu % n(c)*n1*n1+uv % n(c)*n1*n2+uw % n(c)*n1*n3   &
           + uv % n(c)*n2*n1+vv % n(c)*n2*n2+vw % n(c)*n2*n3   &
           + uw % n(c)*n3*n1+vw % n(c)*n3*n2+ww % n(c)*n3*n3)

    a_mn_a_mn = a11*a11 + a22*a22 + a33*a33 + 2.0*(a12*a12+a13*a13+a23*a23)
    a_lk_s_lk = a11*S11 + a22*S22 + a33*S33 + 2.0*(a12*S12+a13*S13+a23*S23)
 
    EE=AA
    fss=1.0-(sqrt(AA) * EE**2)
    do icont=1,6
      Eps11= (1.0 - fss)*r23*Eps %n(c) + fss * uu%n(c)/Kin%n(c) * Eps%n(c)
      Eps22= (1.0 - fss)*r23*Eps %n(c) + fss * vv%n(c)/Kin%n(c) * Eps%n(c)
      Eps33= (1.0 - fss)*r23*Eps %n(c) + fss * ww%n(c)/Kin%n(c) * Eps%n(c)
      Eps12= fss * uv%n(c)/Kin%n(c) * Eps%n(c)
      Eps13= fss * uw%n(c)/Kin%n(c) * Eps%n(c)
      Eps23= fss * vw%n(c)/Kin%n(c) * Eps%n(c) 
      Eps21= Eps12
      Eps31= Eps13
      Eps32= Eps23

      e11= Eps11/Eps%n(c) - r23
      e22= Eps22/Eps%n(c) - r23
      e33= Eps33/Eps%n(c) - r23
      e12= Eps12/Eps%n(c)
      e13= Eps13/Eps%n(c)
      e23= Eps23/Eps%n(c)
      e21= e12
      e31= e13
      e32= e23
      E2=(e11**2)+(e22**2)+(e33**2)+2*((e12**2)+(e13**2)+(e23**2))

      E3= e11**3 + e22**3 + e33**3 + &
         3*e12**2*(e11+e22) + 3*e13**2*(e11+e33) +&
         3*e23**2*(e22+e33) + 6*e12*e13*e23

      EE=1.0 - (9.0/8.0)*(E2-E3)

      EE=max(EE,0.0)
      EE=min(EE,1.0)
      fss=1.0-(AA**0.5*EE**2.0)
    end do
     
    Ret= (Kin % n(c)*Kin % n(c))/(VISc*Eps_tot(c)+tiny)
    Feps = 1.0 - ((Ce2-1.4)/Ce2)*exp(-(Ret/6.0)**2.0)
    ff2=min((Ret/150)**1.5, 1.0)
    fd=1.0/(1.0+0.1*Ret)
    FF1=min(0.6, AA2)
    CC=2.5*AA*FF1**0.25*ff2
    CC1=CC+SQRT(AA)*(EE**2)
    CC2=0.8*SQRT(AA)
    C1W=max((1.0-0.7*CC), 0.3)
    C2W=min(AA,0.3)
    fw=min((Kin%n(c)**1.5)/(2.5*Eps_tot(c)*WallDs(c)),1.4)

    P11 = - 2.0*(  uu % n(c) * u % x(c)     &
                 + uv % n(c) * u % y(c)     &
                 + uw % n(c) * u % z(c))    &
          - 2.0 * omegaY * 2.0 * uw % n(c)  &
          + 2.0 * omegaZ * 2.0 * uv % n(c) 

    P22 = - 2.0*(  uv % n(c) * v % x(c)     &
                 + vv % n(c) * v % y(c)     &
                 + vw % n(c) * v % z(c))    &
          + 2.0 * omegaX * 2.0 * vw % n(c)  &
          - 2.0 * omegaZ * 2.0 * uw % n(c) 

    P33 = - 2.0*(  uw % n(c) * w % x(c)     &
                 + vw % n(c) * w % y(c)     &
                 + ww % n(c) * w % z(c))    &
          - 2.0 * omegaX * 2.0 * vw % n(c)  &
          + 2.0 * omegaY * 2.0 * uw % n(c) 

    P12 = -(  uu % n(c) * v % x(c)      &
            + uv % n(c) * v % y(c)      &
            + uw % n(c) * v % z(c)      &
            + uv % n(c) * u % x(c)      &
            + vv % n(c) * u % y(c)      &
            + vw % n(c) * u % z(c))     &
            + 2.0 * omegaX * uw % n(c)  &
            - 2.0 * omegaY * vw % n(c)  &
            + 2.0 * omegaZ * (vv % n(c) - uu % n(c)) 

    P13 = -(  uw % n(c)*u % x(c)                      &
            + vw % n(c)*u % y(c)                      &
            + ww % n(c)*u % z(c)                      &
            + uu % n(c)*w % x(c)                      &
            + uv % n(c)*w % y(c)                      &
            + uw % n(c)*w % z(c))                     &
            - 2.0 * omegaX * uv % n(c)                &
            - 2.0 * omegaY * (ww % n(c) - uu % n(c))  &
            + 2.0 * omegaZ * vw % n(c) 

    P23 = -(  uv % n(c) * w % x(c)                    &
            + vv % n(c) * w % y(c)                    &
            + vw % n(c) * w % z(c)                    &
            + uw % n(c) * v % x(c)                    &
            + vw % n(c) * v % y(c)                    &
            + ww % n(c) * v % z(c))                   &
            - 2.0 * omegaX * (vw % n(c) - ww % n(c))  &
            + 2.0 * omegaY * uv % n(c)                &
            - 2.0 * omegaZ * uw % n(c) 

    VAR1_11 = -CC1*Eps%n(c)*a11 
    VAR1_22 = -CC1*Eps%n(c)*a22 
    VAR1_33 = -CC1*Eps%n(c)*a33 
    VAR1_12 = -CC1*Eps%n(c)*a12 
    VAR1_13 = -CC1*Eps%n(c)*a13 
    VAR1_23 = -CC1*Eps%n(c)*a23 

    VAR2_11 = -CC2*(P11 - r23*Pk(c))
    VAR2_22 = -CC2*(P22 - r23*Pk(c))
    VAR2_33 = -CC2*(P33 - r23*Pk(c))
    VAR2_12 = -CC2*P12
    VAR2_13 = -CC2*P13
    VAR2_23 = -CC2*P23

    phi2_nn = VAR2_11*n1*n1+2*VAR2_12*n1*n2+2*VAR2_13*n1*n3+VAR2_22*n2*n2+2*VAR2_23*n2*n3+VAR2_33*n3*n3  

    VAR1w_11 = C1W*fw*Eps%n(c)/Kin%n(c)*(uu_nn-1.5*2.0*(uu%n(c)*n1*n1*0.0+uv%n(c)*n1*n2+uw%n(c)*n1*n3))
    VAR1w_22 = C1W*fw*Eps%n(c)/Kin%n(c)*(uu_nn-1.5*2.0*(uv%n(c)*n2*n1+vv%n(c)*n2*n2*0.0+vw%n(c)*n2*n3))
    VAR1w_33 = C1W*fw*Eps%n(c)/Kin%n(c)*(uu_nn-1.5*2.0*(uw%n(c)*n3*n1+vw%n(c)*n3*n2+ww%n(c)*n3*n3*0.0))
    VAR1w_12 = C1W*fw*Eps%n(c)/Kin%n(c)*(-1.5*(uu%n(c)*n2*n1+uv%n(c)*n2*n2*0.0+uw%n(c)*n2*n3 +&
                                               uv%n(c)*n1*n1*0.0+vv%n(c)*n1*n2+vw%n(c)*n1*n3)) 
    VAR1w_13 = C1W*fw*Eps%n(c)/Kin%n(c)*(-1.5*(uu%n(c)*n3*n1+uv%n(c)*n3*n2+uw%n(c)*n3*n3*0.0 +&
                                               uw%n(c)*n1*n1*0.0+vw%n(c)*n1*n2+ww%n(c)*n1*n3))
    VAR1w_23 = C1W*fw*Eps%n(c)/Kin%n(c)*(-1.5*(uw%n(c)*n2*n1+vw%n(c)*n2*n2*0.0+ww%n(c)*n2*n3 +&
                                               uv%n(c)*n3*n1+vv%n(c)*n3*n2+vw%n(c)*n3*n3)*0.0)

    VAR2w_11 = C2W*fw*(phi2_nn-1.5*2.0*(VAR2_11*n1*n1+VAR2_12*n1*n2+VAR2_13*n1*n3))
    VAR2w_22 = C2W*fw*(phi2_nn-1.5*2.0*(VAR2_12*n1*n2+VAR2_22*n2*n2+VAR2_23*n3*n2))
    VAR2w_33 = C2W*fw*(phi2_nn-1.5*2.0*(VAR2_13*n1*n3+VAR2_23*n2*n3+VAR2_33*n3*n3))
    VAR2w_12 = C2W*fw*(-1.5*(VAR2_11*n2*n1+VAR2_12*n2*n2+VAR2_13*n2*n3 +&
                             VAR2_12*n1*n1+VAR2_22*n1*n2+VAR2_23*n1*n3))
    VAR2w_13 = C2W*fw*(-1.5*(VAR2_11*n3*n1+VAR2_12*n3*n2+VAR2_13*n3*n3 +&
                             VAR2_13*n1*n1+VAR2_23*n1*n2+VAR2_33*n1*n3))
    VAR2w_23 = C2W*fw*(-1.5*(VAR2_13*n2*n1+VAR2_23*n2*n2+VAR2_33*n2*n3 +&
                             VAR2_12*n3*n1+VAR2_22*n3*n2+VAR2_23*n3*n3))

    ! uu stress
    if(name_phi == 'UU') then
!==============================================================================================================================!
      b(c) = b(c) + (max(P11,0.0)+CC1*Eps%n(c)*r23+max(VAR2_11,0.0)+max(VAR1w_11,0.0)+max(VAR2w_11,0.0))*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c)) + (CC1*Eps%n(c)/Kin%n(c)+C1W*fw*Eps%n(c)/Kin%n(c)*3.0*n1*n1 + &
                      fss*Eps%n(c)/Kin%n(c))*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c))+(max(-P11,0.0)+max(-VAR2_11,0.0)+max(-VAR1w_11,0.0)+max(-VAR2w_11,0.0) + &
                      (1.0-fss)*r23*Eps%n(c))/max(uu%n(c),1.0e-10)*grid % vol(c) 
!==============================================================================================================================!
    ! vv stress
    else if(name_phi == 'VV') then
!==============================================================================================================================!
      b(c) = b(c) + (max(P22,0.0)+CC1*Eps%n(c)*r23+max(VAR2_22,0.0)+max(VAR1w_22,0.0)+max(VAR2w_22,0.0))*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c)) + (CC1*Eps%n(c)/Kin%n(c)+C1W*fw*Eps%n(c)/Kin%n(c)*3.0*n2*n2 + &
                      fss*Eps%n(c)/Kin%n(c))*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c))+(max(-P22,0.0)+max(-VAR2_22,0.0)+max(-VAR1w_22,0.0)+max(-VAR2w_22,0.0)+ &
                      (1.0-fss)*r23*Eps%n(c))/max(vv%n(c),1.0e-10)*grid % vol(c) 
!==============================================================================================================================!
    ! ww stress
    else if(name_phi == 'WW') then
!==============================================================================================================================!
      b(c) = b(c) + (max(P33,0.0)+CC1*Eps%n(c)*r23+max(VAR2_33,0.0)+max(VAR1w_33,0.0)+max(VAR2w_33,0.0))*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c)) + (CC1*Eps%n(c)/Kin%n(c)+C1W*fw*Eps%n(c)/Kin%n(c)*3.0*n3*n3 + &
                      fss*Eps%n(c)/Kin%n(c))*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c))+(max(-P33,0.0)+max(-VAR2_33,0.0)+max(-VAR1w_33,0.0)+max(-VAR2w_33,0.0)+ &
                      (1.0-fss)*r23*Eps%n(c))/max(ww%n(c),1.0e-10)*grid % vol(c) 
!==============================================================================================================================!
!==============================================================================================================================!
    ! uv stress
    else if(name_phi == 'UV') then
      b(c) = b(c) + (P12 + VAR2_12 + VAR1w_12 + VAR2w_12)*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c)) + (CC1*Eps%n(c)/Kin%n(c)+C1W*fw*Eps%n(c)/Kin%n(c)*1.5*(n1*n1+n2*n2) + &
                      fss*Eps%n(c)/Kin%n(c))*grid % vol(c) 
!==============================================================================================================================!
!==============================================================================================================================!
    ! uw stress
    else if(name_phi == 'UW') then
      b(c) = b(c) + (P13 + VAR2_13 + VAR1w_13 + VAR2w_13)*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c)) + (CC1*Eps%n(c)/Kin%n(c)+C1W*fw*Eps%n(c)/Kin%n(c)*1.5*(n1*n1+n3*n3) + &
                      fss*Eps%n(c)/Kin%n(c))*grid % vol(c) 

!==============================================================================================================================!
!==============================================================================================================================!
    ! vw stress
    else if(name_phi == 'VW') then
      b(c) = b(c) + (P23 + VAR2_23 + VAR1w_23 + VAR2w_23)*grid % vol(c) 
      A % val(A % dia(c)) = A % val(A % dia(c)) + (CC1*Eps%n(c)/Kin%n(c)+C1W*fw*Eps%n(c)/Kin%n(c)*1.5*(n2*n2+n3*n3) + &
                      fss*Eps%n(c)/Kin%n(c))*grid % vol(c) 
!==============================================================================================================================!
!==============================================================================================================================!
    ! Epsilon equation
    else if(name_phi == 'EPS') then 
      Feps = 1.0 - ((Ce2-1.4)/Ce2) * exp(-(Ret/6.0)**2)
      Eps1 = 1.44 * Pk(c) * Eps % n(c) / Kin % n(c)
      Eps2 = Ce2*Feps*Eps%n(c)/Kin%n(c)
      b(c) = b(c) + max(Eps1 + Diss1(c),0.0)*grid % vol(c) 
     
      A % val(A % dia(c)) =  A % val(A % dia(c)) + Eps2*grid % vol(c)
    end if
  end do

  do c = 1, grid % n_cells
    kin_e(c) = sqrt( 0.5 * (uu % n(c) + vv % n(c) + ww % n(c)) )    
  end do 

  if(name_phi == 'EPS') then
    call GraPhi(grid, kin_e, 1, kin_x, .TRUE.)             ! dK/dx
    call GraPhi(grid, kin_e, 2, kin_y, .TRUE.)             ! dK/dy
    call GraPhi(grid, kin_e, 3, kin_z, .TRUE.)             ! dK/dz
    do c = 1, grid % n_cells
      Ret  = (Kin % n(c)**2) / (VISc*Eps % n(c) + TINY)
      Feps = 1.0 - ((Ce2-1.4)/Ce2) * exp(-(Ret/6.0)**2)
      b(c) = b(c) + (Ce2 * Feps * Eps % n(c) / Kin % n(c)                 &
                     * (VISc*(kin_x(c)**2 + kin_y(c)**2 + kin_z(c)**2)))  &
                  * grid % vol(c)
    end do
  end if

  if(name_phi == 'EPS') then
    do s = 1, grid % n_faces
      c1 = grid % faces_c(1,s)
      c2 = grid % faces_c(2,s)

      ! Calculate a values of dissipation  on wall
      if(c2 < 0 .and. TypeBC(c2) /= BUFFER ) then
        if(TypeBC(c2)==WALL .or. TypeBC(c2)==WALLFL) then
          Eps%n(c2) = VISc*(kin_x(c)**2 + kin_y(c)**2 + kin_z(c)**2)
        end if   ! end if of BC=wall
      end if    ! end if of c2<0
    end do
  end if

  end subroutine
