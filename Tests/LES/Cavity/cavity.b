#::::::::::::::::::::::::::::::::::::::::::::::::::::::#
#                                                      #
# Physical properties, Boundary and Initial conditions #
#                                                      #
#::::::::::::::::::::::::::::::::::::::::::::::::::::::#


#------------------------#
#-  physical properties -#
#------------------------#
#  No.   Type         VISc     DENc     CONs      CAPc
   1

   1     Fluid       9.08e-5   1.00    0.0001279    1.0 


#------------------------#
#-- boundary condition --#
#------------------------#
#  No.   Type          U       V       W       T      Kin     Eps     v_2     f22
   3
   1     Wall      0.0     0.0    0.0  5.0 
   2     Wall      0.0     0.0    0.0  15.0 
   3     WallFlux  0.0     0.0    0.0  0.0  


#------------------------#
#-- initial conditions --#
#------------------------#
#  No.                  U       V       W       T      Kin     Eps     v_2     f22
   1
   1  0.0     0.0     0.0     10.0   

