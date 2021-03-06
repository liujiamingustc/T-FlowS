!==============================================================================!
  subroutine Compute_Geometry(grid)
!------------------------------------------------------------------------------!
!   Calculates geometrical quantities of the grid.                             !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use all_mod 
  use gen_mod 
  use Grid_Mod
  use Tokenizer_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
!------------------------------------------------------------------------------!
  include "../Shared/Approx.int"
!----------------------------------[Calling]-----------------------------------!
  real :: Distance
  real :: Distance_Squared    
  real :: Tol
!-----------------------------------[Locals]-----------------------------------!
  integer              :: c, c1, c2, n, s, ss, cc2, c_max, nnn, hh, mm, b
  integer              :: c11, c12, c21, c22, s1, s2, bou_cen
  integer              :: new_face_1, new_face_2
  integer              :: type_per, n_per, number_sides, dir, option
  integer              :: wall_mark, rot_dir
  real                 :: xt(4), yt(4), zt(4), angle_face
  real                 :: xs2, ys2, zs2, x_a, y_a, z_a, x_b, y_b, z_b
  real                 :: x_c, y_c, z_c, Det
  real                 :: ab_i, ab_j, ab_k, ac_i, ac_j, ac_k, p_i, p_j, p_k
  real                 :: dsc1, dsc2, per_min, per_max
  real                 :: t, SurTot, angle 
  real                 :: xc1, yc1, zc1, xc2, yc2, zc2 
  real                 :: max_dis, tot_vol, min_vol, max_vol
  real                 :: xmin, xmax, ymin, ymax, zmin, zmax 
  real, allocatable    :: xspr(:), yspr(:), zspr(:)
  real, allocatable    :: b_coor(:), phi_face(:)
  integer, allocatable :: b_face(:), face_copy(:)
  character(len=80)    :: name_per
