function [CLIFT,CDRAG,CMOME]=cpcrcm(APHIJ,EMIJ)

CLIFT=0;
CMOME=0;
CDRAG=0;
NEG=1;
if (EMIJ>1.D0), EMIJ=.99D0;end
SQT=sqrt(1.-EMIJ.*EMIJ);
C1=1.-EMIJ;
C2=.22689*C1;
C5=EMIJ/(SQT.*SQT);
while (APHIJ<0. || APHIJ>pi)
 if(APHIJ<0.), APHIJ=-APHIJ; NEG=-1*NEG;end
 if(APHIJ>pi),APHIJ=APHIJ-pi*2.; end
end
if (APHIJ<C2)
 ASLOP=5.7296/SQT;
 CLIFT=ASLOP*APHIJ;
 CDRAG=.006+.13131*APHIJ*APHIJ;
 CMOME=1.4324*APHIJ/SQT;
else
 CDRAG=1.1233-.029894*cos(APHIJ)-1.00603*cos(2.*APHIJ);
 CDRAG=CDRAG+.003115*cos(3.*APHIJ)-.091487*cos(4.*APHIJ);
 CDRAG=CDRAG/SQT;
 if (APHIJ<.34906)
   CLIFT=.29269*C1+(1.3*EMIJ-.59)*APHIJ;
   C2=(.12217+.22689*EMIJ)*SQT;
   CMOME=CLIFT/(4*C2);       
   CLIFT=CLIFT/C2;
 elseif (APHIJ<2.7402)
   S=sin(APHIJ);
   S2=sin(2.*APHIJ);
   S3=sin(3.*APHIJ);
   S4=sin(4.*APHIJ);
   CLIFT=(.080373*S+1.04308*S2-.011059*S3+.023127*S4)/SQT;
   CMOME=(-.02827*S+.14022*S2-.00622*S3+.01012*S4)/SQT;
 elseif (APHIJ<3.0020)
   CLIFT=-(.4704+.10313*APHIJ)/SQT;
   CMOME=-(.4786+.02578*APHIJ)/SQT;
 elseif(APHIJ<=pi)
 CLIFT=(-17.55+5.5864*APHIJ)/SQT;
 CMOME=(-12.5109+3.9824*APHIJ)/SQT;
 end
end
if (NEG<=0)
 CLIFT=-CLIFT;
 CMOME=-CMOME;
 APHIJ=-APHIJ;
end
CMOME=CMOME-.25*CLIFT;
return
