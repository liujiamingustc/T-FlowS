!==============================================================================!
  subroutine Cgns_Mod_Read_Number_Of_Bases_In_File
!------------------------------------------------------------------------------!
!   Gets n_bases from base node                                                !
!------------------------------------------------------------------------------!
  implicit none
!-----------------------------------[Locals]-----------------------------------!
  integer*8 :: ierror
!==============================================================================!

  ! Get number of CGNS bases in file
  call Cg_Nbases_F(file_id,  &
                   n_bases,  &
                   ierror)   

  if (ierror .ne. 0) then
    print *, "# Failed to get bases number"
    call Cg_Error_Exit_F()
  endif

  print *, "# Number of bases: ", n_bases

  allocate(cgns_base(n_bases))

  end subroutine