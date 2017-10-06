!======================================================================!
  subroutine GloMax(PHI) 
!----------------------------------------------------------------------!
!   Estimates global maximum among all processors.                     !
!----------------------------------------------------------------------!
  implicit none
!------------------------------[Include]-------------------------------!
  include 'mpif.h'
!-----------------------------[Parameters]-----------------------------!
  real    :: PHI
!-------------------------------[Locals]-------------------------------!
  real    :: PHInew
  integer :: error
!======================================================================!

!================================================
      call MPI_ALLREDUCE      &               
!-----------------------------------+------------
             (PHI,            & ! send buffer
              PHInew,         & ! recv buffer 
              1,              & ! length     
              MPI_REAL,       & ! datatype  
              MPI_MAX,        & ! operation 
              MPI_COMM_WORLD, &             
              error) 
!================================================

  PHI = PHInew

  end subroutine GloMax