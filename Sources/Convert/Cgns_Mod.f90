!==============================================================================!
  module Cgns_Mod
!------------------------------------------------------------------------------!
  implicit none
!------------------------------------------------------------------------------!
  include "cgns_io_f.h"
  include "cgnslib_f.h"
!==============================================================================!

  ! file
  integer*8         :: file_id
  character(len=80) :: file_name

  !-------------------------!
  !   Boundary conditions   ! -> it is similar to Bnd_Cond in ../Share :-(
  !-------------------------!
  type Cgns_Bnd_Cond_Type
    character(len=80)      :: name
    integer*8, allocatable :: mark
    integer*8, allocatable :: type
    integer*8, allocatable :: n_nodes
  end type

  !------------!
  !   Blocks   ! -> contains sections and bnd_conds
  !------------!
  type Cgns_Block_Type
    character(len=80)                     :: name
    integer*8                             :: type
    integer*8                             :: mesh_info(3)
    integer*8                             :: n_sects      
    integer*8                             :: n_bnd_conds
    type(Cgns_Bnd_Cond_Type), allocatable :: bnd_cond(:)
    integer*8                             :: n_coords
  end type

  !----------!
  !   Base   ! -> contains blocks
  !----------!
  integer*8 :: n_bases
  type Cgns_Base_Type
    character(len=80)                  :: name
    integer*8                          :: cell_dim
    integer*8                          :: phys_dim
    integer*8                          :: n_blocks
    type(Cgns_Block_Type), allocatable :: block(:)
  end type
  type(Cgns_Base_Type), allocatable :: cgns_base(:)

  ! Some global counters
  integer*8 :: cnt_nodes
  integer*8 :: cnt_cells
  integer*8 :: cnt_bnd_conds
  integer*8 :: cnt_hex
  integer*8 :: cnt_pyr
  integer*8 :: cnt_wed
  integer*8 :: cnt_tet
  integer*8 :: cnt_qua
  integer*8 :: cnt_tri
  integer*8 :: cnt_x
  integer*8 :: cnt_y
  integer*8 :: cnt_z

  ! elements
  integer*8              :: last_hex
  integer*8, allocatable :: cgns_hex_cell_n(:, :)
  integer*8              :: last_pyr
  integer*8, allocatable :: cgns_pyr_cell_n(:, :)
  integer*8              :: last_wed
  integer*8, allocatable :: cgns_wed_cell_n(:, :)
  integer*8              :: last_tet
  integer*8, allocatable :: cgns_tet_cell_n(:, :)
  integer*8              :: last_tri
  integer*8, allocatable :: cgns_tri_cell_n(:, :)
  integer*8              :: last_qua
  integer*8, allocatable :: cgns_qua_cell_n(:, :)

  ! buffers
  real,      allocatable :: buffer_double(:)
  integer*8, allocatable :: buffer_r1(:,:)
  integer*8, allocatable :: buffer_r2(:,:)

  contains

  include 'Cgns_Mod/Open_File.f90'
  include 'Cgns_Mod/Initialize_Counters.f90'
  include 'Cgns_Mod/Read_Base_Info.f90'
  include 'Cgns_Mod/Read_Number_Of_Bases_In_File.f90'
  include 'Cgns_Mod/Read_Number_Of_Blocks_In_Base.f90'
  include 'Cgns_Mod/Read_Block_Info.f90'
  include 'Cgns_Mod/Read_Block_Type.f90'
  include 'Cgns_Mod/Read_Number_Of_Element_Sections.f90'
  include 'Cgns_Mod/Read_Section_Info.f90'
  include 'Cgns_Mod/Read_Number_Of_Bnd_Conds_In_Block.f90'
  include 'Cgns_Mod/Read_Bnd_Conds_Info.f90'
  include 'Cgns_Mod/Read_Number_Of_Coordinates_In_Block.f90'
  include 'Cgns_Mod/Read_Coordinate_Info.f90'
  include 'Cgns_Mod/Read_Coordinate_Array.f90'
! include 'Cgns_Mod/Read_Bnd_Conds_Data.f90'
! include 'Cgns_Mod/Read_Number_Of_Coordinates_In_Block.f90'
! include 'Cgns_Mod/Read_Section_Connections.f90'
! include 'Cgns_Mod/Read_Block_Type.f90'
! include 'Cgns_Mod/Mark_Bound_Cond.f90'

  end module
