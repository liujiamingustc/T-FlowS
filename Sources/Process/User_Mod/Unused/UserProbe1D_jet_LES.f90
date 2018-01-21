!======================================================================!
  subroutine UserProbe1D_jet(grid) 
!----------------------------------------------------------------------!
! Reads the ".1D" file created by the "Generator" and averages the     !
! results in the planes defined by coordinates in it. Then averages    !
! the values of Umean, Vmean, Wmean, uu, vv, ww, uv, uw and vw and     !
! writes them into file ".1Dr".                                        !
!----------------------------------------------------------------------!
  use all_mod
  use allp_mod
  use les_mod
  use pro_mod
  use par_mod
  use rans_mod
!----------------------------------------------------------------------!
  implicit none
!-----------------------------[Arguments]------------------------------!
  real :: y(-NbC:NC)
  real :: Rad_2, Ufric 
!------------------------------[Calling]-------------------------------!
  interface
    logical function Approx(A,B,tol)
      real           :: A,B
      real, optional :: tol
    end function Approx
  end interface 
!-------------------------------[Locals]-------------------------------!
  integer             :: Nprob, pl, c, dummy, i, count, k, c1, c2, s
  character           :: namCoo*80, namPro*80, answer*80, JetIn*9, namOut*80
  real,allocatable    :: z_p(:), Ump(:), Vmp(:), Wmp(:), & 
                                 uup(:), vvp(:), wwp(:), &
                                 uvp(:), uwp(:), vwp(:), &
                                 Tmp(:), TTp(:),         &
                                 uTp(:), vTp(:), wTp(:), &
                                 Ksgsp(:),               & 
                                 var_1(:), var_2(:), var_3(:), Rad_mp(:), &
                                 var_4(:), var_5(:)  
  integer,allocatable :: Np(:), Ncount(:)
  real                :: R, Urad_mean, Utan_mean, R1, R2, Urad, Utan
!======================================================================!



  do k = 0, 8

!>>>>>>>>>>>>>>>>>>>>>>!
!     read 1D file     !
!>>>>>>>>>>>>>>>>>>>>>>!
    if(this < 2) print *, '# Now reading the file: jet_rad.1D ' 
    open(9, file='jet_rad.1D')

!---- write the number of probes 
    read(9,*) Nprob
    allocate(z_p(Nprob))

!---- write the probe coordinates out
    do pl=1,Nprob
      read(9,*) dummy, z_p(pl)
    end do
    close(9)

    allocate(Np(Nprob));    Np=0 
    allocate(Ump(Nprob));   Ump=0.0
    allocate(Vmp(Nprob));   Vmp=0.0
    allocate(Wmp(Nprob));   Wmp=0.0
    allocate(uup(Nprob));   uup=0.0
    allocate(vvp(Nprob));   vvp=0.0
    allocate(wwp(Nprob));   wwp=0.0
    allocate(uvp(Nprob));   uvp=0.0
    allocate(uwp(Nprob));   uwp=0.0
    allocate(vwp(Nprob));   vwp=0.0
    allocate(Ksgsp(Nprob)); Ksgsp=0.0
    allocate(Rad_mp(Nprob));  Rad_mp=0.0
    allocate(var_1(Nprob));  var_1=0.0
    allocate(var_2(Nprob));  var_2=0.0
    allocate(var_3(Nprob));  var_3=0.0
    allocate(var_4(Nprob));  var_4=0.0
    allocate(var_5(Nprob));  var_5=0.0

    allocate(Ncount(Nprob)); Ncount=0
    count = 0

    if(HOT==YES) then
      allocate(Tmp(Nprob));   Tmp=0.0
      allocate(TTp(Nprob));   TTp=0.0
      allocate(uTp(Nprob));   uTp=0.0
      allocate(vTp(Nprob));   vTp=0.0
      allocate(wTp(Nprob));   wTp=0.0
    end if  

