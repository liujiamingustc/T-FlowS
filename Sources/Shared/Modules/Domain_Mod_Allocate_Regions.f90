!==============================================================================!
  subroutine Domain_Mod_Allocate_Regions(dom, n)
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Domain_Type) :: dom
  integer           :: n
!==============================================================================!

  dom % n_regions = n
  allocate(dom % regions(n))

  end subroutine Domain_Mod_Allocate_Regions
