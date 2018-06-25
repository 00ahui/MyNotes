archive_expire_objects {

  *ContInxOld = 1;
  *Count = 0;
  msiGetIcatTime(*Time,"unix");

  #Loop over files in the collection
  msiMakeGenQuery("DATA_ID,DATA_NAME,DATA_EXPIRY","COLL_NAME = '*Coll'", *GenQInp);
  msiExecGenQuery(*GenQInp, *GenQOut);
  msiGetContInxFromGenQueryOut(*GenQOut,*ContInxNew);
  while(*ContInxOld > 0) {
    foreach(*GenQOut) {
      msiGetValByKey(*GenQOut,"DATA_EXPIRY",*Attrname);
      if(*Attrname <= *Time) {
        msiGetValByKey(*GenQOut,"DATA_NAME",*File);
        writeLine("stdout","File *Coll/*File has expired, archive to *dstResc");
        msiDataObjRepl("*Coll/*File","destRescName=*dstResc",*Status);
        msiDataObjTrim("*Coll/*File","*srcResc","null","1","null",*Status);
        *Count = *Count + 1;
      }
      *ContInxOld = *ContInxNew;
      if(*ContInxOld > 0) {msiGetMoreRows(*GenQInp,*GenQOut,*ContInxNew);}
    }
  }
}
INPUT *Coll = "/zone0/home/admin/test", *srcResc = "resc1", *dstResc = "demoResc"
OUTPUT ruleExecOut
