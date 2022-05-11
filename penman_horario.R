# Tmax - Max temperature
# Tmin - Min temperature
# z - Altitude
# u2 - Wind speed at 2m
# Rs - Solar radiation

# lat - Latitude (Decimal degrees)
# long - Longitude (Decimal degrees)

penman_horario <- 
  function(Tmax, Tmin, z, RHhr, u2, Rs, hour, day, month, year, lat, long){
    long = abs(long)
    
    Thr <- (Tmax+Tmin)/2
    
    if(sum(is.na(Thr),is.na(z),is.na(RHhr), is.na(u2), is.na(Rs))>0){
      return(NA);
    }
    if(Rs<0){
      Rs = 0;
    }
    
    DELTA <- (4098*(0.61088*exp((17.27*Thr)/(Thr+237.3)))/((Thr+237.3)^2))
    
    lambda <- 2.501 - 2.361e-3*Thr
    
    P <- 101.3*((293-0.0065*z)/293)^5.26
    
    gamma <- 1.63e-3*P/lambda
    
    eoT <- 0.61088*exp((17.27*Thr)/(Thr+237.3))
    eoTmax <- 0.61088*exp((17.27*Tmax)/(Tmax+237.3))
    eoTmin <- 0.61088*exp((17.27*Tmin)/(Tmin+237.3))
    eTH <- 0.6108*exp((17.27*Thr)/(Thr+237.3))
    
    es <- (eoTmax+eoTmin)/2
    
    ea<-eTH*(RHhr/100)
    
    J<-as.integer(275*month/9-30+day)-2
    
    if(month<3){
      J <- J+2
    }
    
    if((year %% 4) == 0) {
      if((year %% 100) == 0) {
        if((year %% 400) == 0) {
          if(month > 2){
            J <- J+1 
          }
        }
      } else {
        if(month > 2){
          J <- J+1 
        }
      }
    }
    
    fi <- (pi/180)*lat
    
    dr<- 1+ 0.033*cos((2*pi/365)*J)
    
    delta <- 0.409*sin((2*pi/365)*J-1.39)
    
    b <- (2*pi*(J-81))/364
    
    Sc<-0.1645*sin(2*b)-0.1255*cos(b)-0.025*sin(b)
    
    if(long >= 3){
      lz <- round(long/15, 0)*15
    }else{
      lz<-0
    }
    
    t <- hour/100 -0.5;
    
    omega <- (pi/12)*((t+0.06667*(lz-long)+Sc)-12)
    
    omega1<-omega-(pi/24)
    omega2<-omega+(pi/24)
    
    Ra <- (12*60/pi)*0.082*dr*((omega2-omega1)*sin(fi)*sin(delta)+cos(fi)*cos(delta)*(sin(omega2)-sin(omega1)))
    
    temp <-0;
    if(Rs<=0){
      Rso<-0
    }else{
      Rso<- (0.75+2*z*10^(-5))*Ra  
    }
    
    Rns<- (1-0.23)*Rs
    
    if(Rns == 0){
      Ra <- 0;
    }
    
    stefanBoltzmanHourly <- (4.903*10^-9)*(Thr+273.16)^4/24
    
    if(Rso<=0){
      Rnl = (2.043*10^(-10))*((Tmax+273.16)^4)*(0.34-0.14*sqrt(ea))*(1.35*(0.8)-0.35)
    }else{
      Rnl = (2.043*10^(-10))*((Tmax+273.16)^4)*(0.34-0.14*sqrt(ea))*(1.35*(Rs/Rso)-0.35)
    }
    
    Rn<- Rns-Rnl
    
    G<-0;
    if(Rs<=0){
      G <- 0.5*Rn
    }else{
      G <- 0.1*Rn
    }
    
    Eto <- (0.408*DELTA*(Rn-G)+(gamma*(37/(Thr+273))*u2*(es-ea)))/(DELTA+gamma*(1+0.34*u2))
    
    if(Eto<0){
      Eto=0;
    }
    return(round(Eto, digits=2));    
  }