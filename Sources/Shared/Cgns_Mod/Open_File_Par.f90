!==============================================================================!
  subroutine Cgns_Mod_Open_File_Par(mode)
!------------------------------------------------------------------------------!
!   Opens name_in file and return file index                                   !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  integer :: mode
!-----------------------------------[Locals]-----------------------------------!
  integer :: error
!==============================================================================!

  print *, "# Reading the file:", trim(file_name)

  ! Set the parallel IO mode for CGNS
  call Cgp_Pio_Mode_F(CGP_INDEPENDENT, &
                      error)

  ! Open a CGNS file
  call Cgp_Open_F(file_name, &
                  mode,      &
                  file_id,   &
                  error)

  if (error .ne. 0) then
    print *, "# Failed to open the file: ", trim(file_name)
    call Cgp_Error_Exit_F()
  endif

  end subroutine