!==============================================================================!
  subroutine Cgns_Mod_Close_File_Par
!------------------------------------------------------------------------------!
!   Opens name_in file and return file index                                   !
!------------------------------------------------------------------------------!
  implicit none
!-----------------------------------[Locals]-----------------------------------!
  integer :: error
!==============================================================================!

  ! Close a CGNS file
  call Cgp_Close_F( &
    file_id,       &
    error)

  if (error .ne. 0) then
    print *, "# Failed to close the file: ", trim(file_name)
    call Cgp_Error_Exit_F()
  endif

  end subroutine
