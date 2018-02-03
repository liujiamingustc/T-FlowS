!==============================================================================!
  subroutine Cgns_Mod_Read_Section_Info(base, block, sect)
!------------------------------------------------------------------------------!
!   Read elements connection info for current sect
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  integer*8 :: base, block, sect
!-----------------------------------[Locals]-----------------------------------!
  integer*8         :: base_id       ! base index number
  integer*8         :: block_id      ! block index number
  integer*8         :: sect_id       ! element section index
  character(len=80) :: sect_name     ! name of the Elements_t node
  integer*8         :: cell_type
  integer*8         :: first_cell    ! index of first element
  integer*8         :: last_cell     ! index of last element
  integer*8         :: n_bnd         ! index of last boundary element
  integer*8         :: iparent_flag
  integer*8         :: error
  integer*8         :: cnt, bc
!==============================================================================!

  ! Set input parameters
  base_id  = base
  block_id = block
  sect_id  = sect

  ! Get info for an element section
  ! Recieves sect_name, first_cell: last_cell, n_bnd and cell_type
  call Cg_Section_Read_F(file_id,       &
                         base_id,       &
                         block_id,      &
                         sect_id,       &
                         sect_name,     &
                         cell_type,     &
                         first_cell,    &
                         last_cell,     &
                         n_bnd,         &
                         iparent_flag,  &
                         error)
  if (error.ne.0) then
    print *, '# Failed to read section ', sect, ' info'
    call Cg_Error_Exit_F()
  endif

  ! Number of cells in this section
  cnt = last_cell - first_cell + 1 ! cells in this sections

  ! Consider boundary conditions defined in this block
  do bc = 1, cgns_base(base) % block(block) % n_bnd_conds
    if(sect_name .eq. cgns_base(base) % block(block) % bnd_cond(bc) % name) then
      print *, '#         ---------------------------------'
      print *, '#         Bnd section name:  ', sect_name
      print *, '#         ---------------------------------'
      print *, '#         Bnd section index: ', sect
      print *, '#         Bnd section type:  ', ElementTypeName(cell_type)
      print *, '#         First cell:        ', first_cell
      print *, '#         Last cell:         ', last_cell

      ! Count boundary cells
      if ( ElementTypeName(cell_type) .eq. 'QUAD_4') cnt_qua = cnt_qua + cnt
      if ( ElementTypeName(cell_type) .eq. 'TRI_3' ) cnt_tri = cnt_tri + cnt
    end if
  end do

  ! Consider only three-dimensional cells / sections
  if ( ( ElementTypeName(cell_type) .eq. 'HEXA_8' ) .or.  &
       ( ElementTypeName(cell_type) .eq. 'PYRA_5' ) .or.  &
       ( ElementTypeName(cell_type) .eq. 'PENTA_6') .or.  &
       ( ElementTypeName(cell_type) .eq. 'TETRA_4') ) then

    print *, '#         ---------------------------------'
    print *, '#         Cell section name: ', sect_name
    print *, '#         ---------------------------------'
    print *, '#         Cell section idx:  ', sect
    print *, '#         Cell section type: ', ElementTypeName(cell_type)
    print *, '#         First cell:        ', first_cell
    print *, '#         Last cell:         ', last_cell

    ! Count cells in sect
    if ( ElementTypeName(cell_type) .eq. 'HEXA_8' ) cnt_hex = cnt_hex + cnt
    if ( ElementTypeName(cell_type) .eq. 'PYRA_5' ) cnt_pyr = cnt_pyr + cnt
    if ( ElementTypeName(cell_type) .eq. 'PENTA_6') cnt_wed = cnt_wed + cnt
    if ( ElementTypeName(cell_type) .eq. 'TETRA_4') cnt_tet = cnt_tet + cnt
  end if

  end subroutine