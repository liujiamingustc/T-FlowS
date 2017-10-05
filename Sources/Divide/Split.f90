!======================================================================!
  subroutine Split(sub, Npar)
!----------------------------------------------------------------------!
!   Splits the domain by a geometrical multisection technique.         !
!----------------------------------------------------------------------!
!------------------------------[Modules]-------------------------------!
  use all_mod
  use gen_mod 
  use div_mod
  use par_mod 
!----------------------------------------------------------------------!
  implicit none
!-----------------------------[Parameters]-----------------------------!
  integer :: sub                           ! subdomain to be splitted
  integer :: Npar                          ! number of new partitions
!-------------------------------[Locals]-------------------------------!
  character :: dir                         ! direction for splitting
  integer   :: c, ic, j
  integer   :: Nfiled
  real      :: xmax,ymax,zmax,xmin,ymin,zmin, delx,dely,delz,dxyz 
!======================================================================!
! TESTING TESTING TESTING
!--------------------------------------------! 
!     Find the smallest moment of inertia    !
!--------------------------------------------! 
  if(ALGOR == INERTIAL) then
    call Inertia(sub)
  end if

!-------------------------------------------------! 
!     Find the largest dimension of the domain    !
!-------------------------------------------------! 
  if(ALGOR == COORDINATE) then
    xmax=-HUGE
    ymax=-HUGE
    zmax=-HUGE
    xmin=+HUGE
    ymin=+HUGE
    zmin=+HUGE
    do c=1,NC
      if(proces(c) == sub) then
        xmax=max(xmax, xc(c))
        ymax=max(ymax, yc(c))
        zmax=max(zmax, zc(c))
        xmin=min(xmin, xc(c))
        ymin=min(ymin, yc(c))
        zmin=min(zmin, zc(c))
      end if
    end do
    delx = xmax - xmin
    dely = ymax - ymin
    delz = zmax - zmin

    dxyz = max(delx,dely,delz)
    if(delz == dxyz) dir='z'
    if(dely == dxyz) dir='y'
    if(delx == dxyz) dir='x'
  end if

  do j=1,Npar-1

    Nfiled   = 0

!----------------------------!
!     Fill the subdomain     !
!----------------------------!

    if(ALGOR==COORDINATE) then

      if(dir == 'x') then
        do c=1,NC
          ic=ix(c)
          if(proces(ic) == sub) then
	    proces(ic) = Nsub+j
	    Nfiled = Nfiled + 1
	    if(Nfiled >= subNC(sub)/(Npar-j+1)) goto 2 
          end if
        end do
      end if

      if(dir == 'y') then
        do c=1,NC
          ic=iy(c)
          if(proces(ic) == sub) then
	    proces(ic) = Nsub+j
	    Nfiled = Nfiled + 1
	    if(Nfiled >= subNC(sub)/(Npar-j+1)) goto 2 
          end if
        end do
      end if

      if(dir == 'z') then
        do c=1,NC
          ic=iz(c)
          if(proces(ic) == sub) then
  	    proces(ic) = Nsub+j
	    Nfiled = Nfiled + 1
	    if(Nfiled >= subNC(sub)/(Npar-j+1)) goto 2 
          end if
        end do
      end if
    end if

    if(ALGOR==INERTIAL) then
      do c=1,NC
        ic=iin(c)
        if(proces(ic) == sub) then
          proces(ic) = Nsub+j
          Nfiled = Nfiled + 1
          if(Nfiled >= subNC(sub)/(Npar-j+1)) goto 2 
        end if
      end do
    end if

!--------------------------------! 
!     Subdomain is filled up     !
!--------------------------------! 
 2  subNC(Nsub+j) = Nfiled
    subNC(sub) = subNC(sub) - Nfiled

  end do  ! j

  Nsub = Nsub + Npar - 1

  end subroutine Split
