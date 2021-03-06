      SUBROUTINE dlsumf2in3(LMAX,KAPPA,AK,DLM) 
C--------/---------/---------/---------/---------/---------/---------/--
C     CALCULATES NON-ZERO ELEMENTS OF THE ARRAY DLM 
C     I.E., FOR L+M EVEN. VALUES AS DEFINED BY KAMBE.
C                     DLM=DLM1+DLM2+DLM3,
C     WITH LM=(00),(1-1),(11),(2-2)...  
C     THE PROGRAM ASSUMES THAT THE LAYER IS A BRAVAIS LATTICE. THE 
C     SUMMATION OVER THE LATTICE FOLLOWS THE EWALD METHOD SUGGESTED BY 
C     KAMBE.
C 
C     LMAXD       : INTERNAL CUTOFF IN SPHERICAL WAVES EXPANSIONS  
C     LMAX        : THE ACTUAL CUTOFF IN SPHERICAL WAVES EXPANSIONS 
C     AK          : the Bloch vector PARALLEL 
C                   TO THE SURFACE, REDUCED TO THE 1ST BRILLOUIN ZONE
!
!     ALPHA ... dynamically assigned Ewald parameter
!     XPM(M) CONTAINS VALUES OF XPK**|M|=e^(i*|m|*\phi)
!     AGK(I) CONTAINS VALUES OF (AC/KAPPA)**I
!     GKN(N) CONTAINS VALUES OF (GP/KAPPA)**(2*N-1)*GAM(N,Z)
!     DENOM(K)=1.0D0/(FAC(I1)*FAC(I2)*FAC(I3)) 
!                where I1=I, I2=NN-I+1, I3=NN+M-I 
!                not the same as denom1(iden) in dlmsf2in3!!!
!
!   The number of summation shells in the Kambe summation
!   is limited by summation loop variable N1 to <=10.
!   Yet it exits summation once convergence bounds are satisfied.
!   The measure of convergence is taken to be the usual vector norm
!                   \sum_I |DLM(I))|**2
!  The measure of convergence is controlled by parameters QP and QT
!  The summation is enforced to run over at least IENF shells  
!
!     EMACH/1.D-8/ IS AN OLD MACHINE ACCURACY - TODO
!     PI/3.14159265358979D0 - TODO
!     AN,AN1,AN2 cuold be integers  - TODO
!     Check obsolete IF(AC-1.0D-6) etc - TODO
!
!     Following Kambe, the Faddeeva complex error function is used
!     to generate the values of incomplete gamma function of complex
!     argument in DL1 contribution
!
!     Initially the summation follows Kambe convention of spherical
!     harmonics with e.g. i**(1+|m|) prefactor of DL1
!
!     At the very end FACTOR (-1.0D0)**((M+|M|)/2)=i**(M+|M|) is added after
!     all three contributions DLM1, DLM2, DLM3 are summed up together!!!
!     Thereby the prefactor i**(1+abs(m)) of DL1 is converted into
!
!               i**(1+|m|+M+|M|)=(-1)**m i**(1+M)= i**(1-M)
!
!     Does the latter returns back to the Condon-Shortley convention
!     of spherical harmonics???
C--------/---------/---------/---------/---------/---------/---------/--  
      IMPLICIT NONE 
C  
C ..  PARAMETER STATEMENTS  ..  
C  
      INTEGER   LMAXD,LMAX1D,NDEND,LM1SQD,LMDLMD  
      PARAMETER (LMAXD=14,LMAX1D=LMAXD+1)  
*
*  LMAXD  ==>   NELMD  ==>   NDEND
*    4            809          55
*    5           1925          91
*    6           4032         140
*    7           7680         204
*    8          13593         285
*    9          22693         385
*   10          36124         506
*   14         165152        1240
* 
      PARAMETER (LM1SQD=LMAX1D*LMAX1D,NDEND=1240)  
      PARAMETER (LMDLMD=LMAX1D*(2*LMAXD+1)) 
      
      integer, parameter :: ienf=4  !enforces the shell summation to take
                                    !into account at least ienf number
                                    !of shells
      real(dp), parameter :: QT=1.d8     !initial values of test1;
                                         !default was 1.0D6
      real(dp), parameter :: QP=1.d-6    !required summation precision;
                                         !default was 1.0D-3                                    
C ..  SCALAR ARGUMENTS  ..  
C  
      INTEGER    LMAX  
      REAL*8     EMACH  
      COMPLEX*16 KAPPA  
C  
C ..  ARRAY ARGUMENTS  ..  
C  
      REAL*8     AK(2) 
