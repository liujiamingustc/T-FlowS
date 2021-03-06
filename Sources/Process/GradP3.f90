!==============================================================================!
  subroutine GradP3(grid, phi, phi_x, phi_y, phi_z)
!------------------------------------------------------------------------------!
!   Calculates gradient of generic variable phi. phi may stand either          !
!   for pressure (P) or pressure corrections (PP). This procedure also         !
!   handles different materials.                                               ! 
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use all_mod
  use pro_mod
  use Grid_Mod
  use Work_Mod, only: phi_f => r_face_01
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
  real            :: phi(  -grid % n_bnd_cells:grid % n_cells),        &
                     phi_x(-grid % n_bnd_cells:grid % n_cells),        &
                     phi_y(-grid % n_bnd_cells:grid % n_cells),        &
                     phi_z(-grid % n_bnd_cells:grid % n_cells)
!-----------------------------------[Locals]-----------------------------------!
  integer :: s, c, c1, c2
  real    :: phi_s, xs, ys, zs 
!==============================================================================!
 
  call Exchange(grid, phi)

  phi_f = 0.0

  do c = 1, grid % n_cells
    phi_x(c)=0.0
    phi_y(c)=0.0
    phi_z(c)=0.0
  end do

  !------------------------------------------------------------!
  !   First step: without any wall influence, except outflow   !
  !------------------------------------------------------------!
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(c2 > 0                            .or. &
       c2 < 0 .and. TypeBC(c2) == BUFFER .or. &
       c2 < 0 .and. TypeBC(c2) == OUTFLOW) then  
      if( StateMat(material(c1))==FLUID .and. &
          StateMat(material(c2))==FLUID ) then  
        phi_s = grid % f(s)*phi(c1)+(1.0-grid % f(s))*phi(c2)  
        phi_x(c1) = phi_x(c1) + phi_s * grid % sx(s)
        phi_y(c1) = phi_y(c1) + phi_s * grid % sy(s)
        phi_z(c1) = phi_z(c1) + phi_s * grid % sz(s)
        phi_x(c2) = phi_x(c2) - phi_s * grid % sx(s)
        phi_y(c2) = phi_y(c2) - phi_s * grid % sy(s)
        phi_z(c2) = phi_z(c2) - phi_s * grid % sz(s)
      end if
    end if
  end do

  do c = 1, grid % n_cells
    if(StateMat(material(c))==FLUID) then
      phi_x(c) = phi_x(c) / grid % vol(c)
      phi_y(c) = phi_y(c) / grid % vol(c)
      phi_z(c) = phi_z(c) / grid % vol(c)
    end if
  end do

  !------------------------------------------------------------!
  !   Second step: extrapolate to boundaries, except outflow   !
  !------------------------------------------------------------!
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(c2 < 0               .and. &
       TypeBC(c2) /= BUFFER .and. &
       TypeBC(c2) /= OUTFLOW) then  
      if(StateMat(material(c1))==FLUID) then
        phi_f(s) = (phi(c1)                                   +     &
                    phi_x(c1) * (grid % xc(c2)-grid % xc(c1)) +     &
                    phi_y(c1) * (grid % yc(c2)-grid % yc(c1)) +     &
                    phi_z(c1) * (grid % zc(c2)-grid % zc(c1))   ) / &
              ( 1.0 - (  grid % sx(s) * (grid % xc(c2)-grid % xc(c1))      & 
                       + grid % sy(s) * (grid % yc(c2)-grid % yc(c1))      &
                       + grid % sz(s) * (grid % zc(c2)-grid % zc(c1))  ) / grid % vol(c1)  )
      end if
    end if

    ! Handle two materials
    if(c2 > 0 .or. c2 < 0 .and. TypeBC(c2) == BUFFER) then  
      if( StateMat(material(c1))==FLUID .and. &
          StateMat(material(c2))==SOLID ) then  
        xs = grid % xf(s) 
        ys = grid % yf(s) 
        zs = grid % zf(s) 
        phi_f(s) = (phi(c1)                        +     &
                    phi_x(c1) * (xs-grid % xc(c1)) +     &
                    phi_y(c1) * (ys-grid % yc(c1)) +     &
                    phi_z(c1) * (zs-grid % zc(c1))   ) / &
              ( 1.0 - (  grid % sx(s) * (xs-grid % xc(c1))      & 
                       + grid % sy(s) * (ys-grid % yc(c1))      &
                       + grid % sz(s) * (zs-grid % zc(c1))  ) / grid % vol(c1)  )
      end if
      if( StateMat(material(c1))==SOLID .and. &
          StateMat(material(c2))==FLUID ) then  
        xs = grid % xf(s) 
        ys = grid % yf(s) 
        zs = grid % zf(s) 
        phi_f(s) = (phi(c2)                        +     &
                    phi_x(c2) * (xs-grid % xc(c2)) +     &
                    phi_y(c2) * (ys-grid % yc(c2)) +     &
                    phi_z(c2) * (zs-grid % zc(c2))   ) / &
              ( 1.0 + (  grid % sx(s) * (xs-grid % xc(c2))      & 
                       + grid % sy(s) * (ys-grid % yc(c2))      &
                       + grid % sz(s) * (zs-grid % zc(c2))  ) / grid % vol(c2)  )
      end if
    end if ! c2 < 0
  end do

  !---------------------------------------------!
  !   Third step: compute the final gradients   !
  !---------------------------------------------!
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(c2 < 0               .and. &
       TypeBC(c2) /= BUFFER .and. &
       TypeBC(c2) /= OUTFLOW) then  
      phi_x(c1) = phi_x(c1) + phi_f(s) * grid % sx(s) / grid % vol(c1)
      phi_y(c1) = phi_y(c1) + phi_f(s) * grid % sy(s) / grid % vol(c1)
      phi_z(c1) = phi_z(c1) + phi_f(s) * grid % sz(s) / grid % vol(c1)
    end if

    ! Handle two materials
    if(c2 > 0 .or. c2 < 0 .and. TypeBC(c2) == BUFFER) then  
      if( StateMat(material(c1))==FLUID .and. &
          StateMat(material(c2))==SOLID ) then  
        phi_x(c1) = phi_x(c1) + phi_f(s) * grid % sx(s) / grid % vol(c1)
        phi_y(c1) = phi_y(c1) + phi_f(s) * grid % sy(s) / grid % vol(c1)
        phi_z(c1) = phi_z(c1) + phi_f(s) * grid % sz(s) / grid % vol(c1)
      end if 
      if( StateMat(material(c1))==SOLID .and. &
          StateMat(material(c2))==FLUID ) then  
        phi_x(c2) = phi_x(c2) - phi_f(s) * grid % sx(s) / grid % vol(c2)
        phi_y(c2) = phi_y(c2) - phi_f(s) * grid % sy(s) / grid % vol(c2)
        phi_z(c2) = phi_z(c2) - phi_f(s) * grid % sz(s) / grid % vol(c2)
      end if 
    end if  ! c2 < 0
  end do

  call Exchange(grid, phi_x)
  call Exchange(grid, phi_y)
  call Exchange(grid, phi_z)

  end subroutine
