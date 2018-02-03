!==============================================================================!
  subroutine Cgns_Mod_Read_Number_Of_Element_Sections(base, block)
!------------------------------------------------------------------------------!
!   Gets n_sects from block
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  integer*8 :: base, block
!-----------------------------------[Locals]-----------------------------------!
  integer*8 :: base_id   ! base index number    
  integer*8 :: block_id  ! block index number
  integer*8 :: n_sects   ! number of element sections in a block
  integer*8 :: error
!==============================================================================!

  ! Set input parameters
  base_id  = base
  block_id = block

  ! Get number of element sections
  call Cg_Nsections_F(file_id,   &
                      base_id,   &
                      block_id,  &
                      n_sects,   &
                      error)

  if (error.ne.0) then
    print *, "# Failed to read number of elements"
    call Cg_Error_Exit_F()
  endif

  ! Fetch received parameters
  cgns_base(base) % block(block) % n_sects = n_sects

  print *, "#       Number of sections: ",  &
           cgns_base(base) % block(block) % n_sects

  end subroutine