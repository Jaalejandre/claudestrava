      PROGRAM dm_npt
      use io_dm

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      parameter(maxnat=30000,ncallsx=125,nchx=10,maxlist=120000000)
      parameter(MAXNMOL=10000,MAXMESP=10,MAXK=500000,MAXKMAX=20000)
      real*8 rx(maxnat),ry(maxnat),rz(maxnat)
      real*8 rxq(maxnat),ryq(maxnat),rzq(maxnat)
      real*8 rxup(maxnat),ryup(maxnat),rzup(maxnat)
      real*8 vx(maxnat),vy(maxnat),vz(maxnat)
      real*8 fx(maxnat),fy(maxnat),fz(maxnat)
      real*8 fx1(maxnat),fy1(maxnat),fz1(maxnat)  !Intramolecular
      real*8 fx2(maxnat),fy2(maxnat),fz2(maxnat)  !Real
      real*8 fx2o(maxnat),fy2o(maxnat),fz2o(maxnat)
      real*8 fxi(maxnat),fyi(maxnat),fzi(maxnat)  !Intra
      real*8 fxko(maxnat),fyko(maxnat),fzko(maxnat)
      real*8 fxk(maxnat),fyk(maxnat),fzk(maxnat)  !kwald
      real*8 fx3(maxnat),fy3(maxnat),fz3(maxnat)  !kwald
      real*8 fxkq(maxnat),fykq(maxnat),fzkq(maxnat)
      real*8 rmasat(maxnat),rrmasa(maxnat)
      real*8 cargat(maxnat),carga(maxnat),cargaq(maxnat)
      real*8 bonds(2,maxnat),bondsi(2,maxnat,10)
      real*8 sigma(10,10),eps(10,10),soft(10,10),nij(10,10)
      integer ibonds(2,maxnat),ibondsi(2,maxnat,10),iitipo(maxnat)
      integer nbondsi(10),itipoa(maxnat)
      integer inicio_mol(maxnat),itipo(maxnat,10)
      integer ianglesi(3,maxnat,10),nanglesi(10)
      integer iangles(maxnat,10)
      real*8 anglesi(2,maxnat,10),angles(2,maxnat),diedroi(6,maxnat,10)
      integer idiedroi(4,maxnat,10),ndiedroi(10),idiedro(4,maxnat)
      real*8 diedro(6,maxnat)
      real*8 eta(nchx,maxnat),etadot(nchx,maxnat),q(nchx,maxnat)
      real*8 xi(nchx),xidot(nchx),qp(nchx)
      real*8 dtsuz(ncallsx)
      real*8 rmasa_molar(10)

      REAL*8 RXCM(MAXNMOL),RYCM(MAXNMOL),RZCM(MAXNMOL)
      real*8 pxik(maxnat),pyik(maxnat),pzik(maxnat)
      REAL*8 RXA(MAXNAT),RYA(MAXNAT),RZA(MAXNAT)
      REAL*8 KVEC(MAXK)

      integer n15i(10),i15i(2,maxnat,10),i15(2,maxnat)
      integer nat_mol(10),nmol_esp(10)
      integer nblist1(maxlist),nblist2(maxlist)
      integer iq(maxnat)
      integer c1, c2, rate
      real*8 tiempo
      character*4 symbol2(maxnat)
      character*5 resid_name(maxnat)
      character*20 pot,pot_fdr_sf,pot_lj_sf,pot_lj_sts,pot_sfmie
      logical updatel
      logical termostato,barostato,recip_ewald
      integer fourier_nx,fourier_ny,fourier_nz
      integer nstenergy,nstvout
      character*20 ewald_geometry
      character*20 pcoupltype
      character*20 constraints
      character*20 dispcorr

      real*8 fudgeLJ,fudgeQQ
      real*8 coef_lrc_u
      real*8 coef_lrc_p
      real*8 npair_tipo(10,10)
      real*8 lij(10,10)
      real*8 uslater

      real*8 cmie(10,10)
      real*8 z1(10,10),z2(10,10)

      real*8 uc_lj(10,10),duc_lj(10,10)
      real*8 uc_mie(10,10),duc_mie(10,10)
      real*8 uc_fdr(10,10),duc_fdr(10,10)
      real*8 coulrc

!     logical genpairs
      character*8 genpairs
      logical lrc_energy
      logical lrc_pressure
      logical usa_lrc

! date and time

      CHARACTER(LEN=5) :: current_date
      CHARACTER(LEN=10) :: current_time
      CHARACTER(LEN=5) :: time_zone
      INTEGER :: datetime_values(8)
      REAL :: start_time, end_time

!===============================================================
! Escritura de energy.dat para un programa propio de DM
!
! Formato propuesto:
!   - Una línea de encabezado con nombres de columnas.
!   - Una línea completa por cada paso de escritura.
!   - FLUSH después de cada línea para permitir análisis mientras
!     la dinámica molecular continúa ejecutándose.
!
! Debe abrirse una sola vez al inicio de la simulación y cerrarse
! al terminar.
!===============================================================

      integer iunit_energy
      parameter (iunit_energy=77)
      logical existe_energy

      open(iunit_log,file='dm.log',
     &     status='replace',
     &     form='formatted')

      write(6,*) 'MAIN: abierto dm.log unidad=',iunit_log

      write(iunit_log,*) 'MAIN: prueba escritura log'
      flush(iunit_log)

!---------------------------------------------------------------
! Abrir el archivo al inicio del programa main
!---------------------------------------------------------------

        open(unit=iunit_energy,
     &     file='energy.dat',
     &     status='replace',
     &     form='formatted',
     &     access='sequential',
     &     action='write',
     &     recl=4096)

        write(iunit_energy,'(a)')
     & '# DMENERGY version 1'

      write(iunit_energy,'(a)')
     & '# units: energies=kJ/mol lengths=nm density=kg/m3'//
     & ' temperature=K pressure=bar time=ps'

      write(iunit_energy,'(a)')
     & '# columns: step time_ps vbonds vangles vdiedro'//
     & ' ulj15 ucoul15 ulj ucoul ukw'//
     & ' ekin epot ethermo ebaro etot'//
     & ' pxx pxy pxz pyy pyz pzz'//
     & ' lx ly lz volume density temperature pressure'

      flush(iunit_energy)

      open(10,file="energia_cinetica.dat")
      open(15,file="energia_potencial.dat")
      open(17,file="energia_termostato.dat")
      open(19,file="energia_barostato.dat")
      open(18,file="energia_total_sistema.dat")
      open(20,file="energia_total.dat")
      open(25,file="temperatura.dat")
      open(29,file="densidad.dat")
      open(30,file="presion.dat")
      open(33,file="comp_presion.dat")
      open(35,file="error.dat")
      open(45,file="pab_visc.dat")
!     open(89,file="movie.gro")
      rewind 10
      rewind 15
      rewind 20
      rewind 25
      rewind 35
      rewind 45

      open(iulog,file='dm.log',
     & status='unknown',
     & form='formatted')


      call gro0(maxnat,natgro,rx,ry,rz,boxx,boxy,boxz,symbol2,
     & resid_name,vx,vy,vz)

      vol = boxx*boxy*boxz

!leer datos para DM

!     call mdp_f77(dt,nsteps,nstlog,nstxout,rcut,error_coul,
!    & temp,nch,tau_t,boxx,p_ext,tau_p,termostato,barostato,skin,
!    & pot,nts1,nts2,npab,recip_ewald)

!leer topologia

!     if(pot.ne."pot_sfmie") then

!       call top_f77(maxnat,mesp,nbondsi,ibondsi,bondsi,rmasat,itipo,
!    &  sigma,eps,natom_types,nmol_esp,nat_mol,nat,nmol,rmasa_molar,
!    &  nanglesi,ianglesi,anglesi,ndiedroi,idiedroi,diedroi,itipoa,
!    &  cargat,n15i,i15i,natgro,soft)

!      elseif(pot=="pot_sfmie") then

!       write(6,*) 'Entro a top_sfmie'

!       call top_sfmie_f77(maxnat,mesp,nbondsi,ibondsi,bondsi,rmasat,
!    &  itipo,sigma,eps,natom_types,nmol_esp,nat_mol,nat,nmol,
!    &   rmasa_molar,nanglesi,ianglesi,anglesi,ndiedroi,idiedroi,
!    &   diedroi,itipoa,cargat,n15i,i15i,natgro,nij)

!      endif


      call top_gmx(maxnat,mesp,nbondsi,ibondsi,bondsi, 
     &   rmasat,itipo,sigma,eps,npair_tipo,natom_types,nmol_esp, 
     &   nat_mol,nat,nmol,rmasa_molar, 
     &   nanglesi,ianglesi,anglesi,ndiedroi,idiedroi, 
     &   diedroi,itipoa,cargat,n15i,i15i, 
     &   natgro,nij,soft,lij,
     &   nbfunc,comb_rule,genpairs,fudgeLJ,fudgeQQ)

      write(6,*) ' '
      write(6,*) 'Especies moleculares'
      write(iunit_log,*) 'Especies moleculares'
      write(6,*) 'mesp = ',mesp
      write(iunit_log,*) 'mesp = ',mesp

      write(6,*) 'Cargas atomtypes'
      write(iunit_log,*) 'Cargas atomtypes'
      do i=1,natom_types
         write(6,*) i,cargat(i)
         write(iunit_log,*) i,cargat(i)
      enddo
      write(6,*) 'sigma, esp atomtypes'
      write(iunit_log,*) 'sigma, esp atomtypes'
      do i=1,natom_types
        do j=1,natom_types
         write(6,*) i,j,sigma(i,j),eps(i,j),lij(i,j)
         write(iunit_log,*) i,j,sigma(i,j),eps(i,j),lij(i,j)
      enddo
      enddo

      do ie=1,mesp

         write(6,*) ' '
         write(6,*) 'Especie ',ie
!        write(6,*) 'Nombre = ',trim(molname(ie))
         write(6,*) 'Numero de atomos = ',nat_mol(ie)

         write(6,*) ' '
         write(6,*) 'atom tipo'
         write(6,*) ' '

         write(iunit_log,*) 'Especie ',ie
!        write(6,*) 'Nombre = ',trim(molname(ie))
         write(iunit_log,*) 'Numero de atomos = ',nat_mol(ie)

         write(iunit_log,*) ' '
         write(iunit_log,*) 'atom tipo'

         do i=1,nat_mol(ie)
            write(6,100) i,itipo(i,ie)
            write(iunit_log,100) i,itipo(i,ie)
         enddo

         write(6,*) ' '
         write(6,*) 'Enlaces = ',nbondsi(ie)
         write(iunit_log,*) ' '
         write(iunit_log,*) 'Enlaces = ',nbondsi(ie)

         do i=1,nbondsi(ie)
            write(6,110) ibondsi(1,i,ie),
     &                   ibondsi(2,i,ie),
     &                   bondsi(1,i,ie),
     &                   bondsi(2,i,ie)
            write(iunit_log,110) ibondsi(1,i,ie),
     &                   ibondsi(2,i,ie),
     &                   bondsi(1,i,ie),
     &                   bondsi(2,i,ie)
         enddo

         write(6,*) 'Angulos = ',nanglesi(ie)
         write(6,*) 'Diedros = ',ndiedroi(ie)
         write(6,*) 'Pares 1-5 = ',n15i(ie)

         write(iunit_log,*) 'Angulos = ',nanglesi(ie)
         write(iunit_log,*) 'Diedros = ',ndiedroi(ie)
         write(iunit_log,*) 'Pares 1-5 = ',n15i(ie)

      enddo

