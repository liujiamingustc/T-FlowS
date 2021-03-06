!==============================================================================!
  subroutine Save_Shadows(grid, sub, NCsub)
!------------------------------------------------------------------------------!
!   Writes .shadow file.                                                       !
!----------------------------------[Modules]-----------------------------------!
  use gen_mod
  use Grid_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
  integer         :: sub, NCsub
!-----------------------------------[Locals]-----------------------------------!
  integer           :: s
  character(len=80) :: name_out
!==============================================================================!

  !------------------------!
  !                        !
  !   Create shadow file   !
  !                        !
  !------------------------!
  if(sub /= 0) return

  call Name_File(sub, name_out, '.shadow.gmv', len_trim('.shadow.gmv'))
  open(9, file=name_out)
  write(6, *) '# Now creating the file:', trim(name_out)

  do s = grid % n_faces + 1, grid % n_faces + grid % n_sh
    write(9,*) grid % faces_n_nodes(s) 
    if(grid % faces_n_nodes(s)==3) then
      write(9,*) grid % faces_n(1,s),  &
                 grid % faces_n(2,s),  &
                 grid % faces_n(3,s),  &
                 grid % faces_c(1,s), grid % faces_c(2,s) 
    else if(grid % faces_n_nodes(s)==4) then
      write(9,*) grid % faces_n(1,s),  &
                 grid % faces_n(2,s),  &
                 grid % faces_n(3,s),  &
                 grid % faces_n(4,s),  &
                 grid % faces_c(1,s), grid % faces_c(2,s) 
    end if
  end do  

  close(9)

  end subroutine
