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
 fluid   Fluid       1.00E-4   1.00    1.40e-4    1.0 

#------------------------#
#-- boundary condition --#
#------------------------#
#  Number of
   6
#  Name            Type      U      V      W     T     Kin     Eps     v_2    f22
 symmetry_plane  SYMMETRY   0.0    0.0    0.0  20.0   1.0E-2  1.0E-3  6.6E-2  1.0e-3
 pipe_wall       WallFlux   0.0    0.0    0.0   0.0    0.0    1.0e-3   0.0    0.0
 top_plane       PRESSURE   0.0    0.0    0.0   0.0   20.0    1.0E-2  1.0E-3  6.6E-2  1.0e-3
 lower_wall      WallFlux   0.0    0.0    0.0   0.1    0.0    1.0e-3   0.0    0.0   
 pipe_inlet      INFLOW     File   InletProfile_zeta_Re23000.dat 
 cyl_outlet      PRESSURE   0.0    0.0    0.0   0.0   20.0    1.0E-2  1.0E-3  6.6E-2  1.0e-3

#--sides

#------------------------#
#-- initial conditions --#
#------------------------#
#  No.                  U       V       W       T      Kin     Eps     v_2     f22
   1
   1                   -0.1     0.0     0.0     20.0   1.0E-3  1.0E-4  6.6E-4  1.0e-4