C  
C ..  LOCAL SCALARS  ..  
C 
      INTEGER    LL2,II,I,NNDLM,K,KK,L,MM,NN,M,J1,J2,I1,I2,I3,N1 
      INTEGER    NA,LLL,N,IL,NM,IN 
      REAL*8     AB1,AB2,AC,ACSQ,AD,AL,AN,AN1,AN2,AP,AP1,AP2,AR,B  
      REAL*8     DNORM,RTPI,RTV,TEST,TEST1,TEST2,TV,PI  
      COMPLEX*16 ALPHA,RTA,RTAI,KAPSQ,KANT,KNSQ,XPK,XPA,CF,CI,CP,CX,CZ  
      COMPLEX*16 CZERO,CERF,Z,ZZ,W,WW,A,ACC,GPSQ,GP,BT,AA,AB,U,U1,U2,GAM  
      COMPLEX*16 GK,GKK,SD  
C  
C ..  LOCAL ARRAYS  ..  
C  
      REAL*8     DENOM(NDEND),R(2),B1(2),B2(2),AKPT(2),FAC(4*LMAXD+1)  
      COMPLEX*16 GKN(LMAX1D),AGK(2*LMAXD+1),XPM(2*LMAXD+1),PREF(LM1SQD)  
      COMPLEX*16 DLM(LMDLMD)  
C  
C ..  ARRAYS IN COMMON  ..  
C  
      REAL*8    AR1(2),AR2(2)       ! 2D DIRECT-LATTICE BASIS VECTORS
c      COMMON/X1/AR1,AR2             
!!!!!!!!!!!!!!!!!!!!!!!!!!
C  
C ..  INTRINSIC FUNCTIONS  ..  
C  
*      INTRINSIC ABS,ALOG,DCMPLX,CSQRT,EXP,DBLE,IABS  
*      INTRINSIC MAX0,MOD,SQRT  
C  
C ..  EXTERNAL FUNCTIONS  ..  
C  
      EXTERNAL CERF   !the Faddeeva complex error function
C  
C ..  DATA STATEMENTS  ..  
C  
      DATA CZERO/(0.D0,0.D0)/,CI/(0.D0,1.D0)/,PI/3.14159265358979D0/  
     & ,EMACH/1.D-8/ 
C***********************************************************************
      IF(LMAX.GT.LMAXD)  
     &   STOP 'FROM XMAT: LAMX.GT.MIN0(7,LMAXD)'  
C***********************************************************************
C                            G E O M E T R Y 
C
C               DEFINE DIRECT AND RECIPROCAL BRAVAIS LATTICES
C DIRECT-LATTICE BASIS VECTORS:

      AR1(1)=1.d0
      AR1(2)=0.d0 
      AR2(1)=0.d0 
      AR2(2)=1.d0
*
      TV=ABS(AR1(1)*AR2(2)-AR1(2)*AR2(1))  !unit cell surface
* 
* reciprocal lattice basis vectors:
*
      RTV=2.0D0*PI/TV 
      B1(1)=-AR1(2)*RTV  
      B1(2)=AR1(1)*RTV  
      B2(1)=-AR2(2)*RTV  
      B2(2)=AR2(1)*RTV  
*
C***********************************************************************
C                     E W A L D    P A R A M E T E R 
C  
      RTPI=SQRT(PI)  
      KAPSQ=KAPPA*KAPPA 

C     THE FORMULA OF KAMBE FOR THE SEPARATION CONSTANT, ALPHA, IS  
C     USED, SUBJECT TO A RESTRICTION WHICH IS IMPOSED TO CONTROL  
C     LATER ROUNDING ERRORS  
C  
      ALPHA=TV/(4.0D0*PI)*KAPSQ            
      AL=ABS(ALPHA)     !Ewald parameter used by Kambe and Pendry 
                       

      IF(EXP(AL)*EMACH-5.0D-5) 3,3,2  
   2  AL=LOG(5.0D-5/EMACH)  
   3  ALPHA=DCMPLX(AL,0.0D0)  

      RTA=SQRT(ALPHA) 
C*********************************************************************** 
C      F A C T O R I A L S    A N D   DLM   I N I T I A L I Z A T I O N
C
C     THE FACTORIAL  FUNCTION  IS TABULATED  IN FAC . THE ARRAY  
C     DLM WILL CONTAIN NON-ZERO, I.E., L+M EVEN,VALUES AS DEFINED  
C     BY KAMBE: DLM=DLM1+DLM2+DLM3 WITH LM=(00),(1-1),(11),(2-2)...  
   
      LL2=2*LMAX+1  
      FAC(1)=1.0D0  
      II=4*LMAX 
      DO 4 I=1,II  
       FAC(I+1)=DBLE(I)*FAC(I)         !FAC(N)=(N-1)!
  4   CONTINUE
      NNDLM=(LMAX+1)*(2*LMAX+1)        !The number of DLM \neq 0  
        

      DLM=CZERO
