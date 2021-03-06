!==============================================================================!
  subroutine Compute_Gradient_Matrix(grid, Boundary)
!------------------------------------------------------------------------------!
!   Calculates gradient matrix.                                                !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use all_mod
  use pro_mod
  use Grid_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
  logical         :: Boundary
!-----------------------------------[Locals]-----------------------------------!
  integer :: c, c1, c2, s
  real    :: Dxc1, Dyc1, Dzc1, Dxc2, Dyc2, Dzc2
  real    :: Jac, Ginv(6)
!==============================================================================!

  do c = 1, grid % n_cells
    G(1,c) = 0.0
    G(2,c) = 0.0
    G(3,c) = 0.0
    G(4,c) = 0.0
    G(5,c) = 0.0
    G(6,c) = 0.0
  end do

  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s) 

    Dxc1 = grid % dx(s)
    Dyc1 = grid % dy(s)
    Dzc1 = grid % dz(s)
    Dxc2 = grid % dx(s)
    Dyc2 = grid % dy(s)
    Dzc2 = grid % dz(s)

    ! Take care of material interfaces         ! 2mat
    if( StateMat(material(c1))==FLUID .and. &  ! 2mat
        StateMat(material(c2))==SOLID       &  ! 2mat 
        .or.                                &  ! 2mat
        StateMat(material(c1))==SOLID .and. &  ! 2mat
        StateMat(material(c2))==FLUID ) then   ! 2mat
      Dxc1 = grid % xf(s) - grid % xc(c1)      ! 2mat
      Dyc1 = grid % yf(s) - grid % yc(c1)      ! 2mat
      Dzc1 = grid % zf(s) - grid % zc(c1)      ! 2mat 
      Dxc2 = grid % xf(s) - grid % xc(c2)      ! 2mat
      Dyc2 = grid % yf(s) - grid % yc(c2)      ! 2mat 
      Dzc2 = grid % zf(s) - grid % zc(c2)      ! 2mat
    end if                                     ! 2mat

    ! With boundary cells, velocities, temperatures
    if(Boundary) then
      G(1,c1)=G(1,c1) + Dxc1*Dxc1  ! 1,1
      G(2,c1)=G(2,c1) + Dyc1*Dyc1  ! 2,2
      G(3,c1)=G(3,c1) + Dzc1*Dzc1  ! 3,3
      G(4,c1)=G(4,c1) + Dxc1*Dyc1  ! 1,2  &  2,1
      G(5,c1)=G(5,c1) + Dxc1*Dzc1  ! 1,3  &  3,1
      G(6,c1)=G(6,c1) + Dyc1*Dzc1  ! 2,3  &  3,2
      if(c2  > 0) then  ! this is enough even for parallel
        G(1,c2)=G(1,c2) + Dxc2*Dxc2  ! 1,1
        G(2,c2)=G(2,c2) + Dyc2*Dyc2  ! 2,2
        G(3,c2)=G(3,c2) + Dzc2*Dzc2  ! 3,3
        G(4,c2)=G(4,c2) + Dxc2*Dyc2  ! 1,2  &  2,1
        G(5,c2)=G(5,c2) + Dxc2*Dzc2  ! 1,3  &  3,1
        G(6,c2)=G(6,c2) + Dyc2*Dzc2  ! 2,3  &  3,2
      end if

    ! Without boundary cells => pressure
    else ! Don't use Boundary
      if(c2 > 0 .or. c2 < 0 .and. TypeBC(c2) == BUFFER) then  
        G(1,c1)=G(1,c1) + Dxc1*Dxc1  ! 1,1
        G(2,c1)=G(2,c1) + Dyc1*Dyc1  ! 2,2
        G(3,c1)=G(3,c1) + Dzc1*Dzc1  ! 3,3
        G(4,c1)=G(4,c1) + Dxc1*Dyc1  ! 1,2  &  2,1
        G(5,c1)=G(5,c1) + Dxc1*Dzc1  ! 1,3  &  3,1
        G(6,c1)=G(6,c1) + Dyc1*Dzc1  ! 2,3  &  3,2
      end if
      if(c2 > 0) then
        G(1,c2)=G(1,c2) + Dxc2*Dxc2  ! 1,1
        G(2,c2)=G(2,c2) + Dyc2*Dyc2  ! 2,2
        G(3,c2)=G(3,c2) + Dzc2*Dzc2  ! 3,3
        G(4,c2)=G(4,c2) + Dxc2*Dyc2  ! 1,2  &  2,1
        G(5,c2)=G(5,c2) + Dxc2*Dzc2  ! 1,3  &  3,1
        G(6,c2)=G(6,c2) + Dyc2*Dzc2  ! 2,3  &  3,2
      end if
    end if ! Boundary
  end do

  !----------------------------------!
  !   Find the inverse of matrix G   !
  !----------------------------------!
  do c = 1, grid % n_cells
    Jac  =         G(1,c) * G(2,c) * G(3,c)  &
           -       G(1,c) * G(6,c) * G(6,c)  &
           -       G(4,c) * G(4,c) * G(3,c)  &
           + 2.0 * G(4,c) * G(5,c) * G(6,c)  &
           -       G(5,c) * G(5,c) * G(2,c)

    Ginv(1) = +( G(2,c)*G(3,c) - G(6,c)*G(6,c) ) / (Jac+TINY)
    Ginv(2) = +( G(1,c)*G(3,c) - G(5,c)*G(5,c) ) / (Jac+TINY)
    Ginv(3) = +( G(1,c)*G(2,c) - G(4,c)*G(4,c) ) / (Jac+TINY)
    Ginv(4) = -( G(4,c)*G(3,c) - G(5,c)*G(6,c) ) / (Jac+TINY)
    Ginv(5) = +( G(4,c)*G(6,c) - G(5,c)*G(2,c) ) / (Jac+TINY)
    Ginv(6) = -( G(1,c)*G(6,c) - G(4,c)*G(5,c) ) / (Jac+TINY)

    G(1,c) = Ginv(1) 
    G(2,c) = Ginv(2)
    G(3,c) = Ginv(3)
    G(4,c) = Ginv(4)
    G(5,c) = Ginv(5)
    G(6,c) = Ginv(6)
  end do 

  end subroutine
