!======================================================================!
  subroutine CalcF22(var, PHI,             &
                      dPHIdx, dPHIdy, dPHIdz)
!----------------------------------------------------------------------!
! Discretizes and solves eliptic relaxation equations for f22          !
!----------------------------------------------------------------------!
!------------------------------[Modules]-------------------------------!
  use all_mod
  use pro_mod
  use les_mod
  use rans_mod
  use par_mod
!----------------------------------------------------------------------!
  implicit none
!-----------------------------[Parameters]-----------------------------!
  integer       :: var
  TYPE(Unknown) :: PHI
  real          :: dPHIdx(-NbC:NC), dPHIdy(-NbC:NC), dPHIdz(-NbC:NC)
!-------------------------------[Locals]-------------------------------!
  integer :: s, c, c1, c2, niter, miter
  real    :: Fex, Fim 
  real    :: A0, A12, A21
  real    :: error
  real    :: dPHIdxS, dPHIdyS, dPHIdzS
!======================================================================! 
!  The form of equations which are solved:
!
!     /            /              /
!    |  df22      | f22 dV       | f22hg dV
!  - |  ---- dS + | ------   =   | --------
!    |   dy       |  Lsc^2       |  Lsc^2
!   /            /              /
!
!
!  Dimension of the system under consideration
!
!     [A]{f22} = {b}   [kg K/s]
!
!  Dimensions of certain variables:
!     f22            [1/s]
!     Lsc            [m]
!
!======================================================================!

  Aval = 0.0

  b=0.0


!----- This is important for "copy" boundary conditions. Find out why !
  do c=-NbC,-1
    Abou(c)=0.0
  end do

!-----------------------------------------! 
!     Initialize variables and fluxes     !
!-----------------------------------------! 

!----- old values (o and oo)
  if(ini == 1) then
    do c=1,NC
      PHI % oo(c)  = PHI % o(c)
      PHI % o (c)  = PHI % n(c)
      PHI % Doo(c) = PHI % Do(c)
      PHI % Do (c) = 0.0 
      PHI % Xoo(c) = PHI % Xo(c)
      PHI % Xo (c) = PHI % X(c) 
    end do
  end if


!----------------------------------------------------!
!     Browse through all the faces, where else ?     !
!----------------------------------------------------!

!----- new values
  do c=1,NC
    PHI % X(c) = 0.0
  end do

!==================!
!                  !
!     Difusion     !
!                  !
!==================!

!--------------------------------!
!     Spatial Discretization     !
!--------------------------------!
  do s=1,NS       

    c1=SideC(1,s)
    c2=SideC(2,s)   

    dPHIdxS = fF(s)*dPHIdx(c1) + (1.0-fF(s))*dPHIdx(c2)
    dPHIdyS = fF(s)*dPHIdy(c1) + (1.0-fF(s))*dPHIdy(c2)
    dPHIdzS = fF(s)*dPHIdz(c1) + (1.0-fF(s))*dPHIdz(c2)


!---- total (exact) diffusive flux
    Fex=( dPHIdxS*Sx(s) + dPHIdyS*Sy(s) + dPHIdzS*Sz(s) )

    A0 =  Scoef(s)

!---- implicit diffusive flux
!.... this is a very crude approximation: Scoef is not
!.... corrected at interface between materials
    Fim=( dPHIdxS*Dx(s)                      &
         +dPHIdyS*Dy(s)                      &
         +dPHIdzS*Dz(s))*A0

!---- this is yet another crude approximation:
!.... A0 is calculated approximatelly
!    if( StateMat(material(c1))==FLUID .and.  &  ! 2mat
!        StateMat(material(c2))==SOLID        &  ! 2mat
!        .or.                                 &  ! 2mat 
!        StateMat(material(c1))==SOLID .and.  &  ! 2mat
!        StateMat(material(c2))==FLUID ) then    ! 2mat
!      A0 = A0 + A0                              ! 2mat
!    end if                                      ! 2mat

!---- straight diffusion part 
    if(ini == 1) then
      if(c2  > 0) then
        PHI % Do(c1) = PHI % Do(c1) + (PHI % n(c2)-PHI % n(c1))*A0   
        PHI % Do(c2) = PHI % Do(c2) - (PHI % n(c2)-PHI % n(c1))*A0    
      else
        if(TypeBC(c2) /= SYMMETRY) then
          PHI % Do(c1) = PHI % Do(c1) + (PHI % n(c2)-PHI % n(c1))*A0   
        end if 
      end if 
    end if