!==============================================================================!
!
!                                n3 
!                 +---------------!---------------+
!                /|              /|              /|
!               / |             / |             / |
!              /  |          n2/  |            /  |
!             +---------------!---------------+   |
!             |   |           |   |           |   |
!             |   |     o---- | s-------o     |   |      
!             |   +---- c1 ---|   !---- c2 ---|   +       
!             |  /            |  /n4          |  /
!             | /             | /             | /
!             |/              |/              |/
!             +---------------!---------------+
!                            n1
!
!   Notes:
! 
!     ! side s is oriented from cell center c1 to cell center c2     
!     ! c2 is greater then c1 inside the domain or smaller then 0
!       on the boundary
!     ! nodes are denoted with n1 - n4
!
!            c3           
!             \  4-----3
!              \/ \  . |
!              /   \  +---c2
!             /  .  \  |
!            / .     \ |
!           /.        \|
!          1-----------2
!                   |
!                   c1
!
!                                n3 
!                 +---------------!-------+         
!                /|            n2/|      /|
!               / |             !-------+ |
!              /  |            /|s|  c2 | |
!             +---------------+ | !-----| +
!             |   |           | |/n4    |/
!             |   |     c1    | !-------+
!             |   +-----------|n1 +
!             |  /            |  /
!             | /             | /
!             |/              |/ 
!             +---------------+
!                            n1
! 
!------------------------------------------------------------------------------!
!   Generaly:
!
!   the equation of plane reads: A*x_node + B*y_node + C*z_node + D = 0
!
!   and the equation of line:  x_node = x0 + t*rx
!                              y_node = y0 + t*ry
!                              z_node = z0 + t*rz
!- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!   In our case:
!
!     line is a connection between the two cell centers:
!
!     x_node = xc(c1) + t*(xc(c2)-xc(c1)) = xc(c1) + t*rx
!     y_node = yc(c1) + t*(yc(c2)-yc(c1)) = yc(c1) + t*ry
!     z_node = zc(c1) + t*(zc(c2)-zc(c1)) = zc(c1) + t*rz
!    
!
!     plane is a cell face: 
!
!     Sx * x_node + Sy * y_node + Sz * z_node = 
!     Sx * xsp(s) + Sy * ysp(s) + Sz * zsp(s)
!  
!     and the intersection is at:
!  
!         Sx*(xsp(s)-xc(c1)) + Sy*(ysp(s)-yc(c1) + Sz*(zsp(s)-zc(c1)) 
!     t = -----------------------------------------------------------
!                           rx*Sx + ry*Sy + rz*Sz
!  
!------------------------------------------------------------------------------!
 
  !-----------------------------------------!
  !   Calculate the cell centers            !
  !-----------------------------------------!
  !   => depends on: x_node,y_node,z_node   !
  !   <= gives:      xc,yc,zc c>0           !
  !-----------------------------------------!
  do c = 1, grid % n_cells
    do n = 1, grid % cells_n_nodes(c)
      grid % xc(c) = grid % xc(c) + grid % xn(grid % cells_n(n,c))  &
                   / (1.0*grid % cells_n_nodes(c))
      grid % yc(c) = grid % yc(c) + grid % yn(grid % cells_n(n,c))  &
                   / (1.0*grid % cells_n_nodes(c))
      grid % zc(c) = grid % zc(c) + grid % zn(grid % cells_n(n,c))  &
                   / (1.0*grid % cells_n_nodes(c))
    end do
  end do

  write(*,*) '# Cell centers calculated !'

  !-----------------------------------------------------!
  !   Calculate:                                        ! 
  !      components of cell sides, cell side centers.   !
  !-----------------------------------------------------!
  !   => depends on: x_node,y_node,z_node               !
  !   <= gives:      Sx,Sy,Sz,xsp,yzp,zsp               !
  !-----------------------------------------------------!
  do s = 1, grid % n_faces
    do n = 1, grid % faces_n_nodes(s)    ! for quadrilateral an triangular faces
      xt(n)=grid % xn(grid % faces_n(n,s))
      yt(n)=grid % yn(grid % faces_n(n,s))
      zt(n)=grid % zn(grid % faces_n(n,s))
    end do                       

    ! Cell side components
    if( grid % faces_n_nodes(s)  ==  4 ) then
      grid % sx(s)= 0.5 * ( (yt(2)-yt(1))*(zt(2)+zt(1))   &
                           +(yt(3)-yt(2))*(zt(2)+zt(3))   &
                           +(yt(4)-yt(3))*(zt(3)+zt(4))   &
                           +(yt(1)-yt(4))*(zt(4)+zt(1)) )
      grid % sy(s)= 0.5 * ( (zt(2)-zt(1))*(xt(2)+xt(1))   &
                           +(zt(3)-zt(2))*(xt(2)+xt(3))   &
                           +(zt(4)-zt(3))*(xt(3)+xt(4))   &
                           +(zt(1)-zt(4))*(xt(4)+xt(1)) )
      grid % sz(s)= 0.5 * ( (xt(2)-xt(1))*(yt(2)+yt(1))   & 
                           +(xt(3)-xt(2))*(yt(2)+yt(3))   &
                           +(xt(4)-xt(3))*(yt(3)+yt(4))   &
                           +(xt(1)-xt(4))*(yt(4)+yt(1)) )
    else if( grid % faces_n_nodes(s)  ==  3 ) then 
      grid % sx(s)= 0.5 * ( (yt(2)-yt(1))*(zt(2)+zt(1))   & 
                           +(yt(3)-yt(2))*(zt(2)+zt(3))   &
                           +(yt(1)-yt(3))*(zt(3)+zt(1)) )
      grid % sy(s)= 0.5 * ( (zt(2)-zt(1))*(xt(2)+xt(1))   &
                           +(zt(3)-zt(2))*(xt(2)+xt(3))   & 
                           +(zt(1)-zt(3))*(xt(3)+xt(1)) )
      grid % sz(s)= 0.5 * ( (xt(2)-xt(1))*(yt(2)+yt(1))   &
                           +(xt(3)-xt(2))*(yt(2)+yt(3))   & 
                           +(xt(1)-xt(3))*(yt(3)+yt(1)) )
    else
      write(*,*) 'calc4: something horrible has happened !'
      stop
    end if

    ! Barycenters
    if(grid % faces_n_nodes(s) == 4) then  
      grid % xf(s) = (xt(1)+xt(2)+xt(3)+xt(4))/4.0
      grid % yf(s) = (yt(1)+yt(2)+yt(3)+yt(4))/4.0
      grid % zf(s) = (zt(1)+zt(2)+zt(3)+zt(4))/4.0
    else if(grid % faces_n_nodes(s) == 3) then  
      grid % xf(s) = (xt(1)+xt(2)+xt(3))/3.0
      grid % yf(s) = (yt(1)+yt(2)+yt(3))/3.0
      grid % zf(s) = (zt(1)+zt(2)+zt(3))/3.0
    end if 

  end do ! through sides

  write(*,*) '# Cell face components calculated !'

  !--------------------------------------!
  !   Calculate boundary cell centers    !
  !--------------------------------------!
  !   => depends on: xc,yc,zc,Sx,Sy,Sz   !
  !   <= gives:      xc,yc,zc for c<0    !   
  !--------------------------------------!
  write(*,*) '#===================================='
  write(*,*) '# Position the boundary cell centres:'
  write(*,*) '#------------------------------------'
  write(*,*) '# Type 1 for barycentric placement'
  write(*,*) '# Type 2 for orthogonal placement'
  write(*,*) '#------------------------------------'
  read(*,*) bou_cen 

  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    SurTot = sqrt(  grid % sx(s)*grid % sx(s)  &
                  + grid % sy(s)*grid % sy(s)  &
                  + grid % sz(s)*grid % sz(s) )

    if(c2  < 0) then
      t = (   grid % sx(s)*(grid % xf(s) - grid % xc(c1))        &
            + grid % sy(s)*(grid % yf(s) - grid % yc(c1))        &
            + grid % sz(s)*(grid % zf(s) - grid % zc(c1)) ) / SurTot
      grid % xc(c2) = grid % xc(c1) + grid % sx(s)*t / SurTot
      grid % yc(c2) = grid % yc(c1) + grid % sy(s)*t / SurTot
      grid % zc(c2) = grid % zc(c1) + grid % sz(s)*t / SurTot
      if(bou_cen == 1) then
        grid % xc(c2) = grid % xf(s)
        grid % yc(c2) = grid % yf(s)
        grid % zc(c2) = grid % zf(s)
      end if
    endif 
  end do ! through sides

  !---------------------------------------------------------------!
  !   Move the centers of co-planar molecules towards the walls   !
  !---------------------------------------------------------------!
  !   => depends on: xc,yc,zc                                     !
  !   <= gives:      xc,yc,zc                                     !
  !   +  uses:       Dx,Dy,Dz                                     !
  !---------------------------------------------------------------!
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    if(c2 > 0) then
      grid % dx(c1) = max( grid % dx(c1), abs( grid % xc(c2) - grid % xc(c1) ) )
      grid % dy(c1) = max( grid % dy(c1), abs( grid % yc(c2) - grid % yc(c1) ) )
      grid % dz(c1) = max( grid % dz(c1), abs( grid % zc(c2) - grid % zc(c1) ) )
      grid % dx(c2) = max( grid % dx(c2), abs( grid % xc(c2) - grid % xc(c1) ) )
      grid % dy(c2) = max( grid % dy(c2), abs( grid % yc(c2) - grid % yc(c1) ) )
      grid % dz(c2) = max( grid % dz(c2), abs( grid % zc(c2) - grid % zc(c1) ) )
    end if 
  end do ! through sides

  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    if(c2 < 0) then
      if( Approx(grid % dx(c1), 0.0, 1.e-6) )  &
        grid % xc(c1) = 0.75*grid % xc(c1) + 0.25*grid % xc(c2) 
      if( Approx(grid % dy(c1), 0.0, 1.e-6) )  &
        grid % yc(c1) = 0.75*grid % yc(c1) + 0.25*grid % yc(c2) 
      if( Approx(grid % dz(c1), 0.0, 1.e-6) )  &
        grid % zc(c1) = 0.75*grid % zc(c1) + 0.25*grid % zc(c2) 
    end if 
  end do ! through sides

  ! Why are the following three lines needed?
  grid % dx = 0.0
  grid % dy = 0.0
  grid % dz = 0.0

  !--------------------------------------------!
  !   Find the sides on the periodic boundary  !
  !--------------------------------------------!
  !   => depends on: xc,yc,zc,Sx,Sy,Sz         !
  !   <= gives:      Dx,Dy,Dz                  !
  !--------------------------------------------!
  allocate(b_coor(grid % n_faces)); b_coor=0.0
  allocate(b_face(grid % n_faces)); b_face=0

  !--------------------------------------------------------!
  !                                                        !
  !   Phase I  ->  find the sides on periodic boundaries   !
  !                                                        !
  !--------------------------------------------------------!
  option = 2

  allocate(face_copy(grid % n_faces)); face_copy=0

  write(*,*) 'Number of boundary conditions: ', grid % n_boundary_conditions

2 n_per = 0 
  write(*,*) '#======================================================'
  write(*,*) '# Enter the periodic-boundary-condition name.'
  write(*,*) '# Type skip if there is none !'
  write(*,*) '#------------------------------------------------------'
  write(*,*) '# (Please note that the periodic boundaries have to be' 
  write(*,*) '#  the last on the list of the boundary conditions.'
  write(*,*) '#  Their BC markers have to be larger than the markers'
  write(*,*) '#  of all the other boundary conditions.)'
  write(*,*) '#------------------------------------------------------'
  call Tokenizer_Mod_Read_Line(5)
  name_per = line % tokens(1)
  call To_Upper_Case(name_per)
  if( name_per == 'SKIP' ) then
    type_per = 0
    goto 1  
  end if
  type_per = -1
  do b=1, grid % n_boundary_conditions
    if( name_per == grid % boundary_conditions(b) % name ) then
      type_per = b
    end if
  end do
  if( type_per == -1 ) then
    write(*,*) '# Critical error: boundary condition ', trim(name_per),  &
               ' can''t be found!'
    write(*,*) '# Exiting! '
    stop
  end if

  if(option == 2) then

    write(*,*) '#========================================================'
    write(*,*) '# Insert the periodic direction (1 -> x, 2 -> y, 3 -> z)'
    write(*,*) '#--------------------------------------------------------'
    read(*,*) dir 
    write(*,*) 
    write(*,*) '#=============================================================='
    write(*,*) '# Enter the angle for the rotation of the coordiante system (in'
    write(*,*) '# degrees) and the axes of rotation (1 -> x, 2 -> y, 3 -> z)'
    write(*,*) '#--------------------------------------------------------------'
    write(*,*) '# (If the periodic direction is not parallel to the Caresian '
    write(*,*) '#  axis (x, y and z), the coordinate system has to be rotated'
    write(*,*) '#  in 2D'                                                     
    write(*,*) '#--------------------------------------------------------------'
    read(*,*) angle, rot_dir 

    angle = angle * PI / 180.0

    if(dir == 1) then
      x_a = 0.0
      y_a = 0.0
      z_a = 0.0       
      x_b = 0.0
      y_b = 1.0
      z_b = 0.0       
      x_c = 0.0
      y_c = 0.0
      z_c = 1.0       
    else if(dir == 2) then
      x_a = 0.0
      y_a = 0.0
      z_a = 0.0       
      x_b = 1.0
      y_b = 0.0
      z_b = 0.0       
      x_c = 0.0
      y_c = 0.0
      z_c = 1.0       
    else if(dir == 3) then
      x_a = 0.0
      y_a = 0.0
      z_a = 0.0       
      x_b = 1.0
      y_b = 0.0
      z_b = 0.0       
      x_c = 0.0
      y_c = 1.0
      z_c = 0.0       
    end if        

    ab_i = x_b - x_a 
    ab_j = y_b - y_a 
    ab_k = z_b - z_a 

    ac_i = x_c - x_a 
    ac_j = y_c - y_a 
    ac_k = z_c - z_a

    p_i =  ab_j*ac_k - ac_j*ab_k 
    p_j = -ab_i*ac_k + ac_i*ab_k 
    p_k =  ab_i*ac_j - ac_i*ab_j

    angle_face = angle_face * PI / 180.0
 
    allocate(phi_face(grid % n_faces)); phi_face=0.0
    allocate(xspr(grid % n_faces)); xspr=0.0
    allocate(yspr(grid % n_faces)); yspr=0.0
    allocate(zspr(grid % n_faces)); zspr=0.0

    do s = 1, grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(BCmark(c2) == type_per) then
          if( Approx(angle, 0.0, 1.e-6) ) then
            xspr(s) = grid % xf(s)  
            yspr(s) = grid % yf(s)  
            zspr(s) = grid % zf(s)  
          else 
            if(rot_dir==3) then
              xspr(s) = grid % xf(s)*cos(angle) + grid % yf(s)*sin(angle) 
              yspr(s) =-grid % xf(s)*sin(angle) + grid % yf(s)*cos(angle)
            else if(rot_dir==2) then
              xspr(s) = grid % xf(s)*cos(angle) + grid % zf(s)*sin(angle) 
              zspr(s) =-grid % xf(s)*sin(angle) + grid % zf(s)*cos(angle)
            else if(rot_dir==1) then
              yspr(s) = grid % yf(s)*cos(angle) + grid % zf(s)*sin(angle) 
              zspr(s) =-grid % yf(s)*sin(angle) + grid % zf(s)*cos(angle)
            end if
          end if
        end if
      end if
    end do
  end if

  xmin = +HUGE
  ymin = +HUGE
  zmin = +HUGE
  xmax = -HUGE
  ymax = -HUGE
  zmax = -HUGE

  b_coor=0.0
  b_face=0

  c = 0

  if(option == 1) then 
    do s=1,grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(BCmark(c2) == type_per) then
          c = c + 1
          if(dir==1) b_coor(c) = grid % xf(s)*1000000.0   &
                               + grid % yf(s)*10000.0     &
                               + grid % zf(s)
          if(dir==2) b_coor(c) = grid % yf(s)*1000000.0   &
                               + grid % xf(s)*10000.0     &
                               + grid % zf(s)
          if(dir==3) b_coor(c) = grid % zf(s)*1000000.0   & 
                               + grid % xf(s)*10000.0     &
                               + grid % yf(s)
          b_face(c) = s
        end if
      end if
    end do
    call Sort_Double_Carry_Int(b_coor,b_face,c,2)
  else if(option == 2) then 
    c_max = 0
    do s=1,grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(BCmark(c2) == type_per) then
          c_max = c_max + 1
        end if 
      end if 
    end do
    Tol = 0.0001 
    
10 continue

    nnn = 0
    hh = 0 
    mm = 0 
    c = 0
  
    per_max = -HUGE
    per_min =  HUGE 

    do s=1,grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(BCmark(c2) == type_per) then
          Det = (  p_i*(grid % xf(s))  &
                 + p_j*(grid % yf(s))  &
                 + p_k*(grid % zf(s)))  &
              / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)
          per_min = min(per_min, Det)          
          per_max = max(per_max, Det)          
        end if
      end if
    end do
    
    per_max = 0.5*(per_max + per_min)

    do s=1,grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(BCmark(c2) == type_per) then
          c = c + 1
          Det = (  p_i*(grid % xf(s))   &
                 + p_j*(grid % yf(s))   &
                 + p_k*(grid % zf(s)))  &
              / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)

          if(dir==1) then
            if((Det) < (per_max)) then
              hh = hh + 1
              b_coor(hh) = hh
              b_face(hh) = s
              do ss=1,grid % n_faces
                cc2 = grid % faces_c(2,ss)
                if(cc2 < 0) then
                  if(BCmark(cc2) == type_per) then 
                    Det = (  p_i * (grid % xf(ss))   &
                           + p_j * (grid % yf(ss))   &
                           + p_k * (grid % zf(ss)))  &
                        / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)
                    if((Det) > (per_max)) then
                      if((abs(grid % zf(ss)  - grid % zf(s))) < Tol .and.   &
                         (abs(yspr(ss) - yspr(s))) < Tol) then
                         mm = hh + c_max/2 
                         b_coor(mm) = mm
                         b_face(mm) = ss
                         nnn = nnn + 1
                      end if 
                    end if 
                  end if
                end if  
              end do
            end if          
          end if

          if(dir==2) then
            if((Det) < (per_max)) then
              hh = hh + 1
              b_coor(hh) = hh
              b_face(hh) = s
              do ss=1,grid % n_faces
                cc2 = grid % faces_c(2,ss)
                if(cc2 < 0) then
                  if(BCmark(cc2) == type_per) then 

                    Det = (  p_i * (grid % xf(ss))  &
                           + p_j * (grid % yf(ss))  &
                           + p_k * (grid % zf(ss))) &
                        / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)

                    if((Det) > (per_max)) then
                      if(abs((grid % zf(ss)  - grid % zf(s))) < Tol .and.  &
                         abs((xspr(ss) - xspr(s))) < Tol) then
                        mm = hh + c_max/2 
                        b_coor(mm) = mm
                        b_face(mm) = ss
                        nnn = nnn + 1
                      end if 
                    end if 

                  end if
                end if  
              end do
            end if          
          end if

          if(dir==3) then
            if((Det) < (per_max)) then
              hh = hh + 1
              b_coor(hh) = hh
              b_face(hh) = s
              do ss=1,grid % n_faces
                cc2 = grid % faces_c(2,ss)
                if(cc2 < 0) then
                  if(BCmark(cc2) == type_per) then
                    Det = (  p_i*(grid % xf(ss))  &
                           + p_j*(grid % yf(ss))  &
                           + p_k*(grid % zf(ss)))  &
                        / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)
                    if((Det) > (per_max)) then