!+++++++++++++++++++++++++++++!
!     average the results     !
!+++++++++++++++++++++++++++++!

    if(k == 0) then
      R1 = 0.0829 
      R2 = 0.0
    else if(k == 1) then
      R1 = 1.0032 
      R2 = 1.001 
    else if(k == 2) then
      R1 = 2.1500 
      R2 = 2.0 
    else if(k == 3) then
      R1 = 3.0684
      R2 = 2.9744
    else if(k == 4) then
      R1 = 4.1433 
      R2 = 3.9098
    else if(k == 5) then
      R1 = 0.5047000E+01 
      R2 = 0.4933200E+01 
    else if(k == 6) then
      R1 = 0.6000000E+01
      R2 = 0.5876600E+01
    else if(k == 7) then
      R1 = 1.5281 
      R2 = 1.4861
    else if(k == 8) then
      R1 = 2.5181 
      R2 = 2.4296
    end if  



    do i = 1, Nprob-1
      do c=1,NC
        Rad_2 = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
        if(Rad_2 < R1 .and. Rad_2 > R2) then
          if(zc(c) > z_p(i) .and. zc(c) < z_p(i+1)) then
            R           = (xc(c)*xc(c) + yc(c)*yc(c))**0.5 + tiny
            Urad_mean   = (U % mean(c) * xc(c) / R  + V % mean(c) * yc(c) / R)
            Utan_mean   = (-U % mean(c) * yc(c) / R  + V % mean(c) * xc(c) / R) 
            Urad   = (U % mean(c) * xc(c) / R  + V % mean(c) * yc(c) / R)
            Utan   = (-U % mean(c) * yc(c) / R  + V % mean(c) * xc(c) / R) 
 
            Ump(i)   = Ump(i) + Urad_mean 
            Vmp(i)   = Vmp(i) + (U % mean(c)**2.0 + V % mean(c)** 2.0 + W % mean(c)**2.0)**0.5 
            Wmp(i)   = Wmp(i) + W % mean(c)
            uuP(i)   = uup(i) + (uu % mean(c)- Urad_mean * Urad_mean)
            vvp(i)   = vvp(i) + (vv % mean(c)- Utan_mean * Utan_mean)
            wwp(i)   = wwp(i) + (ww % mean(c)- W % mean(c) * W % mean(c))
            uvp(i)   = uvp(i) + (uv % mean(c)- Urad_mean * Utan_mean )
            uwp(i)   = uwp(i) + (uw % mean(c)- Urad_mean * W % mean(c))

            var_1(i) = var_1(i) + VISt_r(c) 
            var_2(i) = var_2(i) + Urad 
            var_3(i) = var_3(i) + (U % n(c)**2.0 + V % n(c)** 2.0 + W % n(c)**2.0)**0.5 
            var_4(i) = var_4(i) + VISt(c) 
            var_5(i) = var_5(i) + Uf(c)
            if(HOT==YES) then
              Tmp(i)   = Tmp(i) + T % mean(c)
              TTp(i)   = TTp(i) + (TT % mean(c) - T % mean(c) * T % mean(c))
              uTp(i)   = uTp(i) + (uT % mean(c) - Urad_mean * T % mean(c))
              vTp(i)   = vTp(i) + (vT % mean(c) - Utan_mean * T % mean(c))
              wTp(i)   = wTp(i) + (wT % mean(c) - w % mean(c) * T % mean(c))
            end if
       
            Rad_mp(i) = Rad_mp(i) + (xc(c)*xc(c) + yc(c)*yc(c))**0.5
            Ncount(i) = Ncount(i) + 1
          end if
        end if
      end do 
    end do 