100   format(2i8)
110   format(2i4,3(1pe16.8),i8)

       write(*,*) 'Regreso a main'
       write(*,*) 'nbfunc ',nbfunc

       call mdp(dt,nsteps,nstlog,nstxout,nstvout,nstenergy,
     & rcut,error_coul,temp,nch,tau_t,boxx,p_ext,tau_p,
     & termostato,barostato,skin,nts1,nts2,recip_ewald,
     & fourier_nx,fourier_ny,fourier_nz,ewald_geometry,
     & pcoupltype,constraints,dispcorr)

      write(6,*) 'rcut ',rcut
      write(6,*) 'error_coul',error_coul
      write(6,*) 'temp',temp
      write(6,*) 'tau_t ',tau_t
      write(6,*) 'p_ext',p_ext
      write(6,*) 'tau_p ',tau_p
      write(6,*) 'termostato ', termostato
      write(6,*) 'barostato ', barostato
      write(6,*) 'skin ', skin
      write(6,*) 'nts1 ', nts1
      write(6,*) 'nts2 ', nts2
      write(6,*) 'recip_ewald ', recip_ewald
      write(6,*) 'pcoultype ', pcoupltype   
      write(6,*) 'constraints ', constraints 
      write(6,*) 'nstlog ', nstlog      
      write(6,*) 'nstenergy', nstenergy 
      write(6,*) 'nstxout', nstxout
      write(6,*) 'DispCorr ', dispcorr

      write(iunit_log,*) 'Lectura de mdp'
      write(iunit_log,*) 'rcut ',rcut
      write(iunit_log,*) 'error_coul',error_coul
      write(iunit_log,*) 'temp',temp
      write(iunit_log,*) 'tau_t ',tau_t
      write(iunit_log,*) 'p_ext',p_ext
      write(iunit_log,*) 'tau_p ',tau_p
      write(iunit_log,*) 'termostato ', termostato
      write(iunit_log,*) 'barostato ', barostato
      write(iunit_log,*) 'skin ', skin
      write(iunit_log,*) 'nts1 ', nts1
      write(iunit_log,*) 'nts2 ', nts2
      write(iunit_log,*) 'recip_ewald ', recip_ewald
      write(iunit_log,*) 'pcoultype ', pcoupltype   
      write(iunit_log,*) 'constraints ', constraints 
      write(iunit_log,*) 'nstlog ', nstlog      
      write(iunit_log,*) 'nstenergy', nstenergy 
      write(iunit_log,*) 'DispCorr ', dispcorr

      rlist = rcut + skin

      dof = 3.0d0*nat   !solo para moleculas flexibles
      rgas = 8.31446d0
      factor = rgas/1000.0d0
      RT = factor*temp

!     call write_log_header_gmx(iulog,nat,nmol, 
!    &  boxx,boxy,boxz, 
!    &  dt,nsteps, 
!    &  rcut,rlist,nstenergy, 
!    &  nbfunc,comb_rule,genpairs, 
!    &  natom_types,atype,mass,charge,sigma,eps, 
!    &  nij,soft,  
!    &  mesp,nat_mol,nmol_esp)

c=======================================================================
c     Activar correcciones de dispersion
c=======================================================================

      lrc_energy   = .false.
      lrc_pressure = .false.
      usa_lrc      = .false.

      if(trim(dispcorr).eq.'ener') then

         lrc_energy = .true.
         usa_lrc    = .true.

      else if(trim(dispcorr).eq.'enerpres') then

         lrc_energy   = .true.
         lrc_pressure = .true.
         usa_lrc    = .true.

      else if(trim(dispcorr).eq.'no') then

         lrc_energy   = .false.
         lrc_pressure = .false.
         usa_lrc    = .false.

      else

         write(6,*) 'ERROR DispCorr incorrecto'
         write(6,*) trim(dispcorr)
         write(iunit_log,*) 'ERROR DispCorr incorrecto'
         write(iunit_log,*) trim(dispcorr)
         flush(iunit_log)
         stop

      endif

      write(6,*) 'SE inicializa LRC ', usa_lrc,trim(dispcorr)
      write(iunit_log,*) 'SE inicializa LRC ', usa_lrc,trim(dispcorr)

       flush(iunit_log)
c=======================================================================
c  INICIALIZACION DE LAS CORRECCIONES DE LARGO ALCANCE
c=======================================================================

      coef_lrc_u = 0.0d0
      coef_lrc_p = 0.0d0

      ulrc    = 0.0d0
      plrc    = 0.0d0
      wxx_lrc = 0.0d0
      wyy_lrc = 0.0d0
      wzz_lrc = 0.0d0

!     usa_lrc       = .false.
      lrc_energy    = .false.
      lrc_pressure  = .false.

      select case(nbfunc)

c-----------------------------------------------------------------------
c     Potenciales shifted-force: no se aplican LRC
c-----------------------------------------------------------------------

      case(1,2,3)

        usa_lrc=.false.
        write(*,*) 'AVISO: DispCorr se ignora para potencial SF'
        write(*,*) 'nbfunc = ',nbfunc
        write(iunit_log,*) 'AVISO: DispCorr se ignora para potencial SF'
        write(iunit_log,*) 'nbfunc = ',nbfunc

        write(*,*) 'Potencial truncado sin LRC'
        write(*,*) 'usa_lrc, dispcorr', usa_lrc,dispcorr
        write(*,*) 'nbfunc = ',nbfunc
        write(iunit_log,*) 'Potencial truncado sin LRC'
        write(iunit_log,*) 'nbfunc = ',nbfunc
c-----------------------------------------------------------------------
c     Potenciales truncados: LRC opcional
c-----------------------------------------------------------------------

      case(4,5,6,7)


       select case(nbfunc)

c-----------------------------------------------------------------------
c           LJ-ST
c-----------------------------------------------------------------------

            case(4)

             if(usa_lrc) then
               write(*,*) 'Se inicializa LRC para LJ-ST ', dispcorr
               write(iunit_log,*) 'Se inicializa LRC para LJ-ST'

               call setup_lrc_lj_st(natom_types,npair_tipo,
     &              sigma, eps, rcut,
     &              coef_lrc_u,coef_lrc_p)
             endif

c-----------------------------------------------------------------------
c           Mie-ST
c-----------------------------------------------------------------------

            case(5)

             if(usa_lrc) then
               write(*,*) 'Se inicializa LRC para MIE-ST ', dispcorr
               write(iunit_log,*) 'Se inicializa LRC para MIE-ST'

               call setup_lrc_mie(natom_types,npair_tipo,
     &              sigma,eps,nij,rcut,
     &              coef_lrc_u,coef_lrc_p)
             endif

c-----------------------------------------------------------------------
c           FDR-ST
c-----------------------------------------------------------------------

            case(6)

             if(usa_lrc) then
               write(*,*) 'Se inicializa LRC para FDR-ST ', dispcorr
               write(iunit_log,*) 'Se inicializa LRC para FDR-ST'

               call setup_lrc_fdr_st(natom_types,npair_tipo,
     &              sigma,eps,soft,rcut,
     &              coef_lrc_u,coef_lrc_p)
             endif

            case(7)

             if(usa_lrc) then
               write(*,*) 'Se inicializa LRC para LJ-Salter ', dispcorr
               write(iunit_log,*) 'Se inicializa LRC para LJ-Slater'

               call setup_lrc_lj_st(natom_types,npair_tipo,
     &              sigma, eps, rcut,
     &              coef_lrc_u,coef_lrc_p)
             endif

            end select

c-----------------------------------------------------------------------
c     Control de error
c-----------------------------------------------------------------------

      case default

         write(*,*) 'ERROR: nbfunc fuera de rango'
         write(*,*) 'nbfunc = ',nbfunc
         write(iunit_log,*) 'ERROR: nbfunc fuera de rango'
         write(iunit_log,*) 'nbfunc = ',nbfunc
         stop

      end select

c=======================================================================
c  CALCULO INICIAL DE LRC AL VOLUMEN INICIAL
c=======================================================================

      if (usa_lrc) then

         volume = boxx*boxy*boxz

         call lrc_lj_st(volume,
     &        coef_lrc_u,coef_lrc_p,
     &        ulrc,plrc,
     &        wxx_lrc,wyy_lrc,wzz_lrc)

         write(*,*) 'LRC inicializada'
         write(*,*) 'coef_lrc_u = ',coef_lrc_u
         write(*,*) 'coef_lrc_p = ',coef_lrc_p
         write(*,*) 'ulrc       = ',ulrc
         write(*,*) 'plrc       = ',plrc

         write(iunit_log,*) 'LRC inicializada'
         write(iunit_log,*) 'coef_lrc_u = ',coef_lrc_u
         write(iunit_log,*) 'coef_lrc_p = ',coef_lrc_p
         write(iunit_log,*) 'ulrc       = ',ulrc
         write(iunit_log,*) 'plrc       = ',plrc

      endif

c-----------------------------------------------------------------------
c        Calcular correcciones con el volumen inicial
c-----------------------------------------------------------------------

         volume = boxx*boxy*boxz

         call lrc_lj_st(volume,coef_lrc_u,coef_lrc_p,
     &        ulrc,plrc,wxx_lrc,wyy_lrc,wzz_lrc)

         write(6,*)
         write(6,*) 'Correcciones iniciales con volumen inicial'
         write(6,*) 'volume   = ',volume
         write(6,*) 'ulrc     = ',ulrc
         write(6,*) 'plrc     = ',plrc
         write(6,*) 'wxx_lrc  = ',wxx_lrc
         write(6,*) 'wyy_lrc  = ',wyy_lrc
         write(6,*) 'wzz_lrc  = ',wzz_lrc
         write(6,*)

         write(iunit_log,*)
         write(iunit_log,*) 'Correcciones iniciales'
         write(iunit_log,*) 'volume   = ',volume
         write(iunit_log,*) 'ulrc     = ',ulrc
         write(iunit_log,*) 'plrc     = ',plrc
         write(iunit_log,*) 'wxx_lrc  = ',wxx_lrc
         write(iunit_log,*) 'wyy_lrc  = ',wyy_lrc
         write(iunit_log,*) 'wzz_lrc  = ',wzz_lrc

      call distribuir_de(maxnat,mesp,nmol_esp,nbondsi,
     &  ibondsi,bondsi,ibonds,bonds,nbonds,nat_mol)

      call distribuir_angulos(maxnat,ianglesi,anglesi,
     & nanglesi,mesp,nmol_esp,nat_mol,iangles,angles,nangles)

      call distribuir_diedros(maxnat,mesp,nmol_esp,nat_mol,
     &  ndiedroi,idiedroi,idiedro,diedroi,diedro,ndiedro)

      call distribuir_15(maxnat,mesp,nmol_esp,nat_mol,n15i,i15i,
     &  n15,i15)

      call inicio_molecula(maxnat,mesp,nmol_esp,
     &  nat_mol,inicio_mol)
   
      call distribuir_tipos(maxnat,mesp,itipo,iitipo,
     &  nmol_esp,nat_mol)

      call distribuir_masas(maxnat,nat,iitipo,rmasat,rrmasa)
      call distribuir_cargas(maxnat,nat,iitipo,cargat,carga)

      write(6,*) 'Antes de distribuir sistemas'

!     call distribuir_sistema(maxnat,mesp,nmol_esp,nat_mol,
!    & itipo,rmasat,cargat,
!    & nbondsi,ibondsi,bondsi,
!    & nanglesi,ianglesi,anglesi,
!    & ndiedroi,idiedroi,diedroi,
!    & n15i,i15i,
!    & inicio_mol,iitipo,rrmasa,carga,
!    & ibonds,bonds,nbonds,
!    & iangles,angles,nangles,
!    & idiedro,diedro,ndiedro,
!    & i15,n15)

