!==============================================================================!
  subroutine Save_Cns_Geo(grid,             &
                          sub,              &  ! subdomain
                          n_cells_sub,      &  ! number of cells in the sub. 
                          n_faces_sub,      &  ! number of faces in the sub.
                          n_bnd_cells_sub,  &  ! number of bnd. cells in sub
                          n_buf_cells_sub,  &  ! number of buffer cells in sub.
                          NCFsub)
!------------------------------------------------------------------------------!
!   Writes: name.cns, name.geo                                                 !
!----------------------------------[Modules]-----------------------------------!
  use all_mod
  use gen_mod
  use div_mod
  use Grid_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
  integer         :: sub, n_cells_sub, n_faces_sub, n_bnd_cells_sub,  &
                     n_buf_cells_sub, NCFsub
!-----------------------------------[Locals]-----------------------------------!
  integer              :: b, c, s, n, c1, c2, count, var, subo 
  character(len=80)    :: name_out
  integer, allocatable :: iwork(:,:)
  real, allocatable    :: work(:)
!==============================================================================!
!   The files name.cns and name.geo should merge into one file in some         !
!   of the future releases.                                                    !
!                                                                              !
!   sub             - subdomain number                                         !
!   n_cells_sub     - number of cells in subdomain                             !
!   n_faces_sub     - number of sides in subdomain, but without sides on buffer!
!   n_bnd_cells_sub - number of physicall boundary cells in subdomain          !
!   n_buf_cells_sub - number of buffer boundary faces in subdomain             !
!------------------------------------------------------------------------------!

  allocate(iwork(-n_buf_cells_sub-grid % n_bnd_cells:grid % n_faces,0:2)); 
  iwork=0
  allocate(work(grid % n_faces));           
  work=0

  !----------------------!
  !                      !
  !   Create .cns file   !
  !                      !
  !----------------------!
  call Name_File( sub, name_out, '.cns', len_trim('.cns') )
  open(9, file=name_out,form='unformatted')
  write(*, *) '# Now creating the file:', trim(name_out)

  !-----------------------------------------------!
  !   Number of cells, boundary cells ans sides   !
  !-----------------------------------------------!
  write(9) n_cells_sub
  write(9) n_bnd_cells_sub+n_buf_cells_sub 
  write(9) n_faces_sub+n_buf_cells_sub-NCFsub
  write(9) grid % n_sh  ! not sure how meaningful this is
  write(9) grid % n_materials
  write(9) grid % n_boundary_conditions

  !---------------! 
  !   Materials   !
  !---------------! 
  do n = 1, grid % n_materials
    write(9) grid % materials(n) % name
  end do

  !-------------------------! 
  !   Boundary conditions   !
  !-------------------------! 
  do n = 1, grid % n_boundary_conditions
    write(9) grid % boundary_conditions(n) % name
  end do

  !-----------! 
  !   Cells   ! 
  !-----------! 
  count=0
  do c = 1, grid % n_cells
    if(NewC(c) /= 0) then
      count=count+1
      iwork(count,1) = material(c)
    end if
  end do 
  write(9) (iwork(c,1), c=1,count)

  ! Physicall cells
  count=0
  do c = -1,-grid % n_bnd_cells, -1
    if(NewC(c) /= 0) then
      count=count+1
      iwork(count,1) = material(c)
    end if
  end do

  ! Buffer boundary cell centers
  do s = 1, n_buf_cells_sub
    count=count+1
    iwork(count,1) = material(BuReIn(s))
  end do
  write(9) (iwork(c,1), c=1,count)
                      
  !-----------! 
  !   Faces   ! 
  !-----------!
  count=0

  ! n_faces_sub physical faces
  do s = 1, grid % n_faces  ! OK, later chooses just sides with NewS
    if( NewS(s)  > 0  .and.  NewS(s) <= n_faces_sub ) then
      count=count+1 
      iwork(count,0) = 0 
      iwork(count,1) = NewC(grid % faces_c(1,s))
      iwork(count,2) = NewC(grid % faces_c(2,s))
    end if
  end do 

  ! n_buf_cells_sub buffer faces (copy faces here, avoid them with BufPos) 
  do s = 1, n_buf_cells_sub
    if(BufPos(s)  < 0) then         ! normal buffer (non-copy) 
      count=count+1 
      iwork(count,0) = BuReIn(s)    ! old cell number
      iwork(count,1) = BuSeIn(s)    ! new cell number
      iwork(count,2) = BufPos(s)    ! position in the buffer
    end if
  end do 