!---- average over all processors
    do pl=1, Nprob
      call IGlSum(Ncount(pl))

      call GloSum(Ump(pl))
      call GloSum(Vmp(pl))
      call GloSum(Wmp(pl))
      call GloSum(Rad_mp(pl))

      call GloSum(uup(pl))
      call GloSum(vvp(pl))
      call GloSum(wwp(pl))

      call GloSum(uvp(pl))
      call GloSum(uwp(pl))
      call GloSum(vwp(pl))
      call GloSum(var_1(pl))
      call GloSum(var_2(pl))
      call GloSum(var_3(pl))
      call GloSum(var_4(pl))
      call GloSum(var_5(pl))

      count =  count + Ncount(pl) 

      if(HOT==YES) then
        call GloSum(Tmp(pl))
        call GloSum(TTp(pl))
        call GloSum(uTp(pl))
        call GloSum(vTp(pl))
        call GloSum(wTp(pl))
      end if
    end do

    JetIn  = 'Jet_res_x'
    write(JetIn(9:9),'(I1)') k

    open(3,file=JetIn)
    do i = 1, Nprob
      if(Ncount(i) /= 0) then
        Wmp(i)    =  Wmp(i)/Ncount(i)
        Ump(i)    =  Ump(i)/Ncount(i)
        Vmp(i)    =  Vmp(i)/Ncount(i)
        uup(i)    =  uup(i)/Ncount(i)
        vvp(i)    =  vvp(i)/Ncount(i)
        wwp(i)    =  wwp(i)/Ncount(i)
        uvp(i)    =  uvp(i)/Ncount(i)
        uwp(i)    =  uwp(i)/Ncount(i)
        Tmp(i)    =  Tmp(i)/Ncount(i)
        TTp(i)    =  TTp(i)/Ncount(i)
        uTp(i)    =  uTp(i)/Ncount(i)
        vTp(i)    =  vTp(i)/Ncount(i)
        wTp(i)    =  wTp(i)/Ncount(i)
        var_1(i)  =  var_1(i)/Ncount(i)
        var_2(i)  =  var_2(i)/Ncount(i)
        var_3(i)  =  var_3(i)/Ncount(i)
        var_4(i)  =  var_4(i)/Ncount(i)
        var_5(i)  =  var_5(i)/Ncount(i)
        Rad_mp(i) =  Rad_mp(i)/Ncount(i)
        write(3,'(19E15.7)') (z_p(i)+z_p(i+1))/4.0, Ump(i), Vmp(i), Wmp(i) , uup(i), vvp(i), wwp(i), uvp(i), uwp(i),&
                               Tmp(i), TTp(i), uTp(i), vTp(i), wTp(i), var_1(i), var_2(i), var_3(i), var_4(i),var_5(i) 
      end if
    end do 
    close(3)

    deallocate(Np)
    deallocate(z_p)
    deallocate(Ump)
    deallocate(Vmp)
    deallocate(Wmp)
    deallocate(uup)
    deallocate(vvp)
    deallocate(wwp)
    deallocate(uvp)
    deallocate(uwp)
    deallocate(vwp)
    deallocate(var_1)
    deallocate(var_2)
    deallocate(var_3)
    deallocate(var_4)
    deallocate(var_5)
    deallocate(Rad_mp)
    deallocate(Ksgsp)
    deallocate(Ncount)
    if(HOT==YES) then
      deallocate(Tmp)
      deallocate(TTp)
      deallocate(uTp)
      deallocate(vTp)
      deallocate(wTp)
    end if
  end do   !end number of radius


!   namOut ='proba'
!   call Name_File(this, namOut, '.r', len_trim('.r') )
!
!    open(3,file=namOut)
!    do s=1,NS
!      c1=SideC(1,s)
!      c2=SideC(2,s)
!      if(c2 < 0) then
!        if(TypeBC(c2).eq.WALLFL) then
!          Rad_2 = (xc(c1)*xc(c1) + yc(c1)*yc(c1))**0.5
!          if(Rad_2 < 4.0433 .and. Rad_2 > 3.9798.and.zc(c1) < 0.1) then
!            write(3,*) T % n(c1), T % n(c2), T % mean(c1), T % mean(c2), Rad_2      
!          end if 
!        end if
!      end if
!    end do
!    close(3) 

  if(this < 2) print *, 'Finished with UserProbe1D_jet '

  end subroutine UserProbe1D_jet
