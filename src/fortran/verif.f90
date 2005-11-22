! Magnus Hagdorn, 2005
!
! verif
! front-end to verif test cases

module verif

  use verifBC
  use verifD
  use glimmer_global, only : rk, sp

  private :: rk, sp

  type verif_type
     type(verifBC_type), pointer :: vb => NULL()
     type(verifD_type),  pointer :: vd => NULL()

     real(rk), dimension(:,:), pointer :: exact_h => NULL() !*FD exact ice thickness
     real(sp), dimension(:,:), pointer :: mb => NULL()      !*FD mass balance
     real(rk) :: ivol_e = 0.
  end type verif_type

contains
  subroutine verif_config(config,veri)
    !*FD read configuration
    use glimmer_config
    use glimmer_log
    implicit none
    type(verif_type)             :: veri    !*FD structure holding test setup
    type(ConfigSection), pointer :: config  !*FD structure holding sections of configuration file   
    ! local variables
    type(ConfigSection), pointer :: section

    ! looking for test case B/C
    call GetSection(config,section,'verifBC')
    if (associated(section)) then
       allocate(veri%vb)
       call verifBC_config(section,veri%vb)
       return
    end if
    ! looking for test case D
    call GetSection(config,section,'verifD')
    if (associated(section)) then
       allocate(veri%vd)
       call verifD_config(section,veri%vd)
       return
    end if

    call write_log('No test configuration found, need either verifBC or verifD',type=GM_FATAL,file=__FILE__,line=__LINE__)

  end subroutine verif_config

  subroutine verif_printconfig(veri)
    !*FD print configuration to log
    implicit none
    type(verif_type)           :: veri    !*FD structure holding test setup

    if (associated(veri%vb)) then
       call verifBC_printconfig(veri%vb)
    end if
    if (associated(veri%vd)) then
       call verifD_printconfig(veri%vd)
    end if
  end subroutine verif_printconfig

  subroutine verif_init(model, veri)
    !*FD initialise test
    use glide_types
    implicit none
    
    type(glide_global_type) :: model !*FD model instance
    type(verif_type)           :: veri    !*FD structure holding test setup

    if (associated(veri%vb)) then
       call verifBC_init(model,veri%vb)
    end if
    if (associated(veri%vd)) then
       call verifD_init(model,veri%vd)
    end if

    ! allocate memory
    allocate(veri%exact_h(model%general%ewn,model%general%nsn))
    allocate(veri%mb(model%general%ewn,model%general%nsn))    
  end subroutine verif_init

  subroutine verif_initthk(model, veri)
    !*FD calculate exact ice thickness and mass balance
    use glide_types
    use paramets, only : thk0
    implicit none
    type(glide_global_type)   :: model !*FD model instance
    type(verif_type)          :: veri  !*FD structure holding test setup
 
    model%geometry%thck = veri%exact_h/thk0
  end subroutine verif_initthk
  
  subroutine verif_update(model, veri, time)
    !*FD calculate exact ice thickness and mass balance
    use glide_types
    use glide
    implicit none
    type(glide_global_type)   :: model !*FD model instance
    type(verif_type)          :: veri  !*FD structure holding test setup
    real(kind=rk), intent(in) :: time  !*FD current time

    if (associated(veri%vb)) then
       call verifBC_update(model,veri%vb, time, veri%exact_h, veri%mb)
    end if
    if (associated(veri%vd)) then
       call verifD_update(model,veri%vd, time, veri%exact_h, veri%mb)
    end if

    ! set mass balance
    call glide_set_acab(model,veri%mb)

    ! calculate ice volume
    veri%ivol_e = sum(veri%exact_h)*model%numerics%dew * model%numerics%dns

  end subroutine verif_update
end module verif
