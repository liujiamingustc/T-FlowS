noinst_LIBRARIES = libUser.a

libUser_a_SOURCES =	\
  User_Force.f90	\
  User_Save_Resuts.f90	\
  User_Source.f90       \
  User_Channel_profiles.f90\
  User_Backstep_profiles.f90\
  User_Backstep_Cf_St.f90\
  User_Impinging_jet_profiles.f90\
  User_Impinging_jet_Nu.f90

SUBDIRS = ../../Shared

LDADD = ../../Shared/libShared.a

INCLUDE = -I@top_srcdir@/
