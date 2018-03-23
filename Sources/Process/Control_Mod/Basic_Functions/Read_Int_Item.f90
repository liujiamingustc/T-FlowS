!==============================================================================!
  subroutine Control_Mod_Read_Int_Item(keyword, def, val, verbose)
!------------------------------------------------------------------------------!
!   Working horse function to read integer value (argument "val") behind a     !
!   keyword (argument "keyword") in control file.  If not found, a default     !
!   vaue specified in argument "def" is used.
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  character(len=*)  :: keyword
  integer           :: def      ! default value
  integer           :: val      ! spefified value, if found
  logical, optional :: verbose
!-----------------------------------[Locals]-----------------------------------!
  logical :: reached_end
!==============================================================================!

  rewind(CONTROL_FILE_UNIT)

  ! Set default value
  val = def

  ! Browse through command file to see if user specificed it
  do
    call Tokenizer_Mod_Read_Line(CONTROL_FILE_UNIT, reached_end)
    if(reached_end) goto 1
    if(line % tokens(1) == trim(keyword)) then
      read(line % tokens(2), *) val
      return
    end if
  end do

1 if(present(verbose)) then
    if(verbose) then
      print '(a,a,a)', ' # Could not find the keyword: ', keyword, '.'
      print '(a,i9)',  ' # Using the default value of: ', def
    end if
  end if

  end subroutine