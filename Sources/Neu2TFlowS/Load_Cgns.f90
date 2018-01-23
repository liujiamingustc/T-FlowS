!==============================================================================!
  subroutine Load_Cgns(grid) 
!------------------------------------------------------------------------------!
!   Reads the Fluents (Gambits) neutral file format.                           !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use all_mod 
  use gen_mod 
  use neu_mod 
  use Grid_Mod
  use Tokenizer_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
!------------------------------------------------------------------------------!
  include "cgns_io_f.h"
  include "cgnslib_f.h"
!-----------------------------------[Locals]-----------------------------------!
  character(len=80)       :: name_in
  integer                 :: i, j, n_blocks, n_bnd_sect, dum1, dum2
  integer,allocatable     :: temp(:)
  integer                 :: c, n, dir
  integer                 :: ier, index_file, index_base, index_zone
  integer, dimension(3,3) :: isize
  integer, dimension(3)   :: irmin, irmax
  character(len=80)       :: name_zone
!==============================================================================!

  name_in = problem_name
  name_in(len_trim(problem_name)+1:len_trim(problem_name)+5) = '.cgns'

  ! Open CGNS file
  print *, '# Reading the file: ', trim(name_in)
  call Cg_Open_F(name_in,         &  ! file name
                 CGIO_MODE_READ,  &  ! mode
                 index_file,      &  ! file handle
                 ier)

  ! Assume there is only one zone and one base
  index_base = 1
  index_zone = 1

  ! Read size of the zone (is it number of nodes)?
  call Cg_Zone_Read_F(index_file,      &  ! probably file handle
                      index_base,      &  ! assumed to be 1
                      index_zone,      &  ! assumed to be 1
                      name_zone,       &  ! returns name of the zone
                      isize,           &  ! number of nodes I hope
                      ier)

  print *, name_zone
  print *, 'n_nodes = ', isize(1,1)
  print *, 'n_cells = ', isize(2,1)
  print *, 'n_????? = ', isize(3,1)

  grid % n_nodes     = isize(1,1)
  grid % n_cells     = isize(2,1)
  grid % n_bnd_cells = isize(3,1) ! ???

  ! Allocate memory =--> carefull, there is no checking!
  call Grid_Mod_Allocate_Nodes(grid, grid % n_nodes) 
  call Grid_Mod_Allocate_Cells(grid, grid % n_cells,   grid % n_bnd_cells) 

  irmin(1) = 1
  irmin(2) = 1
  irmin(3) = 1

  irmax(1) = isize(1,1)
  irmax(2) = isize(2,1)
  irmax(3) = isize(3,1)

  ! Read x coordinade
  call Cg_Coord_Read_F(index_file,     &  ! file handle
                       index_base,     &  ! assumed to be 1
                       index_zone,     &  ! assumed to be 1
                       'CoordinateX',  &  ! take "x" coordinate
                       RealDouble,     &  ! data type
                       irmin, irmax,   &  ! range?
                       grid % xn,      &  ! where to store 
                       ier)
  call Cg_Coord_Read_F(index_file,     &  ! file handle
                       index_base,     &  ! assumed to be 1
                       index_zone,     &  ! assumed to be 1
                       'CoordinateY',  &  ! take "x" coordinate
                       RealDouble,     &  ! data type
                       irmin, irmax,   &  ! range?
                       grid % yn,      &  ! where to store 
                       ier)
  call Cg_Coord_Read_F(index_file,     &  ! file handle
                       index_base,     &  ! assumed to be 1
                       index_zone,     &  ! assumed to be 1
                       'CoordinateZ',  &  ! take "x" coordinate
                       RealDouble,     &  ! data type
                       irmin, irmax,   &  ! range?
                       grid % zn,      &  ! where to store 
                       ier)
  print *, irmin, irmax

  do n = 1, grid % n_nodes
    print *, grid % xn(n), grid % yn(n), grid % zn(n)
  end do

stop





  open(9,file=name_in)
  print *, '# Reading the file: ', trim(name_in)

  ! Skip first 6 lines
  do i = 1, 6
    call Tokenizer_Mod_Read_Line(9)
  end do 

  ! Read the line which contains usefull information  
  call Tokenizer_Mod_Read_Line(9)

  read(line % tokens(1),*) grid % n_nodes  
  read(line % tokens(2),*) grid % n_cells
  read(line % tokens(3),*) n_blocks
  read(line % tokens(4),*) n_bnd_sect

  print *, '# Total number of nodes:  ',            grid % n_nodes
  print *, '# Total number of cells:  ',            grid % n_cells
  print *, '# Total number of blocks: ',            n_blocks
  print *, '# Total number of boundary sections: ', n_bnd_sect

  ! Count the boundary cells
  grid % n_bnd_cells = 0
  do 
    call Tokenizer_Mod_Read_Line(9)
    if( line % tokens(1) == 'BOUNDARY' ) then
      do j = 1, n_bnd_sect
        if(j>1) call Tokenizer_Mod_Read_Line(9) ! BOUNDARY CONDITIONS
        call Tokenizer_Mod_Read_Line(9)
        read(line % tokens(3),*) dum1  
        grid % n_bnd_cells = grid % n_bnd_cells + dum1 
        do i = 1, dum1
          read(9,*) c, dum2, dir
        end do
        call Tokenizer_Mod_Read_Line(9)         ! ENDOFSECTION
      end do
      print *, '# Total number of boundary cells: ', grid % n_bnd_cells
      go to 1
    end if
  end do 

