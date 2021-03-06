!==============================================================================!
  subroutine Domain_Mod_Allocate_Blocks(dom, n)
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Domain_Type) :: dom
  integer           :: n
!==============================================================================!

  dom % n_blocks = n
  allocate(dom % blocks(n))

  end subroutine