!old
!      DO 5 I=1,NNDLM  
!       DLM(I)=CZERO 
!  5   CONTINUE 
C  
!--------/---------/---------/---------/---------/---------/---------/--
C                             DLM1
C     DLM1, THE  SUM  OVER  RECIPROCAL   LATTICE  VECTORS, IS  
C     CALCULATED FIRST. 
!
!     THE PREFACTOR PREF IS TABULATED  FOR EVEN
C     VALUES OF L+|M|, THUS LM=(00),(11),(20),(22),(2*LMAX,2*LMAX)
!  
!  THE FACTORIAL FACTOR F1 IS TABULATED IN DENOM
!  FOR ALL VALUES OF N=0,(L-|M|)/2  
C  
!--------/---------/---------/---------/---------/---------/---------/--
! Lattice vectors independent part
! Determining the arrays
! PREF(KK)=AP*CP comprising the i**(1+|m|) prefactor
! DENOM(K)

      K=1  
      KK=1  
      AP1=-2.0D0/TV  
      AP2=-1.0D0  
      CF=CI/KAPPA  
*
      DO L=1,LL2       !LL2=2*LMAX+1
       AP1=AP1/2.0D0     !=-1.d0/(TV*2.0D0**(l-1)) 
       AP2=AP2+2.0D0     !=2*L-1
       CP=CF             !hides i**(1+|m|) prefactor 
       MM=1  
*
       IF(MOD(L,2)) 7,6,7  
   6   MM=2  
       CP=CI*CP  
   7   NN=(L-MM)/2+2        !L-MM even here
*
        DO M=MM,L,2         !MM=1 or 2 depending on L odd/even
        J1=L+M-1            !=1 for L=M=1
        J2=L-M+1            !=1 for L=M=1  

        AP=AP1*SQRT(AP2*FAC(J1)*FAC(J2))  
        PREF(KK)=AP*CP      !comprises i**(1+|m|) prefactor 

        CP=-CP              !because loop step=2, mere sign change
        KK=KK+1  
        NN=NN-1             !=(L-MM)/2+1
*
         DO I=1,NN        !n-summation for DL1 in JPA39 eq 85
         I1=I  
         I2=NN-I+1          !I2=I3=(L-MM)/2+1  for M=I=1
         I3=NN+M-I 
 
         DENOM(K)=1.0D0/(FAC(I1)*FAC(I2)*FAC(I3))  

         K=K+1 

      end do  !M-loop
      end do  !I-loop
      end do  !L-loop

!--------/---------/---------/---------/---------/---------/---------/--
! Lattice vectors dependent part
!
C     THE  RECIPROCAL LATTICE IS  DEFINED BY B1, B2. THE  SUMMATION
C     BEGINS WITH THE ORIGIN POINT OF THE LATTICE, AND CONTINUES IN
C     STEPS OF 8*N1 POINTS, EACH  STEP INVOLVING THE PERIMETER OF A
C     PARALLELOGRAM OF LATTICE POINTS ABOUT THE ORIGIN, OF SIDE 2*N1+1  
C     EACH STEP BEGINS AT LABEL 9
!     AKPT= THE CURRENT \vK_\parallel IN THE SUM  

! convergence parameter:  
      TEST1=QT    !default was 1.0D6

! the dual lattice summation includes the vector \vg==0. In this case
! there is only a single passage of the "do 21" loop controlled by
! the initial setting of the variable II=1 at the loop end:

      II=1  

! Setting counter N1 for the reciprocal lattice summation:
      N1=-1
   9  N1=N1+1       !begins dual lattice summation for a given lm with N1=0
                    !N1 labels summation shells

 
      NA=N1+N1+II      !beginning from NA=1
      AN1=DBLE(N1)     !beginning from AN1=0
      AN2=-AN1-1.0D0   !beginning from AN2=-1

! Main summation loop:
! The dual lattice summation loop until convergence bounds are satisfied

      DO I1=1,NA   
      AN2=AN2+1.0D0    !beginning from AN2=0

! Generate 4 different (AN1,AN2) ---> (-AN2,AN1)
! Does not make sense if AN1=AN2=0. Therefore, in the latter
! case, there is only a single loop passage controlled by the initial
! setting of the variable II=1 at the loop end

      DO 21 I2=1,4 
 
C     WRITE(16,307) I1,I2  
C 307 FORMAT(33X,'I1=',I2,' , I2=',I2/33X,12('='))  
      AN=AN1  
      AN1=-AN2  
      AN2=AN  

!Set dual lattice vector \vg:
      AB1=AN1*B1(1)+AN2*B2(1)  
      AB2=AN1*B1(2)+AN2*B2(2) 

!Set \vK_parallel: 
      AKPT(1)=AK(1)+AB1  
      AKPT(2)=AK(2)+AB2  
      