1 rewind(9)

  ! Skip first 7 lines
  do i = 1, 7
    call Tokenizer_Mod_Read_Line(9)
  end do 

  ! Allocate memory =--> carefull, there is no checking!
  call Grid_Mod_Allocate_Nodes(grid, grid % n_nodes) 
  call Grid_Mod_Allocate_Cells(grid, grid % n_cells,   grid % n_bnd_cells) 
  call Grid_Mod_Allocate_Faces(grid, grid % n_cells*5, 0) 

  allocate(material(-grid % n_bnd_cells:grid % n_cells));  material=0 
  allocate(BCtype( grid % n_cells,6));                     BCtype=0
  allocate(grid % bnd_cond % mark(-grid % n_bnd_cells-1:-1))
  grid % bnd_cond % mark=0

  grid % n_copy = grid % n_faces  ! I believe it is n_cells * 5 at this point
  allocate(grid % bnd_cond % copy_c( -grid % n_bnd_cells:-1))
  grid % bnd_cond % copy_c = 0
  allocate(grid % bnd_cond % copy_s(2,grid % n_copy))
  grid % bnd_cond % copy_s=0

  allocate(NewN( grid % n_nodes));                      NewN=0  
  allocate(NewC(-grid % n_bnd_cells-1:grid % n_cells)); NewC=0  
  allocate(NewS( grid % n_cells*5));                    NewS=0  

  allocate(temp(grid % n_cells)); temp=0

  ! Skip one line 
  call Tokenizer_Mod_Read_Line(9)

  !--------------------------------!
  !   Read the nodal coordinates   !
  !--------------------------------!
  call Tokenizer_Mod_Read_Line(9)          ! NODAL COORDINATES
  do i = 1, grid % n_nodes
    call Tokenizer_Mod_Read_Line(9)
    read(line % tokens(2),*) grid % xn(i) 
    read(line % tokens(3),*) grid % yn(i)
    read(line % tokens(4),*) grid % zn(i)
  end do
  call Tokenizer_Mod_Read_Line(9)          ! ENDOFSECTION

  !-----------------------------!
  !   Read nodes of each cell   !
  !-----------------------------!
  call Tokenizer_Mod_Read_Line(9)          ! ELEMENTS/CELLS
  do i = 1, grid % n_cells
    read(9,'(I8,1X,I2,1X,I2,1X,7I8:/(15X,7I8:))') dum1, dum2, &
           grid % cells_n_nodes(i),                           &
          (grid % cells_n(j,i), j = 1,grid % cells_n_nodes(i))
  end do
  call Tokenizer_Mod_Read_Line(9)          ! ENDOFSECTION

  !---------------------------------!
  !   Read block (material?) data   !
  !---------------------------------!
  allocate(grid % materials(n_blocks))
  if(n_blocks .gt. 1) then
    print *, '# Multiple materials from .neu file not been implemented yet!'
    print *, '# Exiting!'
  end if

  grid % n_materials = 1
  grid % materials(1) % name = "AIR"

  do j = 1, n_blocks
    call Tokenizer_Mod_Read_Line(9)        ! ELEMENT GROUP
    call Tokenizer_Mod_Read_Line(9)
    read(line % tokens(4),'(I10)') dum1  
    call Tokenizer_Mod_Read_Line(9)        ! block*
    call Tokenizer_Mod_Read_Line(9)        ! 0
    read(9,'(10I8)') (temp(i), i = 1, dum1)
    do i = 1, dum1
      material(temp(i)) = j
    end do
    call Tokenizer_Mod_Read_Line(9)        ! ENDOFSECTION
  end do

  !-------------------------!
  !   Boundary conditions   !
  !-------------------------!
  grid % n_bnd_cond = n_bnd_sect
  allocate(grid % bnd_cond % name(n_bnd_sect))

  do j = 1, n_bnd_sect
    call Tokenizer_Mod_Read_Line(9)        ! BOUNDARY CONDITIONS
    call Tokenizer_Mod_Read_Line(9)
    call To_Upper_Case(  line % tokens(1)  )
    grid % bnd_cond % name(j) = line % tokens(1)
    read(line % tokens(3),'(I8)') dum1  
    do i = 1, dum1
      read(9,*) c, dum2, dir
      BCtype(c,dir) = j 
    end do
    call Tokenizer_Mod_Read_Line(9)        ! ENDOFSECTION
  end do

  print *, '#==================================================='
  print *, '# Found the following boundary conditions:'
  print *, '#---------------------------------------------------'
  do j = 1, n_bnd_sect
    print *, '# ', grid % bnd_cond % name(j)
  end do
  print *, '#---------------------------------------------------'

  close(9)

  end subroutine