!==============================================================================!
  subroutine Save_Cgns_Results(grid, name_save)
!------------------------------------------------------------------------------!
!   Adds fields to existing grid cgns file.                                    !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use Name_Mod, only: problem_name
  use Const_Mod
  use Flow_Mod
  use rans_mod
  use Comm_Mod, only: this_proc
  use Tokenizer_Mod
  use Grid_Mod
  use Cgns_Mod
  use Work_Mod, only: v2_calc => r_cell_01,  &
                      uu_mean => r_cell_02,  &
                      vv_mean => r_cell_03,  &
                      ww_mean => r_cell_04,  &
                      uv_mean => r_cell_05,  &
                      uw_mean => r_cell_06,  &
                      vw_mean => r_cell_07,  &
                      tt_mean => r_cell_08,  &
                      ut_mean => r_cell_09,  &
                      vt_mean => r_cell_10,  &
                      wt_mean => r_cell_11
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type)  :: grid
  character(len=*) :: name_save
!-----------------------------------[Locals]-----------------------------------!
  character(len=80) :: store_name, name_out
  integer           :: base
  integer           :: block
  integer           :: solution
  integer           :: field
  integer           :: c
!==============================================================================!

  ! Store the name
  store_name = problem_name

  problem_name = name_save

  call Name_File(0, name_out, ".cgns")

  if (this_proc .lt. 2) print *, "# subroutine Save_Cgns_Results"

  !-------------------------------------------!
  !   Write a mesh (if not already written)   !
  !-------------------------------------------!
  
  call Save_Cgns_Cells(grid, this_proc)

  !--------------------------!
  !   Open file for modify   !
  !--------------------------!
  file_mode = CG_MODE_MODIFY
  call Cgns_Mod_Open_File(name_out, file_mode)


  call Cgns_Mod_Initialize_Counters

  ! Count number of 3d cell type elements
  do c = 1, grid % n_cells
    if(grid % cells_n_nodes(c) == 8) cnt_hex = cnt_hex + 1
    if(grid % cells_n_nodes(c) == 6) cnt_wed = cnt_wed + 1
    if(grid % cells_n_nodes(c) == 5) cnt_pyr = cnt_pyr + 1
    if(grid % cells_n_nodes(c) == 4) cnt_tet = cnt_tet + 1
  end do

  !-----------------!
  !                 !
  !   Bases block   !
  !                 !
  !-----------------!
  n_bases = 1
  allocate(cgns_base(n_bases))

  base = 1
  cgns_base(base) % name = "Base 1"
  cgns_base(base) % cell_dim = 3
  cgns_base(base) % phys_dim = 3

  !-----------------!
  !                 !
  !   Zones block   !
  !                 !
  !-----------------!

  cgns_base(base) % n_blocks = 1
  allocate(cgns_base(base) % block(cgns_base(base) % n_blocks))

  block = 1
  cgns_base(base) % block(block) % name = "Zone 1"
  cgns_base(base) % block(block) % mesh_info(1) = grid % n_nodes
  cgns_base(base) % block(block) % mesh_info(2) = grid % n_cells
  cgns_base(base) % block(block) % mesh_info(3) = 0

  !--------------------!
  !                    !
  !   Solution block   !
  !                    !
  !--------------------!

  cgns_base(base) % block(block) % n_solutions = 1

  allocate(cgns_base(base) % block(block) % solution( &
    cgns_base(base) % block(block) % n_solutions))
  solution = 1

  cgns_base(base) % block(block) % solution(solution) % name = "FlowSolution"
  cgns_base(base) % block(block) % solution(solution) % sol_type = CellCenter

  call Cgns_Mod_Write_Solution_Info(base, block, solution)

  !-----------------!
  !                 !
  !   Field block   !
  !                 !
  !-----------------!

  !---------------------------------------------!
  !   Copied code below from Save_Vtu_Results   !
  !---------------------------------------------!

  !--------------!
  !   Velocity   !
  !--------------!
  call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                            u % n(1),"VelocityX")
  call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                            v % n(1),"VelocityY")
  call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                            w % n(1),"VelocityZ")
  !--------------!
  !   Pressure   !
  !--------------!
  call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                            p % n(1),"Pressure")
  !-----------------!
  !   Temperature   !
  !-----------------!
  if(heat_transfer == YES) then
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              t % n(1),"Temperature")
  end if
  !--------------------------!
  !   Turbulent quantities   !
  !--------------------------!

  ! Kin and Eps
  if(turbulence_model == K_EPS                 .or.  &
     turbulence_model == K_EPS_ZETA_F          .or.  &
     turbulence_model == HYBRID_K_EPS_ZETA_F   .or.  &
     turbulence_model == REYNOLDS_STRESS_MODEL .or.  &
     turbulence_model == HANJALIC_JAKIRLIC  ) then

    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              kin % n(1),"TurbulentEnergyKinetic")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              eps % n(1),"TurbulentDissipation")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              p_kin(1),"TurbulentEnergyKineticProduction")
  end if

  ! zeta, v2 and f22
  if(turbulence_model == K_EPS_ZETA_F   .or.  &
     turbulence_model == HYBRID_K_EPS_ZETA_F) then
    do c = 1, grid % n_cells
      v2_calc(c) = kin % n(c) * zeta % n(c)
    end do
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              v2_calc(1),  "TurbulentQuantityV2")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              zeta % n(1), "TurbulentQuantityZeta")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              f22 % n(1),  "TurbulentQuantityF22")
  end if

  ! Vis and Turbulent Vicosity_t
  if(turbulence_model == DES_SPALART .or.  &
     turbulence_model == SPALART_ALLMARAS) then
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              vis % n(1),"TurbulentViscosity")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              vort(1),"VorticityMagnitude")
  end if
  if(turbulence_model == K_EPS                 .or.  &
     turbulence_model == K_EPS_ZETA_F          .or.  &
     turbulence_model == HYBRID_K_EPS_ZETA_F   .or.  &
     turbulence_model == REYNOLDS_STRESS_MODEL .or.  &
     turbulence_model == HANJALIC_JAKIRLIC     .or.  &
     turbulence_model == LES                   .or.  &
     turbulence_model == DES_SPALART           .or.  &
     turbulence_model == SPALART_ALLMARAS) then
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              vis_t(1:grid % n_cells)/viscosity,"VIS_T_to_VIS")
  end if

  ! Reynolds stress models
  if(turbulence_model == REYNOLDS_STRESS_MODEL .or.  &
     turbulence_model == HANJALIC_JAKIRLIC) then
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              uu % n(1),"ReynoldsStressXX")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              vv % n(1),"ReynoldsStressYY")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              ww % n(1),"ReynoldsStressZZ")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              uv % n(1),"ReynoldsStressXY")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              uw % n(1),"ReynoldsStressXZ")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              vw % n(1),"ReynoldsStressYZ")
  end if

  ! Statistics for large-scale simulations of turbulence
  if(turbulence_model == LES .or.  &
     turbulence_model == DES_SPALART) then
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              u % n(1),"MeanVelocityX")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              v % n(1),"MeanVelocityY")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              w % n(1),"MeanVelocityZ")
    uu_mean = uu % mean(c) - u % mean(c) * u % mean(c)
    vv_mean = vv % mean(c) - v % mean(c) * v % mean(c)
    ww_mean = ww % mean(c) - w % mean(c) * w % mean(c)
    uv_mean = uv % mean(c) - u % mean(c) * v % mean(c)
    uw_mean = uw % mean(c) - u % mean(c) * w % mean(c)
    vw_mean = vw % mean(c) - v % mean(c) * w % mean(c)
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              uu_mean(1),"ReynoldsStressXX")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              vv_mean(1),"ReynoldsStressYY")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              ww_mean(1),"ReynoldsStressZZ")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              uv_mean(1),"ReynoldsStressXY")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              uw_mean(1),"ReynoldsStressXZ")
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              vw_mean(1),"ReynoldsStressYZ")
    if(heat_transfer == YES) then
      call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                                t % mean(1), "MeanTemperature")
      tt_mean = tt % mean(c) - t % mean(c) * t % mean(c)
      ut_mean = ut % mean(c) - u % mean(c) * t % mean(c)
      vt_mean = vt % mean(c) - v % mean(c) * t % mean(c)
      wt_mean = wt % mean(c) - w % mean(c) * t % mean(c)
      call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                                tt_mean(1),"TemperatureFluctuations")
      call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                                ut_mean(1),"TurbulentHeatFluxX")
      call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                                vt_mean(1),"TurbulentHeatFluxY")
      call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                                wt_mean(1),"TurbulentHeatFluxZ")
    end if
  end if

  ! Save y+ for all turbulence models
  if(turbulence_model .ne. NONE) then
    call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                              y_plus(1),"TurbulentQuantityYplus")
  end if

  ! Wall distance and delta
  call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                            grid % wall_dist(1),"WallDistance")
  call Cgns_Mod_Write_Field(base, block, solution, field, grid, &
                            grid % delta(1),"CellDelta")

  !----------------------------!
  !   Add info on dimensions   !
  !----------------------------!

  call Write_Dimensions_Info(base, block)

  !----------------------------------!
  !   Add additional info you want   !
  !----------------------------------!
  
!      call cg_goto_f(index_file,index_base,ier,"end")
!      text1="Supersonic vehicle with landing gear"
!      text2="M=4.6, Re=6 million"
!      textstring=text1//char(10)//text2
!      call cg_descriptor_write_f("Information",textstring,ier)

  ! Close DB
  call Cgns_Mod_Close_File

  if (this_proc .lt. 2) &
    print *, "Successfully added fields to ", trim(name_out)

  deallocate(cgns_base)

  ! Restore the name
  problem_name = store_name

  end subroutine
