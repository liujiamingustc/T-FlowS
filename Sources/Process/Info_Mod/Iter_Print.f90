!==============================================================================!
  subroutine Info_Mod_Iter_Print()
!------------------------------------------------------------------------------!
!   Prints information about inner iteration on the screen.                    !
!------------------------------------------------------------------------------!
  implicit none
!-----------------------------------[Locals]-----------------------------------!
  integer               :: i
  character(len=L_LINE) :: tmp
!==============================================================================!

  print *, iter_info % line_lead  

  ! Print only lines which have colon in the first column :-)
  print *, iter_info % lines(1)
  do i=2,4
    tmp = iter_info % lines(i)
    if( tmp(6:6) == ':') print *, iter_info % lines(i)
  end do

  print *, iter_info % line_trail  
  print *, ' '
                 
  end subroutine
