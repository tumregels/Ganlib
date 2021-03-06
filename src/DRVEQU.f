*DECK DRVEQU
      SUBROUTINE DRVEQU(NENTRY,HENTRY,IENTRY,JENTRY,KENTRY)
*
*-----------------------------------------------------------------------
*
* STANDARD EQUALITY MODULE.
*
* INPUT/OUTPUT PARAMETERS:
*  NENTRY : NUMBER OF LCM OBJECTS USED BY THE MODULE.
*  HENTRY : CHARACTER*12 NAME OF EACH LCM OBJECT OR FILE.
*  IENTRY : =0 CLE-2000 VARIABLE; =1 MEMORY-RESIDENT; =2 XSM FILE;
*           =3 SEQUENTIAL BINARY FILE; =4 SEQUENTIAL ASCII FILE;
*           =5 DIRECT ACCESS FILE.
*  JENTRY : =0 THE LCM OBJECT OR FILE IS CREATED.
*           =1 THE LCM OBJECT OR FILE IS OPEN FOR MODIFICATIONS;
*           =2 THE LCM OBJECT OR FILE IS OPEN IN READ-ONLY MODE.
*  KENTRY : =FILE OR LCM OBJECT ADDRESSES.
*           DIMENSION HENTRY(NENTRY),IENTRY(NENTRY),JENTRY(NENTRY),
*           KENTRY(NENTRY)
*
*-------------------------------------- AUTHOR: A. HEBERT ; 02/11/93 ---
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER NENTRY,IENTRY(NENTRY),JENTRY(NENTRY)
      TYPE(C_PTR) KENTRY(NENTRY)
      CHARACTER HENTRY(NENTRY)*12
*----
*  LOCAL VARIABLES
*----
      TYPE(C_PTR) IPLIST,JPLIST
      CHARACTER HSMG*131,TEXT12*12,TEXT4*4,NAMT*12,TEXT2*2
      DOUBLE PRECISION DFLOTT
      LOGICAL LOG
