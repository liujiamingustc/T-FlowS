!==============================================================================!
  subroutine Source_Eps_K_Eps(grid)
!------------------------------------------------------------------------------!
!   Computes the source terms in the eps transport equation,                   !
!   wall shear stress (wall function approuch)                                 !
!------------------------------------------------------------------------------! 
!                           2                                                  !
!       eps              eps                                                   !
!   Ce1 --- Gk - Ce2 rho ---                                                   !
!        K                K                                                    !
!                                                                              !
!   assigns epsilon from the wall function:                                    !
!                                                                              !
!               3/4      3/2                                                   !
!   Eps_w = Cmu^    * K^     / (Kappa/y)                                       !
!                                                                              !
!----------------------------------[Modules]-----------------------------------!
  use Const_Mod
  use Flow_Mod
  use les_mod
  use rans_mod
  use Grid_Mod
  use Grad_Mod
  use Control_Mod
  use Work_Mod, only: shear_x => r_cell_01,  &
                      shear_y => r_cell_02,  &
                      shear_z => r_cell_03           
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
!-----------------------------------[Locals]-----------------------------------!
  integer           :: s, c, c1, c2, j
  real              :: Ret, Fmu, L1, L2, YAP, yStar, Lf
!==============================================================================!

  if(turbulence_model_variant == HIGH_RE) then
    do c = 1, grid % n_cells

      ! Positive contribution:
      b(c) = b(c) & 
           + Ce1 * eps % n(c) / kin % n(c) * p_kin(c) * grid % vol(c)
    
      ! Negative contribution:
      A % val(A % dia(c)) = A % val(A % dia(c)) &
           + Ce2 * density * eps % n(c) / kin % n(c) * grid % vol(c)
    end do 

    !--------------------------------------------!
    !   Cut-off the wall influence in order to   !
    !   impose the boundary condition for EPS    !
    !--------------------------------------------!
    do s = 1, grid % n_faces
      c1=grid % faces_c(1,s)
      c2=grid % faces_c(2,s)

      if(c2 < 0.and.Grid_Mod_Bnd_Cond_Type(grid,c2) /= BUFFER ) then  
        if(Grid_Mod_Bnd_Cond_Type(grid,c2) == WALL .or.  &
           Grid_Mod_Bnd_Cond_Type(grid,c2) == WALLFL) then

          ! This will fix the value of eps in the first cell
          if(ROUGH==NO) then
            eps % n(c1) = Cmu75 * (kin % n(c1))**1.5   &
                        / (kappa*grid % wall_dist(c1))
          else if(ROUGH==YES) then
            eps % n(c1) = Cmu75*(kin%n(c1))**1.5  &
                        / (kappa*(grid % wall_dist(c1)+Zo))
          end if
          do j=A % row(c1), A % row(c1+1) -1
            A % val(j) = 0.0
          end do   
          A % val(A % dia(c1)) = 1.0
          b(c1) = eps % n(c1)
        end if  ! Grid_Mod_Bnd_Cond_Type(grid,c2)==WALL or WALLFL
      end if    ! c2 < 0
    end do
  end if        ! end if mode = wf   

  !-------------------------!
  !   Jones-Launder model   !
  !-------------------------!
  if(turbulence_model_variant == LOW_RE) then

   call Calculate_Shear_And_Vorticity(grid)
   call Grad_Mod_For_Phi(grid, shear, 1, shear_x, .true.)  ! dU/dx
   call Grad_Mod_For_Phi(grid, shear, 2, shear_y, .true.)  ! dW/dy
   call Grad_Mod_For_Phi(grid, shear, 3, shear_z, .true.)  ! dV/dz

    do c = 1, grid % n_cells

      ! Positive contribution:
      b(c) = b(c) & 
           + Ce1 * eps % n(c) / kin % n(c) * p_kin(c) * grid % vol(c)        & 
           + 2.0 * viscosity * vis_t(c) * &
           (shear_x(c)**2 + shear_y(c)**2 + shear_z(c)**2) * grid % vol(c)
    
      ! Negative contribution:
      Ret = kin % n(c)*kin % n(c)/(viscosity*eps % n(c))
      Fmu = 1.0 - 0.3*exp(-(Ret*Ret))
      A % val(A % dia(c)) = A % val(A % dia(c))  &
      + Fmu * Ce2 * density * eps % n(c) / kin % n(c) * grid % vol(c)        

       ! Yap correction
       L1 = kin % n(c)**1.5/eps % n(c)
       L2 = 2.55 * grid % wall_dist(c)
       YAP = 0.83 * eps % n(c) * eps % n(c)/kin % n(c)  &
                  * max((L1/L2 - 1.0) * (L1/L2)**2, 0.0)
       b(c) = b(c) + YAP * grid % vol(c) 
    end do 

    !-----------------------------------!
    !   Boundary condition fo epsilon   !
    !-----------------------------------!
    do s = 1, grid % n_faces
      c1=grid % faces_c(1,s)
      c2=grid % faces_c(2,s)

      if(c2 < 0 .and. Grid_Mod_Bnd_Cond_Type(grid,c2) /= BUFFER ) then
        if(Grid_Mod_Bnd_Cond_Type(grid,c2)==WALL .or.  &
           Grid_Mod_Bnd_Cond_Type(grid,c2)==WALLFL) then

          eps % n(c2) = 0.0

        end if  ! Grid_Mod_Bnd_Cond_Type(grid,c2)==WALL or WALLFL
      end if    ! c2 < 0
    end do
  end if

  if(turbulence_model == HYBRID_PITM) then
    do c = 1, grid % n_cells

      ! Positive contribution:
      b(c) = b(c) &
           + Ce1 * eps % n(c) / kin % n(c) * p_kin(c) * grid % vol(c)

      Lf = grid % vol(c)**ONE_THIRD

      ! Negative contribution:
      Ret = kin % n(c)*kin % n(c)/(viscosity*eps % n(c))
      yStar = (viscosity * eps % n(c))**0.25 * grid % wall_dist(c) / viscosity
      Fmu = (1.0 - exp(-yStar/3.1))**2*(1.0 - 0.25*exp(-(Ret/6.)*(Ret/6.)))
      Fmu = min(Fmu,1.0)

      Ce2 =  1.5 + 0.4/(1.0 + 2.4*(0.41*grid % wall_dist(c)/Lf)**TWO_THIRDS)

      A % val(A % dia(c)) = A % val(A % dia(c))            &
                         + (Ce1 + (Ce2 - Ce1) * Fmu )      &
                         * density * eps % n(c)  &
                         / kin % n(c) * grid % vol(c)

    end do

    !-----------------------------------!
    !   Boundary condition fo epsilon   !
    !-----------------------------------!
    do s = 1, grid % n_faces
      c1=grid % faces_c(1,s)
      c2=grid % faces_c(2,s)

      if(c2 < 0.and.Grid_Mod_Bnd_Cond_Type(grid,c2) /= BUFFER ) then
        if(Grid_Mod_Bnd_Cond_Type(grid,c2)==WALL .or.  &
           Grid_Mod_Bnd_Cond_Type(grid,c2)==WALLFL) then

          eps % n(c2) = 2.0 * viscosity * kin % n(c1)  &
                      / (grid % wall_dist(c1)*grid % wall_dist(c1))

        end if  ! Grid_Mod_Bnd_Cond_Type(grid,c2)==WALL or WALLFL
      end if    ! c2 < 0
    end do
  end if        ! end if mode = stan

  end subroutine