!     call BUILD_CHARGED_ATOMS_EWALD(MAXNAT,NAT,RX,RY,RZ,CARGA,
!    &   NATQ,IQ,RXQ,RYQ,RZQ,CARGAQ)

      call remove_vcofm(maxnat,nat,rrmasa,vx,vy,vz)

! Unir atomos en la molecula

       open(unit=89,file='movie.gro',
     &     status='replace',
     &     form='formatted',
     &     action='write')

      close(89)

      istep = 0
      call shift_cofm(maxnat,nat,rrmasa,rz)
      call cofm(maxnat,maxmesp,maxnmol,nmol,rx,ry,rz,boxx,boxy,boxz,
     &  mesp,nmol_esp,nat_mol,rrmasa,rxcm,rycm,rzcm,
     &  pxik,pyik,pzik)
         call xyz_cofm(maxnat,maxmesp,maxnmol,mesp,nmol_esp,nat_mol,
     &  rxcm,rycm,rzcm,
     &  pxik,pyik,pzik,rxa,rya,rza,boxx,boxy,boxz)

!     call gro(maxnat,nat,rxa,rya,rza,boxx,boxy,boxz,symbol2,
!    &   resid_name,vx,vy,vz,iistep,dt)

!   escalar parametros

!     nmts = nts2

!     write(6,*) 'NMTS ', nmts
!     write(iunit_log,*) 'NMTS ', nmts

!     tau_t = nmts*tau_t
!     tau_p = nmts*tau_p

      time_ps = dble(istep)*dt*nmts
      call gro_write(maxnat,nat,rxa,rya,rza,boxx,boxy,boxz,
     &        symbol2,vx,vy,vz,istep,time_ps)


! Si noy hay enlaces --> corresponde solo a LJ
! La lista de vecinos es para moleculas

!     if(nbonds.eq.0) nmts = 1

      call kappa_coulomb(error_coul,rkappa,rcut)

!inicializar variables del termostato

      if(termostato) then
!      call ini_etas(maxnat,nat,temp,nch,eta,etadot,q,dt,
!    & dtsuz,ncalls,nit,tau_t)

      call ini_etas_system(maxnat,nat,temp,nch,eta,etadot,q,dt,
     & dtsuz,ncalls,nit,tau_t,dof,RT)

      endif

! Lista de vecinos

!     rlist = rcut + skin   
      write(6,*) 'rcut,rlist, skin ', rcut,rlist,skin
      write(iunit_log,*) 'rcut,rlist, skin ', rcut,rlist,skin

      nupdate = 1
      updatel = .true.

      call save(maxnat,nat,rx,ry,rz,rxup,ryup,rzup)

      CALL CPU_TIME(start_time)
      call lista(maxnat,maxlist,nat,rx,ry,rz,boxx,boxy,boxz,
     & nblist1,nblist2,npares,rlist,inicio_mol)
      CALL CPU_TIME(end_time)

      write(6,*) 'LISTA '
      write(6,*) 'rlist', rlist
      write(6,*) 'Lista npares ', npares
      write(6,*) 'Tiempo lista ', end_time - start_time

      if(recip_ewald) then

      call compute_kmax_ewald(boxx,boxy,boxz,rcut,error_coul,
     &     rkappa,kmaxx,kmaxy,kmaxz)

!  Valores para Vectores reciprocos

      write(6,*) 'rkappa,kmaxx, kmaxy, kmaxz',rkappa,kmaxx,kmaxy,kmaxz

      CALL SETUP2(MAXK,RKAPPA,KMAXX,KMAXY,KMAXZ,KVEC,
     &  BOXX, BOXY, BOXZ)

!     write(6,*) 'SETUP2 '
!     write(6,*) 'KMAXX, ...',KMAXX, KMAXY, KMAXZ
!     do i=1,6
!        write(6,*) 'I, KVEC', i, kvec(i)
!     enddo

      endif

      call fzas_de(maxnat,nat,rx,ry,rz,ibonds,bonds,nbonds,
     & vbonds,fx1,fy1,fz1,wxx1,wxy1,wxz1,wyy1,wyz1,wzz1,
     & boxx,boxy,boxz)

      call fzas_angulo(maxnat,nat,rx,ry,rz,boxx,boxy,boxz,
     & iangles,angles,nangles,fx1,fy1,fz1,vangles,
     & wxx1,wxy1,wxz1,wyy1,wyz1,wzz1)

      call fzas_diedro(maxnat,nat,ndiedro,idiedro,diedro,
     &  rx,ry,rz,fx1,fy1,fz1,boxx,boxy,boxz,
     &  wxx1,wxy1,wxz1,wyy1,wyz1,wzz1,vdiedro)

      call fzas_15(maxnat,rx,ry,rz,fx1,fy1,fz1,sigma,eps,carga,
     &  rkappa,wxx1,wxy1,wxz1,wyy1,wyz1,wzz1,n15,i15,iitipo,
     &  boxx,boxy,boxz,ulj15,ucoul15,rcut)

      write(6,*) '  '
      write(6,*) 'vbonds ', vbonds/nat
      write(6,*) 'vangles ', vangles/nat
      write(6,*) 'vdiedro ', vdiedro/nat
      write(6,*) 'ulj15 ', ulj15/nat
      write(6,*) 'ucoulomb15 ', ucoul15/nat
      write(6,*) 'wxx ', wxx1,wyy1,wzz1

C     Calcular constantes de los potenciales

      write(6,*) 'nbfunc, natom_types,rcut,rkappa'
      write(6,*) nbfunc, natom_types,rcut,rkappa

      call setup_nonbond_constants(nbfunc,natom_types,
     &     sigma,eps,nij,soft,rcut,rkappa,
     &     cmie,z1,z2,
     &     uc_lj,duc_lj,
     &     uc_mie,duc_mie,
     &     uc_fdr,duc_fdr,
     &     coulrc)

         if(nbfunc.eq.5) then
         write(6,*) 'nij(1,1)     = ',nij(1,1)
         write(6,*) 'cmie(1,1)    = ',cmie(1,1)
         write(6,*) 'uc_mie(1,1)  = ',uc_mie(1,1)
         write(6,*) 'duc_mie(1,1) = ',duc_mie(1,1)
         write(6,*) 'coulrc        = ',coulrc
      endif

       write(6,*) 'Entra LJ npares',npares

c=======================================================================
c     Seleccion del potencial intermolecular
c=======================================================================

      select case(nbfunc)

      case(1)

c        Lennard-Jones shifted-force

       call system_clock(c1)
       call fzas_lj_sf_f77(maxnat,maxlist,nat,rx,ry,rz,iitipo,
     &  fx2o,fy2o,fz2o,eps,sigma,
     &  wxx2o,wxy2o,wxz2o,wyy2o,wyz2o,wzz2o,
     &  rcut,boxx,boxy,boxz,carga,rkappa,uljo,ucoulo,
     &  npares,nblist1,nblist2)
        call system_clock(c2,rate)
        tiempo_f77 = dble(c2-c1)/dble(rate)

       call system_clock(c1)
       call fzas_lj_sf(maxnat,maxlist,rx,ry,rz,iitipo,
     &  fx2,fy2,fz2,
     &  eps,sigma,uc_lj,duc_lj,
     &  wxx2,wxy2,wxz2,wyy2,wyz2,wzz2,
     &  rcut,boxx,boxy,boxz,carga,rkappa,coulrc,
     &  ulj,ucoul,
     &  npares,nblist1,nblist2)
        call system_clock(c2,rate)
        tiempo_gpu = dble(c2-c1)/dble(rate)

        call escribe_error_fzas(1,nat,tiempo_f77,tiempo_gpu, 
     &   uljo,ulj,ucoulo,ucoul, 
     &   wxx2o,wxx2,wyy2o,wyy2,wzz2o,wzz2, 
     &   fx2o,fy2o,fz2o,fx2,fy2,fz2)

      case(2)

c        Mie shifted-force

!      coulrc = derfc(rkappa*rcut)/rcut

       call system_clock(c1)
       call fzas_mie_sf_f77(maxnat,maxlist,nat,rx,ry,rz,iitipo,
     &  fx2o,fy2o,fz2o,eps,sigma,
     &  wxx2o,wxy2o,wxz2o,wyy2o,wyz2o,wzz2o,
     &  rcut,boxx,boxy,boxz,carga,rkappa,uljo,ucoulo,
     &  npares,nblist1,nblist2,nij)
         call system_clock(c2,rate)
         tiempo_f77 = dble(c2-c1)/dble(rate)

       call system_clock(c1)
       call fzas_mie_sf(maxnat,maxlist,nat,rx,ry,rz,iitipo,
     &  fx2,fy2,fz2,
     &  eps,sigma,nij,cmie,uc_mie,duc_mie,
     &  wxx2,wxy2,wxz2,wyy2,wyz2,wzz2,
     &  rcut,boxx,boxy,boxz,carga,rkappa,coulrc,
     &  ulj,ucoul,
     &  npares,nblist1,nblist2)
         call system_clock(c2,rate)
         tiempo_gpu = dble(c2-c1)/dble(rate)

         write(6,*) 'uljo, ulj ', uljo, ulj

        call escribe_error_fzas(2,nat,tiempo_f77,tiempo_gpu, 
     &   uljo,ulj,ucoulo,ucoul, 
     &   wxx2o,wxx2,wyy2o,wyy2,wzz2o,wzz2, 
     &   fx2o,fy2o,fz2o,fx2,fy2,fz2)

      case(3)

c        FDR shifted-force

         call system_clock(c1)
         call fzas_fdr_sf_f77(maxnat,maxlist,nat,
     &        rx,ry,rz,iitipo,
     &        fx2o,fy2o,fz2o,
     &        eps,sigma,
     &        wxx2o,wxy2o,wxz2o,wyy2o,wyz2o,wzz2o,
     &        rcut,boxx,boxy,boxz,
     &        carga,rkappa,
     &        uljo,ucoulo,
     &        npares,nblist1,nblist2,soft)
          call system_clock(c2,rate)
          tiempo_f77 = dble(c2-c1)/dble(rate)

         call system_clock(c1)
         call fzas_fdr_sf(maxnat,maxlist,nat,
     &        rx,ry,rz,iitipo,
     &        fx2,fy2,fz2,
     &        eps,sigma,
     &        wxx2,wxy2,wxz2,wyy2,wyz2,wzz2,
     &        rcut,boxx,boxy,boxz,
     &        carga,rkappa,
     &        ulj,ucoul,
     &        npares,nblist1,nblist2,soft)
          call system_clock(c2,rate)
          tiempo_gpu = dble(c2-c1)/dble(rate)

        call escribe_error_fzas(3,nat,tiempo_f77,tiempo_gpu, 
     &   uljo,ulj,ucoulo,ucoul, 
     &   wxx2o,wxx2,wyy2o,wyy2,wzz2o,wzz2, 
     &   fx2o,fy2o,fz2o,fx2,fy2,fz2)

      case(4)

c        Lennard-Jones truncado ST

         call system_clock(c1)
         call fzas_lj_st_f77(maxnat,maxlist,nat,
     &        rx,ry,rz,iitipo,
     &        fx2o,fy2o,fz2o,
     &        eps,sigma,wxx2o,wxy2o,wxz2o,wyy2o,wyz2o,wzz2o,
     &        rcut,boxx,boxy,boxz,
     &        carga,rkappa,uljo,ucoulo,npares,nblist1,nblist2)
          call system_clock(c2,rate)
          tiempo_f77 = dble(c2-c1)/dble(rate)

         call system_clock(c1)
         call fzas_lj_st(maxnat,maxlist,nat,
     &        rx,ry,rz,iitipo,
     &        fx2,fy2,fz2,
     &        eps,sigma,
     &        wxx2,wxy2,wxz2,
     &        wyy2,wyz2,wzz2,
     &        rcut,boxx,boxy,boxz,
     &        carga,rkappa,
     &        ulj,ucoul,
     &        npares,nblist1,nblist2)
          call system_clock(c2,rate)
          tiempo_GPU = dble(c2-c1)/dble(rate)

        call escribe_error_fzas(4,nat,tiempo_f77,tiempo_gpu, 
     &   uljo,ulj,ucoulo,ucoul, 
     &   wxx2o,wxx2,wyy2o,wyy2,wzz2o,wzz2, 
     &   fx2o,fy2o,fz2o,fx2,fy2,fz2)

      case(5)

