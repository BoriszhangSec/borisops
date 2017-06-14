# Purpose : Parse the access log
# Author  : ZhiLiang Han

# ---- Functions Begin ----
function IniMonth() {
        Month["Jan"] = 1;
        Month["Feb"] = 2;
        Month["Mar"] = 3;
        Month["Apr"] = 4;
        Month["May"] = 5;
        Month["Jun"] = 6;
        Month["Jnl"] = 7;
        Month["Aug"] = 8;
        Month["Sep"] = 9;
        Month["Oct"] = 10; 
        Month["Nov"] = 11; 
        Month["Dec"] = 12; 
}

function SetArrByArr(arr1,arr2, arr2_size, i) {
    for(i=1; i<=arr2_size; i++) {
        arr1[arr2[i]] = 0;   
    }
}

function InitHttpStatus(HttpStatus,arr, size) {
    #HttpResCode="100,101";
    #size = split(HttpResCode, arr, ",");
    #SetArrByArr(HttpStatus, arr, size);
    #SetArrByArr(PeriodHttpStatus, arr, size);

    #HttpResCode="200,201,202,203,204,205,206";
    #size = split(HttpResCode, arr, ",");
    #SetArrByArr(HttpStatus, arr, size);
    #SetArrByArr(PeriodHttpStatus, arr, size);

    #HttpResCode="300,301,302,303,304,305,307";
    HttpResCode="0,200,303,404,500,503,Err";
    size = split(HttpResCode, arr, ",");
    SetArrByArr(HttpStatus, arr, size);
    SetArrByArr(PeriodHttpStatus, arr, size);

    #HttpResCode="400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417";
    #size = split(HttpResCode, arr, ",");
    #SetArrByArr(HttpStatus, arr, size);
    #SetArrByArr(PeriodHttpStatus, arr, size);

    #HttpResCode="500,501,502,503,504,505";
    #size = split(HttpResCode, arr, ",");
    #SetArrByArr(HttpStatus, arr, size);
    #SetArrByArr(PeriodHttpStatus, arr, size);
}

# Timestr format : day/month/year:hour:min:sec
function ConvTimeStr(timestr, timezone, curtimezone, year, month, day, hour, min, sec, i,j,k) {
        i = split(timestr,dateArr, "/");
        day=dateArr[1];
        month = Month[dateArr[2]];
        i = split(dateArr[3], timeArr, ":");
        year = timeArr[1];
        hour = timeArr[2];
        min = timeArr[3];
        sec = timeArr[4];
        i = sprintf("%d %d %d %d %d %d", year, month, day, hour, min, sec);
        i = mktime(i);
        
        curtimezone = strftime("%z", systime());
        if(curtimezone == timezone) {
            return i;
        } else {
            j = substr(curtimezone, 1, 1) ==  "-" ? -1 * (substr(curtimezone, 2, 1)*10 + substr(curtimezone, 3,1)) \
              : substr(curtimezone, 2, 1)*10 + substr(curtimezone, 3,1);
            k = substr(timezone, 1, 1) == "-" ? -1 * (substr(timezone, 2, 1)*10 + substr(timezone, 3, 1)) \
              : substr(timezone, 2, 1)*10 + substr(timezone, 3, 1); 
            i += (j - k) * 3600;

            return i;
        }
}

# Check time day align
function IsDayAlign(timestamp, hour, min, sec, i) {
    hour = strftime("%k", timestamp);
    min = strftime("%M", timestamp);
    sec = strftime("%S", timestamp);
    return ((hour == 0) &&
             (min == 0) &&
             (sec == 0));
}

function IsDayChange(time1, time2, day1, day2) {
    day1 = strftime("%F", time1);
    day2 = strftime("%F", time2);
    return (day1 != day2);
}

function PrintArrCaption(arr, filename, var, Caption) {
       Caption = sprintf("Time");
       for(var in arr){
           Caption = sprintf("%s,%s", Caption, var);
       }
       print Caption >> filename;
}

function PrintArrEleAndReset(arr, filename, period, RecTimeString, var, line) {
    
    if(period == "day") {
        RecTimeString = strftime("%F %T", PreRecDayTime);
    } else if(period == "5min") {
        RecTimeString = strftime("%F %T", PreRecTime);
    } else {
        RecTimeString = strftime("%F %T", CurRecTime);
    }

    line = sprintf("%s", RecTimeString);
    for(var in arr){
        line = sprintf("%s,%d", line, arr[var]);
        arr[var] = 0;
    }
    print line >> filename;
}