!---- cross diffusion part
    PHI % X(c1) = PHI % X(c1) + Fex - Fim 
    if(c2  > 0) then
      PHI % X(c2) = PHI % X(c2) - Fex + Fim 
    end if 

!----- calculate the coefficients for the sysytem matrix
    if( (DIFFUS == CN) .or. (DIFFUS == FI) ) then  

      if(DIFFUS  ==  CN) then       ! Crank Nicholson
        A12 = 0.5 * A0 
        A21 = 0.5 * A0 
      end if

      if(DIFFUS  ==  FI) then       ! Fully implicit
        A12 = A0 
        A21 = A0
      end if

!----- fill the system matrix
      if(c2  > 0) then
        Aval(SidAij(1,s)) = Aval(SidAij(1,s)) - A12
        Aval(Adia(c1))    = Aval(Adia(c1))    + A12
        Aval(SidAij(2,s)) = Aval(SidAij(2,s)) - A21
        Aval(Adia(c2))    = Aval(Adia(c2))    + A21
      else if(c2  < 0) then
!- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -!
! Outflow is not included because it was causing problems     !
!- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -! 
        if( (TypeBC(c2) == INFLOW)) then                    
!---------  (TypeBC(c2) == OUTFLOW) ) then   
          Aval(Adia(c1)) = Aval(Adia(c1)) + A12
          b(c1) = b(c1) + A12 * PHI % n(c2)

        else

        if( (TypeBC(c2) == WALL).or.                          &
            (TypeBC(c2) == WALLFL) ) then
          Aval(Adia(c1)) = Aval(Adia(c1)) + A12
!=============================================================!
! Source coefficient is filled in SourceF22.f90 in order to   !
! get updated values of f22 on the wall.                      !
! Othrwise f22 equation does not converge very well           !
!          b(c1) = b(c1) + A12 * PHI % n(c2)                  !
!=============================================================!
        else if( TypeBC(c2) == BUFFER ) then  
          Aval(Adia(c1)) = Aval(Adia(c1)) + A12
          Abou(c2) = - A12  ! cool parallel stuff
        endif
      end if     
     end if
    end if

  end do  ! through sides

!---------------------------------!
!     Temporal discretization     !
!---------------------------------!

!----- Adams-Bashfort scheeme for diffusion fluxes
  if(DIFFUS == AB) then 
    do c=1,NC
      b(c) = b(c) + 1.5 * PHI % Do(c) - 0.5 * PHI % Doo(c)
    end do  
  end if

!----- Crank-Nicholson scheme for difusive terms
  if(DIFFUS == CN) then 
    do c=1,NC
      b(c) = b(c) + 0.5 * PHI % Do(c)
    end do  
  end if
                 
!----- Fully implicit treatment for difusive terms
!      is handled via the linear system of equations 

!----- Adams-Bashfort scheeme for cross diffusion 
  if(CROSS == AB) then
    do c=1,NC
      b(c) = b(c) + 1.5 * PHI % Xo(c) - 0.5 * PHI % Xoo(c)
    end do 
  end if

!----- Crank-Nicholson scheme for cross difusive terms
  if(CROSS == CN) then
    do c=1,NC
      b(c) = b(c) + 0.5 * PHI % X(c) + 0.5 * PHI % Xo(c)
    end do 
  end if

!----- Fully implicit treatment for cross difusive terms
  if(CROSS == FI) then
    do c=1,NC
      b(c) = b(c) + PHI % X(c)
    end do 
  end if

!========================================!
!                                        !  
!     Source terms and wall function     !
!     (Check if it is good to call it    !
!      before the under relaxation ?)    !
!                                        !
!========================================!

  if(SIMULA == EBM) then
    call SourceF22_EBM
  else
    call SourceF22KEPSV2F()
  end if

!=====================================!
!                                     !
!     Solve the equations for PHI     !
!                                     !    
!=====================================!
    do c=1,NC
      b(c) = b(c) + Aval(Adia(c)) * (1.0-PHI % URF)*PHI % n(c) / PHI % URF
      Aval(Adia(c)) = Aval(Adia(c)) / PHI % URF
    end do 


  if(ALGOR == SIMPLE)   miter=300
  if(ALGOR == FRACT)    miter=5

  niter=miter
  call cg(NC, Nbc, NONZERO, Aval,Acol,Arow,Adia,Abou,   &
           PHI % n, b, PREC,                            &
           niter,PHI % STol, res(var), error)

  
  if(this < 2) write(*,*) 'Var ', var, res(var), niter 

  call Exchng(PHI % n)

  RETURN

  end subroutine CalcF22