c        Mie truncado ST

       call system_clock(c1)
       call fzas_mie_st_f77(maxnat,maxlist,nat,rx,ry,rz,iitipo,
     &  fx2o,fy2o,fz2o,eps,sigma,
     &  wxx2o,wxy2o,wxz2o,wyy2o,wyz2o,wzz2o,
     &  rcut,boxx,boxy,boxz,carga,rkappa,uljo,ucoulo,
     &  npares,nblist1,nblist2,nij)
       call system_clock(c2,rate)
       tiempo_f77 = dble(c2-c1)/dble(rate)
 
       call system_clock(c1)
       call fzas_mie_st(maxnat,maxlist,nat,rx,ry,rz,
     &  iitipo,fx2,fy2,fz2,eps,sigma,nij,cmie,uc_mie, 
     &  wxx2,wxy2,wxz2,wyy2,wyz2,wzz2, 
     &  rcut,boxx,boxy,boxz,carga,rkappa,ulj,ucoul, 
     &  npares,nblist1,nblist2)
         call system_clock(c2,rate)
         tiempo_GPU = dble(c2-c1)/dble(rate)

        call escribe_error_fzas(5,nat,tiempo_f77,tiempo_gpu, 
     &   uljo,ulj,ucoulo,ucoul, 
     &   wxx2o,wxx2,wyy2o,wyy2,wzz2o,wzz2, 
     &   fx2o,fy2o,fz2o,fx2,fy2,fz2)

         case(6)

       call system_clock(c1)
        call fzas_fdr_st_f77(maxnat,maxlist,nat,rx,ry,rz,
     &  iitipo,fx2o,fy2o,fz2o,eps,sigma,soft,z1,z2,
     &  wxx2o,wxy2o,wxz2o,wyy2o,wyz2o,wzz2o,
     &  rcut,boxx,boxy,boxz,carga,rkappa,uljo,ucoulo,
     &  npares,nblist1,nblist2)
        call system_clock(c2,rate)
        tiempo_f77 = dble(c2-c1)/dble(rate)

       call system_clock(c1)
       call fzas_fdr_st(maxnat,maxlist,nat,rx,ry,rz, 
     &  iitipo,fx2,fy2,fz2,eps,sigma,soft,z1,z2, 
     &  wxx2,wxy2,wxz2,wyy2,wyz2,wzz2, 
     &  rcut,boxx,boxy,boxz,carga,rkappa,ulj,ucoul, 
     &  npares,nblist1,nblist2)
        call system_clock(c2,rate)
        tiempo_gpu = dble(c2-c1)/dble(rate)

        call escribe_error_fzas(6,nat,tiempo_f77,tiempo_gpu, 
     &   uljo,ulj,ucoulo,ucoul, 
     &   wxx2o,wxx2,wyy2o,wyy2,wzz2o,wzz2, 
     &   fx2o,fy2o,fz2o,fx2,fy2,fz2)

         case(7)

       call system_clock(c1)
        call fzas_lj_st_slater_f77(maxnat,maxlist,nat,
     & rx,ry,rz,iitipo,fx2o,fy2o,fz2o,eps,sigma,lij,
     & wxx2o,wxy2o,wxz2o,wyy2o,wyz2o,wzz2o,
     & rcut,boxx,boxy,boxz,carga,rkappa,
     & uljo,ucoulo,uslatero,npares,nblist1,nblist2)
        call system_clock(c2,rate)
        tiempo_f77 = dble(c2-c1)/dble(rate)

       call system_clock(c1)
       call fzas_lj_st_slater(maxnat,maxlist,nat,rx,ry,rz,
     &        iitipo,fx2,fy2,fz2,eps,sigma,lij,
     &        wxx2,wxy2,wxz2,wyy2,wyz2,wzz2,
     &        rcut,boxx,boxy,boxz,carga,rkappa,
     &        ulj,ucoul,uslater,npares,nblist1,nblist2)

        call system_clock(c2,rate)
        tiempo_gpu = dble(c2-c1)/dble(rate)

        call escribe_error_fzas(6,nat,tiempo_f77,tiempo_gpu, 
     &   uljo,ulj,ucoulo,ucoul, 
     &   wxx2o,wxx2,wyy2o,wyy2,wzz2o,wzz2, 
     &   fx2o,fy2o,fz2o,fx2,fy2,fz2)

        write(6,*) 'Error USlater',uslater-uslatero
        write(iunit_log,*) 'Error Slater', uslater-uslatero

      case default

         write(6,*) 'ERROR: nbfunc no reconocido en fuerzas'
         write(6,*) 'nbfunc = ',nbfunc
         stop

      end select

      do i=1,nat
        fx3(i)=0.0d0
        fy3(i)=0.0d0
        fz3(i)=0.0d0
      enddo
      vkwald = 0.0d0
      vkwaldi = 0.0d0
      wxx3 = 0.0d0
      wyy3 = 0.0d0
      wzz3 = 0.0d0
      vir3 = 0.0d0

      if(recip_ewald) then  !SOLO SI RECIP_EWALD

      write(6,*) 'NAT, NATQ, Ewald ', NAT, NATQ

      CALL INTRA(MAXNAT,MAXMESP,NAT,RX,RY,RZ,CARGA,RKAPPA,
     &    BOXX,BOXY,BOXZ,FXI,FYI,FZI,VKWALDI,
     &    WXXI,WXYI,WXZI,WYYI,WYZI,WZZI,
     &    MESP,NMOL_ESP,NAT_MOL,NMOL)

      ! KWALD en cuda

      call cofm(maxnat,maxmesp,maxnmol,nmol,rx,ry,rz,boxx,boxy,boxz,
     &  mesp,nmol_esp,nat_mol,rrmasa,rxcm,rycm,rzcm,
     &  pxik,pyik,pzik)
       call xyz_cofm(maxnat,maxmesp,maxnmol,mesp,nmol_esp,nat_mol,
     &  rxcm,rycm,rzcm,
     &  pxik,pyik,pzik,rxq,ryq,rzq,boxx,boxy,boxz)

!     call BUILD_CHARGED_ATOMS_EWALD(MAXNAT,NAT,RX,RY,RZ,CARGA,
!    &   NATQ,IQ,RXQ,RYQ,RZQ,CARGAQ)

      CALL KWALD(NAT,VKWALD,RKAPPA,KMAXX,KMAXY,KMAXZ,CARGA,
     &    RXQ,RYQ,RZQ,FXKQ,FYKQ,FZKQ,KVEC,
     &    WXX_KW,WXY_KW,WXZ_KW,WYY_KW,WYZ_KW,WZZ_KW,
     &    BOXX,BOXY,BOXZ)

!     do i=1,nat
!       fx3(i) = 0.0d0
!       fy3(i) = 0.0d0
!       fz3(i) = 0.0d0
!     enddo

!     do iqn = 1,natq
!       ia = iq(iqn)
!       fxk(ia) = fxkq(iqn)
!       fyk(ia) = fykq(iqn)
!       fzk(ia) = fzkq(iqn)
!     enddo

      do i=1,nat
        fx3(i) = fxkq(i) - fxi(i)
        fy3(i) = fykq(i) - fyi(i)
        fz3(i) = fzkq(i) - fzi(i)
      enddo

      write(6,*) 
      write(6,*) 'RESULTADOS TOTALES'
      write(6,*) 'ULJ, UCOUL,ULJ+UCOUL ', ulj,ucoul,ulj+ucoul     
      write(6,*) 'Vkwaldi ', Vkwaldi
      write(6,*) 'Vkwald ', Vkwald
      write(6,*) 'Uslater ', uslater

      vewald = (ucoul+vkwald-vkwaldi)/nmol
      vpot = (ulj+ucoul+uslater+vkwald-vkwaldi)/nmol

      write(*,*)
      write(6,*) 'vewald ',vewald
      write(6,*) 'vpot ',vpot   

      write(*,*)
      write(6,*) ' Viriales '
      write(6,*) 'WXX2 ',wxx2,wyy2,wzz2
      wxx = wxx2 + wxx_kw - wxxi
      wyy = wyy2 + wyy_kw - wyyi
      wzz = wzz2 + wzz_kw - wzzi

      write(6,*) 'wxx ',wxx
      write(6,*) 'wyy ',wyy
      write(6,*) 'wzz ',wzz
      write(*,*) 
      write(6,*) 'Fuerzas sin surf' 
      do i=1,nat
        fx(i) = fx2(i) + fx3(i)
        fy(i) = fy2(i) + fy3(i)
        fz(i) = fz2(i) + fz3(i)
        if(i.le.6) write(*,*) i, fx(i),fy(i),fz(i)
      enddo

      wxx3 = wxx_kw-wxxi
      wyy3 = wyy_kw-wyyi
      wzz3 = wzz_kw-wzzi

      vir3 = wxx3 + wyy3 + wzz3

      endif


      if (nbfunc.eq.7) then
         write(6,*) 'CASE 7: LJ + EWALD REAL + SLATER'
         write(6,*) 'lij(1,1) = ',lij(1,1)
         write(6,*) 'lij(1,2) = ',lij(1,2)
         write(6,*) 'lij(2,2) = ',lij(2,2)
      endif

!      write(6,*) 'NMTS ', nmts
!      write(iunit_log,*) 'NMTS ', nmts

       sumf1 = 0.0d0
       sumf2 = 0.0d0
       sumf3 = 0.0d0
       do i=1,nat
        fx(i) = fx1(i)+nts1*fx2(i)+nts2*fx3(i)
        fy(i) = fy1(i)+nts1*fy2(i)+nts2*fy3(i)
        fz(i) = fz1(i)+nts1*fz2(i)+nts2*fz3(i)
        sumf1 = sumf1+dsqrt(fx1(i)**2+fy1(i)**2+fz1(i)**2)
        sumf2 = sumf2+dsqrt(fx2(i)**2+fy2(i)**2+fz2(i)**2)
        sumf3 = sumf3+dsqrt(fx3(i)**2+fy3(i)**2+fz3(i)**2)
       enddo
       write(6,*) 'SUMF123', sumf1,sumf2,sumf3

       if(usa_lrc) then

         volume=boxx*boxy*boxz

         call lrc_lj_st(volume,coef_lrc_u,coef_lrc_p,ulrc,plrc,
     &        wxx_lrc,wyy_lrc,wzz_lrc)

      endif

      virk = 0.0d0
      do i=1,nat
        virk = virk + rrmasa(i)*(vx(i)*vx(i)+vy(i)*vy(i)+vz(i)*vz(i))
      enddo
      ek = 0.5d0*virk

! temperatura instantanea

      dof = 3.0d0*nat   !solo para moleculas flexibles
      rgas = 8.31446d0
      factor_temp = 1000.0d0/rgas
      tempi = 2.0d0*ek/dof
      tempi = tempi*factor_temp

!convertir p(kJ/mol)/nm^3 --> bares 100/6.023

      factor_pres = 16.605d0

!inicializar variables del barostato y agregar LRC

