!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
!                                                                      !
!                                     Bojan Niceno                     !
!                                     Delft University of Technology   !
!                                     Section Heat Transfer            !
!                                     niceno@wt.tn.tudelft.nl          !
!                                                                      !
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
!======================================================================!
  PROGRAM Divisor
!----------------------------------------------------------------------!
!   Divides the domain in equaly balanced subdomains.                  !
!----------------------------------------------------------------------!
!------------------------------[Modules]-------------------------------!
  use all_mod
  use gen_mod 
  use div_mod
  use par_mod
!----------------------------------------------------------------------!
  implicit none
!-------------------------------[Locals]-------------------------------!
  integer          :: Nsubto              ! total number of subdomains
  integer          :: Ndiv                ! total number of divisions
  integer          :: chunks(128)
  integer          :: i, j
  character        :: answer*8
  real             :: start, finish
!======================================================================!
  call cpu_time(start)
!---- Test the precision
  open(90,FORM='UNFORMATTED',FILE='Divisor.real');
  write(90) 3.1451592
  close(90)
               
  call logo

!---- load the finite volume grid
  call DivLoa
  call GeoLoa
  call BCelLoa

  call IniDiv 

  write(*,*) 'Sorting the cells'
  do i=1,NC
    ix(i) = i
    criter(i) = xc(i) + 0.01 * yc(i) + 0.0001 * zc(i)
  end do
  call RISort(criter(1),ix(1),NC,2)
  do i=1,NC
    iy(i) = i
    criter(i) = yc(i) + 0.01 * zc(i) + 0.0001 * xc(i)
  end do
  call RISort(criter(1),iy(1),NC,2)
  do i=1,NC
    iz(i) = i
    criter(i) = zc(i) + 0.01 * xc(i) + 0.0001 * yc(i)
  end do
  call RISort(criter(1),iz(1),NC,2)
  write(*,*) 'Finished sorting'

  call GeoLoa

  write(*,*) 'Number of subdomains:'
  read(*,*)  Nsubto
  Npro = Nsubto      ! Needed for EpsPar

  write(*,*) 'Algorythm for decomposition:'
  write(*,*) 'COO -> Coordinate multisection' 
  write(*,*) 'INE -> Inertial multisection' 
  read(*,*) answer
  call ToUppr(answer)
  if(answer == 'COO') then
    ALGOR = COORDINATE
  else if(answer == 'INE') then
    ALGOR = INERTIAL
  else
    write(*,*) 'Error in input. Exiting!' 
    stop
  end if

  Nsub=1
  subNC(Nsub) = NC

!-------------------------------------!
!     Find the number of divisions    !
!-------------------------------------!
  call Factor(Ndiv, Nsubto, chunks)  ! ovu funkciju provjeri
  write(*,*) 'Number of divisions:', Ndiv

!----------------------------------! 
!     Through all the divisions    !
!----------------------------------!
  do i = 1, Ndiv

    do j=1,Nsub
      write(*,*) 'Dividing', j, ' into', chunks(i), ' chunks'
      call Split(j, chunks(i))
    end do

  end do     

  do j=1,Nsub
    write(*,*) 'Processor:', j, ' cells:', subNC(j)
  end do

  call Number 

  call ComSav
  call cpu_time(finish)
  print '("Time = ",f14.3," seconds.")',finish-start

  end PROGRAM Divisor
