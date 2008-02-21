      SUBROUTINE SETUP0
      INCLUDE 'O8COMM.INC'
C   THIS IS EXAMPLE HIMMELBLAU 20 (PAVIANI N=24)
      SILENT=.FALSE.
      ANALYT=.TRUE.
      EPSDIF=0.D0
      PROU=10
      MEU=20
C   DEL0 AND TAU0: SEE BELOW
      NRESET=N
      RETURN
      END
      SUBROUTINE SETUP
      RETURN
      END
      BLOCK DATA
      INCLUDE 'O8BLOC.INC'
      INTEGER I,J
      DATA NAME/'PAVIANI2'/
      DATA (X(I),I=1,24)/24*0.04D0/
      DATA N/24/ , NH/14/ , NG/32/
      DATA DEL0/0.005D0/ ,TAU0/0.1D0/ ,TAU/.1D0/
      DATA (GUNIT(1,I),I=0,14)/15*-1/,((GUNIT(I,J),I=2,3),J=0,14)/30*0/,
     F     (GUNIT(1,I),I=15,38)/24*1/(GUNIT(2,I),I=15,38)/1,2,3,4,5,6,7,
     F     8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24/,
     F     (GUNIT(3,I),I=15,38)/24*100/,
     F     (GUNIT(1,I),I=39,46)/8*-1/,((GUNIT(I,J),I=2,3),J=39,46)/16*0/
      END
      SUBROUTINE EF(X,FX)
      INCLUDE 'O8FUCO.INC'
      INTEGER I
      DOUBLE PRECISION  FX,X(*),A(24)
      SAVE A
      DATA A/0.0693D0,0.0577D0,0.05D0,0.2D0,0.26D0,0.55D0,0.06D0,0.1D0,
     1       0.12D0,0.18D0,0.1D0,0.09D0,0.0693D0,0.0577D0,0.05D0,0.2D0,
     2       0.26D0,0.55D0,0.06D0,0.1D0,0.12D0,0.18D0,0.1D0,0.09D0/
      ICF=ICF+1
      FX=0.D0
      DO      100      I=1,24
      FX=FX+A(I)*X(I)
 100  CONTINUE
      FX=FX*100.D0
      RETURN
      END
      SUBROUTINE EGRADF(X,GRADF)
      INCLUDE 'O8FUCO.INC'
      INTEGER I
      DOUBLE PRECISION X(*),GRADF(*),A(24)
      SAVE A
      DATA A/0.0693D0,0.0577D0,0.05D0,0.2D0,0.26D0,0.55D0,0.06D0,0.1D0,
     1       0.12D0,0.18D0,0.1D0,0.09D0,0.0693D0,0.0577D0,0.05D0,0.2D0,
     2       0.26D0,0.55D0,0.06D0,0.1D0,0.12D0,0.18D0,0.1D0,0.09D0/
      ICGF=ICGF+1
      DO      100      I=1,24
      GRADF(I)=A(I)*100.D0
  100 CONTINUE
      RETURN
      END
      SUBROUTINE EH(I,X,HXI)
      INCLUDE 'O8FUCO.INC'
      INTEGER I,J,JJ
      DOUBLE PRECISION HXI,X(*),B(12),C(12),D(12),S1,S2,F,SUM
      SAVE B,C,D
      DATA B/44.094D0,2*58.12D0,137.4D0,120.9D0,170.9D0,62.501D0,
     1       84.94D0,133.425D0,82.507D0,46.07D0,60.097D0/
      DATA C/123.7D0,31.7D0,45.7D0,14.7D0,84.7D0,27.7D0,49.7D0,7.1D0,
     1       2.1D0,17.7D0,0.85D0,0.64D0/
      DATA D/31.244D0,36.12D0,34.784D0,92.7D0,82.7D0,91.6D0,56.708D0,
     1       82.7D0,80.8D0,64.517D0,49.4D0,49.1D0/
      CRES(I)=CRES(I)+1
      F=0.7302D0*530.D0*14.7D0/40.D0
      IF(I .GT. 12)      GOTO 100
      S2=0.D0
      S1=0.D0
      DO      10      J=13,24
      JJ=J-12
      S1=S1+X(J)/B(JJ)
      S2=S2+X(JJ)/B(JJ)
   10 CONTINUE
      HXI=X(I+12)/(B(I)*S1)-C(I)*X(I)/(40.D0*B(I)*S2)
      RETURN
  100 CONTINUE
      IF(I .EQ. 14)      GOTO 200
      SUM=0.D0
      DO     110      J=1,24
      SUM=SUM+X(J)
  110 CONTINUE
      HXI=SUM-1.D0
      RETURN
  200 CONTINUE
      S1=0.D0
      S2=0.D0
      DO      210      J=1,12
      S1=S1+X(J)/D(J)
      S2=S2+X(J+12)/B(J)
  210 CONTINUE
      HXI=S1+F*S2-1.671D0
      RETURN
      END
      SUBROUTINE EGRADH(I,X,GRADHI)
      INCLUDE 'O8FUCO.INC'
      INTEGER I,J
      DOUBLE PRECISION X(*),GRADHI(*),B(12),C(12),D(12),S1,S2,F,XK1,XK2
      SAVE B,C,D
      DATA B/44.094D0,2*58.12D0,137.4D0,120.9D0,170.9D0,62.501D0,
     1       84.94D0,133.425D0,82.507D0,46.07D0,60.097D0/
      DATA C/123.7D0,31.7D0,45.7D0,14.7D0,84.7D0,27.7D0,49.7D0,7.1D0,
     1       2.1D0,17.7D0,0.85D0,0.64D0/
      DATA D/31.244D0,36.12D0,34.784D0,92.7D0,82.7D0,91.6D0,56.708D0,
     1       82.7D0,80.8D0,64.517D0,49.4D0,49.1D0/
      CGRES(I)=CGRES(I)+1
      F=0.7302D0*530.D0*14.7D0/40.D0
      IF(I .GT. 12)      GOTO 200
      S2=0.D0
      S1=0.D0
      DO      10      J=1,12
      S1=S1+X(J+12)/B(J)
      S2=S2+X(J)/B(J)
   10 CONTINUE
      XK1=1.D0/B(I)
      XK2=-C(I)/(40.D0*B(I))
      DO      100      J=1,12
      GRADHI(J)=0.D0
      IF(I .EQ. J)      GRADHI(J)=S2
      GRADHI(J)= XK2*(GRADHI(J)-X(I)/B(J))/S2**2
  100 CONTINUE
      DO      150      J=13,24
      GRADHI(J)=0.D0
      IF(I .EQ. J-12 )     GRADHI(J)=S1
      GRADHI(J)=XK1*(GRADHI(J)-X(I+12)/B(J-12))/S1**2
  150 CONTINUE
      RETURN
  200 CONTINUE
      IF(I .EQ. 14)      GOTO 300
      DO     210      J=1,24
      GRADHI(J)=1.D0
  210 CONTINUE
      RETURN
  300 CONTINUE
      DO      310      J=1,12
      GRADHI(J)=1.D0/D(J)
  310 CONTINUE
      DO      320      J=13,24
      GRADHI(J)=F/B(J-12)
  320 CONTINUE
      RETURN
      END
      SUBROUTINE EG(I,X,GXI)
      INCLUDE 'O8FUCO.INC'
      INTEGER I,II,K1,K2,I1,I2,J
      DOUBLE PRECISION X(*),E(6),GXI,SUM
      SAVE E
      DATA E/0.1D0,0.3D0,0.4D0,0.3D0,0.6D0,0.3D0/
      IF (I.GT.24) THEN
      CRES(I+NH)=CRES(I+NH)+1
      GOTO 50
      ENDIF
      GXI=X(I)*100.D0
      RETURN
   50 CONTINUE
      II=I-24
      GOTO(100,100,100,200,200,200,300,400) II
 100  CONTINUE
      K1=0
      K2=12
 105  SUM=0.D0
      DO     110      J=1,24
      SUM=SUM+X(J)
 110  CONTINUE
      I1=II+K1
      I2=II+K2
      GXI=-(X(I1) + X(I2)) /  SUM+E(II)
      RETURN
  200 CONTINUE
      K1=3
      K2=15
      GOTO 105
  300 CONTINUE
      GXI=0.D0
      DO     310     J=1,12
      GXI=GXI+X(J)*100.D0
  310 CONTINUE
      RETURN
  400 CONTINUE
      GXI=0.D0
      DO      410     J=13,24
      GXI=GXI+X(J)*100.D0
  410 CONTINUE
      RETURN
      END
      SUBROUTINE EGRADG(I,X,GRADGI)
      INCLUDE 'O8FUCO.INC'
      INTEGER I,J,II,I1,I2,K1,K2
      DOUBLE PRECISION X(*),GRADGI(*),E(6),XNEN
      SAVE E
      DATA E/0.1D0,0.3D0,0.4D0,0.3D0,0.6D0,0.3D0/
      IF(I .GT. 24)      GOTO 50
      RETURN
   50 CONTINUE
      DO  60  J=1,24
        GRADGI(J)=0.D0
   60 CONTINUE
      CGRES(I+NH)=CGRES(I+NH)+1
      II=I-24
      GOTO(100,100,100,200,200,200,300,400),II
  100 CONTINUE
      K1=0
      K2=12
  105 XNEN=0.D0
      DO     110      J=1,24
      XNEN=XNEN+X(J)
  110 CONTINUE
      I1=II+K1
      I2=II+K2
      DO      120      J=1,24
      IF(I1 .EQ. J .OR. I2 .EQ. J)   GRADGI(J)=-1.D0
      GRADGI(J)=(GRADGI(J)*XNEN+(X(I1)+X(I2)))/XNEN**2
  120 CONTINUE
      RETURN
  200 CONTINUE
      K1=3
      K2=15
      GOTO 105
  300 CONTINUE
      DO      310       J=1,12
      GRADGI(J)=100.D0
  310 CONTINUE
      RETURN
  400 CONTINUE
      DO      410       J=13,24
      GRADGI(J)=100.D0
  410 CONTINUE
      RETURN
      END