c=======================================================================
c     AGREGAR CORRECCION A LOS VIRIALES
c=======================================================================

      if(usa_lrc) then
        wxx2 = wxx2 + wxx_lrc
        wyy2 = wyy2 + wyy_lrc
        wzz2 = wzz2 + wzz_lrc
      endif

      vir1 = wxx1 + wyy1 + wzz1
      vir2 = wxx2 + wyy2 + wzz2
      vir3 = wxx3 + wyy3 + wzz3

      pressi = factor_pres*(virk + vir1 + vir2 + vir3)/(3.0d0*vol)

      write(6,*) 'VIR1 .. ', vir1
      write(6,*) 'VIR2 .. ', vir2
      write(6,*) 'VIR3 .. ', vir3
      write(6,*) 'PRESSI ', pressi


!Case A: nbonds=0, recip_ewald=F  !Solo LJ
       if(.not.recip_ewald.and.nbonds.eq.0) then
          nts1 = 1
          nmts = 1
       endif

!Case B: nbonds>0, recip_ewald=F Moleculas flexibles con LJ
       if(.not.recip_ewald.and.nbonds.gt.0) nmts = nts1

!Case C: nbonds>0, recip_ewald=T  Moleculas flexible con LJ + Ewald
       if(nbonds.gt.0.and.recip_ewald) nmts = nts2

!Case D: nbonds=0, recip_ewald=T  Iones con LJ + Ewald
       if(nbonds.eq.0.and.recip_ewald) then
         nmts = nts2
!        nts1 = 1
       endif

       write(6,*) 'VIR1,VIR2,VIR3 ', vir1,vir2,vir3

       if(barostato) then
!      call ini_xis(nat,temp,nch,xi,xidot,qp,tau_p,wnose,ve,evol)

      call ini_xis_system(ncallsx,nchx,nat,nch,
     &  xi,xidot,qp,tau_p,wnose,ve,evol,dof,RT)

      write(6,'("XI",3f12.4)') (xi(i),xidot(i),i=1,nch)

       vol0 = vol
       alfa = 1.0d0+1.0d0/nat
       sum_presion1 = 0.0d0
       sum_presion2 = 0.0d0
       sum_presion3 = 0.0d0

!Case A: nbonds=0, recip_ewald=F

        if(.not.recip_ewald.and.nbonds.eq.0) then
          p1 = 0.0d0
          p2 = p_ext
          p3 = 0.0d0
          nts1 = 1
          nts2 = 0
          nmts = nts1
          write(6,*) 'USA Case A para NPT'
          write(iunit_log,*) 'USA Case A para NPT'
        endif

!Case B: nbonds>0, recip_ewald=F

        if(.not.recip_ewald.and.nbonds.gt.0) then
          nmts = nts1
          p1 = p_ext*nts1/(nmts+1)
          p2 = p_ext/(nmts+1)
          p3 = 0.0d0
          write(6,*) 'USA Case B para NPT'
          write(iunit_log,*) 'USA Case B para NPT'
        endif

!Case C: nbonds>0, recip_ewald=F

        if(nbonds.gt.0.and.recip_ewald) then
          nmts = nts2
          p1 = p_ext*nts1/(nmts+1)
          p2 = p_ext*(nts2-nts1)/(nmts+1)
          p3 = p_ext/(nmts+1)
          write(6,*) 'USA Case C para NPT'
          write(iunit_log,*) 'USA Case C para NPT'
        endif

!Case D: nbonds=0, recip_ewald=T
        if(recip_ewald.and.nbonds.eq.0) then
          nts1 = 1
          nmts = nts2
          p1 = 0.0d0
          p2 = p_ext*nts2/(nmts+1)
          p3 = p_ext/(nmts+1)
          write(6,*) 'USA Case D para NPT'
          write(iunit_log,*) 'USA Case D para NPT'
        endif

!      if(.not.recip_ewald) then
!        p1 = p_ext*nts1/(nts1 + 1)
!        p2 = p_ext/(nts1 + 1)
!        p3 = 0.0d0
!        nts2 = 1
!        nmts = nts1
!       endif

!       write(6,*) 'NMTS, NTS1, NTS2',nmts, nts1, nts2

        sum_pes = p1 + p2 + p3

        write(6,*) 'NMTS,SUM_PES, P_EXT ', nmts,sum_pes, p_ext
        write(iunit_log,*) 'NMTS,SUM_PES, P_EXT ', nmts,sum_pes, p_ext
        if(dabs(sum_pes-p_ext).gt.1.0d-10) then
          write(iunit_log,*) 'P1+P2+P3 no es igual a P_ext',
     &   sum_pes,p_ext
          stop
        endif

        vir1 = wxx1 + wyy1 + wzz1
        vir2 = wxx2 + wyy2 + wzz2 
        vir3 = wxx3 + wyy3 + wzz3

        gu = vir1 + vir2 + vir3 - 3.0d0*p_ext*vol*factorp

        write(6,*) 'GU, vir1,vir2,vir3 ',GU, vir1,vir2,vir3
        write(iunit_log,*) 'GU, vir1,vir2,vir3 ',GU, vir1,vir2,vir3

        virk = 0.0d0
        do i=1,nat
          virk = virk + rrmasa(i)*(vx(i)*vx(i)+vy(i)*vy(i)+vz(i)*vz(i))
        enddo
        eki = 0.5d0*virk

        pressi = (virk + vir1 + vir2 + vir3)/(3.0d0*vol)
        pressi = pressi*factor_pres
      endif

!  ====
      
!     call iniciar_variables(suma_lj,suma_lj2,suma_dens,suma_dens2,
!    & suma_temp,suma_temp2,suma_pres,suma_pres2 )

      enh = 0.0d0

      if(termostato) then
!      call thermo_nh(maxnat,nat,nit,ncalls,
!    &     eta,etadot,q,dtsuz,temp,nch,rrmasa,vx,vy,vz)

       call thermo_nh_system(maxnat,ncallsx,nchx,nat,nit,ncalls,
     &  eta,etadot,q,dtsuz,nch,rrmasa,vx,vy,vz,dof,RT)

       factort = rgas/1000.0d0

!      do n=1,nat
!        do i=1,nch
!         enh = enh + 0.5d0*q(i,n)*etadot(i,n)*etadot(i,n)+
!    & factort*eta(i,n)*temp
!        enddo
!       enh = enh + factort*(3.0d0*temp*eta(1,n)-eta(1,n)*temp)
!      enddo
!     endif

      call energy_thermo_system(maxnat,nchx,nch,eta,
     &  etadot,q,enh,dof,RT)

      endif

      enhb = 0.0d0

      if(barostato) then
        call baros_nh_system(ncallsx,nchx,nit,ncalls,dtsuz,
     & wnose,ve,xi,xidot,qp,nch,RT)

!      call baros_nh(nit,ncalls,dtsuz,wnose,ve,xi,
!    & xidot,temp,qp,nch)

        do i=1,nch
          enhb = enhb+0.5d0*qp(i)*xidot(i)*xidot(i)+factort*xi(i)*temp
        enddo
        enhb = enhb + p_ext*vol*factorp + 0.5d0*wnose*ve*ve

       endif

       ukwald = vkwald-vkwaldi

       epot = vbonds + vangles + vdiedro + ulj15 + ucoul15
     &        + ulj + ucoul + ukwald

      ekin = ek
      ethermo = enh
      ebaro = enhb

      etot = ekin + epot + ethermo + ebaro

      volx = boxx*boxy*boxz
      denom = (volx*1.0d-27)*6.023d23

      densidad = 0.0d0
      do ie=1,mesp
        densidad = densidad +nmol_esp(ie)*rmasa_molar(ie)*1.0d-3/denom
      enddo

      write(6,*) 
      write(6,'("Valores iniciales/nmol ")')
      write(6,'("Vbonds kJ/mol     ", f15.6)') vbonds/nmol
      write(6,'("Vangles kJ/mol    ", f15.6)') vangles/nmol
      write(6,'("Vdiedro kJ/mol    ", f15.6)') vdiedro/nmol
      write(6,'("ULJ15 kJ/mol      ", f15.6)') ulj15/nmol
      write(6,'("UCoul15 kJ/mol    ", f15.6)') ucoul15/nmol
      write(6,'("USlater kJ/mol    ", f15.6)') uslater/nmol
      write(6,'("ULJ kJ/mol        ", f15.6)') ulj/nmol
      write(6,'("UCoul kJ/mol      ", f15.6)') ucoul/nmol
      write(6,'("Ukwald kJ/mol     ", f15.6)') ukwald/nmol
      write(6,'("Ethermo kJ/mol    ", f15.6)')  ethermo/nmol
      write(6,'("Ebaro kJ/mol      ", f15.6)') ebaro/nmol
      write(6,'("Etot kJ/mol       ", f15.6)') etot /nmol
      write(6,'("Densidad kJ/m3    ", f15.6)') densidad
      write(6,'("Temperatura K     ", f15.6)') tempi
      write(6,'("Presion bars      ", f15.6)') pressi
      write(6,*) 
      write(6,*) 'DM para ',nsteps*nmts,' pasos'
      write(6,*) 'Termostato', termostato
      write(6,*) 'Barostato ', barostato        
      write(6,*) '  '

      write(iunit_log,*) 
      write(iunit_log,'("Valores iniciales/nmol ")')
      write(iunit_log,'("Vbonds kJ/mol     ", f15.6)') vbonds/nmol
      write(iunit_log,'("Vangles kJ/mol    ", f15.6)') vangles/nmol
      write(iunit_log,'("Vdiedro kJ/mol    ", f15.6)') vdiedro/nmol
      write(iunit_log,'("ULJ15 kJ/mol      ", f15.6)') ulj15/nmol
      write(iunit_log,'("UCoul15 kJ/mol    ", f15.6)') ucoul15/nmol
      write(iunit_log,'("ULJ kJ/mol        ", f15.6)') ulj/nmol
      write(iunit_log,'("UCoul kJ/mol      ", f15.6)') ucoul/nmol
      write(iunit_log,'("Ukwald kJ/mol     ", f15.6)') ukwald/nmol
      write(iunit_log,'("Ethermo kJ/mol    ", f15.6)')  ethermo/nmol
      write(iunit_log,'("Ebaro kJ/mol      ", f15.6)') ebaro/nmol
      write(iunit_log,'("Etot kJ/mol       ", f15.6)') etot /nmol
      write(iunit_log,'("Densidad kJ/m3    ", f15.6)') densidad
      write(iunit_log,'("Temperatura K     ", f15.6)') tempi
      write(iunit_log,'("Presion bars      ", f15.6)') pressi
      write(iunit_log,*) 
      write(iunit_log,*) 'DM para ',nsteps*nmts,' pasos'
      write(iunit_log,*) 'Termostato', termostato
      write(iunit_log,*) 'Barostato ', barostato        

      call iniciar_variables_gmx(
     & suma_vbonds,suma_vb2,
     & suma_vangles,suma_va2,
     & suma_vdiedro,suma_vd2,
     & suma_ulj15,suma_lj152,
     & suma_ucoul15,suma_c152,
     & suma_ulj,suma_lj2,
     & suma_ucoul,suma_coul2,
     & suma_disp,suma_disp2,
     & suma_ukwald,suma_kw2,
     & suma_epot,suma_epot2,
     & suma_ekin,suma_ekin2,
     & suma_etot,suma_etot2,
     & suma_dens,suma_dens2,
     & suma_temp,suma_temp2,
     & suma_pres,suma_pres2,
     & suma_deltaE,suma_deltaE2)

      fv1=1.0d0
      fv2=1.0d0
      fr1=1.0d0
      fr2=1.0d0

      sum_pxxt = 0.0d0
      sum_pxyt = 0.0d0
      sum_pxzt = 0.0d0
      sum_pyyt = 0.0d0
      sum_pyzt = 0.0d0
      sum_pzzt = 0.0d0

      CALL CPU_TIME(start_time)


      do istep = 1,nsteps  !Inicia DM

