C++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++C
C                                                            C
C  HIERARCHICAL CLUSTERING using (user-specified) criterion. C
C                                                            C
C  Parameters:                                               C
C                                                            C
C  N                 the number of points being clustered    C
C  DISS(LEN)         dissimilarities in lower half diagonal  C
C                    storage; LEN = N.N-1/2,                 C
C  IOPT              clustering criterion to be used,        C
C  IA, IB, CRIT      history of agglomerations; dimensions   C
C                    N, first N-1 locations only used,       C
C  MEMBR, NN, DISNN  vectors of length N, used to store      C 
C                    cluster cardinalities, current nearest  C
C                    neighbour, and the dissimilarity assoc. C
C                    with the latter.                        C
C  FLAG              boolean indicator of agglomerable obj./ C
C                    clusters.                               C
C                                                            C
C  F. Murtagh, ESA/ESO/STECF, Garching, February 1986.       C
C  R. Ihaka, Modifications for R, December 1996              C
C                                                            C
C------------------------------------------------------------C
      SUBROUTINE HCLUST(N,LEN,IOPT,IA,IB,CRIT,MEMBR,NN,DISNN,
     X                FLAG,DISS)
C     IMPLICIT UNDEFINED(A-H,O-Z)
      DOUBLE PRECISION MEMBR(N),DISS(LEN), DISNN(N)
      INTEGER IA(N),IB(N)
      DOUBLE PRECISION CRIT(N)
      DIMENSION NN(N)
      LOGICAL FLAG(N)
      DOUBLE PRECISION INF, DMIN, X, XX
      DATA INF/1.D+20/
c
c     unnecessary initialization of im jj jm to keep g77 -Wall happy
c
      IM = 0
      JJ = 0
      JM = 0
C
C  Initializations
C
      DO I=1,N
         MEMBR(I)=1.
         FLAG(I)=.TRUE.
      ENDDO
      NCL=N
C
C  Carry out an agglomeration - first create list of NNs
C
      DO I=1,N-1
         DMIN=INF
         DO J=I+1,N
            IND=IOFFSET(N,I,J)
            IF (DISS(IND).GE.DMIN) GOTO 500
               DMIN=DISS(IND)
               JM=J
  500    CONTINUE
         ENDDO
         NN(I)=JM
         DISNN(I)=DMIN
      ENDDO
C
  400 CONTINUE
C     Next, determine least diss. using list of NNs
      DMIN=INF
      DO I=1,N-1
         IF (.NOT.FLAG(I)) GOTO 600
         IF (DISNN(I).GE.DMIN) GOTO 600
            DMIN=DISNN(I)
            IM=I
            JM=NN(I)
  600    CONTINUE
      ENDDO
      NCL=NCL-1
C
C  This allows an agglomeration to be carried out.
C
      I2=MIN0(IM,JM)
      J2=MAX0(IM,JM)
      IA(N-NCL)=I2
      IB(N-NCL)=J2
      CRIT(N-NCL)=DMIN
C
C  Update dissimilarities from new cluster.
C
      FLAG(J2)=.FALSE.
      DMIN=INF
      DO K=1,N
         IF (.NOT.FLAG(K)) GOTO 800
         IF (K.EQ.I2) GOTO 800
         X=MEMBR(I2)+MEMBR(J2)+MEMBR(K)
         IF (I2.LT.K) THEN
                           IND1=IOFFSET(N,I2,K)
                      ELSE
                           IND1=IOFFSET(N,K,I2)
         ENDIF
         IF (J2.LT.K) THEN
                           IND2=IOFFSET(N,J2,K)
                      ELSE
                           IND2=IOFFSET(N,K,J2)
         ENDIF
         IND3=IOFFSET(N,I2,J2)
         XX=DISS(IND3)
C
C  WARD'S MINIMUM VARIANCE METHOD - IOPT=1.
C
         IF (IOPT.EQ.1) THEN
            DISS(IND1)=(MEMBR(I2)+MEMBR(K))*DISS(IND1)+
     X                 (MEMBR(J2)+MEMBR(K))*DISS(IND2)-
     X                 MEMBR(K)*XX
            DISS(IND1)=DISS(IND1)/X
         ENDIF
C
C  SINGLE LINK METHOD - IOPT=2.
C
         IF (IOPT.EQ.2) THEN
            DISS(IND1)=MIN(DISS(IND1),DISS(IND2))
         ENDIF
C
C  COMPLETE LINK METHOD - IOPT=3.
C
         IF (IOPT.EQ.3) THEN
            DISS(IND1)=MAX(DISS(IND1),DISS(IND2))
         ENDIF
C
C  AVERAGE LINK (OR GROUP AVERAGE) METHOD - IOPT=4.
C
         IF (IOPT.EQ.4) THEN
            DISS(IND1)=(MEMBR(I2)*DISS(IND1)+MEMBR(J2)*DISS(IND2))/
     X                 (MEMBR(I2)+MEMBR(J2))
         ENDIF
C
C  MCQUITTY'S METHOD - IOPT=5.
C
         IF (IOPT.EQ.5) THEN
            DISS(IND1)=0.5*DISS(IND1)+0.5*DISS(IND2)
         ENDIF