! For a square lattice one has the primitive basis vectors:
! 
! B2=(6.28318530717958; 3.6275987284684272)
! B1=(0;7.2551974569368678)
! 
! Check that there is:
!
!       AKPT(1)=AK(1)\pm B1
!       AKPT(2)=AK(2)\pm AB2
!
! in the resulting summation!!!
!--------/---------/---------/---------/---------/---------/---------/--
C     FOR  EVERY LATTICE VECTOR OF THE SUM, THREE SHORT ARRAYS ARE  
C     INITIALISED AS BELOW. AND USED AS TABLES: 
! 
!     XPM(M) CONTAINS VALUES OF XPK**|M|  
!     AGK(I) CONTAINS VALUES OF (AC/KAPPA)**I  
!     GKN(N) CONTAINS VALUES OF (GP/KAPPA)**(2*N-1)*GAM(N,Z)  
!     WHERE L=0,2*LMAX;M=-L,L;N=0,(L-|M|)/2;I=L-2*N
!
!     GAM IS THE INCOMPLETE GAMMA FUNCTION, WHICH IS CALCULATED BY  
!     RECURRENCE  FROM  THE VALUE  FOR N=0, WHICH  IN TURN CAN  BE  
!     EXPRESSED IN TERMS OF the Faddeeva complex error function
!     provided by CERF routine
!     AC=MOD(AKPT). NOTE SPECIAL ACTION IF AC=0  
 
      ACSQ=AKPT(1)*AKPT(1)+AKPT(2)*AKPT(2)  !K_\parallel^2
      GPSQ=KAPSQ-ACSQ                       !K_\perp^2
*
      IF(ABS(GPSQ).LT.EMACH*EMACH)   THEN 
      WRITE(7,100) 
  100 FORMAT(13X,'FATAL ERROR FROM XMAT:'/3X,'GPSQ IS TOO SMALL.' 
     & /3X,'GIVE A SMALL BUT NONZERO VALUE FOR "EPSILON"'/3X,  
     & 'IN THE DATA STATEMENT OF THE MAIN PROGRAM.' 
     & /3X,'THIS DEFINES A SMALL IMAGINARY PART' 
     & /3X,'IN THE FREQUENCY OR WAVELENGTH VALUE.') 
      STOP 
      ENDIF 

!Faddeeva function part:
      AC=SQRT(ACSQ)       !K_\parallel; always real number
      GP=SQRT(GPSQ)       !K_\perp; complex in general

      XPK=CZERO  
      GK=CZERO  
      GKK=DCMPLX(1.0D0,0.0D0)  

      IF(AC-EMACH) 11,11,10  

  10  XPK=DCMPLX(AKPT(1)/AC,AKPT(2)/AC)    !\vphi=\vK_parallel/K_\parallel
      GK=AC/KAPPA                          !K_\parallel/\sigma
      GKK=GPSQ/KAPSQ                       !K_\perp^2/\sigma^2
  11  XPM(1)=DCMPLX(1.0D0,0.0D0)  
*
      AGK(1)=DCMPLX(1.0D0,0.0D0)  
*
      DO I=2,LL2  
      XPM(I)=XPM(I-1)*XPK         !XPK**(I-1)= e**(i*|m|*phi)
      AGK(I)=AGK(I-1)*GK          !AGK**(I-1)=(K_\perp/\sigma)^(2*|m|)  
                                  !for I=1=lm=(0,0)
      end do

!--------/---------/---------/---------/---------/---------/---------/--
! Initialize gamfn(0) for recurrence [Eq. (42) of Ka2; JPA39 eq. 88] 
! beginning with b=-1/2
! Results stored in array GKN(I)
!--------/---------/---------/---------/---------/---------/---------/--
      CF=KAPPA/GP                      !\sigma/K_\perp
      ZZ=-ALPHA*GKK                    !-ALPHA*K_\perp^2/\sigma^2  
      CZ=SQRT(-ZZ)  
      Z=-CI*CZ  
      CX=EXP(-ZZ)  
      GAM=RTPI*CERF(CZ,EMACH)  
      GKN(1)=CF*CX*GAM  
      BT=Z  

      B=0.5D0  
      LLL=LMAX+1  

! recurrence [Eq. (42) of Ka2; JPA39 eq. 88] 
      DO I=2,LLL 
      BT=BT/ZZ 
      B=B-1.0D0  
      GAM=(GAM-BT)/B 
      CF=CF*GKK 
 
      GKN(I)=CF*CX*GAM  

      end do 
C--------/---------/---------/---------/---------/---------/---------/--
*                         DLM1 term
C--------/---------/---------/---------/---------/---------/---------/--
C     THE CONTRIBUTION TO THE SUM DLM1 FOR A PARTICULAR  
C     RECIPROCAL LATTICE VECTOR IS NOW ACCUMULATED INTO  
C     THE ELEMENTS OF DLM, NOTE SPECIAL ACTION IF AC=0  
C  
      K=1  
      KK=1  