! Barostato

        if(barostato) then

!    call baros_nh(nit,ncalls,dtsuz,wnose,ve,xi,xidot,
!    &   temp,qp,nch)

        call baros_nh_system(ncallsx,nchx,nit,ncalls,dtsuz,
     & wnose,ve,xi,xidot,qp,nch,RT)
       endif

! Termostato

      if(termostato) then
!       call thermo_nh(maxnat,nat,nit,ncalls,
!    &  eta,etadot,q,dtsuz,temp,nch,rrmasa,vx,vy,vz)

       call thermo_nh_system(maxnat,ncallsx,nchx,nat,nit,ncalls,
     &  eta,etadot,q,dtsuz,nch,rrmasa,vx,vy,vz,dof,RT)
       endif

      presi_mts = 0.0d0
 
      sum_pxx = 0.0d0
      sum_pxy = 0.0d0
      sum_pxz = 0.0d0
      sum_pyy = 0.0d0
      sum_pyz = 0.0d0
      sum_pzz = 0.0d0

      do k=1,nmts   !inicia MTS

      if(barostato) then
        virk = 0.0d0
        do i=1,nat
          virk = virk + rrmasa(i)*(vx(i)*vx(i)+vy(i)*vy(i)+vz(i)*vz(i))
        enddo

!       gu = vir1 + vir2 + vir3 - 3.0d0*p_ext*vol*factorp
!       write(6,*) 'GU k',k,gu 

        ge = alfa*virk + gu
        ve = ve + 0.5d0*ge*dt/wnose

!        write(6,*) 'virk,ge,gu,ve ',virk,ge,gu,ve 

        call factores(alfa,dt,ve,fv1,fv2,fr1,fr2)
      endif

!     vx(dt/2) usando fx(t)

        do i=1,nat
           vx(i) = fv1*vx(i) + 0.5d0*fv2*dt*fx(i)/rrmasa(i)
           vy(i) = fv1*vy(i) + 0.5d0*fv2*dt*fy(i)/rrmasa(i)
           vz(i) = fv1*vz(i) + 0.5d0*fv2*dt*fz(i)/rrmasa(i)
         enddo

!     rx(t+dt) usando v(dt/2)

        do i=1,nat
           rx(i) = fr1*rx(i) + fr2*dt*vx(i)
           ry(i) = fr1*ry(i) + fr2*dt*vy(i)
           rz(i) = fr1*rz(i) + fr2*dt*vz(i)
         enddo

!  NPT  Isotropico ====

      if(barostato) then
        evol = evol + dt*ve

        vol = vol0*dexp(3.0d0*evol)

        boxx = vol**(1.0d0/3.0d0)
        boxy = boxx
        boxz = boxx

!       write(6,*) 'vol, boxx ',vol,boxx

        if(rcut.gt.0.5d0*boxx) then
         write(6,*) 'Rcut > Lx/2', rcut, boxx/2.0d0,evol
         write(iunit_log,*) 'Rcut > Lx/2', rcut, boxx/2.0d0,evol
         stop
        endif
      endif


c=======================================================================
c     ACTUALIZAR LRC CUANDO CAMBIA EL VOLUMEN EN NPT
c=======================================================================

      if (usa_lrc) then

        volume = boxx*boxy*boxz

       call lrc_lj_st(volume,
     &        coef_lrc_u,coef_lrc_p,
     &        ulrc,plrc,
     &        wxx_lrc,wyy_lrc,wzz_lrc)

      endif

!   Condiciones priodicias 

        do i=1,nat
          rx(i) = rx(i) - dnint(rx(i)/boxx)*boxx
          ry(i) = ry(i) - dnint(ry(i)/boxy)*boxy
          rz(i) = rz(i) - dnint(rz(i)/boxz)*boxz
        enddo

! Lista de vecinos

      call check(maxnat,nat,rx,ry,rz,rxup,ryup,rzup,
     & rlist,rcut,updatel,boxx,boxy,boxz)

      if(updatel) then
        call lista(maxnat,maxlist,nat,rx,ry,rz,boxx,boxy,boxz,
     &   nblist1,nblist2,npares,rlist,inicio_mol)
         nupdate = nupdate + 1
         call save(maxnat,nat,rx,ry,rz,rxup,ryup,rzup)
!        write(6,*) 'Entro a lista',nupdate
       endif

      call fzas_de(maxnat,nat,rx,ry,rz,ibonds,bonds,nbonds,
     & vbonds,fx1,fy1,fz1,wxx1,wxy1,wxz1,wyy1,wyz1,wzz1,
     & boxx,boxy,boxz)

      call fzas_angulo(maxnat,nat,rx,ry,rz,boxx,boxy,boxz,
     & iangles,angles,nangles,fx1,fy1,fz1,vangles,
     & wxx1,wxy1,wxz1,wyy1,wyz1,wzz1)

       call fzas_diedro(maxnat,nat,ndiedro,idiedro,diedro,
     &  rx,ry,rz,fx1,fy1,fz1,boxx,boxy,boxz,
     &  wxx1,wxy1,wxz1,wyy1,wyz1,wzz1,vdiedro)

       call fzas_15(maxnat,rx,ry,rz,fx1,fy1,fz1,sigma,eps,carga,
     &  rkappa,wxx1,wxy1,wxz1,wyy1,wyz1,wzz1,n15,i15,iitipo,
     &  boxx,boxy,boxz,ulj15,ucoul15,rcut)

       do ii=1,nat
        fx(ii) = fx1(ii)
        fy(ii) = fy1(ii)
        fz(ii) = fz1(ii)
       enddo

      vir1 = wxx1 + wyy1 + wzz1

!     write(6,*) 'VIR1 ', vir1

      if(barostato) then
        g1 = vir1  - 3.0d0*p1*vol*factorp
        gu = g1
       endif
       
!      write(6,*) 'Knts1,nts2, ',nts1,nts2,k,vbonds,vangles,vdiedro

      if(mod(k,nts1).eq.0) then

c=======================================================================
c     Seleccion del potencial intermolecular
c=======================================================================

      select case(nbfunc)

      case(1)

c        Lennard-Jones shifted-force

       call fzas_lj_sf(maxnat,maxlist,rx,ry,rz,iitipo,
     &  fx2,fy2,fz2,
     &  eps,sigma,uc_lj,duc_lj,
     &  wxx2,wxy2,wxz2,wyy2,wyz2,wzz2,
     &  rcut,boxx,boxy,boxz,carga,rkappa,coulrc,
     &  ulj,ucoul,
     &  npares,nblist1,nblist2)

!        write(6,*) 'Entra a fzas_lj_coul1'

      case(2)

c        Mie shifted-force

       call fzas_mie_sf(maxnat,maxlist,nat,rx,ry,rz,iitipo,
     &  fx2,fy2,fz2,
     &  eps,sigma,nij,cmie,uc_mie,duc_mie,
     &  wxx2,wxy2,wxz2,wyy2,wyz2,wzz2,
     &  rcut,boxx,boxy,boxz,carga,rkappa,coulrc,
     &  ulj,ucoul,
     &  npares,nblist1,nblist2)

!        write(6,*) 'Entra a fzas_sfmie'
      case(3)

c        FDR shifted-force

       call fzas_fdr_sf(maxnat,maxlist,nat,rx,ry,rz,iitipo,
     &  fx2,fy2,fz2,
     &  eps,sigma,wxx2,wxy2,wxz2,wyy2,wyz2,wzz2,
     &  rcut,boxx,boxy,boxz,carga,rkappa,ulj,ucoul,
     &  npares,nblist1,nblist2,soft)

!        write(6,*) 'Entra a fzas_fdr_sf'

      case(4)

c        Lennard-Jones truncado ST

         call fzas_lj_st(maxnat,maxlist,nat,rx,ry,rz,iitipo,
     &        fx2,fy2,fz2,
     &        eps,sigma,wxx2,wxy2,wxz2,
     &        wyy2,wyz2,wzz2,
     &        rcut,boxx,boxy,boxz,carga,rkappa,
     &        ulj,ucoul,npares,nblist1,nblist2)
!        write(6,*) 'Entra a fzas_lj_st '

      case(5)

c        Mie truncado ST   

       call fzas_mie_st(maxnat,maxlist,nat,rx,ry,rz,
     &  iitipo,fx2,fy2,fz2,eps,sigma,nij,cmie,uc_mie, 
     &  wxx2,wxy2,wxz2,wyy2,wyz2,wzz2, 
     &  rcut,boxx,boxy,boxz,carga,rkappa,ulj,ucoul, 
     &  npares,nblist1,nblist2)

!      write(6,*) 'Salgo de fzas MIE ST'

       case(6)

       call fzas_fdr_st(maxnat,maxlist,nat,rx,ry,rz, 
     &  iitipo,fx2,fy2,fz2,eps,sigma,soft,z1,z2, 
     &  wxx2,wxy2,wxz2,wyy2,wyz2,wzz2, 
     &  rcut,boxx,boxy,boxz,carga,rkappa,ulj,ucoul, 
     &  npares,nblist1,nblist2)

       case(7)

       call fzas_lj_st_slater(maxnat,maxlist,nat,rx,ry,rz,
     &        iitipo,fx2,fy2,fz2,eps,sigma,lij,
     &        wxx2,wxy2,wxz2,wyy2,wyz2,wzz2,
     &        rcut,boxx,boxy,boxz,carga,rkappa,
     &        ulj,ucoul,uslater,npares,nblist1,nblist2)

      case default

         write(6,*) 'ERROR: nbfunc no reconocido en fuerzas'
         write(6,*) 'nbfunc = ',nbfunc
         write(iunit_log,*) 'ERROR: nbfunc no reconocido en fuerzas'
         write(iunit_log,*) 'nbfunc = ',nbfunc
         stop

      end select

      do ii=1,nat
       fx(ii) = fx1(ii) + nts1*fx2(ii)
       fy(ii) = fy1(ii) + nts1*fy2(ii)
       fz(ii) = fz1(ii) + nts1*fz2(ii)
      enddo

c=======================================================================
c     AGREGAR CORRECCION A LOS VIRIALES
c=======================================================================

      if (usa_lrc) then

        volume = boxx*boxy*boxz

       call lrc_lj_st(volume,
     &        coef_lrc_u,coef_lrc_p,
     &        ulrc,plrc,
     &        wxx_lrc,wyy_lrc,wzz_lrc)

        wxx2 = wxx2 + wxx_lrc
        wyy2 = wyy2 + wyy_lrc
        wzz2 = wzz2 + wzz_lrc

      endif

       vir2 = wxx2 + wyy2 + wzz2

       if(barostato) then
         g2 = vir2 - 3.0d0*p2*vol*factorp
         gu = g1 + nts1*g2
       endif

!      write(6,*) 'K ulj,ucoul ',k,ulj,ucoul

      endif  !end nts1

!     if(nts2.eq.0) nts2 = 1
      if(mod(k,nts2).eq.0) then

       if(recip_ewald) then


        CALL INTRA(MAXNAT,MAXMESP,NAT,RX,RY,RZ,CARGA,RKAPPA,
     &    BOXX,BOXY,BOXZ,FXI,FYI,FZI,VKWALDI,
     &    WXXI,WXYI,WXZI,WYYI,WYZI,WZZI,
     &    MESP,NMOL_ESP,NAT_MOL,NMOL)

      call cofm(maxnat,maxmesp,maxnmol,nmol,rx,ry,rz,boxx,boxy,boxz,
     &  mesp,nmol_esp,nat_mol,rrmasa,rxcm,rycm,rzcm,
     &  pxik,pyik,pzik)
       call xyz_cofm(maxnat,maxmesp,maxnmol,mesp,nmol_esp,nat_mol,
     &  rxcm,rycm,rzcm,
     &  pxik,pyik,pzik,rxq,ryq,rzq,boxx,boxy,boxz)