!!write(9) (iwork(s,0), s=1,count) why is it OK to neglect this?
  write(9) (iwork(s,1), s=1,count)
  write(9) (iwork(s,2), s=1,count)

  !--------------! 
  !   Boundary   !
  !--------------! 
  count=0          ! count goes to negative

  ! n_bnd_cells_sub physical boundary cells
  do c = -1,-grid % n_bnd_cells,-1  ! OK, later chooses just cells with NewC
    if(NewC(c) /= 0) then
      count=count-1 
      ! nekad bio i: NewC(c)
      iwork(count,1) = BCmark(c)   
      iwork(count,2) = NewC(CopyC(c)) 
      if(CopyC(c) /= 0) then
        if(proces(CopyC(c)) /= sub) then
          do b=1,n_buf_cells_sub
            if(BuReIn(b) == CopyC(c)) then
              write(*,*) BufPos(b) 
              write(*,*) grid % xc(CopyC(c)),  &
                         grid % yc(CopyC(c)),  &
                         grid % zc(CopyC(c))  
              iwork(count,2)=-BufPos(b) ! - sign, copy buffer
            end if
          end do
        endif
      endif
    end if
  end do 

  ! n_buf_cells_sub buffer cells
  do c = 1, n_buf_cells_sub
    count=count-1 
    ! nekad bio i: -n_bnd_cells_sub-c, 
    iwork(count,1) = BUFFER 
    iwork(count,2) = 0        ! hmm ? unused ? hmm ?
  end do 

  write(9) (iwork(c,1), c=-1,count,-1)
  write(9) (iwork(c,2), c=-1,count,-1)

  !----------!
  !   Copy   !
  !----------!
  count = 0
  do s = 1, grid % n_copy
    count = count + 1
    iwork(count,1) = CopyS(1,s) 
    iwork(count,2) = CopyS(2,s) 
  end do

  write(9) count 
  write(9) (iwork(c,1), c=1,count)
  write(9) (iwork(c,2), c=1,count)

  close(9)

  !----------------------!
  !                      !
  !   Create .geo file   !
  !                      !
  !----------------------!
  call Name_File( sub, name_out, '.geo', len_trim('.geo') )
  open(9, file=name_out, form='unformatted')
  write(*, *) '# Now creating the file:', trim(name_out)

  !---------------------------------!
  !     cell center coordinates     !
  !---------------------------------!
  do var = 1, 3
    count=0
    do c=1,grid % n_cells
      if(NewC(c)  > 0) then
        count=count+1
        if(var == 1) work(count) = grid % xc(c)
        if(var == 2) work(count) = grid % yc(c)
        if(var == 3) work(count) = grid % zc(c)
      end if
    end do 
    write(9) (work(c), c=1,count)
  end do

  !---------------------------!
  !   Boundary cell centers   !
  !---------------------------!

  ! Physicall cells
  do var = 1, 3
    count=0
    do c = -1, -grid % n_bnd_cells, -1
      if(NewC(c) /= 0) then
        count=count+1
        if(var == 1) work(count) = grid % xc(c)
        if(var == 2) work(count) = grid % yc(c)
        if(var == 3) work(count) = grid % zc(c)
      end if
    end do 

    ! Buffer boundary cell centers
    do s = 1, n_buf_cells_sub
      count=count+1
      if(var ==  1) work(count) = grid % xc(BuReIn(s))
      if(var ==  2) work(count) = grid % yc(BuReIn(s))
      if(var ==  3) work(count) = grid % zc(BuReIn(s))
    end do
    write(9) (work(c), c=1,count)
  end do

  !------------------!
  !   Cell volumes   !
  !------------------!
  count=0
  do c = 1, grid % n_cells
    if(NewC(c)  > 0) then
      count=count+1
      work(count) = grid % vol(c)
    end if
  end do
  write(9) (work(c), c=1,count) 

  !---------------!
  !   Cell data   !
  !---------------!
  count=0
  do c = 1, grid % n_cells
    if(NewC(c)  > 0) then
      count=count+1
      work(count) = delta(c)
    end if
  end do
  write(9) (work(c), c=1,count) 

  !-------------------!
  !   Wall distance   !
  !-------------------!
  count=0
  do c = 1, grid % n_cells
    if(NewC(c)  > 0) then
      count=count+1
      work(count) = WallDs(c)
    end if
  end do
  write(9) (work(c), c=1,count) 

  !-----------!
  !   Faces   !
  !-----------!

  ! From 1 to n_faces_sub -> cell faces for which both cells are inside sub
  do var=1,10
  count=0

  do s = 1, grid % n_faces
    if(NewS(s)  > 0 .and. NewS(s) <= n_faces_sub) then
      count=count+1
      if(var ==  1)  work(count) = grid % sx(s)
      if(var ==  2)  work(count) = grid % sy(s)
      if(var ==  3)  work(count) = grid % sz(s)
      if(var ==  4)  work(count) = grid % dx(s)
      if(var ==  5)  work(count) = grid % dy(s)
      if(var ==  6)  work(count) = grid % dz(s)
      if(var ==  7)  work(count) = grid % f(s)
      if(var ==  8)  work(count) = grid % xf(s)
      if(var ==  9)  work(count) = grid % yf(s)
      if(var == 10)  work(count) = grid % zf(s)
    end if 
  end do

  ! From n_faces_sub+1 to n_faces_sub + n_buf_cells_sub (think: are they in right order ?)
  do subo = 1, n_sub
    do s = 1, grid % n_faces
      if(NewS(s)  > n_faces_sub .and. NewS(s) <= n_faces_sub+n_buf_cells_sub) then
        c1 = grid % faces_c(1,s)
        c2 = grid % faces_c(2,s)
        if(c2  > 0) then
          if( (proces(c1) == sub) .and. (proces(c2) == subo) ) then 
            count=count+1
            if(var ==  1)  work(count) = grid % sx(s)
            if(var ==  2)  work(count) = grid % sy(s)
            if(var ==  3)  work(count) = grid % sz(s)
            if(var ==  4)  work(count) = grid % dx(s)
            if(var ==  5)  work(count) = grid % dy(s)
            if(var ==  6)  work(count) = grid % dz(s)
            if(var ==  7)  work(count) = grid % f(s)
            if(var ==  8)  work(count) = grid % xf(s)
            if(var ==  9)  work(count) = grid % yf(s)
            if(var == 10)  work(count) = grid % zf(s)
          end if  
          if( (proces(c2) == sub) .and. (proces(c1) == subo) ) then 
            count=count+1
            if(var ==  1)  work(count) = -grid % sx(s)
            if(var ==  2)  work(count) = -grid % sy(s)
            if(var ==  3)  work(count) = -grid % sz(s)
            if(var ==  4)  work(count) = -grid % dx(s)
            if(var ==  5)  work(count) = -grid % dy(s)
            if(var ==  6)  work(count) = -grid % dz(s)
            if(var ==  7)  work(count) = 1.0 - grid % f(s)
            if(var ==  8)  work(count) = grid % xf(s) - grid % dx(s)
            if(var ==  9)  work(count) = grid % yf(s) - grid % dy(s)
            if(var == 10)  work(count) = grid % zf(s) - grid % dz(s)
          end if  
        end if  ! c2 > 0 
      end if    ! I think this is not really necessary 
    end do
  end do

  write(9) (work(s),s=1,count)

  end do

  close(9)

  deallocate (iwork)
  deallocate (work)

  end subroutine
