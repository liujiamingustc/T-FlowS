!==============================================================================!
  subroutine Comm_Mod_End
!------------------------------------------------------------------------------!
!   Ends parallel execution.                                                   !
!------------------------------------------------------------------------------!
  implicit none
!-----------------------------------[Locals]-----------------------------------!
  integer :: error
!==============================================================================!

  call Mpi_Finalize(error)

  end subroutine