!     call BUILD_CHARGED_ATOMS_EWALD(MAXNAT,NAT,RX,RY,RZ,CARGA,
!    &   NATQ,IQ,RXQ,RYQ,RZQ,CARGAQ)

! Checar las coordenadas de las tomos cargados, xyz_cofm son para todos
! los atomos. Funciona para el agua pero no para moleculas con atomos
! sin carga

       CALL KWALD(NAT,VKWALD,RKAPPA,KMAXX,KMAXY,KMAXZ,CARGA,
     &    RXQ,RYQ,RZQ,FXKQ,FYKQ,FZKQ,KVEC,
     &    WXX_KW,WXY_KW,WXZ_KW,WYY_KW,WYZ_KW,WZZ_KW,
     &    BOXX,BOXY,BOXZ)

!       do i=1,nat
!         fx3(i) = 0.0d0
!         fy3(i) = 0.0d0
!         fz3(i) = 0.0d0
!       enddo

!       do iqn = 1,natq
!         ia = iq(iqn)
!         fxk(ia) = fxkq(iqn)
!         fyk(ia) = fykq(iqn)
!         fzk(ia) = fzkq(iqn)
!       enddo

        do i=1,nat
          fx3(i) = fxkq(i)-fxi(i)
          fy3(i) = fykq(i)-fyi(i)
          fz3(i) = fzkq(i)-fzi(i)
        enddo

        wxx3 = wxx_kw - wxxi
        wxy3 = wxy_kw - wxyi
        wxz3 = wxz_kw - wxzi
        wyy3 = wyy_kw - wyyi
        wyz3 = wyz_kw - wyzi
        wzz3 = wzz_kw - wzzi

        vir3 = wxx3 + wyy3 + wzz3

      endif

      do ii=1,nat
       fx(ii) = fx1(ii) + nts1*fx2(ii) + nts2*fx3(ii)
       fy(ii) = fy1(ii) + nts1*fy2(ii) + nts2*fy3(ii)
       fz(ii) = fz1(ii) + nts1*fz2(ii) + nts2*fz3(ii)
      enddo

       vir3 = wxx3 + wyy3 + wzz3

       if(barostato) then
         g3 = vir3 - 3.0d0*p3*vol*factorp
         gu = g1 + nts1*g2 + nts2*g3
       endif

!      write(6,*) 'K vkwald,vir3 ',k,vkwald,vir3    

       endif  !end nts2

!     vx(t+dt) usando Fx(t+dt)

      do i=1,nat
         vx(i) = fv1*vx(i) + 0.5d0*fv2*dt*fx(i)/rrmasa(i)
         vy(i) = fv1*vy(i) + 0.5d0*fv2*dt*fy(i)/rrmasa(i)
         vz(i) = fv1*vz(i) + 0.5d0*fv2*dt*fz(i)/rrmasa(i)
      enddo

      if(barostato) then
       virk = 0.0d0
       do i=1,nat
        virk = virk + rrmasa(i)*(vx(i)*vx(i)+vy(i)*vy(i)+vz(i)*vz(i))
       enddo

       vir1 = wxx1 + wyy1 + wzz1
       vir2 = wxx2 + wyy2 + wzz2
       vir3 = wxx3 + wyy3 + wzz3

       ge = alfa*virk + gu

       ve = ve + 0.5d0*ge*dt/wnose

       presi_mts = presi_mts + (virk+vir1+vir2)/(3.0d0*vol)

!      write(6,*) 'g1+g2, gu ',g1+g2, gu
!      write(6,*) 'GE, VE, virk', ge, ve,virk,vir1+vir2

      endif

       presi_mts = presi_mts + (virk+vir1+vir2+vir3)

       wxxv = 0.0d0
       wxyv = 0.0d0
       wxzv = 0.0d0
       wyyv = 0.0d0
       wyzv = 0.0d0
       wzzv = 0.0d0

       do i=1,nat
        wxxv = wxxv + rrmasa(i)*vx(i)*vx(i)
        wxyv = wxyv + rrmasa(i)*vx(i)*vy(i)
        wxzv = wxzv + rrmasa(i)*vx(i)*vz(i)
        wyyv = wyyv + rrmasa(i)*vy(i)*vy(i)
        wyzv = wyzv + rrmasa(i)*vy(i)*vz(i)
        wzzv = wzzv + rrmasa(i)*vz(i)*vz(i)
       enddo

       sum_pxx = sum_pxx + (wxxv +wxx1 + wxx2 + wxx3)
       sum_pxy = sum_pxy + (wxyv +wxy1 + wxy2 + wxy3)
       sum_pxz = sum_pxz + (wxzv +wxz1 + wxz2 + wxz3)
       sum_pyy = sum_pyy + (wyyv +wyy1 + wyy2 + wyy3)
       sum_pyz = sum_pyz + (wyzv +wyz1 + wyz2 + wyz3)
       sum_pzz = sum_pzz + (wzzv +wzz1 + wzz2 + wzz3)

       pxxi = (wxxv +wxx1 + wxx2 + wxx3)
       pxyi = (wxyv +wxy1 + wxy2 + wxy3)
       pxzi = (wxzv +wxz1 + wxz2 + wxz3)
       pyyi = (wyyv +wyy1 + wyy2 + wyy3)
       pyzi = (wyzv +wyz1 + wyz2 + wyz3)
       pzzi = (wzzv +wzz1 + wzz2 + wzz3)

      enddo  !End MTS

!     write(6,*) 'factor_pres,vol,nmts ',factor_pres,vol,nmts

!     stop

      factor = factor_pres/(vol*nmts)

      presi_mts = factor*presi_mts/3.0d0   ! en bares

      pxx = factor*sum_pxx
      pxy = factor*sum_pxy
      pxz = factor*sum_pxz
      pyy = factor*sum_pyy
      pyz = factor*sum_pyz
      pzz = factor*sum_pzz

      sum_pxxt = sum_pxxt + pxx
      sum_pxyt = sum_pxyt + pxy
      sum_pxzt = sum_pxzt + pxz
      sum_pyyt = sum_pyyt + pyy
      sum_pyzt = sum_pyzt + pyz
      sum_pzzt = sum_pzzt + pzz

      rgas = 8.31446d0

      enh = 0.0d0

      if(termostato) then
!      call thermo_nh(maxnat,nat,nit,ncalls,
!    &     eta,etadot,q,dtsuz,temp,nch,rrmasa,vx,vy,vz)

       call thermo_nh_system(maxnat,ncallsx,nchx,nat,nit,ncalls,
     &  eta,etadot,q,dtsuz,nch,rrmasa,vx,vy,vz,dof,RT)

       call energy_thermo_system(maxnat,nchx,nch,eta,
     &  etadot,q,enh,dof,RT)

       factort = rgas/1000.0d0

!      do n=1,nat
!       do i=1,nch
!         enh = enh + 0.5d0*q(i,n)*etadot(i,n)*etadot(i,n)+
!    & factort*eta(i,n)*temp
!       enddo
!       enh = enh + factort*(3.0d0*temp*eta(1,n)-eta(1,n)*temp)
!      enddo

      endif

      virk = 0.0d0
      do i=1,nat
        virk = virk + rrmasa(i)*(vx(i)*vx(i)+vy(i)*vy(i)+vz(i)*vz(i))
      enddo
      ek = 0.5d0*virk

      enhb = 0.0d0

      if(barostato) then
        call baros_nh_system(ncallsx,nchx,nit,ncalls,dtsuz,
     & wnose,ve,xi,xidot,qp,nch,RT)

!      call baros_nh(nit,ncalls,dtsuz,wnose,ve,xi,
!    & xidot,temp,qp,nch)

        do i=1,nch
          enhb = enhb+0.5d0*qp(i)*xidot(i)*xidot(i)+factort*xi(i)*temp
        enddo
        enhb = enhb + p_ext*vol*factorp + 0.5d0*wnose*ve*ve

        presion1 = (alfa*virk+vir1)/(3.0d0*vol)
        presion2 = vir2/(3.0d0*vol)
        presion3 = vir3/(3.0d0*vol)
        sum_presion1 = sum_presion1 + presion1
        sum_presion2 = sum_presion2 + presion2
        sum_presion3 = sum_presion3 + presion3
      endif

! temperatura instantanea

         dof = 3.0d0*nat   !solo para moleculas flexibles
         rgas = 8.31446d0
         factor_temp = 1000.0d0/rgas
         tempi = 2.0d0*ek/dof
         tempi = tempi*factor_temp

!        write(58,*) istep,tempi

!convertir p(kJ/mol)/nm^3 --> bares 100/6.023
         factor_pres = 16.605d0
         presi = (pxx+pyy+pzz)/3.0d0    

!        write(*,*)
!        write(6,*) 'ULJ, UCOUL 2', ULJ, UCOUL
!        write(6,*) 'vkwald, vkwaldi 2 ', vkwald,vkwaldi
!        write(*,*)

         ek = ek/nmol
         vbonds = vbonds/nmol
         vangles = vangles/nmol
         vdiedro = vdiedro/nmol
         ulj15 = ulj15/nmol
         ucoul15 = ucoul15/nmol

c=======================================================================
c     AGREGAR CORRECCION A LA ENERGIA
c=======================================================================

      if(usa_lrc) then

          ulj = ulj + ulrc

      endif

         ulj = ulj/nmol
         ucoul = ucoul/nmol
         uslater = uslater/nmol

         ukwald = (vkwald-vkwaldi)/nmol

         enh = enh/nmol
         enhb = enhb/nmol

!        write(6,*) 'vkwald ', vkwald/nmol
!        write(6,*) 'vkwaldi ', vkwaldi/nmol

         vintra = vbonds+vangles+vdiedro
         vinter = ulj15+ucoul15+ulj+ucoul+uslater+ukwald

         ep = vintra + vinter

!     write(6,*) 'presi, ulj, ucoul ', presi, ulj, ucoul
!     write(6,*) 'enh,enhb ', enh,enhb
         
! Constante de movimiento

         et = ek + ep + enh + enhb

         ekin = ek
         epot = ep
         etot = et

         if(istep.eq.1) et0 = et

         deltaE = dabs((et-et0)/et0)
          
!  Calcular la densidad en kg/m^3

        volx = boxx*boxy*boxz
        denom = (volx*1.0d-27)*6.023d23

        densx = 0.0d0
        do ie=1,mesp
          densx = densx +nmol_esp(ie)*rmasa_molar(ie)*1.0d-3/denom
        enddo

!      write(6,*) 'densx ', densx  

