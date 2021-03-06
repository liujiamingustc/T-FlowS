!==============================================================================!
  subroutine Compute_Pressure_Fractional(grid)
!------------------------------------------------------------------------------!
!   Forms and solves pressure equation for the fractional step method.         !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use all_mod
  use pro_mod
  use Grid_Mod
  use Info_Mod
  use Parameters_Mod
  use Solvers_Mod,     only: Bicg, Cg, Cgs
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
!-----------------------------------[Locals]-----------------------------------!
  integer :: s, c, c1, c2, niter
  real    :: Pmax, Pmin
  real    :: error
  real    :: Us, Vs, Ws, DENs, fs
  real    :: A12
!==============================================================================!
!     
!   The form of equations which are being solved:
!     
!      /               /            
!     |               |             
!     | rho u dS = dt | GRAD pp dS
!     |               |             
!    /               /              
!
!   Dimension of the system under consideration
!   
!     [App] {pp} = {bpp}               [kg/s]
!   
!   Dimensions of certain variables
!
!     APP            [ms]
!     PP,            [kg/ms^2]
!     b              [kg/s]
!     Flux           [kg/s]
!   
!------------------------------------------------------------------------------!

  ! Initialize matrix and source term
  A % val = 0.0
  b = 0.0 

  !-------------------------------------------------!
  !   Calculate the mass fluxes on the cell faces   !
  !-------------------------------------------------!
  do s=1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    fs = grid % f(s)

    ! Handle two materials
    if( StateMat(material(c1))==FLUID .and.      &
        StateMat(material(c2))==FLUID) then
      DENs =      fs  * DENc(material(c1))     &
           + (1.0-fs) * DENc(material(c2))
    else if( StateMat(material(c1))==FLUID .and. &
             StateMat(material(c2))==SOLID) then
      DENs = DENc(material(c1)) 
    else if( StateMat(material(c1))==SOLID .and. &
             StateMat(material(c2))==FLUID) then
      DENs = DENc(material(c2)) 
    else
      DENs =      fs  * DENc(material(c1))     &
           + (1.0-fs) * DENc(material(c2))
    end if  

    ! Face is inside the domain
    if( c2  > 0 .or. c2  < 0 .and. TypeBC(c2) == BUFFER) then 

      ! Extract the "centred" pressure terms from cell velocities
      Us = fs*      (U % n(c1) + p % x(c1)*grid % vol(c1)/A % sav(c1))       &
         + (1.0-fs)*(U % n(c2) + p % x(c2)*grid % vol(c2)/A % sav(c2))

      Vs = fs*      (V % n(c1) + p % y(c1)*grid % vol(c1)/A % sav(c1))       &
         + (1.0-fs)*(V % n(c2) + p % y(c2)*grid % vol(c2)/A % sav(c2))

      Ws = fs*      (W % n(c1) + p % z(c1)*grid % vol(c1)/A % sav(c1))       &
         + (1.0-fs)*(W % n(c2) + p % z(c2)*grid % vol(c2)/A % sav(c2))

      ! Add the "staggered" pressure terms to face velocities
      Us= Us + (P % n(c1)-P % n(c2))*grid % sx(s)*                         &
         ( fs/A % sav(c1) + (1.0-fs)/A % sav(c2) )
      Vs=Vs+(P % n(c1)-P % n(c2))*grid % sy(s)*                            &
         ( fs/A % sav(c1) + (1.0-fs)/A % sav(c2) )
      Ws=Ws+(P % n(c1)-P % n(c2))*grid % sz(s)*                            &
         ( fs/A % sav(c1) + (1.0-fs)/A % sav(c2) )

      ! Now calculate the flux through cell face
      Flux(s) = DENs * ( Us*grid % sx(s) + Vs*grid % sy(s) + Ws*grid % sz(s) )

      A12=DENs*(  grid % sx(s)*grid % sx(s)  &
                + grid % sy(s)*grid % sy(s)  &
                + grid % sz(s)*grid % sz(s))
      A12=A12*(fs/A % sav(c1)+(1.-fs)/A % sav(c2))

      if(c2  > 0) then 
        A % val(A % pos(1,s)) = -A12
        A % val(A % pos(2,s)) = -A12
        A % val(A % dia(c1))  = A % val(A % dia(c1)) +  A12
        A % val(A % dia(c2))  = A % val(A % dia(c2)) +  A12
      else
        A % bou(c2) = -A12
        A % val(A % dia(c1)) = A % val(A % dia(c1)) +  A12
      endif

      b(c1)=b(c1)-Flux(s)
      if(c2  > 0) b(c2)=b(c2)+Flux(s)

    ! Face is on the boundary
    else
      Us = U % n(c2)
      Vs = V % n(c2)
      Ws = W % n(c2)

      Flux(s) = DENs * (  Us*grid % sx(s)  &
                        + Vs*grid % sy(s)  &
                        + Ws*grid % sz(s) )

      b(c1) = b(c1)-Flux(s)
    end if

  end do

  !----------------------------------------!
  !   Initialize the pressure correction   !
  !----------------------------------------!
  PP % n = 0.0 

  errmax=0.0
  do c = 1, grid % n_cells
    errmax=errmax + abs(b(c))
  end do
  call glosum(errmax)                       

  !--------------------------------------------!
  !   Solve the pressure correction equation   !
  !--------------------------------------------!

  ! Give the "false" flux back and set it to zero   ! 2mat
  do s = 1, grid % n_faces                          ! 2mat
    c1 = grid % faces_c(1,s)                                   ! 2mat
    c2 = grid % faces_c(2,s)                                   ! 2mat
    if(c2>0 .or. c2<0.and.TypeBC(c2)==BUFFER) then  ! 2mat
      if(StateMat(material(c1))==SOLID .or. &       ! 2mat
         StateMat(material(c2))==SOLID) then        ! 2mat
        b(c1) = b(c1) + Flux(s)                     ! 2mat
        if(c2 > 0) b(c2) = b(c2) - Flux(s)          ! 2mat
        Flux(s) = 0.0                               ! 2mat
      end if                                        ! 2mat
    end if                                          ! 2mat
  end do                                            ! 2mat

  ! Disconnect the SOLID cells from FLUID system    ! 2mat
  do s = 1, grid % n_faces                          ! 2mat
    c1 = grid % faces_c(1,s)                                   ! 2mat
    c2 = grid % faces_c(2,s)                                   ! 2mat
    if(c2>0 .or. c2<0.and.TypeBC(c2)==BUFFER) then  ! 2mat 
      if(c2 > 0) then ! => not BUFFER               ! 2mat
        if(StateMat(material(c1)) == SOLID) then    ! 2mat
          A12 = -A % val(A % pos(2,s))              ! 2mat
          A % val(A % pos(1,s)) = 0.0               ! 2mat
          A % val(A % pos(2,s)) = 0.0               ! 2mat
          if(StateMat(material(c2)) == FLUID) then  ! 2mat
            A % val(A % dia(c2)) = &                ! 2mat
            A % val(A % dia(c2)) -  A12             ! 2mat
          endif                                     ! 2mat
        end if                                      ! 2mat
        if(StateMat(material(c2)) == SOLID) then    ! 2mat
          A12 = -A % val(A % pos(1,s))              ! 2mat
          A % val(A % pos(2,s)) = 0.0               ! 2mat
          A % val(A % pos(1,s)) = 0.0               ! 2mat
          if(StateMat(material(c1)) == FLUID) then  ! 2mat
            A % val(A % dia(c1)) = &                ! 2mat
            A % val(A % dia(c1)) -  A12             ! 2mat
          endif                                     ! 2mat
        end if                                      ! 2mat
      else            ! => BUFFER                   ! 2mat
        if(StateMat(material(c1)) == SOLID  .or. &  ! 2mat
           StateMat(material(c2)) == SOLID) then    ! 2mat
          A12 = -A % bou(c2)                        ! 2mat
          A % bou(c2) = 0.0                         ! 2mat
          if(StateMat(material(c1)) == FLUID) then  ! 2mat
            A % val(A % dia(c1)) = &                ! 2mat
            A % val(A % dia(c1)) -  A12             ! 2mat
          endif                                     ! 2mat
        end if                                      ! 2mat
      end if                                        ! 2mat
    end if                                          ! 2mat
  end do                                            ! 2mat

  ! Don't solve the pressure corection too accurate.
  ! Value 1.e-18 blows the solution.
  ! Value 1.e-12 keeps the solution stable
  if(ALGOR == FRACT)  niter = 200
  if(ALGOR == SIMPLE) niter =  15
  call Cg(A, PP % n, b,            &
          PREC, niter, PP % STol,  &
          res(4), error) 
  call Info_Mod_Iter_Fill_At(1, 3, pp % name, niter, res(4))

  !-------------------------------!
  !   Update the pressure field   !
  !-------------------------------!
  P % n  =  P % n  +  P % URF  *  PP % n

  !----------------------------------!
  !   Normalize the pressure field   !
  !----------------------------------!
  Pmax  = maxval(P % n(1:grid % n_cells))
  Pmin  = minval(P % n(1:grid % n_cells))

  call glomax(Pmax) 
  call glomin(Pmin) 

  P % n  =  P % n  -  0.5 * (Pmax+Pmin)

  call Exchange(grid, PP % n) 

  end subroutine
