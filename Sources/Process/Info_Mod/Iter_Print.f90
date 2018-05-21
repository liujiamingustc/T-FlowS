!==============================================================================!
  subroutine Info_Mod_Iter_Print()
!------------------------------------------------------------------------------!
!   Prints information about inner iteration on the screen.                    !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use Comm_Mod, only: this_proc    
!------------------------------------------------------------------------------!
  implicit none
!-----------------------------------[Locals]-----------------------------------!
  integer               :: i
  character(len=L_LINE) :: tmp
!==============================================================================!

  if (this_proc < 2) then

    print '(a87)', iter_info % line_lead  

    ! Print only lines which have colon in the first column :-)
    print '(a87)', iter_info % lines(1)

    ! First print normal lines
    do i = 2, 4
      tmp = iter_info % lines(i)
      if( tmp(7:7) == ':') print '(a87)', iter_info % lines(i)
    end do

    ! Then print user lines
    do i = 1, iter_info % n_user_lines
      tmp = iter_info % lines_user(i)
      if( tmp(7:7) == ':') print '(a87)', iter_info % lines_user(i)
    end do

    print '(a87)', iter_info % line_trail  
    print '(a87)', ' '

  end if
                 
  end subroutine