!       call sumas(suma_lj,suma_lj2,ulj,suma_dens,suma_dens2,densx,
!    & suma_temp,suma_temp2,tempi,suma_pres,suma_pres2,presi)

       call sumas_gmx(
     & suma_vbonds,suma_vb2,vbonds,
     & suma_vangles,suma_va2,vangles,
     & suma_vdiedro,suma_vd2,vdiedro,
     & suma_ulj15,suma_lj152,ulj15,
     & suma_ucoul15,suma_c152,ucoul15,
     & suma_ulj,suma_lj2,ulj,
     & suma_ucoul,suma_coul2,ucoul,
     & suma_disp,suma_disp2,udisp,
     & suma_ukwald,suma_kw2,ukwald,
     & suma_epot,suma_epot2,epot,
     & suma_ekin,suma_ekin2,ekin,
     & suma_etot,suma_etot2,etot,
     & suma_dens,suma_dens2,densx,
     & suma_temp,suma_temp2,tempi,
     & suma_pres,suma_pres2,presi,
     & suma_deltaE,suma_deltaE2,deltaE)

        if(mod(istep,nstlog).eq.0) then

         av_nupdate= real(istep)/nupdate

         write(iunit_log,*) ' '
         write(iunit_log,'(" istep ",i10,"  time(ps)  ",f15.4)')  
     &    istep*nmts,dble(istep)*dt*nmts 
         write(6,'(" istep ",i10,"  time(ps)  ",f15.4)')  
     &    istep*nmts,dble(istep)*dt*nmts 
         write(iunit_log,*) ' '
         write(iunit_log,*) ' vbonds,vangles,vdiedro,ulj15,ucoul15,ulj,
     &ucoul,ukwald kJ/mol'
         write(6,*) ' vbonds,vangles,vdiedro,ulj15,ucoul15,ulj,
     &ucoul,ukwald kJ/mol'
         write(iunit_log,10) vbonds,vangles,vdiedro,ulj15,ucoul15,
     &    ulj,ucoul,ukwald
         write(6,10) vbonds,vangles,vdiedro,ulj15,ucoul15,
     &    ulj,ucoul,ukwald
         write(iunit_log,*) 'ecinet,epot,ethermo,ebaros,etotal,deltaE
     & (kJ/mol)'
        write(iunit_log,13) ek,ep,enh,enhb,et,deltaE
         write(iunit_log,*) 'boxx(nm),tempi(K),presi(bars),dens(kg/m3),
     & nupdate'
        write(iunit_log,66) boxx,tempi,presi,densx,av_nupdate
         write(6,*) 'boxx(nm),tempi(K),presi(bars),dens(kg/m3),
     & nupdate'
        write(6,66) boxx,tempi,presi,densx,av_nupdate

         if(usa_lrc) write(iunit_log,'("ulrc(kJ/mol),
     &   plrc(bars)",2f12.5)') ulrc/nmol, plrc

         write(6,'("USLATER",f12.4)')  uslater
         write(iunit_log,'("USLATER",f12.4)')  uslater

!        write(10,'(i10,f12.4)') istep,ek
!        write(15,'(i10,f12.4)') istep,ep
!        write(18,'(i10,f12.4)') istep,ek+ep
!        write(17,'(i10,f12.4)') istep,enh
!        write(19,'(i10,f12.4)') istep,enhb
!        write(20,'(i10,f12.4)') istep,et
!        write(25,*) istep,tempi
!        write(30,*) istep,presi
         write(35,'(i10,f13.8)') istep,deltaE
!        write(33,'(i10,6f15.6)') istep,pxx,pxy,pxz,pyy,pyz,pzz
         
!        write(29,*) istep,densx
!        write(6,*) '  '

        endif

!       if(mod(istep,npab).eq.0) then 
!        write(45,'(i10,5f15.6)') istep,tempi,vol,pxy,pxz,pyz
!       endif

10     format(8f12.5)
13     format(5f12.5,f12.7)
16     format(5f12.5,i12,i6)
66     format(5f12.5)

! Variables sugeridas:
!
! istep       paso de integración
! time_ps     tiempo en ps
! vbonds      energía de enlaces
! vangles     energía de ángulos
! vdiedro     energía de diedros
! ulj15       LJ intramolecular 1-5 o exclusiones usadas
! ucoul15     Coulomb intramolecular 1-5 o exclusiones usadas
! ulj         energía LJ intermolecular
! ucoul       Coulomb real
! ukw         energía recíproca de Ewald/SPME
! ekin        energía cinética
! epot        energía potencial total
! ethermo     energía del termostato
! ebaro       energía del barostato
! etot        energía conservada extendida
! pxx...pzz   tensor de presión en bar
! boxx...boxz longitudes de caja en nm
! volume      volumen en nm^3
! density     densidad en kg/m^3
! temperature temperatura instantánea en K
! pressure    presión escalar en bar
!
! Cálculos recomendados:
!
! volume  = boxx*boxy*boxz
!
! epot = vbonds + vangles + vdiedro + ulj15 + ucoul15
!    & + ulj + ucoul + ukw
!
! etot = ekin + epot + ethermo + ebaro
!
! pressure = (pxx + pyy + pzz)/3.0d0
!
! Para densidad:
!
! density = masa_total_kg/volume_m3
!
! Si la masa total está en g/mol:
!
! density = (masa_total_gmol*1.0d-3/NA)
!    &      /(volume*1.0d-27)
!
!---------------------------------------------------------------

       if(mod(istep,nstenergy).eq.0) then

         time_ps = dble(istep)*dt*nmts
         volume = boxx*boxy*boxz

         epot = vbonds + vangles + vdiedro
     &        + ulj15 + ucoul15
     &        + ulj + ucoul + ukwald

         ethermo = enh

       enhx = 0.0d0
       do n=1,nat
        do i=1,nch
          enhx = enhx + 0.5d0*q(i,n)*etadot(i,n)*etadot(i,n)+
     & factort*eta(i,n)*temp
        enddo
        enhx = enhx + factort*(3.0d0*temp*eta(1,n)-eta(1,n)*temp)
       enddo
       enhx = enhx/nmol
       
       eta_max=0.0d0
       etadot_max= 0.0d0
       do n=1,nat
        do i=1,nch
         eta_max=dmax1(dabs(eta(i,n)),eta_max)
         etadot_max=dmax1(dabs(etadot(i,n)),etadot_max)
        enddo
       enddo

         if(dabs(enhx).ge.100.0) then
           write(iunit_log,*) 'Ethermo >  500.0',enhx   

           do n=1,nat
       if(n.le.6)write(6,'(i6,6f12.4)') n,(eta(i,n),etadot(i,n),i=1,nch)
           enddo

           write(6,*) 'eta_max, etadot_max', eta_max, etadot_max

          stop
         endif

         ebaro = enhb
         ekin = ek
         temperature = tempi

         etot = ekin + epot + ethermo + ebaro

         pressure = (pxx + pyy + pzz)/3.0d0

         density = densx

         write(iunit_energy,1000)
     &        istep,time_ps,
     &        vbonds,vangles,vdiedro,
     &        ulj15,ucoul15,ulj,ucoul,ukwald,
     &        ekin,epot,ethermo,ebaro,etot,
     &        pxx,pxy,pxz,pyy,pyz,pzz,
     &        boxx,boxy,boxz,volume,
     &        density,temperature,pressure

         call flush(iunit_energy)

      endif

 1000 format(i12,1x,27(es24.15,1x))

        if(mod(istep,nstxout).eq.0) then
          iistep = istep*nmts 
! Para unir atomos en las moleculas
          call shift_cofm(maxnat,nat,rrmasa,rz)
        call cofm(maxnat,maxmesp,maxnmol,nmol,rx,ry,rz,boxx,boxy,boxz,
     &  mesp,nmol_esp,nat_mol,rrmasa,rxcm,rycm,rzcm,
     &  pxik,pyik,pzik)
         call xyz_cofm(maxnat,maxmesp,maxnmol,mesp,nmol_esp,nat_mol,
     &  rxcm,rycm,rzcm,
     &  pxik,pyik,pzik,rxa,rya,rza,boxx,boxy,boxz)

!       call gro(maxnat,nat,rxa,rya,rza,boxx,boxy,boxz,symbol2,
!    &   resid_name,vx,vy,vz,iistep,dt)

        time_ps = dble(istep)*dt*nmts
        call gro_write(maxnat,nat,rxa,rya,rza,boxx,boxy,boxz,
     &        symbol2,vx,vy,vz,istep,time_ps)
        endif

        if(istep.eq.nsteps) then
         call grof(maxnat,nat,rxa,rya,rza,boxx,boxy,boxz,symbol2,
     &   resid_name,vx,vy,vz,istep)
        endif

      enddo    !fin de DM


      write(6,*) '  '
      CALL CPU_TIME(end_time)
      PRINT *, "CPU Time taken: ", end_time - start_time, " seconds"
      CALL DATE_AND_TIME(current_date, current_time, time_zone,
     & datetime_values)
        
      Print *, "Day: ",datetime_values(3), "Month:",datetime_values(2),
     &"Year:",datetime_values(1)
      Print *, "Hora: ", datetime_values(6),"Minutos",
     & datetime_values(7), "Segundos ", datetime_values(8)
      write(6,*) '  '

!     call promedios(nsteps,suma_lj,suma_lj2,suma_dens,suma_dens2,
!    &  suma_temp,suma_temp2,suma_pres,suma_pres2)

       call promedios_gmx(
     & nsteps,
     & suma_vbonds,suma_vb2,
     & suma_vangles,suma_va2,
     & suma_vdiedro,suma_vd2,
     & suma_ulj15,suma_lj152,
     & suma_ucoul15,suma_c152,
     & suma_ulj,suma_lj2,
     & suma_ucoul,suma_coul2,
     & suma_disp,suma_disp2,
     & suma_ukwald,suma_kw2,
     & suma_epot,suma_epot2,
     & suma_ekin,suma_ekin2,
     & suma_etot,suma_etot2,
     & suma_dens,suma_dens2,
     & suma_temp,suma_temp2,
     & suma_pres,suma_pres2,
     & suma_deltaE,suma_deltaE2)

      prom_pxxt = sum_pxxt/nsteps
      prom_pxyt = sum_pxyt/nsteps
      prom_pxzt = sum_pxzt/nsteps
      prom_pyyt = sum_pyyt/nsteps
      prom_pyzt = sum_pyzt/nsteps
      prom_pzzt = sum_pzzt/nsteps

      write(6,*) '  '
      write(6,*) 'Promedios componentes presion'
      write(6,'("<PXX> ",f12.4)') prom_pxxt
      write(6,'("<PXY> ",f12.4)') prom_pxyt
      write(6,'("<PXZ> ",f12.4)') prom_pxzt
      write(6,'("<PYY> ",f12.4)') prom_pyyt
      write(6,'("<PYZ> ",f12.4)') prom_pyzt
      write(6,'("<PZZ> ",f12.4)') prom_pzzt
      write(6,*) '  '

      write(iunit_log,*) '  '
      write(iunit_log,*) 'Promedios componentes presion'
      write(iunit_log,'("<PXX> ",f12.4)') prom_pxxt
      write(iunit_log,'("<PXY> ",f12.4)') prom_pxyt
      write(iunit_log,'("<PXZ> ",f12.4)') prom_pxzt
      write(iunit_log,'("<PYY> ",f12.4)') prom_pyyt
      write(iunit_log,'("<PYZ> ",f12.4)') prom_pyzt
      write(iunit_log,'("<PZZ> ",f12.4)') prom_pzzt
      write(iunit_log,*) '  '

      if(barostato) then
        prom_presion1 = sum_presion1/nsteps
        prom_presion2 = sum_presion2/nsteps
        write(6,*) 'prom_presion1 ',prom_presion1
        write(6,*) 'prom_presion2 ',prom_presion2
        write(6,*) 'presion1+presion2 ',prom_presion1+prom_presion2
        write(6,*) '  '
      endif

c=======================================================================
c     Cerrar archivos de salida de la corrida
c=======================================================================

      flush(iunit_energy)
      close(iunit_energy)

      flush(iunit_log)
      close(iunit_log)
      write(6,*) '   '
      write(6,*) 'Archivos de salida. Se pueden graficar con xmgrace'
      write(6,*) '   '
      write(6,*) "energia_cinetica.dat"
      write(6,*) "energia_potencial.dat"
      write(6,*) "energia_total_sistema.dat"
      write(6,*) "energia_termostato.dat"
      write(6,*) "energia_barostato.dat"
      write(6,*) "energia_total.dat"
      write(6,*) "temperatura.dat"
      write(6,*) "presion.dat"
      write(6,*) "densidad.dat"
      write(6,*) "movie.gro para VMD"

      stop
      end

