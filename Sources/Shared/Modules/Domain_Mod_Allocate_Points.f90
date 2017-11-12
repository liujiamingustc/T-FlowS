!==============================================================================!
  subroutine Domain_Mod_Allocate_Points(dom, n)
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Domain_Type) :: dom
  integer           :: n
!==============================================================================!

  dom % n_points = n
  allocate(dom % points(n))

  end subroutine Domain_Mod_Allocate_Points