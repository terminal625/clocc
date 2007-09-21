C************ FROM HOCK&SCHITTKOWSKI
C   HS101
      SUBROUTINE SETUP0
      INCLUDE 'O8COMM.INC'
      INTEGER I
      NAME='HS101'
      DO I=1,7
        X(I)=6.D0
      ENDDO
      N=7
      NH=0
      NG=20
      DEL0=0.05D0
      TAU0=0.05D0
      TAU=0.1D0
      DO I=0,6
        GUNIT(1,I)=-1
        GUNIT(2,I)=0
        GUNIT(3,I)=0
      ENDDO
      DO I=7,13
        GUNIT(1,I)=1
        GUNIT(2,I)=I-6
        GUNIT(3,I)=1
        GUNIT(1,I+7)=1
        GUNIT(2,I+7)=I-6
        GUNIT(3,I+7)=-1
      ENDDO
      PROU=10
      MEU=20
      COLD=.TRUE.
      SILENT=.FALSE.
      RETURN
      END
      SUBROUTINE EF(X,FX)
      INCLUDE 'O8FUCO.INC'
      DOUBLE PRECISION X(*),FX,DL(NX),ALF(6,4),GAMF(4)
      INTEGER KF(6,4)
      SAVE KF,ALF,GAMF
      DATA KF/1,2,4,6,7,0,1,2,3,4,5,7,1,2,4,5,6,0,1,2,3,5,6,7/
      DATA GAMF/10.D0,15.D0,20.D0,25.D0/
      DATA ALF/ 1.D0,-1.D0,2.D0,-3.D0,-0.25D0,0.D0,
     1         -1.D0,-2.D0,1.D0,1.D0,-1.D0,-.5D0,
     2         -2.D0,1.D0,-1.D0,-2.D0,1.D0,0.D0,
     3          2.D0,2.D0,-1.D0,.5D0,-2.D0,1.D0/
      ICF=ICF+1
      CALL FGEO(X,0.D0,GAMF,.FALSE.,DL,KF,ALF,6,4,7,FX)
      RETURN
      END
      SUBROUTINE EGRADF(X,GRADF)
      INCLUDE 'O8FUCO.INC'
      DOUBLE PRECISION X(*),GRADF(*),DL(NX),ALF(6,4),GAMF(4)
      INTEGER KF(6,4)
      SAVE KF,ALF,GAMF
      DATA KF/1,2,4,6,7,0,1,2,3,4,5,7,1,2,4,5,6,0,1,2,3,5,6,7/
      DATA GAMF/10.D0,15.D0,20.D0,25.D0/
      DATA ALF/ 1.D0,-1.D0,2.D0,-3.D0,-0.25D0,0.D0,
     1         -1.D0,-2.D0,1.D0,1.D0,-1.D0,-.5D0,
     2         -2.D0,1.D0,-1.D0,-2.D0,1.D0,0.D0,
     3          2.D0,2.D0,-1.D0,.5D0,-2.D0,1.D0/
      ICGF=ICGF+1
      CALL DFGEO(X,GAMF,.FALSE.,DL,KF,ALF,6,4,GRADF,7)
      RETURN
      END
      SUBROUTINE EH(I,X,HXI)
      INCLUDE 'O8FUCO.INC'
      DOUBLE PRECISION X(NX),HXI
      INTEGER I
      CRES(I)=CRES(I)+1
      RETURN
      END
      SUBROUTINE EGRADH(I,X,GRADHI)
      INCLUDE 'O8FUCO.INC'
      DOUBLE PRECISION X(*),GRADHI(*)
      INTEGER I
      CGRES(I)=CGRES(I)+1
      RETURN
      END
      SUBROUTINE EG(I,X,GXI)
      INCLUDE 'O8FUCO.INC'
      DOUBLE PRECISION GXI
      DOUBLE PRECISION X(*),DL(NX),ALF(6,4),GAMF(4),
     F       GAM1(4),GAM2(4),UG(7)
      DOUBLE PRECISION  GAM3(4),GAM4(4),AL1(6,4),AL2(6,4),
     F       AL3(6,4),AL4(6,4)
      INTEGER  I,K1(6,4),K2(6,4),K3(6,4),K4(6,4),KF(6,4)
      SAVE KF,K1,K2,K3,K4,ALF,GAMF,GAM1,GAM2,GAM3,
     F         GAM4,AL1,AL2,AL3,AL4
      SAVE UG
      DATA KF/1,2,4,6,7,0,1,2,3,4,5,7,1,2,4,5,6,0,1,2,3,5,6,7/
      DATA GAMF/10.D0,15.D0,20.D0,25.D0/
      DATA ALF/ 1.D0,-1.D0,2.D0,-3.D0,-0.25D0,0.D0,
     1         -1.D0,-2.D0,1.D0,1.D0,-1.D0,-.5D0,
     2         -2.D0,1.D0,-1.D0,-2.D0,1.D0,0.D0,
     3          2.D0,2.D0,-1.D0,.5D0,-2.D0,1.D0/
      DATA GAM1/-.5D-3,-.7D-3,-.2D-3,0.D0/
      DATA GAM2/-1.3D-3,-.8D-3,-3.1D-3,0.D-3/
      DATA GAM3/-2.0D-3,-.1D-3,-1.0D-3,-.65D-3/
      DATA GAM4/-.20D-3,-.3D-3,-.40D-3,-.5D-3/
      DATA AL1/ .5D0,-1.D0,-2.D0,1.D0,0.D0,0.D0,
     1         3.D0,1.D0,-2.D0,1.D0,.5D0,0.D0,
     2        -1.D0,1.D0,-.5D0,.66666666666666D0,.25D0,7*0.D0/
      DATA AL2/-.5D0,1.D0,2*-1.D0,1.D0,0.D0,
     1          1.D0,2*-1.D0,2.D0,2*0.D0,
     2         -1.D0,.5D0,-2.D0,-1.D0,.33333333333333D0,7*0.D0/
      DATA AL3/ 1.D0,-1.5D0,1.D0,-1.D0,.33333333333333D0,0.D0,
     1          1.D0,-.5D0,1.D0,-1.D0,-.5D0,0.D0,
     2         -1.D0,1.D0,.5D0,1.D0,2*0.D0,
     3         -2.D0,2*1.D0,-1.D0,1.D0,0.D0/
      DATA AL4/-2.D0, 1.0D0,-1.D0,.5D0,.33333333333333D0,0.D0,
     1    .5D0, 2.D0,1.D0,.33333333333333D0,.25D0,-.66666666666666D0,
     2         -3.D0,-2.D0,2*1.D0,.75D0,0.D0,
     3         -2.D0,1.D0,.5D0,3*0.D0/
      DATA K1/1,3,6,7,2*0,1,2,3,6,7,0,2,3,4,6,7,7*0/
      DATA K2/1,2,3,5,6,0,3,4,5,6,2*0,1,2,4,5,6,7*0/
      DATA K3/1,3,5,6,7,0,2,3,5,6,7,0,1,2,3,5,2*0,2,3,5,6,7,0/
      DATA K4/1,2,4,5,7,0,1,2,3,4,7,5,1,2,3,5,7,0,3,4,7,3*0/
      DATA UG/6*.1D0,.01D0/
      IF ( I .LE. 6 ) CRES(I+NH)=CRES(I+NH)+1
      IF(I .GT. 6)      GOTO 700
      GOTO (100,200,300,400,500,600),I
  100 CONTINUE
      CALL FGEO(X,1.D-3,GAM1,.FALSE.,DL,K1,AL1,6,4,7,GXI)
      RETURN
  200 CONTINUE
      CALL FGEO(X,1.D-3,GAM2,.FALSE.,DL,K2,AL2,6,4,7,GXI)
      RETURN
  300 CONTINUE
      CALL FGEO(X,1.D-3,GAM3,.FALSE.,DL,K3,AL3,6,4,7,GXI)
      RETURN
  400 CONTINUE
      CALL FGEO(X,1.D-3,GAM4,.FALSE.,DL,K4,AL4,6,4,7,GXI)
      RETURN
  500 CONTINUE
      CALL FGEO(X,-1.D2,GAMF,.FALSE.,DL,KF,ALF,6,4,7,GXI)
      RETURN
  600 CONTINUE
      CALL FGEO(X,-3.D3,GAMF,.FALSE.,DL,KF,ALF,6,4,7,GXI)
      GXI=-GXI
      RETURN
  700 CONTINUE
      IF( I .LE. 13)    GXI=(X(I-6)-UG(I-6))
      IF( I .GT. 13)    GXI=(10.D0-X(I-13))
      RETURN
      END
      SUBROUTINE EGRADG(I,X,GRADGI)
      INCLUDE 'O8FUCO.INC'
      DOUBLE PRECISION X(*),GRADGI(*)
      DOUBLE PRECISION DL(NX),ALF(6,4),GAMF(4),GAM1(4),GAM2(4)
      DOUBLE PRECISION  GAM3(4),GAM4(4),AL1(6,4),AL2(6,4),
     F                AL3(6,4),AL4(6,4)
      INTEGER  K1(6,4),K2(6,4),K3(6,4),K4(6,4),KF(6,4),I,J
      SAVE KF,K1,K2,K3,K4,ALF,GAMF,AL1,AL2,AL3,AL4,
     F     GAM1,GAM2,GAM3,GAM4
      DATA KF/1,2,4,6,7,0,1,2,3,4,5,7,1,2,4,5,6,0,1,2,3,5,6,7/
      DATA GAMF/10.D0,15.D0,20.D0,25.D0/
      DATA ALF/ 1.D0,-1.D0,2.D0,-3.D0,-0.25D0,0.D0,
     1         -1.D0,-2.D0,1.D0,1.D0,-1.D0,-.5D0,
     2         -2.D0,1.D0,-1.D0,-2.D0,1.D0,0.D0,
     3          2.D0,2.D0,-1.D0,.5D0,-2.D0,1.D0/
      DATA GAM1/-.5D-3,-.7D-3,-.2D-3,0.D0/
      DATA GAM2/-1.3D-3,-.8D-3,-3.1D-3,0.D-3/
      DATA GAM3/-2.0D-3,-.1D-3,-1.0D-3,-.65D-3/
      DATA GAM4/-.20D-3,-.3D-3,-.40D-3,-.5D-3/
      DATA AL1/ .5D0,-1.D0,-2.D0,1.D0,0.D0,0.D0,
     1         3.D0,1.D0,-2.D0,1.D0,.5D0,0.D0,
     2        -1.D0,1.D0,-.5D0,.66666666666666D0,.25D0,7*0.D0/
      DATA AL2/-.5D0,1.D0,2*-1.D0,1.D0,0.D0,
     1          1.D0,2*-1.D0,2.D0,2*0.D0,
     2         -1.D0,.5D0,-2.D0,-1.D0,.33333333333333D0,7*0.D0/
      DATA AL3/ 1.D0,-1.5D0,1.D0,-1.D0,.33333333333333D0,0.D0,
     1          1.D0,-.5D0,1.D0,-1.D0,-.5D0,0.D0,
     2         -1.D0,1.D0,.5D0,1.D0,2*0.D0,
     3         -2.D0,2*1.D0,-1.D0,1.D0,0.D0/
      DATA AL4/-2.D0, 1.0D0,-1.D0,.5D0,.33333333333333D0,0.D0,
     1    .5D0, 2.D0,1.D0,.33333333333333D0,.25D0,-.66666666666666D0,
     2         -3.D0,-2.D0,2*1.D0,.75D0,0.D0,
     3         -2.D0,1.D0,.5D0,3*0.D0/
      DATA K1/1,3,6,7,2*0,1,2,3,6,7,0,2,3,4,6,7,7*0/
      DATA K2/1,2,3,5,6,0,3,4,5,6,2*0,1,2,4,5,6,7*0/
      DATA K3/1,3,5,6,7,0,2,3,5,6,7,0,1,2,3,5,2*0,2,3,5,6,7,0/
      DATA K4/1,2,4,5,7,0,1,2,3,4,7,5,1,2,3,5,7,0,3,4,7,3*0/
      IF(I .GT. 6)      RETURN
      CGRES(I+NH)=CGRES(I+NH)+1
      GOTO (100,200,300,400,500,600),I
  100 CONTINUE
      CALL DFGEO(X,GAM1,.FALSE.,DL,K1,AL1,6,4,GRADGI,7)
      RETURN
  200 CONTINUE
      CALL DFGEO(X,GAM2,.FALSE.,DL,K2,AL2,6,4,GRADGI,7)
      RETURN
  300 CONTINUE
      CALL DFGEO(X,GAM3,.FALSE.,DL,K3,AL3,6,4,GRADGI,7)
      RETURN
  400 CONTINUE
      CALL DFGEO(X,GAM4,.FALSE.,DL,K4,AL4,6,4,GRADGI,7)
      RETURN
  500 CONTINUE
      CALL DFGEO(X,GAMF,.FALSE.,DL,KF,ALF,6,4,GRADGI,7)
      RETURN
  600 CONTINUE
      CALL DFGEO(X,GAMF,.FALSE.,DL,KF,ALF,6,4,GRADGI,7)
      DO      700      J=1,7
      GRADGI(J) =-GRADGI(J)
  700 CONTINUE
      RETURN
      END
