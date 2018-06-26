# core rule exmaples
# put this file to the end of file /etc/irods/core.re

acPreprocForDataObjOpen { 
  # version control
  ON ($objPath like "/zone0/home/admin/test/*") {
    # if it's a write operation
    if($writeFlag == "1") {
        *coll = trimr($objPath, "/");
        *name = substr($objPath, strlen(*coll)+1, strlen($objPath));
        foreach(*d in SELECT DATA_MODIFY_TIME WHERE COLL_NAME = *coll AND DATA_NAME = *name) {
            msiGetValByKey(*d, "DATA_MODIFY_TIME", *v);
            *Tim = timestrf(datetimef(*v, "%s"), "%Y%m%d%H%M%S");
            *newName = "/zone0/home/admin/testbkup/*name.*Tim";
            msiDataObjCopy($objPath, *newName, "destRescName=resc1++++forceFlag=", *status);
        }
    }
  }
}