function PrintArrIndexEleAndReset(arr, filename, period, var, prefix) {
    
    if(period == "day") {
        RecTimeString = strftime("%F %T", PreRecDayTime);
    } else if(period == "5min") {
        RecTimeString = strftime("%F %T", PreRecTime);
    } else {
        RecTimeString = strftime("%F %T", CurRecTime);
    } 
    
    prefix = sprintf("%s", RecTimeString);
    for(var in arr) {
        print prefix "," var "," arr[var] >> filename;
        delete arr[var];
    }
}

function PrintUipCaption(filename, UipCaption) {
   UipCaption = "Time,IP,Times";
   print UipCaption >> filename;
}

function PrintUrlCaption(filename, UrlCaption) {
    UrlCaption = "Time,Url,Times";
    print UrlCaption >> filename;
}

function PrintReferCaption(filename, ReferCaption) {
    ReferCaption = "Time,Refer,Times";
    print ReferCaption >> filename;
}

function PrintPlayerCaption(filename, PlayerCaption) {
    PlayerCaption = "Time,Player,Times";
    print PlayerCaption >> filename;
}

function PeriodOutputSts(Caption, line, var) {
    #Print the caption
    if(FirstOut == 0) {
        #Http Status Period statics
        PrintArrCaption(PeriodHttpStatus, PrdHttpStatusFile);
        #Ip Period statics
        PrintUipCaption(PrdUipFile);
        #Url Period statics
        PrintUrlCaption(PrdUrlFile);
        #Refer caption
        PrintReferCaption(PrdReferFile);
        #Player caption
        PrintPlayerCaption(PrdPlayerFile);

        FirstOut = 1;
    }
    #HttpStatus
    PrintArrEleAndReset(PeriodHttpStatus, PrdHttpStatusFile, "5min");
    #Uip
    PrintArrIndexEleAndReset(PeriodUip, PrdUipFile, "5min");
    #Url
    PrintArrIndexEleAndReset(PeriodUurl, PrdUrlFile, "5min");
    #Refer
    PrintArrIndexEleAndReset(PeriodRefer, PrdReferFile, "5min");
    #Player
    PrintArrIndexEleAndReset(PeriodUplayer, PrdPlayerFile, "5min");
}

function PeriodProc() {
    PeriodOutputSts();
}

function OutputHttpStatus(flag, num) {
    if(flag) {
        sprintf("cat %s/httpstatus/status.sts|wc -l", FilePrefix) | getline num;
        if(num < 1) {
            PrintArrCaption(HttpStatus, HttpStatusFile);       
        }
    } else {
        PrintArrEleAndReset(HttpStatus, HttpStatusFile, "day");
    }
}

function OutputUip(flag, num) {
    
    if(flag) {
        sprintf("cat %s/uip/uip.sts|wc -l", FilePrefix) | getline num;   
        if(num < 1) { 
            PrintUipCaption(UipFile);   
        }
    } else {
        PrintArrIndexEleAndReset(UniqIp, UipFile, "day");
    }
}

function OutputUrl(flag, num) {
    if(flag) {
        sprintf("cat %s/url/url.sts|wc -l", FilePrefix) | getline num;
        if(num < 1) { 
            PrintUrlCaption(UrlFile);
        }
    } else {
        PrintArrIndexEleAndReset(UniqUrl, UrlFile, "day");
    }
}

function OutputRefer(flag, num) {
    if(flag) {
        sprintf("cat %s/refer/refer.sts|wc -l", FilePrefix) | getline num;   
        if(num < 1) {
            PrintReferCaption(ReferFile);        
        }
    } else {
        PrintArrIndexEleAndReset(Refer, ReferFile, "day");
    }
}

function OutputPlayer(flag, num) {
    if(flag) {
        sprintf("cat %s/player/player.sts|wc -l", FilePrefix) | getline num;
        if(num < 1) { 
            PrintPlayerCaption(PlayerFile);
        }
    } else {
        PrintArrIndexEleAndReset(Player, PlayerFile, "day");
    }
}

function OutputSts(flag) {
    OutputHttpStatus(flag);
    OutputUip(flag);
    OutputUrl(flag);
    OutputRefer(flag);
    OutputPlayer(flag);
}