*
      DO L=1,LL2  
      MM=1  
*
      IF(MOD(L,2)) 15,14,15  
  14  MM=2  
  15  N=(L*L+MM)/2  
*
      NN=(L-MM)/2+2  
      DO M=MM,L,2          !MM=1 or 2 depending on L odd/even
      ACC=CZERO  
      NN=NN-1  
      IL=L  
*
       DO I=1,NN           !=(L-MM)/2+1

       ACC=ACC+DENOM(K)*AGK(IL)*GKN(I)  

       IL=IL-2  
       K=K+1  
       end do     !I-loop

       ACC=PREF(KK)*ACC  

! PREF(KK)=AP*CP where AP=AP1*SQRT(AP2*FAC(J1)*FAC(J2)), 
! CP=CI/KAPPA, +/- 1/KAPPA,
! AP1=-1.d0/(TV*2.0D0**(l-1)) with TV being unit cell area, and 
! AP2=2*L-1, J1=L+M-1, J2=L-M+1
*
       IF(AC-1.0D-6) 17,17,165  

 165   DLM(N)=DLM(N)+ACC/XPM(M)    !XPM(M)= e**(i*|m|*phi) 
 
       IF(M-1) 17,18,17 
 
  17   NM=N-M+1  
*
       DLM(NM)=DLM(NM)+ACC*XPM(M)   !XPM(M)= e**(i*|m|*phi) 

  18   KK=KK+1  
       N=N+1  
       end do   !l-loop
*
      IF(II) 21,21,22  !II=1 exits the "do 21"-loop and goes straight to II=0
                       !in the "do I1"-loop
* 
  21  CONTINUE  !over i2
  
  22  II=0      !from now on, the "do 21"-loop is performed fully
                
      enddo     !over I1
C  
C     AFTER EACH STEP OF THE SUMMATION THE TEST ON THE  
C     CONVERGENCE  OF THE  ELEMENTS OF  DLM IS  MADE  
C  
      TEST2=0.0D0  
*
      DO I=1,NNDLM  
      DNORM=ABS(DLM(I))  
      TEST2=TEST2+DNORM*DNORM    !=\sum_I |DLM(I))|**2  
      end do     !I-loop
*
      TEST=ABS((TEST2-TEST1)/TEST1) 
      TEST1=TEST2 
*
! to force summation to go beyond N1=1
      if (n1<=ienf) go to 9    !where the DLM1 shell summation begins
!
      IF(TEST-QP) 27,27,24  
  24  IF(N1-10) 9,25,25  
*
!unsuccessful exit-even if not converged
!continues further to the DLM2-summation:

  25  WRITE(16,26) N1  
  26  FORMAT(29H**DLM1,S NOT CONVERGED BY N1=,I2)  

      GOTO 285   !to DLM2-summation

!successful exit:

  27  WRITE(16,28) N1  
  28  FORMAT(25H DLM1,S CONVERGED BY N1 =,I2)  
