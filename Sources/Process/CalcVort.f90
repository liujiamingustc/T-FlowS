!==============================================================================!
  subroutine CalcVort(grid)
!------------------------------------------------------------------------------!
!  Computes the magnitude of the vorticity                                     !
!------------------------------------------------------------------------------!
!  Vort = sqrt( 2 * Sij * Sij )                                                !
!  Sij = 1/2 ( dUi/dXj - dUj/dXi )                                             !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use all_mod
  use pro_mod
  use les_mod
  use rans_mod
  use Grid_Mod
  use Work_Mod, only: u_x => r_cell_01,  &
                      u_y => r_cell_02,  &
                      u_z => r_cell_03,  &
                      v_x => r_cell_04,  &
                      v_y => r_cell_05,  &
                      v_z => r_cell_06,  &
                      w_x => r_cell_07,  &
                      w_y => r_cell_08,  &
                      w_z => r_cell_09           
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
!-----------------------------------[Locals]-----------------------------------!
  integer :: c
!==============================================================================!

  call Exchange(grid, u % n)
  call Exchange(grid, v % n)
  call Exchange(grid, w % n)

  call GraPhi(grid, u % n, 1, u_x, .TRUE.)  ! du/dx
  call GraPhi(grid, u % n, 2, u_y, .TRUE.)  ! du/dy
  call GraPhi(grid, u % n, 3, u_z, .TRUE.)  ! du/dz

  call GraPhi(grid, v % n, 1, v_x, .TRUE.)  ! dv/dx
  call GraPhi(grid, v % n, 2, v_y, .TRUE.)  ! dv/dy
  call GraPhi(grid, v % n, 3, v_z, .TRUE.)  ! dv/dz

  call GraPhi(grid, w % n, 1, w_x, .TRUE.)  ! dw/dx
  call GraPhi(grid, w % n, 2, w_y, .TRUE.)  ! dw/dy
  call GraPhi(grid, w % n, 3, w_z, .TRUE.)  ! dw/dz

  do c = 1, grid % n_cells
    vort(c) = 2.0 * (0.5 * (w_y(c) - v_z(c)))**2  &
            + 2.0 * (0.5 * (w_x(c) - u_z(c)))**2  &
            + 2.0 * (0.5 * (v_x(c) - u_y(c)))**2

    vort(c) = sqrt(abs(2.0 * vort(c)))
  end do

  end subroutine
