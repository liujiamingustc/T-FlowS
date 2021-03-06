!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>!
!                                 !                                    !
!                                 !   Bojan Niceno                     !
!   RANS models  variable         !   Delft University of Technology   !
!   definitions for the processor !   Section Heat Transfer             !
!                                 !   niceno@duttwta.wt.tn.tudelft.nl  !
!                                 !                                    !
!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>!

  module rans_mod

  use Var_Mod

  implicit none

  ! Turbulence models variables
  type(Var_Type) :: kin
  type(Var_Type) :: eps
  type(Var_Type) :: v_2
  type(Var_Type) :: f22
  type(Var_Type) :: vis

  ! Reynolds stresses
  type(Var_Type) :: uu
  type(Var_Type) :: vv
  type(Var_Type) :: ww
  type(Var_Type) :: uv
  type(Var_Type) :: uw
  type(Var_Type) :: vw
 
  ! Temperature fluctuations
  type(Var_Type) :: tt
  type(Var_Type) :: ut
  type(Var_Type) :: vt
  type(Var_Type) :: wt
 
  ! Constants for the k-eps model:
  real :: Ce1, Ce2, Ce3, Cmu, Cmu25, Cmu75, kappa, Elog, Zo
 
  ! Constants for the k-eps-v2f model:
  real :: CmuD, Cl, Ct, alpha, Cni, cf1, cf2, cf3, Cf_1, Cf_2
  real :: Lim
  real :: g1, g1_star, g2, g3, g3_star, g4, g5 

  ! Constants for the Spalart-Allmaras model:
  real :: Cb1, Cb2, SIGMAv, Cw1, Cw2, Cw3, Cvis1

  ! Total dissipation in HJ model
  real,allocatable :: eps_tot(:)

  ! Vorticity
  real,allocatable :: Vort(:), VortMean(:)

  ! Turbulent viscosity
  real,allocatable :: VISt(:), CmuS(:)
 
  ! Turbulent conductivity
  real,allocatable :: CONt(:)
 
  ! Lenght and Time Scales
  real,allocatable :: Lsc(:)
  real,allocatable :: Tsc(:)   

  ! Production of turbulent kinetic energy
  real,allocatable :: Pk(:)
  ! Buoyancy production
  real,allocatable :: Gbuoy(:)
  real,allocatable :: buoyBeta(:)
  real,allocatable :: Pbuoy(:)
 
  ! Non-dimensional distance
  real,allocatable :: Ynd(:)
 
  ! Friction velocity
  real,allocatable :: Uf(:)
  real,allocatable :: Ufmean(:)

  ! Gravity
  real :: grav_x, grav_y, grav_z

  ! Wall viscosity (wall function approuch)
  real,allocatable :: VISwall(:)
  real,allocatable :: CONwall(:)

  real,allocatable :: Fs(:)

  end module 