C     WRITE(16,250) DLM  
C250  FORMAT(5H0DLM1,//,45(2E13.5,/))  
C
C--------/---------/---------/---------/---------/---------/---------/--
*                         DLM2 term
C--------/---------/---------/---------/---------/---------/---------/--
C     DLM2, THE SUM OVER REAL SPACE LATTICE VECTORS, BEGINS WITH  
C     THE ADJUSTMENT OF THE ARRAY PREF, TO CONTAIN VALUES OF THE  
C     PREFACTOR  'P2' FOR LM=(00),(11),(20),(22),...  
!     The direct lattice vector R=0 is excluded from the summation.
!     Therefore there is no need to enforce a single passage of "do I2"
!     loop as was the case of dual lattice summation
  
 285  KK=1  
      AP1=TV/(4.0D0*PI)  
      CF=KAPSQ/CI 
      
      ! convergence parameter:
      test1=qt   !default was 1.0D6
* 
      DO L=1,LL2  
      CP=CF  
      MM=1  
*
      IF(MOD(L,2)) 30,29,30  
  29  MM=2  
      CP=-CI*CP  
  30  J1=(L-MM)/2+1  
*
      J2=J1+MM-1  
      IN=J1+L-2  
      AP2=((-1.0D0)**IN)*AP1  
      DO M=MM,L,2  
      AP=AP2/(FAC(J1)*FAC(J2))  
      PREF(KK)=AP*CP*PREF(KK)  
      J1=J1-1  
      J2=J2+1  
      AP2=-AP2  
      CP=-CP  
      KK=KK+1 
      enddo !M-loop  
      enddo !L-loop 
*
 
C     THE SUMMATION PROCEEDS IN STEPS OF 8*N1 LATTICE POINTS  
C     AS BEFORE, BUT THIS  TIME EXCLUDING  THE ORIGIN  POINT  
C     R=THE CURRENT LATTICE VECTOR IN THE SUM  
C     AR=MOD(R)  

      N1=0  
  32  N1=N1+1  
      NA=N1+N1  
      AN1=DBLE(N1)  
      AN2=-AN1-1.0D0 
* 
! Main summation loop:
! The direct lattice summation loop until convergence bounds are satisfied

      DO 40 I1=1,NA  
      AN2=AN2+1.0D0  
*
       DO 40 I2=1,4  
       AN=AN1  
       AN1=-AN2  
       AN2=AN  
       R(1)=AN1*AR1(1)+AN2*AR2(1)  
       R(2)=AN1*AR1(2)+AN2*AR2(2)  
       AR=SQRT(R(1)*R(1)+R(2)*R(2)) 
       XPK=DCMPLX(R(1)/AR,R(2)/AR)  
       XPM(1)=DCMPLX(1.0D0,0.0D0)  

        DO I=2,LL2  
        XPM(I)=XPM(I-1)*XPK  
        enddo !I-loop 

      AD=AK(1)*R(1)+AK(2)*R(2)  
      SD=EXP(-AD*CI)  
C  
C     FOR EACH LATTICE VECTOR THE INTEGRAL 'U' IS OBTAINED  
C     FROM THE RECURRENCE RELATION IN L SUGGESTED BY KAMBE  
C     U1 AND U2 ARE THE  INITIAL TERMS OF THIS RECURRENCE,   
C     FOR L#-1 AND L=0, AND THEY ARE EVALUATED IN TERMS OF   
C     THE COMPLEX ERROR FUNCTION CERF  
C  
      KANT=0.5D0*AR*KAPPA  
      KNSQ=KANT*KANT  
      Z=CI*KANT/RTA  
      ZZ=RTA-Z  
      Z=RTA+Z  
      WW=CERF(-ZZ,EMACH)  
      W=CERF(Z,EMACH)  
      AA=0.5D0*RTPI*(W-WW)/CI  
      AB=0.5D0*RTPI*(W+WW)  
      A=ALPHA-KNSQ/ALPHA  
      XPA=EXP(A)  
      U1=AA*XPA  
      U2=AB*XPA/KANT  
C  
C     THE CONTRIBUTION TO DLM2 FROM A PARTICULAR LATTICE  
C     VECTOR IS ACCUMULATED INTO THE ELEMENTS OF DLM.
C     THIS PROCEDURE INCLUDES THE TERM (KANT**L) AND THE  
C     RECURRENCE FOR THE INTEGRAL 'U' 
C  
      KK=1  
      AL=-0.5D0  
      CP=RTA  
      CF=DCMPLX(1.0D0,0.0D0)  
*
       DO L=1,LL2  
       MM=1 
* 
       IF(MOD(L,2)) 35,34,35  
  34   MM=2  
  35   N=(L*L+MM)/2 
* 
        DO M=MM,L,2  
        ACC=PREF(KK)*U2*CF*SD  
        DLM(N)=DLM(N)+ACC/XPM(M)  
*
        IF(M-1) 36,37,36  
  36    NM=N-M+1  
        DLM(NM)=DLM(NM)+ACC*XPM(M)  
  37    KK=KK+1 
* 
        N=N+1  
        enddo !M-loop  
*
       AL=AL+1.0D0  
       CP=CP/ALPHA  
       U=(AL*U2-U1+CP*XPA)/KNSQ  
       U1=U2  
       U2=U  
       CF=KANT*CF  
       enddo !L-loop 
  40  CONTINUE    !I1, I2 main summation loop
C  
C     AFTER EACH STEP OF THE SUMMATION A TEST ON THE  
C     CONVERGENCE OF THE ELEMENTS OF DLM IS MADE  
C  
      TEST2=0.0D0  
*
      DO I=1,NNDLM  
      DNORM=ABS(DLM(I))  
      TEST2=TEST2+DNORM*DNORM   !=\sum_I |DLM(I))|**2  
      enddo !I-loop 

      TEST=ABS((TEST2-TEST1)/TEST1)  
      TEST1=TEST2  
*
! to force summation to go beyond N1=1
      if (n1<=ienf) go to 32    !where the DLM2 shell summation begins
!
      IF(TEST-QP) 45,45,42  
  42  IF(N1-10) 32,43,43  
*
!unsuccessful exit-even if not converged
!continues further to the DLM3-summation:

  43  WRITE(16,44) N1  
  44  FORMAT(31H0**DLM2,S NOT CONVERGED BY N1 =,I2) 
 
      GOTO 465   !to DLM3-summation

!successful exit:

  45  WRITE(16,46) N1 
  46  FORMAT(24H DLM2,S CONVERGED BY N1=,I2)  

