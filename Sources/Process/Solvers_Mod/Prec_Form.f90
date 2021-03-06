!==============================================================================!
  subroutine Prec_Form(A, prec) 
!------------------------------------------------------------------------------!
!   Forms preconditioning matrix "D" from provided matrix "A".                 !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use par_mod
  use Matrix_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Matrix_Type) :: A
  integer           :: prec
!-----------------------------------[Locals]-----------------------------------!
  real     :: sum1
  integer  :: i, j, k, N
!==============================================================================!
                 
  N = A % pnt_grid % n_cells

  !---------------------------------! 
  !   1) diagonal preconditioning   !
  !---------------------------------!
  if(prec == 1) then        
    do i=1,N                     
      D % val(D % dia(i)) = A % val(A % dia(i))           
    end do                      

  !--------------------------------------------! 
  !   2) incomplete cholesky preconditioning   !
  !--------------------------------------------!
  else if(prec == 2) then   
    do i = 1,N
      sum1 = A % val(A % dia(i))       ! take diaginal entry   
      do j = A % row(i), A % dia(i)-1  ! only lower traingular
        k = A % col(j)                    
        sum1 = sum1 - D % val(D % dia(k)) * A % val(j) * A % val(j)  
      end do
      D % val(D % dia(i)) = 1.0 / sum1
    end do

  !---------------------------!
  !   .) no preconditioning   !
  !---------------------------!
  else                          
    do i=1,N
      D % val(D % dia(i)) = 1.0
    end do
  end if 

  end subroutine