C
C  MEDIAN (GOWER'S) METHOD - IOPT=6.
C
         IF (IOPT.EQ.6) THEN
            DISS(IND1)=0.5*DISS(IND1)+0.5*DISS(IND2)-0.25*XX
         ENDIF
C
C  CENTROID METHOD - IOPT=7.
C
         IF (IOPT.EQ.7) THEN
            DISS(IND1)=(MEMBR(I2)*DISS(IND1)+MEMBR(J2)*DISS(IND2)-
     X          MEMBR(I2)*MEMBR(J2)*XX/(MEMBR(I2)+MEMBR(J2)))/
     X          (MEMBR(I2)+MEMBR(J2))
            ENDIF
C
         IF (I2.GT.K) GOTO 800
         IF (DISS(IND1).GE.DMIN) GOTO 800
            DMIN=DISS(IND1)
            JJ=K
  800    CONTINUE
      ENDDO
      MEMBR(I2)=MEMBR(I2)+MEMBR(J2)
      DISNN(I2)=DMIN
      NN(I2)=JJ
C
C  Update list of NNs insofar as this is required.
C
      DO I=1,N-1
         IF (.NOT.FLAG(I)) GOTO 900
         IF (NN(I).EQ.I2) GOTO 850
         IF (NN(I).EQ.J2) GOTO 850
         GOTO 900
  850    CONTINUE
C        (Redetermine NN of I:)
         DMIN=INF
         DO J=I+1,N
            IND=IOFFSET(N,I,J)
            IF (.NOT.FLAG(J)) GOTO 870
            IF (I.EQ.J) GOTO 870
            IF (DISS(IND).GE.DMIN) GOTO 870
               DMIN=DISS(IND)
               JJ=J
  870       CONTINUE
         ENDDO
         NN(I)=JJ
         DISNN(I)=DMIN
  900    CONTINUE
      ENDDO
C
C  Repeat previous steps until N-1 agglomerations carried out.
C
      IF (NCL.GT.1) GOTO 400
C
C
      RETURN
      END
C
C
      FUNCTION IOFFSET(N,I,J)
C  Map row I and column J of upper half diagonal symmetric matrix 
C  onto vector.
      IOFFSET=J+(I-1)*N-(I*(I+1))/2
      RETURN
      END
C+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++C
C                                                               C
C  Given a HIERARCHIC CLUSTERING, described as a sequence of    C
C  agglomerations, prepare the seq. of aggloms. and "horiz."    C
C  order of objects for plotting the dendrogram using S routine C
C  'plclust'.                                                   C
C                                                               C
C  Parameters:                                                  C
C                                                               C
C  IA, IB:       vectors of dimension N defining the agglomer-  C
C                 ations.                                       C
C  IIA, IIB:     used to store IA and IB values differently     C
C                (in form needed for S command `plclust`        C
C  IORDER:       "horiz." order of objects for dendrogram       C
C                                                               C
C  F. Murtagh, ESA/ESO/STECF, Garching, June 1991               C
C                                                               C
C  HISTORY                                                      C
C                                                               C
C  Adapted from routine HCASS, which additionally determines    C
C   cluster assignments at all levels, at extra comput. expense C
C                                                               C
C---------------------------------------------------------------C
      SUBROUTINE HCASS2(N,IA,IB,IORDER,IIA,IIB)
      INTEGER IA(N),IB(N),IORDER(N),IIA(N),IIB(N)
C
C     Following bit is to get seq. of merges into format acceptable to plclust
C     I coded clusters as lowest seq. no. of constituents; S's `hclust' codes
C     singletons as -ve numbers, and non-singletons with their seq. nos.
C
      DO 912 I=1,N
         IIA(I)=IA(I)
         IIB(I)=IB(I)
  912 CONTINUE
      DO 915 I=1,N-2
C        In the following, smallest (+ve or -ve) seq. no. wanted
         K=MIN(IA(I),IB(I))
         DO 913 J=I+1, N-1
            IF(IA(J).EQ.K) IIA(J)=-I
            IF(IB(J).EQ.K) IIB(J)=-I
  913    CONTINUE
  915 CONTINUE
      DO 916 I=1,N-1
         IIA(I)=-IIA(I)
         IIB(I)=-IIB(I)
  916 CONTINUE
      DO 917 I=1,N-1
         IF (IIA(I).GT.0.AND.IIB(I).LT.0) THEN
            K = IIA(I)
            IIA(I) = IIB(I)
            IIB(I) = K
         ENDIF
         IF (IIA(I).GT.0.AND.IIB(I).GT.0) THEN
            K1 = MIN(IIA(I),IIB(I))
            K2 = MAX(IIA(I),IIB(I))
            IIA(I) = K1
            IIB(I) = K2
         ENDIF
  917 CONTINUE
C
C
C     NEW PART FOR `ORDER'
C
      IORDER(1) =IIA(N-1)
      IORDER(2) =IIB(N-1)
      LOC=2
      DO 175 I=N-2,1,-1
        DO 169 J=1,LOC
          IF(IORDER(J).EQ.I) THEN
C           REPLACE IORDER(J) WITH IIA(I) AND IIB(I)
            IORDER(J)=IIA(I)
            IF (J.EQ.LOC) THEN
                LOC=LOC+1
                IORDER(LOC)=IIB(I)
                GOTO 171
            ENDIF
            LOC=LOC+1
            DO 95 K=LOC,J+2,-1
               IORDER(K)=IORDER(K-1)
  95        CONTINUE
            IORDER(J+1)=IIB(I)
            GOTO 171
          ENDIF
 169    CONTINUE
C       SHOULD NEVER REACH HERE
 171    CONTINUE
 175  CONTINUE
C
C
      DO 181 I=1,N
         IORDER(I) = -IORDER(I)
 181  CONTINUE
C
C
      RETURN
      END
