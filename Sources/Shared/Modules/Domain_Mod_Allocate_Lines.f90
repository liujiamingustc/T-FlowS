!==============================================================================!
  subroutine Domain_Mod_Allocate_Lines(dom, n)
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Domain_Type) :: dom
  integer           :: n
!==============================================================================!

  dom % n_lines = n
  allocate(dom % lines(n))

  end subroutine Domain_Mod_Allocate_Lines