function SortHttpStatuDaySts(tmp, KeyArr, ValArr, PreVal, Date, PreDate, i, size,Total) {
    fflush(HttpStatusFile);
    close(HttpStatusFile);
    system(sprintf("rm -rf %s", HttpStatusSortFile));

    sprintf("cat %s | grep Time", HttpStatusFile) | getline tmp;
    print sprintf("%s,Total",tmp) > HttpStatusSortFile;
    size = split(tmp, KeyArr, ",");
    PreDate = "";
    Total = 0;
    while(sprintf("cat %s | sort -k 1|grep -v Time", HttpStatusFile) | getline) {
        split($2, ValArr, ",");
        Date = $1;
        #for the first time
        if(PreDate == "") {
           for(i=2; i<=size; i++) {
               PreVal[i] = ValArr[i];
           } 
           PreDate = Date;
        } else {
            if(Date == PreDate) {
                for(i=2; i<=size; i++) {
                    PreVal[i] += ValArr[i];
                }
            } else {
                tmp = sprintf("%s",PreDate);
                for(i=2; i<=size; i++){
                    tmp =sprintf("%s,%d",tmp, PreVal[i]);
                    Total += PreVal[i];
                    PreVal[i] = ValArr[i];
                }
                print sprintf("%s,%d", tmp, Total) > HttpStatusSortFile;
                PreDate = Date;
                Total = 0;
            }
        } 
    }

    #Print the last line
    tmp = sprintf("%s",PreDate);
    for(i=2; i<=size; i++){
        tmp =sprintf("%s,%d",tmp, PreVal[i]);
        Total += PreVal[i]
    }
    print sprintf("%s,%d", tmp, Total) > HttpStatusSortFile;
}

function SetWhiteFile() {
    FileWhiteList["actmp.log"] = 1;
}

# Check whether the file is parsed.
function CheckProcFiles(filesArr, basename) {
    #Jump white file
    close(sprintf("basename %s", FILENAME) | getline basename); 
    if(FileWhiteList[basename] == 1) {
	ImmLeave = 1;
        return;
    }

    if(ImmLeave) exit;

    while(sprintf("cat %s", FilesPsd)|getline FilePsd) { 
        #filesArr[FilePsd] = 1;
        if(FilePsd ~ FILENAME) {
            ImmLeave = 1;
            nextfile;
        }
    }
	
    close(FilesPsd);

    #if(filesArr[FILENAME] == 1) {
    #    ImmLeave = 1;
    #    nextfile;
    #}
    
}

# Put file to parsed list
function PutFileToFilePsd() {
    print FILENAME >> FilesPsd;   
}

# ---- Functions END ----

# BEGIN section, all initial work do here
BEGIN {
    #TimeNow
    TimeNow = strftime("%F_%T", systime());
    StartRecTimeStr = "";
    #FilePrefix, for data output
    FilePrefix = "/SO-AcLog/wan";
    system(sprintf("mkdir -p %s", FilePrefix));

    #File list had parsed
    FilesPsd = sprintf("%s/filels.psd", FilePrefix);
    # When file in FileWhiteList, file must be Parsed
    # - FileWhiteList
    SetWhiteFile();

    # Avoid Error or warning
    system(sprintf("touch %s", FilesPsd));
    IfFilePsd = 0;
    ImmLeave = 0;

    #Move the old log to new position

    #HttpStatusFile
    system(sprintf("mkdir -p %s/httpstatus/", FilePrefix));
    HttpStatusFile = sprintf("%s/httpstatus/status.sts", FilePrefix);
    PrdHttpStatusFile = sprintf("%s/httpstatus/%s.prd", FilePrefix, TimeNow);
    HttpStatusSortFile = sprintf("%s/httpstatus/status-wan.sort", FilePrefix);
    system(sprintf("touch %s", HttpStatusFile));
    #system(sprintf("touch %s", PrdHttpStatusFile));
    system(sprintf("touch %s", HttpStatusSortFile));

    #UipFile
    system(sprintf("mkdir -p %s/uip/",FilePrefix));
    UipFile = sprintf("%s/uip/uip.sts", FilePrefix);
    PrdUipFile = sprintf("%s/uip/%s.prd", FilePrefix, TimeNow);
    system(sprintf("touch %s", UipFile));
    #system(sprintf("touch %s", PrdUipFile));

    #UrlFile
    system(sprintf("mkdir -p %s/url/",FilePrefix));
    UrlFile = sprintf("%s/url/url.sts", FilePrefix);
    PrdUrlFile = sprintf("%s/url/%s.prd", FilePrefix, TimeNow);
    system(sprintf("touch %s", UrlFile));
    #system(sprintf("touch %s", PrdUrlFile));

    #Refer
    system(sprintf("mkdir -p %s/refer/",FilePrefix));
    ReferFile = sprintf("%s/refer/refer.sts", FilePrefix);
    PrdReferFile = sprintf("%s/refer/%s.prd", FilePrefix, TimeNow);
    system(sprintf("touch %s", ReferFile));
    #system(sprintf("touch %s", PrdReferFile));


    #PlayerFile
    system(sprintf("mkdir -p %s/player/",FilePrefix));
    PlayerFile = sprintf("%s/player/player.sts", FilePrefix);
    PrdPlayerFile = sprintf("%s/player/%s.prd", FilePrefix, TimeNow);
    system(sprintf("touch %s", PlayerFile));
    #system(sprintf("touch %s", PrdPlayerFile));

    #Month array, for handling the disgusting log format
    IniMonth();
    InitHttpStatus(HttpStatus);
    
    #Print Caption
    OutputSts(1);

    #----------Global Declaration Begin-----------
    #UniqIp statistic
    # - UniqIp; 
    # - PeriodUip;

    #UniqUrl statistic
    # - UniqUrl;
    # - PeriodUurl;

    #Player statistic
    # - Player;
    # - PeriodUplayer;

    #Status statistic
    # - HttpStatus;
    # - PeriodHttpStatus;

    #Request times statistic
    PeriodReqTimes = 0;
    TotalReqTimes = 0;
    
    #PeriodTime, time for loop
    FixPeriod = 60*60;
    PreRecTime = 0;
    OneDay = 24 * 3600;
    PreRecDayTime = 0;

    #Current Record timestamp
    CurRecTime = 0;

    #Flag for first output the caption
    FirstOut = 0;

    #-----------------Global DCX End --------------------
}

