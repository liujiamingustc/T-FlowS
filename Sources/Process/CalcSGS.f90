!======================================================================!
  subroutine CalcSGS()
!----------------------------------------------------------------------!
!   Calculates SGS stresses and turbulent viscosity for LES.           !
!----------------------------------------------------------------------!
!------------------------------[Modules]-------------------------------!
  use all_mod
  use pro_mod
  use les_mod
  use rans_mod
!----------------------------------------------------------------------!
! near(c) is the number of corresponding cell on the nearest wall.
! In case that, in parallel executions, the subdomain does not have 
! any nearwall cells, the near(c) is zero.
! near(c) is calculated in NearWallCells.f90, only ones in the beginig
! of a simulation.
!----------------------------------------------------------------------!
  implicit none
!-------------------------------[Locals]-------------------------------!
  integer :: c, s, c1, c2 
  real    :: Nx, Ny, Nz
  real    :: Cs, R
  real    :: Stot, lf, UtauL, Uff 
  real    :: Utot, Unor, Utan, Apow, Bpow, nu, dely, yPlus 
  real    :: fun, Nc2
!======================================================================!
  
!===================!
!                   !
!     SGS terms     !
!                   !
!===================!
  if(BUOY==YES) then
    call GraPhi(T % n,1,PHIx,.TRUE.)            ! dT/dx
    call GraPhi(T % n,2,PHIy,.TRUE.)            ! dT/dy
    call GraPhi(T % n,3,PHIz,.TRUE.)            ! dT/dz
  end if 
 
  if(MODE == SMAG) then
    do c=1,NC
      lf = volume(c)**0.333333
!=====================================================!
! if(near(c) /= 0) is needed for parallel version
! since the subdomains which do not "touch" wall
! has near(c) = 0. 
!=====================================================!    
      if(near(c) /= 0) then
        Uff = (VISc*(U % n(near(c)) * U % n(near(c))    & 
                   + V % n(near(c)) * V % n(near(c))    &
                   + W % n(near(c)) * W % n(near(c)))**0.5/(WallDs(near(c))+tiny) )**0.5    
        yPlus = WallDs(c) * Uff / VISc
        Cs = Cs0 * (1.0-exp(-yPlus/25.0))
      else  
        Cs = Cs0
      end if
      VISt(c) = DENc(material(c)) &
               * (lf*lf)          &          ! delta^2 
               * (Cs*Cs)          &          ! Cs^2   
              * Shear(c) 
    end do
  else if(MODE == DYN) then
    do c=1,NC
      lf =  (volume(c)**0.333333)  
      VISt(c) = DENc(material(c))    &
            * (lf*lf)                &          ! delta^2 
            * Cdyn(c)                &          ! Cdynamic   
            * Shear(c) 
    end do
  else if(MODE == WALE) then
    do c=1,NC
      lf =  (volume(c)**0.333333)    
      VISt(c) = DENc(material(c))     &
               * (lf*lf)              &
               * (0.5*0.5)            &
               * WALEv(c) 
    end do
  end if

  if(BUOY==YES) then
    do c=1,NC
      Nc2 = -(grav_x*PHIx(c)+grav_y*PHIy(c)+grav_z*PHIz(c))/Tref
      Nc2 = max(0.0, Nc2) 
      VISt(c) = VISt(c)*sqrt(1.0 - min(2.5*Nc2/(Shear(c)*Shear(c)),1.0))
    end do
  end if
!-----------------------!
!     Wall function     !
!-----------------------+--------------!
!     Law of the wall:                 !
!                                      !
!       u+ = yz+  for z+ < 11.81       !
!                                      !
!     and                              !
!                                      !
!       u+ = A(y+)^B   for y+ > 11.81  !
!                                      !
!       with: A=8.3 and B = 1/7        !
!                                      !
!------------------------------------------------------------------!
! The procedure below should be activated only if the wall function 
! approach is used. 
!----------------.--------------------------------------------------! 
  do s=1,NS
    c1=SideC(1,s)
    c2=SideC(2,s)

    if(c2  < 0) then 
      Stot = sqrt(Sx(s)*Sx(s) + Sy(s)*Sy(s) + Sz(s)*Sz(s))
      Nx = Sx(s)/Stot 
      Ny = Sy(s)/Stot 
      Nz = Sz(s)/Stot 
      if(TypeBC(c2)==WALL .or. TypeBC(c2)==WALLFL) then

        Utot = sqrt(  U % n(c1) * U % n(c1) &
            + V % n(c1) * V % n(c1) &
                    + W % n(c1) * W % n(c1)  )

        Unor = ( U % n(c1) * Nx + V % n(c1) * Ny + W % n(c1) * Nz )   

        if( abs(Utot) > abs(Unor) ) then
          Utan = sqrt(Utot * Utot - Unor * Unor)
        else
          Utan = TINY 
        end if

        Apow = 8.3
        Bpow = 1.0/7.0
        nu = VISc/DENc(material(c1))
        dely = WallDs(c1)
!----- calculate UtauL
        UtauL = ( Utan/Apow * (nu/dely)**Bpow )                     &
          ** (1.0/(1.0+Bpow))

!----- calculate TauWall 
        TauWall(c1) = VISc * Utan / dely 
 
!----- calculate y+
        yPlus  = dely*UtauL/nu
        if(yPlus  >=  11.81) then
!----- this one is effective viscosity
          VISwall(c1) = DENc(material(c1))*UtauL*UtauL*dely/abs(Utan) 
        else 
          VISwall(c1) = VISc + fF(s)*VISt(c1)+(1.0-fF(s))*VISt(c2)
        endif
      end if  ! TypeBC(c2)==WALL or WALLFL
    end if    ! c2 < 0
  end do

  call Exchng(VISt)
  call Exchng(VISwall)

  end subroutine CalcSGS