!                     write(*,*) '# Warning!  Potentially a bug in ...'
!                     write(*,*) '# ... Compute_Geometry, line 557'
!                     write(*,*) '# Contact developers, and if you ... '
!                     write(*,*) '# ... are one of them, fix it!'   
                      if(abs((grid % xf(ss) - grid % xf(s))) < Tol .and.  &
                         abs((grid % yf(ss) - grid % yf(s))) < Tol) then
                        mm = hh + c_max/2 
                        b_coor(mm) = mm
                        b_face(mm) = ss
                        nnn = nnn + 1
                      end if 
                    end if 
                  end if
                end if  
              end do
            end if          
          end if

        end if 
      end if 
    end do

    write(*,*)'Iterating search for periodic cells: ',  &
    'Target: ', c_max/2, 'Result: ',nnn, 'Tolerance: ',Tol

    if(nnn == c_max/2) then
      continue
    else
      Tol = Tol*0.5 
      go to 10
    end if

    deallocate(phi_face)
    deallocate(xspr)
    deallocate(yspr)
    deallocate(zspr)

    call Sort_Double_Carry_Int(b_coor,b_face,c,2)
  end if  ! end option

  do s = 1, c/2
    s1 = b_face(s)
    s2 = b_face(s+c/2)
    c11 = grid % faces_c(1,s1)  ! cell 1 for side 1
    c21 = grid % faces_c(2,s1)  ! cell 2 for cell 1
    c12 = grid % faces_c(1,s2)  ! cell 1 for side 2
    c22 = grid % faces_c(2,s2)  ! cell 2 for side 2
    face_copy(s1) = s2   ! just to remember where it was coppied from
    grid % faces_c(2,s1) = c12 
    grid % faces_c(1,s2) = 0    ! c21 
    grid % faces_c(2,s2) = 0    ! c21 
  end do

  n_per = c/2
  write(*,*) '# Phase I: periodic cells: ', n_per
  go to 2

  !----------------------------------------------------!
  !                                                    !
  !   Phase II  ->  similar to the loop in Generator   !
  !                                                    !
  !----------------------------------------------------!