# ----Patern begin, for every line process----

# Check whether the file is parsed;
IfFilePsd == 0 {    
    CheckProcFiles();
    IfFilePsd = 1;
}

# Blank line, do nothing
/^[ \t\n]*$/ { 
    next;
}

$0 ~ "127.0.0.1" {
   next;
}

# Jump invalid line, loose check
NF < 12 {
    next;   
}

# Get current log timestamp
{
        CurTimeStr = $9;
        TimeZone = $10;
        sub(/[\[\]]/, "", CurTimeStr);
        sub(/[\[\]]/, "", TimeZone);
        CurRecTime = ConvTimeStr(CurTimeStr, TimeZone);
        if(CurRecTime <= 0) {
            print "Err: CurRecTime is",CurRecTime",TimeStr is",CurTimeStr;
            print "The Record:",$0;

            next;
        }
}

# Set PreRecTime
PreRecTime == 0 || PreRecDayTime == 0 {
    StartRecTimeStr = strftime("%F %T", CurRecTime);
    if(CurRecTime > 0) {
        PreRecTime = CurRecTime;
        PreRecDayTime = CurRecTime;
     }else { 
        next;
     }
}

# Check output period 5 Min
CurRecTime - PreRecTime > FixPeriod {
    PeriodProc();
    PreRecTime = CurRecTime;
}

# Check period for one day
( IsDayAlign(CurRecTime) && (CurRecTime != PreRecDayTime) ) || 
( IsDayChange(CurRecTime, PreRecDayTime) ) ||
( CurRecTime - PreRecDayTime >= OneDay ) {
    OutputSts(0);
    PreRecDayTime = CurRecTime;
}

# Set the log field
{
    #Every 5 MIN
    PeriodReqTimes++;
    #Every Day
    TotalReqTimes++;

    if(length($14) > 3) {
        #A invalid line to parse
        HttpStatus["Err"]++;
        PeriodHttpStatus["Err"]++;

        next;
    }

    if($14 >= 100 && $14 <600) {
        HttpStatus[$14]++;
        PeriodHttpStatus[$14]++;
    } else {
        #A invalid line to parse
        HttpStatus["Err"]++;
        PeriodHttpStatus["Err"]++;
        
        next;
    }

    UniqIp[$6]++;
    PeriodUip[$6]++;

    UniqUrl[$12]++;
    PeriodUurl[$12]++;
    
    Refer[$16]++;
    PeriodRefer[$16]++;

    Player[$17]++;
    PeriodUplayer[$17]++;
}

# End Section
END {
    CheckProcFiles();

    PeriodProc();      
    OutputSts(0);
    SortHttpStatuDaySts();

    PutFileToFilePsd();
}