*----
*  PARAMETER VALIDATION.
*----
      IF(NENTRY.LE.1) CALL XABORT('DRVEQU: PARAMETER EXPECTED.')
      NRHS=0
      NLHS=0
      LOG=.FALSE.
      ITYPE=-1
      JPLIST=C_NULL_PTR
      DO 10 I=1,NENTRY
      IF(JENTRY(I).LE.1) THEN
         IF(IENTRY(I).EQ.5) CALL XABORT('DRVEQU: THE EQUALITY MODULE '
     1   //'CANNOT WORKS WITH DIRECT ACCESS FILES (1).')
         NLHS=NLHS+1
         LOG=LOG.OR.(IENTRY(I).LE.2)
         IF(JENTRY(I).EQ.1) THEN
*           Erase the LCM object.
            CALL LCMCL(KENTRY(I),3)
            CALL LCMOP(KENTRY(I),HENTRY(I),1,IENTRY(I),0)
         ENDIF
      ELSE IF(JENTRY(I).EQ.2) THEN
         IF(IENTRY(I).EQ.5) CALL XABORT('DRVEQU: THE EQUALITY MODULE '
     1   //'CANNOT WORKS WITH DIRECT ACCESS FILES (2).')
         NRHS=NRHS+1
         TEXT12=HENTRY(I)
         ITYPE=IENTRY(I)
         IPLIST=KENTRY(I)
         GO TO 20
      ENDIF
   10 CONTINUE
   20 IF(NLHS.EQ.0) THEN
         CALL XABORT('DRVEQU: NO LHS ENTRY.')
      ELSE IF(NRHS.NE.1) THEN
         CALL XABORT('DRVEQU: ONE RHS ENTRY EXPECTED.')
      ENDIF
*----
*  STEP UP/AT FOR THE RHS OBJECT.
*----
      IMPX=1
      IMPY=0
      L1995=0
   30 CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
      IF(INDIC.EQ.10) GO TO 40
      IF(INDIC.NE.3) CALL XABORT('DRVEQU: CHARACTER DATA EXPECTED.')
      IF(TEXT4.EQ.'EDIT') THEN
         CALL REDGET(INDIC,IMPX,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('DRVEQU: INTEGER DATA EXPECTED.')
         IF(IMPX.GE.10) IMPY=1
      ELSE IF(TEXT4.EQ.'OLD') THEN
*        CREATE AN ASCII FILE IN 1995 SPECIFICATION.
         L1995=1
      ELSE IF(TEXT4.EQ.'SAP') THEN
*        IMPORT/CREATE AN ASCII FILE IN SAPHYR SPECIFICATION.
         L1995=2
      ELSE IF(TEXT4.EQ.'STEP') THEN
*        CHANGE THE HIERARCHICAL LEVEL ON THE LCM OBJECT.
         IF(ITYPE.GT.2) CALL XABORT('DRVEQU: UNABLE TO STEP INTO A SE'
     1   //'QUENTIAL FILE.')
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('DRVEQU: CHARACTER DATA EXPECTED.')
         IF(TEXT4.EQ.'UP') THEN
            CALL REDGET(INDIC,NITMA,FLOTT,NAMT,DFLOTT)
            IF(INDIC.NE.3) CALL XABORT('DRVEQU: CHARACTER DATA EXPECT'
     1      //'ED.')
            IF(IMPX.GT.0) WRITE (6,100) NAMT
            JPLIST=LCMGID(IPLIST,NAMT)
         ELSE IF(TEXT4.EQ.'AT') THEN
            CALL REDGET(INDIC,NITMA,FLOTT,NAMT,DFLOTT)
            IF(INDIC.NE.1) CALL XABORT('DRVEQU: INTEGER EXPECTED.')
            IF(IMPX.GT.0) WRITE (6,110) NITMA
            JPLIST=LCMGIL(IPLIST,NITMA)
         ELSE
            CALL XABORT('DRVEQU: UP OR AT EXPECTED.')
         ENDIF
         IPLIST=JPLIST
      ELSE IF(TEXT4.EQ.';') THEN
         GO TO 40
      ELSE
         WRITE(HSMG,'(8HDRVEQU: ,A4,30H IS AN INVALID UTILITY ACTION.)
     1   ') TEXT4
         CALL XABORT(HSMG)
      ENDIF
      GO TO 30
*----
*  RECOVER THE RHS.
*----
   40 NUNIT=0
      IF(LOG.AND.(ITYPE.LE.2)) THEN
         IF(NLHS.EQ.1) THEN
*           FAST COPY.
            DO 45 I=1,NENTRY
            IF(JENTRY(I).LE.1) CALL LCMEQU(IPLIST,KENTRY(I))
   45       CONTINUE
            RETURN
         ENDIF
         NUNIT=KDROPN('DUMMYSQ',0,2,0)
         IF(NUNIT.LE.0) CALL XABORT('DRVEQU: KDROPN FAILURE.')
         CALL LCMEXP(IPLIST,IMPY,NUNIT,1,1)
         REWIND(NUNIT)
      ENDIF
*----
*  CREATE THE LHS.
*----
      DO 50 I=1,NENTRY
      IF(JENTRY(I).LE.1) THEN
         IF((IENTRY(I).LE.2).AND.(ITYPE.LE.2)) THEN
            CALL LCMEXP(KENTRY(I),IMPY,NUNIT,1,2)
            REWIND(NUNIT)
            IF(IMPX.GT.0) WRITE(6,'(/29H DRVEQU: A LCM OBJECT NAMED '',
     1      A12,20H'' WAS SET EQUAL TO '',A12,2H''.)') HENTRY(I),TEXT12
         ELSE IF((IENTRY(I).GE.3).AND.(ITYPE.LE.2)) THEN
            NUNIT2=FILUNIT(KENTRY(I))
            IF((L1995.EQ.1).AND.(IENTRY(I).EQ.4)) THEN
*              THE EXPORT ASCII FILE IS A 1995 SPECIFICATION.
               CALL LCMEXPV3(IPLIST,IMPY,NUNIT2,IENTRY(I)-2,1)
            ELSE IF((L1995.EQ.2).AND.(IENTRY(I).EQ.4)) THEN
*              THE EXPORT ASCII FILE IS A SAPHYR SPECIFICATION.
               CALL LCMEXS(IPLIST,IMPY,NUNIT2,IENTRY(I)-2,1)
            ELSE
               CALL LCMEXP(IPLIST,IMPY,NUNIT2,IENTRY(I)-2,1)
            ENDIF
            REWIND(NUNIT2)
            IF(IMPX.GT.0) WRITE(6,'(/29H DRVEQU: A LCM OBJECT NAMED '',
     1      A12,24H'' WAS EXPORTED TO FILE '',A12,2H''.)') TEXT12,
     2      HENTRY(I)
            IF((IMPX.GT.0).AND.(L1995.EQ.1)) THEN
               WRITE(6,'(/35H DRVEQU: 1995 SPECIFICATION EXPORT.)')
            ELSE IF((IMPX.GT.0).AND.(L1995.EQ.2)) THEN
               WRITE(6,'(/37H DRVEQU: SAPHYR SPECIFICATION EXPORT.)')
            ENDIF
         ELSE IF((IENTRY(I).LE.2).AND.(ITYPE.GE.3)) THEN
            NUNIT2=FILUNIT(IPLIST)
            IF((ITYPE.EQ.4).AND.(L1995.EQ.0)) THEN
               READ(NUNIT2,'(A2)',END=90) TEXT2
               IF(TEXT2.NE.'->') L1995=1
               REWIND(NUNIT2)
            ENDIF
            IF(L1995.EQ.1) THEN
*              THE IMPORT ASCII FILE IS A 1995 SPECIFICATION.
               CALL LCMEXPV3(KENTRY(I),IMPY,NUNIT2,ITYPE-2,2)
            ELSE IF(L1995.EQ.2) THEN
*              THE IMPORT ASCII FILE IS A SAPHYR SPECIFICATION.
               CALL LCMEXS(KENTRY(I),IMPY,NUNIT2,ITYPE-2,2)
            ELSE
               CALL LCMEXP(KENTRY(I),IMPY,NUNIT2,ITYPE-2,2)
            ENDIF
            REWIND(NUNIT2)
            IF(IMPX.GT.0) WRITE(6,'(/29H DRVEQU: A LCM OBJECT NAMED '',
     1      A12,26H'' WAS IMPORTED FROM FILE '',A12,2H''.)') HENTRY(I),
     2      TEXT12
            IF((IMPX.GT.0).AND.(L1995.EQ.1)) THEN
               WRITE(6,'(/35H DRVEQU: 1995 SPECIFICATION IMPORT.)')
            ELSE IF((IMPX.GT.0).AND.(L1995.EQ.2)) THEN
               WRITE(6,'(/37H DRVEQU: SAPHYR SPECIFICATION IMPORT.)')
            ENDIF
         ELSE IF((IENTRY(I).GE.3).AND.(ITYPE.GE.3)) THEN
            WRITE(HSMG,'(43HDRVEQU: UNABLE TO EQUAL THE TWO SEQUENTIAL ,
     1      7HFILES '',A12,7H'' AND '',A12,2H''.)') HENTRY(I),TEXT12
            CALL XABORT(HSMG)
         ENDIF
      ENDIF
   50 CONTINUE
      IF(NUNIT.GT.0) THEN
         IERR=KDRCLS(NUNIT,2)
         IF(IERR.LT.0) THEN
            WRITE(HSMG,'(29HDRVEQU: KDRCLS FAILURE. IERR=,I3)') IERR
            CALL XABORT(HSMG)
         ENDIF
      ENDIF
      RETURN
   90 CALL XABORT('DRVEQU: EOF ENCOUNTERED.')
  100 FORMAT (/27H DRVEQU: STEP UP TO LEVEL ',A12,2H'.)
  110 FORMAT (/26H DRVEQU: STEP AT COMPONENT,I6,1H.)
      END