C****************************************************************
      SUBROUTINE FGEO(X,CON,GAM,LIN,DL,K,AL,NLEN,NANZ,NX,FX)
      IMPLICIT NONE
      INTEGER NLEN,NANZ,NX
      DOUBLE PRECISION GAM(*),AL(NLEN,*),X(*),DL(*),CON,FX
      INTEGER K(NLEN,*)
      LOGICAL LIN
C******* EVALUATE A GENERALIZED POLYNOMIAL GIVEN BY CON,DL,GAM,AL,K
C******* AT X GIVING FX. IF LIN=.FALSE., DL IS NOT USED
C**** HERE
C                 { 0 IF LIN=.FALSE.                 }
C   FX=F(X)=CON + {                                  }+
C                 { SUM(I=1,N){DL(I)*X(I)} OTHERWISE }
C
C               + SUM(I=1,NANZ){GAM(I)*(PROD(J=1,NLEN){X(K(J,I))**AL(J,I)} }
C
C
      INTEGER I,J,IL
      DOUBLE PRECISION S,P,EXPO
      S=CON
      IF(.NOT. LIN)      GOTO 200
      DO      100      I=1,NX
      S=S+DL(I)*X(I)
  100 CONTINUE
  200 CONTINUE
      DO      600      I=1,NANZ
      IF(GAM(I) .EQ. 0.D0)      GOTO 600
      P=1.D0
      DO      500      J=1,NLEN
      IL=K(J,I)
      IF(IL .EQ. 0)      GOTO 500
      EXPO=AL(J,I)
      IF(EXPO .EQ. 0.D0)      GOTO 500
      P=P*EXP(EXPO*LOG(ABS(X(IL))))
  500 CONTINUE
      S=S+GAM(I)*P
  600 CONTINUE
      FX=S
      RETURN
      END
      SUBROUTINE DFGEO(X,GAM,LIN,DL,K,AL,NLEN,NANZ,G,NX)
C******* EVALUATE THE GRADIENT OF A GENERALIZED POLYNOMIAL FUNCTION
C******* DEFINED BY GAM,AL,K,DL AT THE POINT X GIVING G
C*** FOR FUNCTION DEFINITION SEE FGEO ABOVE
      IMPLICIT NONE
      INTEGER NLEN,NANZ,NX
      DOUBLE PRECISION GAM(NANZ),AL(NLEN,*),X(*),G(*),DL(*)
      INTEGER K(NLEN,*)
      LOGICAL LIN
C******* LOCAL
      INTEGER L,I,J,IL
      DOUBLE PRECISION S,P,FC,EXPO,FIJ
      INTRINSIC EXP,LOG,ABS
      DO      500      L=1,NX
      S=0.D0
      DO      400      I=1,NANZ
      IF(GAM(I) .EQ. 0.D0)     GOTO 400
      P=1.D0
      FC=0.D0
      DO      300      J=1,NLEN
      IL=K(J,I)
      IF(IL .EQ. 0)      GOTO 300
      IF(IL .NE. L)      GOTO 100
      FC=1.D0
  100 CONTINUE
      EXPO=AL(J,I)
      IF(EXPO .EQ. 0.D0)      GOTO 300
      FIJ=1.D0
      IF(IL .NE. L)      GOTO 200
      FIJ=EXPO
      EXPO=EXPO-1.D0
  200 CONTINUE
      P=P*FIJ*EXP(EXPO*LOG(ABS(X(IL))))
  300 CONTINUE
      IF(FC .NE. 0.D0)    S=S+P*GAM(I)
  400 CONTINUE
      IF(LIN)    S=S+DL(L)
      G(L)=S
  500 CONTINUE
      RETURN
      END
      SUBROUTINE SETUP
      RETURN
      END