C--------/---------/---------/---------/---------/---------/---------/--
*                         DLM3 term
C--------/---------/---------/---------/---------/---------/---------/--
C     THE TERM DLM3 HAS A NON-ZERO CONTRIBUTION  ONLY  
C     WHEN L=M=0.IT IS EVALUATED HERE IN TERMS OF THE  
C     COMPLEX ERROR FUNCTION CERF  
C  
 465  XPA=EXP(-ALPHA)  
      RTAI=1.0D0/(RTPI*RTA)  
      ACC=KAPPA*(CI*(XPA-CERF(RTA,EMACH))-RTAI)/XPA  
      AP=-0.5D0/RTPI  
      DLM(1)=DLM(1)+AP*ACC  

!--------/---------/---------/---------/---------/---------/---------/--
C                          RESCALING
C     FINALLY THE ELEMENTS OF DLM ARE MULTIPLIED BY THE  
C     FACTOR (-1.0D0)**((M+|M|)/2)  
C
*  
      DO L=2,LL2,2  
      N=L*L/2+1 
* 
      DO M=2,L,2  
      DLM(N)=-DLM(N)  
      N=N+1 
      enddo !M-loop  
      enddo !L-loop 
*
C     WRITE(16,251) DLM  
C 251 FORMAT(15H0DLM1+DLM2+DLM3,//45(2E13.5,/))  
C  
      RETURN  
      end subroutine dlsumf2in3

!--------/---------/---------/---------/---------/---------/---------/--

      FUNCTION CERF(Z,EMACH)  
!--------/---------/---------/---------/---------/---------/---------/--  
C     GIVEN COMPLEX ARGUMENT Z, PROVIDES THE FADDEEVA 
C     COMPLEX ERROR FUNCTION (Eq. (7.2.3) of \ct{Ol}): 
!
!     W(Z)=EXP(-Z**2)*(1.0-ERF(-I*Z))  ... 7.1.3 AS; 7.2.3 Ol
!
C     THE EVALUATION ALWAYS TAKES  PLACE IN THE FIRST QUADRANT.
C     ONE OF THREE METHODS IS EXPLOYED DEPENDING ON THE SIZE OF THE 
C     ARGUMENT (A POWER SERIES,A RECURRENCE BASED ON CONTINUED FRACTIONS
C     THEORY, OR AN ASYMPTOTIC SERIES). 
!
!     EMACH IS THE OLD MACHINE ACCURACY - TODO
!
!     THE ARGUMENT IS TRANSLATED TO THE FIRST QUADRANT FROM  
!     THE NN_TH QUADRANT, BEFORE THE METHOD FOR THE FUNCTION  
!     EVALUATION IS CHOSEN
!     SYMMETRY RELATIONS ARE NOW USED TO TRANSFORM THE FUNCTION  
!     BACK TO QUADRANT NN 
!
!     AS = ABRAMOWITZ AND STEGUN HANDBOOK OF MATHEMATICAL FUNCTIONS
!     Ol = Olver NIST HANDBOOK OF MATHEMATICAL FUNCTIONS 
!           at https://dlmf.nist.gov
C     ------------------------------------------------------------------  
C  
C ..  SCALAR ARGUMENTS  ..  
C
      IMPLICIT NONE   
      REAL*8, intent(in) :: EMACH
      COMPLEX*16, intent(in) :: Z  
C  
C ..  LOCAL SCALARS  ..  
C  
      INTEGER    NN,N 
      REAL*8     ABSZ,ABTERM,API,EPS,FACT,FACTD,FACTN,PI  
      REAL*8     Q,RTPI,TEST,X,Y,YY  
      COMPLEX*16 ZZ,CONE,CI,CZERO,SUM,ZZS,XZZS,CER,CERF   
      COMPLEX*16 H1,H2,H3,U1,U2,U3,TERM1,TERM2  
C  
C ..  INTRINSIC FUNCTIONS  ..  
C  
*     INTRINSIC DCMPLX,EXP,DCONJG  
C  
C ..  DATA STATEMENTS  ..  
C  
      DATA PI/3.14159265358979D0/  
      DATA CONE/(1.D0,0.D0)/,CI/(0.D0,1.D0)/,CZERO/(0.D0,0.D0)/  
C     ------------------------------------------------------------------  
  
      EPS=5.0D0*EMACH  
      API=1.0D0/PI 

! the Faddeeva complex error function part:

      IF(ABS(Z)) 2,1,2  
   1  CERF=CONE         !special value for z==0
      GOTO 29
      
!     Herein below z/=0
!     THE ARGUMENT Z/=0 IS TRANSLATED FROM THE NN_TH QUADRANT INTO ZZ
!     IN THE FIRST QUADRANT, BEFORE THE METHOD FOR THE
!     Faddeeva complex error function EVALUATION IS CHOSEN 
 
   2  X=DBLE(Z)  
      Y=DIMAG(Z)  
      YY=Y  
      IF(Y) 6,3,3  
   3  IF(X) 5,4,4  
   4  ZZ=Z  
      NN=1  
      GOTO 9  
   5  ZZ=DCMPLX(-X,Y)  
      NN=2  
      GOTO 9  
   6  YY=-Y  
      IF(X) 7,8,8  
   7  ZZ=-Z  
      NN=3  
      GOTO 9  
   8  ZZ=DCMPLX(X,-Y)  
      NN=4  
   9  ZZS=ZZ*ZZ  
      XZZS=EXP(-ZZS)  
      ABSZ=ABS(ZZ)  
      IF(ABSZ-10.0D0) 10,10,23  
  10  IF(YY-1.0D0) 11,12,12  
  11  IF(ABSZ-4.0D0) 13,18,18  
  12  IF(ABSZ-1.0D0) 13,18,18  
 
! POWER SERIES (SEE 7.1.5 AS, p. 297; 7.6.1 Ol) 
! In the series, n-th term for -iz is a z**2*(2n-1)/(n*(2n+1))
! multiple of the (n-1)-th term
! The overall prefactor of the series is -2*i/\sqrt{\pi} for (-iz)
! argument
!
! One wonders why not the power series 7.1.8 AS, p. 297; 7.6.3 Ol
! is being used?? The latter would lead directly 
! to the Faddeeva error function w(z)??? TODO
 
  13  Q=1.0D0          !provides n!
      FACTN=-1.0D0     !provides (2n-1) 
      FACTD=1.0D0      !provides (2n+1) 
      TERM1=ZZ         !==z**2  ... the first term of the sum for n=0
      SUM=ZZ           !==z**2  ... the first term of the sum for n=0 

  14  DO N=1,5  
      FACTN=FACTN+2.0D0  
      FACTD=FACTD+2.0D0  
      FACT=FACTN/(Q*FACTD)  !=(2n-1)/(n*(2n+1))

      TERM1=FACT*ZZS*TERM1  !generates nth term from the (n-1)th term
      SUM=SUM+TERM1         !summation

      Q=Q+1.0D0
      enddo
  
      ABTERM=ABS(TERM1)  
      IF(ABTERM-EPS) 17,16,16  
  16  IF(Q-100.0D0) 14,17,17  

  17  FACT=2.0D0*SQRT(API)  
      SUM=FACT*CI*SUM       !adds the missing prefactor 2*i/\sqrt{\pi} for 
                            !the (-iz) argument to provide -erf(-iz)
      CER=XZZS+XZZS*SUM     !generates Faddeeva error function w(z)
                            !according to 7.1.3 AS; 7.2.3 Ol
      GOTO 24  
  
C     CONTINUED FRACTION THEORY (W(Z) IS RELATED TO THE LIMITING  
C     VALUE OF U(N,Z)/H(N,Z), WHERE U AND H OBEY THE SAME  
C     RECURRENCE RELATION IN N. SEE FADDEEVA AND TERENTIEV  
C     (TABLES OF VALUES OF W(Z) FOR COMPLEX ARGUMENTS, PERGAMON  
C     N.Y. 1961)  
!
!  7.9 Ol
  
  18  TERM2=DCMPLX(1.D6,0.0D0)  
      Q=1.0D0  
      H1=CONE  
      H2=2.0D0*ZZ  
      U1=CZERO  
      RTPI=2.0D0*SQRT(PI)  
      U2=DCMPLX(RTPI,0.0D0)  
  19  TERM1=TERM2  
      DO 20 N=1,5  
      H3=H2*ZZ-Q*H1  
      U3=U2*ZZ-Q*U1  
      H1=H2  
      H2=2.0D0*H3  
      U1=U2  
      U2=2.0D0*U3  
  20  Q=Q+1.0D0  
      TERM2=U3/H3  
      TEST=ABS((TERM2-TERM1)/TERM1)  
      IF(TEST-EPS) 22,21,21  
  21  IF(Q-60.0D0) 19,19,13  
  22  CER=API*CI*TERM2  
      GOTO 24  
 
!
!     7.12 Ol 
C     ASYMPTOTIC SERIES: SEE ABRAMOWITZ AND STEGUN, P328  
  
  23  CER=0.5124242D0/(ZZS-0.2752551D0)+0.05176536D0/(ZZS-2.724745D0)  
      CER=CI*ZZ*CER  
  
C     SYMMETRY RELATIONS ARE NOW USED TO TRANSFORM THE FUNCTION  
C     BACK TO QUADRANT NN  
  
  24  GOTO(28,26,27,25),NN  
  25  CER=2.0D0*XZZS-CER  
  26  CERF=DCONJG(CER)  
      GOTO 29  
  27  CERF=2.0D0*XZZS-CER  
      GOTO 29  
  28  CERF=CER  
  29  RETURN  
      end subroutine cerf