1 continue 
  grid % n_sh = 0
  do s = 1, grid % n_faces

    ! Initialize
    grid % dx(s)=0.0
    grid % dy(s)=0.0
    grid % dz(s)=0.0

    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(c2   >  0) then

      ! Scalar product of the side with line c1-c2 is good criteria
      if( (grid % sx(s) * (grid % xc(c2)-grid % xc(c1) )+                  &
           grid % sy(s) * (grid % yc(c2)-grid % yc(c1) )+                  &
           grid % sz(s) * (grid % zc(c2)-grid % zc(c1) ))  < 0.0 ) then

        grid % n_sh = grid % n_sh + 2

        ! Find the coordinates of ...
        if(grid % faces_n_nodes(s) == 4) then

          ! Coordinates of the shadow face
          xs2=grid % xf(face_copy(s))
          ys2=grid % yf(face_copy(s))
          zs2=grid % zf(face_copy(s))

          ! Add shadow faces
          new_face_1 = grid % n_faces+grid % n_sh-1
          new_face_2 = grid % n_faces+grid % n_sh  
          grid % faces_n_nodes(new_face_1) = 4
          grid % faces_c(1, new_face_1) = c1
          grid % faces_c(2, new_face_1) = -grid % n_bnd_cells-1
          grid % faces_n(1, new_face_1) = grid % faces_n(1,s)
          grid % faces_n(2, new_face_1) = grid % faces_n(2,s)
          grid % faces_n(3, new_face_1) = grid % faces_n(3,s)
          grid % faces_n(4, new_face_1) = grid % faces_n(4,s)
          grid % sx(new_face_1) = grid % sx(s)
          grid % sy(new_face_1) = grid % sy(s)
          grid % sz(new_face_1) = grid % sz(s)
          grid % xf(new_face_1) = grid % xf(s)
          grid % yf(new_face_1) = grid % yf(s)
          grid % zf(new_face_1) = grid % zf(s)
          grid % faces_n_nodes(new_face_2) = 4
          grid % faces_c(1, new_face_2) = c2
          grid % faces_c(2, new_face_2) = -grid % n_bnd_cells-1
          grid % faces_n(1, new_face_2) = grid % faces_n(1,face_copy(s))
          grid % faces_n(2, new_face_2) = grid % faces_n(2,face_copy(s))
          grid % faces_n(3, new_face_2) = grid % faces_n(3,face_copy(s))
          grid % faces_n(4, new_face_2) = grid % faces_n(4,face_copy(s))
          grid % sx(new_face_2) = grid % sx(s)
          grid % sy(new_face_2) = grid % sy(s)
          grid % sz(new_face_2) = grid % sz(s)
          grid % xf(new_face_2) = xs2
          grid % yf(new_face_2) = ys2
          grid % zf(new_face_2) = zs2
        else if(grid % faces_n_nodes(s) == 3) then

          ! Coordinates of the shadow face
          xs2=grid % xf(face_copy(s))
          ys2=grid % yf(face_copy(s))
          zs2=grid % zf(face_copy(s))
 
          ! Add shadow faces
          new_face_1 = grid % n_faces+grid % n_sh-1
          new_face_2 = grid % n_faces+grid % n_sh  
          grid % faces_n_nodes(new_face_1) = 3
          grid % faces_c(1, new_face_1) = c1
          grid % faces_c(2, new_face_1) = -grid % n_bnd_cells-1
          grid % faces_n(1, new_face_1) = grid % faces_n(1,s)
          grid % faces_n(2, new_face_1) = grid % faces_n(2,s)
          grid % faces_n(3, new_face_1) = grid % faces_n(3,s)
          grid % sx(new_face_1) = grid % sx(s)
          grid % sy(new_face_1) = grid % sy(s)
          grid % sz(new_face_1) = grid % sz(s)
          grid % xf(new_face_1) = grid % xf(s)
          grid % yf(new_face_1) = grid % yf(s)
          grid % zf(new_face_1) = grid % zf(s)
          grid % faces_n_nodes(new_face_2) = 3
          grid % faces_c(1, new_face_2) = c2
          grid % faces_c(2, new_face_2) = -grid % n_bnd_cells-1
          grid % faces_n(1, new_face_2) = grid % faces_n(1,face_copy(s)) 
          grid % faces_n(2, new_face_2) = grid % faces_n(2,face_copy(s))
          grid % faces_n(3, new_face_2) = grid % faces_n(3,face_copy(s))
          grid % sx(new_face_2) = grid % sx(s)
          grid % sy(new_face_2) = grid % sy(s)
          grid % sz(new_face_2) = grid % sz(s)
          grid % xf(new_face_2) = xs2
          grid % yf(new_face_2) = ys2
          grid % zf(new_face_2) = zs2
        end if

        grid % dx(s) = grid % xf(s) - xs2  !
        grid % dy(s) = grid % yf(s) - ys2  ! later: xc2 = xc2 + Dx  
        grid % dz(s) = grid % zf(s) - zs2  !

      endif !  S*(c2-c1) < 0.0
    end if  !  c2 > 0
  end do    !  sides
  write(*,*) '# Phase II: number of shadow faces: ', grid % n_sh

  deallocate(face_copy)

  !-------------------------------------------------------!
  !                                                       !
  !   Phase III  ->  find the new numbers of cell faces   !
  !                                                       !
  !-------------------------------------------------------!
  number_sides = 0
  do s = 1, grid % n_faces+grid % n_sh
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(c1 > 0) then
      number_sides = number_sides  + 1
      NewS(s) = number_sides 
    else
      NewS(s) = -1
    end if
  end do
  write(*,'(A22,I9,Z9)') ' # Old number of sides: ', &
                          grid % n_faces, grid % n_faces
  write(*,'(A22,I9,Z9)') ' # New number of sides: ', &
                          number_sides-grid % n_sh,number_sides-grid % n_sh
  
  !--------------------------------------!
  !                                      !
  !   Phase IV  ->  compress the sides   !
  !                                      !
  !--------------------------------------!
  do s = 1, grid % n_faces+grid % n_sh
    if(NewS(s) > 0) then
      grid % faces_c(1,NewS(s)) = grid % faces_c(1,s) 
      grid % faces_c(2,NewS(s)) = grid % faces_c(2,s)
      grid % faces_n_nodes(NewS(s)) = grid % faces_n_nodes(s)
      grid % faces_n(1,NewS(s)) = grid % faces_n(1,s)
      grid % faces_n(2,NewS(s)) = grid % faces_n(2,s)
      grid % faces_n(3,NewS(s)) = grid % faces_n(3,s)
      grid % faces_n(4,NewS(s)) = grid % faces_n(4,s)
      grid % xf(NewS(s)) = grid % xf(s)
      grid % yf(NewS(s)) = grid % yf(s)
      grid % zf(NewS(s)) = grid % zf(s)
      grid % sx(NewS(s)) = grid % sx(s)
      grid % sy(NewS(s)) = grid % sy(s)
      grid % sz(NewS(s)) = grid % sz(s)
      grid % dx(NewS(s)) = grid % dx(s)
      grid % dy(NewS(s)) = grid % dy(s)
      grid % dz(NewS(s)) = grid % dz(s)
    end if
  end do 
  grid % n_faces = number_sides-grid % n_sh

  !-----------------------------------!
  !   Check the periodic boundaries   !
  !-----------------------------------!
  max_dis = 0.0 
  do s = 1, grid % n_faces-grid % n_sh
    max_dis = max(max_dis, (  grid % dx(s)*grid % dx(s)  &
                            + grid % dy(s)*grid % dy(s)  &
                            + grid % dz(s)*grid % dz(s) ) )
  end do
  write(*,*) '# Maximal distance of periodic boundary is:', sqrt(max_dis)

  !----------------------------------!
  !   Calculate the cell volumes     !
  !----------------------------------!
  !   => depends on: xc,yc,zc,       !
  !                  Dx,Dy,Dz,       !
  !                  xsp, ysp, zsp   !
  !   <= gives:      volume          !
  !----------------------------------!
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)   

    grid % vol(c1) = grid % vol(c1)               &
                   + grid % xf(s) * grid % sx(s)  &
                   + grid % yf(s) * grid % sy(s)  &
                   + grid % zf(s) * grid % sz(s)

    if(c2 > 0) then
      grid % vol(c2) = grid % vol(c2)                                &
                     - (grid % xf(s) - grid % dx(s)) * grid % sx(s)  &
                     - (grid % yf(s) - grid % dy(s)) * grid % sy(s)  &
                     - (grid % zf(s) - grid % dz(s)) * grid % sz(s)
    end if
  end do
  grid % vol = grid % vol * ONE_THIRD
  c1 = 0
  min_vol =  HUGE
  max_vol = -HUGE
  tot_vol = 0.0
  do c = 1, grid % n_cells
    tot_vol = tot_vol + grid % vol(c)
    min_vol = min(min_vol, grid % vol(c))
    max_vol = max(max_vol, grid % vol(c))
  end do
  write(*,*) '# Minimal cell volume is: ', min_vol
  write(*,*) '# Maximal cell volume is: ', max_vol
  write(*,*) '# Total domain volume is: ', tot_vol
  write(*,*) '# Cell volumes calculated !'

  if(min_vol < 0.0) then
    write(*,*) '# Negative volume occured! Slower, algoritham should be run !'
    write(*,*) '# Execution will halt now! '
    stop
  end if 
 
  deallocate(b_coor)
  deallocate(b_face)

  !------------------------------------------!
  !     Calculate delta                      !
  !------------------------------------------!
  !     => depends on: x_node,y_node,z_node  !
  !     <= gives:      delta                 !
  !------------------------------------------!
  allocate(delta(-grid % n_bnd_cells:grid % n_cells));  delta=0.0

  do c = 1, grid % n_cells
    delta(c)=0.0
    xmin = +HUGE
    ymin = +HUGE
    zmin = +HUGE
    xmax = -HUGE
    ymax = -HUGE
    zmax = -HUGE
    do n = 1, grid % cells_n_nodes(c)
      xmin = min(xmin, grid % xn(grid % cells_n(n,c)))
      ymin = min(ymin, grid % yn(grid % cells_n(n,c)))
      zmin = min(zmin, grid % zn(grid % cells_n(n,c)))
      xmax = max(xmax, grid % xn(grid % cells_n(n,c)))
      ymax = max(ymax, grid % yn(grid % cells_n(n,c)))
      zmax = max(zmax, grid % zn(grid % cells_n(n,c)))
    end do
    delta(c) = xmax-xmin
    delta(c) = max(delta(c), (ymax-ymin))
    delta(c) = max(delta(c), (zmax-zmin))
  end do

  !------------------------------------------------------------------!
  !   Calculate distance from the cell center to the nearest wall.   !
  !------------------------------------------------------------------!
  !     => depends on: xc,yc,zc inside and on the boundary.          !
  !     <= gives:      WallDs i                                      !
  !------------------------------------------------------------------!
  allocate(WallDs(-grid % n_bnd_cells:grid % n_cells)); WallDs = HUGE

  write(*,*) '#================================================================'
  write(*,*) '# Type the total number of wall boundary conditions:'
  write(*,*) '#----------------------------------------------------------------'
  write(*,*) '# (Please note that the walls have to be the first on the list)'
  write(*,*) '# of the boundary conditions. Their BC markers have to be smaller'
  write(*,*) '# than the markers of the other boundary conditions.)'
  write(*,*) '#----------------------------------------------------------------'
  read(*,*) wall_mark
 
  if(wall_mark == 0) then
    WallDs = 1.0
    write(*,*) '# Distance to the wall set to 1.0 everywhere !'
  else
    do c1 = 1, grid % n_cells
      if(mod(c1,10000) == 0) then
        write(*,'(a2, f5.0, a14)') ' #', (100.*c1/(1.*grid % n_cells)),  &
                                   ' % complete...'
      endif
      do c2=-1,-grid % n_bnd_cells,-1
        if(BCmark(c2) <= wall_mark) then
          WallDs(c1)=min(WallDs(c1),                                      &
          Distance_Squared(grid % xc(c1), grid % yc(c1), grid % zc(c1),   &
                           grid % xc(c2), grid % yc(c2), grid % zc(c2)))
        end if
      end do
    end do

    WallDs = sqrt(WallDs)

    write(*,*) '# Distance to the wall calculated !'
  end if

  !------------------------------------------------------------!
  !   Calculate the interpolation factors for the cell sides   !
  !------------------------------------------------------------!
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    ! First cell
    xc1  = grid % xc(c1)
    yc1  = grid % yc(c1)
    zc1  = grid % zc(c1)
    dsc1 = Distance(xc1, yc1, zc1,   &
                    grid % xf(s), grid % yf(s), grid % zf(s))

    ! Second cell (pls. check if xsi=xc on the boundary)
    xc2  = grid % xc(c2) + grid % dx(s)
    yc2  = grid % yc(c2) + grid % dy(s)
    zc2  = grid % zc(c2) + grid % dz(s)
    dsc2 = Distance(xc2, yc2, zc2,   &
                    grid % xf(s), grid % yf(s), grid % zf(s))

    ! Interpolation factor
    grid % f(s) = dsc2 / (dsc1 + dsc2)
  end do 

  write(*,*) '# Interpolation factors calculated !'

  return

  write(*,*) '# Horror ! Negative volume between cells ', c1, ' and ', c2
  stop

  end subroutine
