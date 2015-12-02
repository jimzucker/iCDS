/*
 * ISDA CDS Standard Model
 *
 * Copyright (C) 2009 International Swaps and Derivatives Association, Inc.
 * Developed and supported in collaboration with Markit
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the ISDA CDS Standard Model Public License.
 */

#include "version.h"
#include "macros.h"
#include "cerror.h"
#include "tcurve.h"
#include "cdsone.h"
#include "convert.h"
#include "zerocurve.h"
#include "cds.h"
#include "cxzerocurve.h"
#include "dateconv.h"
#include "date_sup.h"
#include "busday.h"
#include "ldate.h"
#include "cashflow.h"

int CDS_FeeLegFlows( TDate startDate
	, TDate endDate
	, double rate
	, double notional
	, char *couponInterval
	, char *stubType
	, char *paymentDcc
	, char badDayConv
	, char *holidays
				   
)
{
    static char   *routine = "CDS_FeeLegFlows";
    int            status = 1;

	
    int            i;
	
	TStubMethod    stub;    
//  SET_DEFAULT(stubType, "f/s");
    if (JpmcdsStringToStubMethod(stubType, &stub) != SUCCESS)
        goto done;
	
	long           dcc;
//	SET_DEFAULT(paymentDcc, "ACT/360");
    if (JpmcdsStringToDayCountConv(paymentDcc, &dcc) != SUCCESS)
        goto done;
		
	TDateInterval  ivl;
    if (JpmcdsStringToDateInterval(couponInterval, routine, &ivl) != SUCCESS)
        goto done;

	
	TCashFlowList *cfl = JpmcdsCdsFeeLegFlows(startDate,
                               endDate,
                               &ivl,
                               &stub,
                               notional,
                               rate,
                               dcc,
                               badDayConv,
                               holidays);
	
    if (cfl == NULL)
        goto done;
    
	
	printf("\n CashFlows: \n");
    for (i = 0; i < cfl->fNumItems; i++)
    {
		printf("%s : %10.2f\n",JpmcdsFormatDate(cfl->fArray[i].fDate), cfl->fArray[i].fAmount);
    }
	
    status = SUCCESS;
	
done:
    JpmcdsFreeCFL(cfl);
 //   FREE(stubType);
 //FREE(paymentDcc);
	return status;
}

/*
 ***************************************************************************
 ** Build IR zero curve.
 ***************************************************************************
 */
TCurve* BuildExampleZeroCurve(char *maturities[],double rates[], TDate spotDate
							  , char *currency
							  , char baddayconvention			
							  , char *holidays			
							  , char *moneyMarketDCC			
							  , char *swapFixedDCC
							  , char *swapFloatDCC
							  , char *swapFloatFreq
							  , char *swapFixFreq
							  , char *types
							  )
{
    static char  *routine		= "BuildExampleZeroCurve"	;
    TCurve       *zc			= NULL						;
	
	//default to USD Curve
	currency			= currency == NULL			? "USD"		: currency			;
	baddayconvention	= baddayconvention == '?'	? 'M'		: baddayconvention	;			
	holidays			= holidays == NULL			? "none"	: holidays			;
	moneyMarketDCC		= moneyMarketDCC == NULL	? "Act/360"	: moneyMarketDCC	;
	swapFixedDCC		= swapFixedDCC == NULL		? "Act/360" : swapFixedDCC		;
	swapFloatDCC		= swapFloatDCC == NULL		? "30/360"	: swapFloatDCC		;
	swapFloatFreq		= swapFloatFreq == NULL		? "3M"		: swapFloatFreq		;
	swapFixFreq			= swapFixFreq == NULL		? "6M"		: swapFixFreq		;
	types				= types == NULL				? "MMMMMSSSSSSSSSSSSSSS" : types ;

	//default curve from 24Nov2009
	char *default_maturities[20] = {"1M", "2M", "3M", "6M", "9M", "1Y", "2Y", "3Y", "4Y", "5Y", "6Y", "7Y", "8Y", "9Y", "10Y", "12Y", "15Y", "20Y", "25Y", "30Y"};
	double default_rates[20] = {0.002359, 0.002469, 0.002619, 0.004856, 0.007600, 0.010200, 0.010613, 0.016504, 0.021211, 0.024921, 0.027881, 0.030174, 0.031988, 0.033504,0.034766,0.036861,0.039056,0.040675, 0.041384,0.041783};
	maturities			= maturities == NULL			? default_maturities : maturities	;
	rates				= rates	== NULL				? default_rates	   : rates		;
	
	//convert format of inputs
	long mmDCC, fixDCC, floatDCC;
	double fixFreq, floatFreq	;
	if (JpmcdsStringToDayCountConv(moneyMarketDCC, &mmDCC) != SUCCESS)		goto done;
	if (JpmcdsStringToDayCountConv(swapFixedDCC, &fixDCC) != SUCCESS)		goto done;
	if (JpmcdsStringToDayCountConv(swapFloatDCC, &floatDCC) != SUCCESS)		goto done;
		
	TDateInterval ivl;
	if (JpmcdsStringToDateInterval(swapFixFreq, routine, &ivl) != SUCCESS)		goto done;
	if (JpmcdsDateIntervalToFreq(&ivl, &fixFreq) != SUCCESS)					goto done;
	if (JpmcdsStringToDateInterval(swapFloatFreq, routine, &ivl) != SUCCESS)	goto done;
	if (JpmcdsDateIntervalToFreq(&ivl, &floatFreq) != SUCCESS)					goto done;
		
  //  baseDate = JpmcdsDate(2008, 1, 3);
	
    int numberInstruments = strlen(types);

    TDate *dates = NEW_ARRAY(TDate, numberInstruments);
    for (int i = 0; i < numberInstruments; i++)
    {
        TDateInterval tmp;		
        if (JpmcdsStringToDateInterval(maturities[i], routine, &tmp) != SUCCESS)
        {
            JpmcdsErrMsg ("%s: invalid interval for element[%d].\n", routine, i);
            goto done;
        }
        
        if (JpmcdsDateFwdThenAdjust(spotDate, &tmp, JPMCDS_BAD_DAY_NONE, "None", dates+i) != SUCCESS)
        {
            JpmcdsErrMsg ("%s: invalid interval for element[%d].\n", routine, i);
            goto done;
        }
    }
	
    //printf("calling JpmcdsBuildIRZeroCurve...\n");
    zc = JpmcdsBuildIRZeroCurve(spotDate,
								types,
								dates,
								rates,
								numberInstruments,
								mmDCC,
								(long) fixFreq,
								(long) floatFreq,
								fixDCC,
								floatDCC,
								baddayconvention,
								holidays);
done:
    FREE(dates);
    return zc;
}
/*
void printTCurve(TCurve *theCurve)
{
    printf("BaseDate     = %d %d %d\n", theCurve->fBaseDate);
    printf("NumItems     = %d\n", theCurve->fNumItems);
    printf("Basis        = %f\n", theCurve->fBasis);
    printf("DayCountConv = %d\n", theCurve->fDayCountConv);
	
	double discountFactor;
    for (int i = 0; i < theCurve->fNumItems; i++)
    {
		JpmcdsDiscountDate(theCurve->fArray[i].fDate,
						   theCurve,
						   JPMCDS_FLAT_FORWARDS,
						   &discountFactor);
		
        printf("Point=%d	Date=%d	rate=%f		df=%f\n", i
			, theCurve->fArray[i].fDate
			, theCurve->fArray[i].fRate
			, discountFactor);
			  
    }
	
}
*/
TCurve* BuildZeroCurve(char *maturities[],double rates[], TDate spotDate, TDate tradeDate
							  , char *currency
							  , char baddayconvention			
							  , char *holidays			
							  , char *moneyMarketDCC			
							  , char *swapFixedDCC
							  , char *swapFloatDCC
							  , char *swapFloatFreq
							  , char *swapFixFreq
							  , char *types
							  , TDate **liborMaturities
							, double **discountFactors
							  )
{
    static char  *routine		= "BuildExampleZeroCurve"	;
    TCurve       *zc			= NULL						;
	
	//convert format of inputs
	long mmDCC, fixDCC, floatDCC;
	if (JpmcdsStringToDayCountConv(moneyMarketDCC, &mmDCC) != SUCCESS)		goto done;
	if (JpmcdsStringToDayCountConv(swapFixedDCC, &fixDCC) != SUCCESS)		goto done;
	if (JpmcdsStringToDayCountConv(swapFloatDCC, &floatDCC) != SUCCESS)		goto done;
	
	TDateInterval ivl;
	double fixFreq, floatFreq	;
	if (JpmcdsStringToDateInterval(swapFixFreq, routine, &ivl) != SUCCESS)		goto done;
	if (JpmcdsDateIntervalToFreq(&ivl, &fixFreq) != SUCCESS)					goto done;
	if (JpmcdsStringToDateInterval(swapFloatFreq, routine, &ivl) != SUCCESS)	goto done;
	if (JpmcdsDateIntervalToFreq(&ivl, &floatFreq) != SUCCESS)					goto done;
		
    int numberInstruments = strlen(types);
    TDate *dates = NEW_ARRAY(TDate, numberInstruments);

	/** adjust cash rates dates to business day */
    TDate baseDate = tradeDate;
	int dtSuccess;
    for(int i = 0; i < numberInstruments; i++)
    {
	
			//convert the interval to a date
		TDateInterval tmpIlvl;		
        if (JpmcdsStringToDateInterval(maturities[i], routine, &tmpIlvl) != SUCCESS)
        {
            JpmcdsErrMsg ("%s: invalid interval for element[%d].\n", routine, i);
            goto done;
        }
        
        if (JpmcdsDateFwdThenAdjust(spotDate, &tmpIlvl, JPMCDS_BAD_DAY_NONE, "None", dates+i) != SUCCESS)
        {
            JpmcdsErrMsg ("%s: invalid interval for element[%d].\n", routine, i);
            goto done;
        }

			//move the date to a valid business date
        if(types[i] == 'M')
        {
            if(dates[i] - baseDate <= 3)
            {
                /* for business days */
				TDateInterval tmp;
				TDateAdjIntvl busday;
				
                tmp.flag = 0;
                tmp.prd = dates[i] - baseDate;
                tmp.prd_typ = 'D';
                busday.holidayFile = holidays;
                busday.isBusDays = TRUE;
                busday.badDayConv = JPMCDS_BAD_DAY_FOLLOW;
                busday.interval = tmp;
                /* adjust to business day */
                dtSuccess = JpmcdsDtFwdAdj(baseDate, &busday, dates+i);
            }
            else if(dates[i] - baseDate <= 21)
            {
                /* for less than or equal to 3 weeks */
                /* adjust to business day */
                dtSuccess = JpmcdsBusinessDay(dates[i],'F', holidays, dates+i);
            }
            else
            {
                /* adjust to business day */
                dtSuccess = JpmcdsBusinessDay(dates[i],'M', holidays, dates+i);
            }
			
		}
    }
	
	
    //printf("calling JpmcdsBuildIRZeroCurve...\n");
    zc = JpmcdsBuildIRZeroCurve(spotDate,
								types,
								dates,
								rates,
								numberInstruments,
								mmDCC,
								(long) fixFreq,
								(long) floatFreq,
								fixDCC,
								floatDCC,
								baddayconvention,
								holidays);
	
	if (discountFactors != NULL) 
	{
			//create an array of the discount factors
		*discountFactors = NEW_ARRAY(double, numberInstruments);
		for (int i=0; i < numberInstruments; i++) 
		{
			*discountFactors[i] = 0.0;
		} //for i
		
	} //discountFactors
	
done:
	if (liborMaturities) {
		*liborMaturities = dates;
	} else {
		FREE(dates);
	}

    return zc;
}

/*
 ***************************************************************************
 ** Calculate upfront charge.
 ***************************************************************************
 */
double CalcUpfrontCharge(TCurve* curve
						 , double couponRate
						 , double parSpread
						 , double recoveryRate
						 , double notional
						 , TDate today
						 , TDate valueDate
						 , TDate startDate
						 , TDate endDate
						 , TDate benchmarkStart
						 , TDate stepinDate
						 , TBoolean isPriceClean
						 )
{
    static char  *routine = "CalcUpfrontCharge";
    
	/*
	 TDate         today;
	 TDate         valueDate;
	 TDate         startDate;
	 TDate         benchmarkStart;
	 TDate         stepinDate;
	 TDate         endDate;
	 */
	
	TBoolean      payAccOnDefault = TRUE;
    TDateInterval ivl;
    TStubMethod   stub;
    long          dcc;
	//  double        parSpread = 3600;
	// double        recoveryRate = 0.4;
  //  TBoolean      isPriceClean = FALSE;
	// double        notional = 1e7;
    double        result = -1.0;
	
    if (curve == NULL)
    {
        JpmcdsErrMsg("CalcUpfrontCharge: NULL IR zero curve passed\n");
        goto done;
    }
	
	/*
	 today          = JpmcdsDate(2008, 2, 1);
	 valueDate      = JpmcdsDate(2008, 2, 1);
	 benchmarkStart = JpmcdsDate(2008, 2, 2);
	 startDate      = JpmcdsDate(2008, 2, 8);
	 endDate        = JpmcdsDate(2008, 2, 12);
	 stepinDate     = JpmcdsDate(2008, 2, 9);
	 */
    if (JpmcdsStringToDayCountConv("Act/360", &dcc) != SUCCESS)
        goto done;
    
//    if (JpmcdsStringToDateInterval("1S", routine, &ivl) != SUCCESS)
	if (JpmcdsStringToDateInterval("Q", routine, &ivl) != SUCCESS)
        goto done;
	
	//short Front Stub
    if (JpmcdsStringToStubMethod("f/s", &stub) != SUCCESS)
        goto done;
	
    if (JpmcdsCdsoneUpfrontCharge(today,
                                  valueDate,
                                  benchmarkStart,
                                  stepinDate,
                                  startDate,
                                  endDate,
                                  couponRate / 10000.0,
                                  payAccOnDefault,
                                  &ivl,
                                  &stub,
                                  dcc,
                                  'F',
                                  "none",
                                  curve,
                                  parSpread / 10000.0,
                                  recoveryRate,
                                  isPriceClean,
                                  &result) != SUCCESS) goto done;
done:
    //return result * notional;
    return result;
}

void isda_calcValueAndStepinDate(TDate today
									,char baddayconvention
									, char *holidays			
									, TDate **valueDate
									, TDate **stepinDate
								 )
{
	TDateAdjIntvl ivl;
	ivl.isBusDays		= JPMCDS_DATE_ADJ_TYPE_BUSINESS;
	ivl.holidayFile		= holidays;
	ivl.badDayConv		= (long)baddayconvention;
	
	//valueDate T+3 Business Days
	SET_TDATE_INTERVAL(ivl.interval, 3, 'D');
	*valueDate = (TDate *)JpmcdsMallocSafe(sizeof(TDate));
	JpmcdsDtFwdAdj(today, &ivl, *valueDate);
	
	//stepinDate T+1 Calendar Days
	ivl.isBusDays = JPMCDS_DATE_ADJ_TYPE_CALENDAR;
	ivl.badDayConv = JPMCDS_BAD_DAY_NONE;
	SET_TDATE_INTERVAL(ivl.interval, 1, 'D');
	*stepinDate = (TDate *)JpmcdsMallocSafe(sizeof(TDate));
	JpmcdsDtFwdAdj(today, &ivl, *stepinDate);
	
}


int idsa_JpmcdsCdsoneSpread ( double couponRate, double upfrontCharge, double recovery, double notional
									   , TDate today
									   , TDate valueDate
									   , TDate startDate
									   , TDate endDate
									   , TDate benchmarkStart
									   , TDate stepinDate
									   , char *maturities[],double rates[]
									   , TDate spotDate
									   , const char *currency
									   , char baddayconvention			
									   , char *holidays			
									   , char *moneyMarketDCC			
									   , char *swapFixedDCC
									   , char *swapFloatDCC
									   , char *swapFloatFreq
									   , char *swapFixFreq
									   , char *types
									   , TBoolean isPriceClean
										, double *result
									   )
{
	static char  *routine = "idsa_JpmcdsCdsoneSpread";
	
	int status		= 1;
//	double result	= 0.0;
	*result = 0.0;
	
	//enable debugging
	if (JpmcdsErrMsgEnableRecord(20, 128) != SUCCESS) /* ie. 20 lines, each of max length 128 */
        goto done;
		
    long dcc;
    if (JpmcdsStringToDayCountConv("Act/360", &dcc) != SUCCESS)
        goto done;
    
	TDateInterval frequency;
	if (JpmcdsStringToDateInterval("Q", routine, &frequency) != SUCCESS)
        goto done;
	
	//short Front Stub
	TStubMethod stub;
    if (JpmcdsStringToStubMethod("f/s", &stub) != SUCCESS)
        goto done;
	
	
	TCurve *zerocurve = BuildZeroCurve(maturities,rates,spotDate, today
									   , (char *)currency
									   , baddayconvention			
									   , holidays			
									   , moneyMarketDCC			
									   , swapFixedDCC
									   , swapFloatDCC
									   , swapFloatFreq
									   , swapFixFreq
									   , types
									   , NULL
									   , NULL
									   );
	
    if (zerocurve == NULL)
        goto done;
	
	/*
	 CDS_FeeLegFlows(  startDate
	 ,  endDate
	 , couponRate
	 , notional
	 , "Q"
	 , "f/s"
	 , "ACT/360"
	 , 'F'
	 , "none"
	 );
	 
	 */	
	TBoolean payAccOnDefault = TRUE;
	if (JpmcdsCdsoneSpread(today,
						   valueDate,
						   benchmarkStart,
						   stepinDate,
						   startDate,
						   endDate,
						   couponRate / 10000.0,
						   payAccOnDefault,
						   &frequency,
						   &stub,
						   dcc,
						   'F',
						   holidays,
						   zerocurve,
						   upfrontCharge / 100.0,
						   recovery,
						   isPriceClean,
						   result) != SUCCESS) goto done;

	
    /* return 'no error' */
    status = 0;
	
done:
	/*
    if (status != 0)
	{
        printf("\n*** ERROR ***\n");
		
		
		printf("\n");
		printf("Error log contains:\n");
		printf("------------------:\n");
		
		char **lines = JpmcdsErrGetMsgRecord();
		if (lines == NULL)
			printf("(no log contents)\n");
		else
		{
			for(int i = 0; lines[i] != NULL; i++)
			{
				if (strcmp(lines[i],"") != 0)
					printf("%s\n", lines[i]);
			}//for
		}// if lines
	}//if status
	*/
	
    FREE(zerocurve);
    return status;
}


int idsa_JpmcdsCdsoneUpfrontCharge ( double couponRate, double parSpread, double recovery, double notional
			   , TDate today
			   , TDate valueDate
			   , TDate startDate
			   , TDate endDate
			   , TDate benchmarkStart
			   , TDate stepinDate
			   , char *maturities[],double rates[]
			   , TDate spotDate
			   , const char *currency
			   , char baddayconvention			
			   , char *holidays			
			   , char *moneyMarketDCC			
			   , char *swapFixedDCC
			   , char *swapFloatDCC
			   , char *swapFloatFreq
			   , char *swapFixFreq
			   , char *types
			   , TBoolean isPriceClean
				, double *result
			   )
{
	static char  *routine = "idsa_JpmcdsCdsoneUpfrontCharge";
	
	int status		= 1;
	//double result	= 0.0;
	*result = 0.0;

	//enable debugging
	if (JpmcdsErrMsgEnableRecord(20, 128) != SUCCESS) /* ie. 20 lines, each of max length 128 */
        goto done;
	
    long dcc;
    if (JpmcdsStringToDayCountConv("Act/360", &dcc) != SUCCESS)
        goto done;
    
	TDateInterval frequency;
	if (JpmcdsStringToDateInterval("Q", routine, &frequency) != SUCCESS)
        goto done;
	
		//short Front Stub
	TStubMethod stub;
    if (JpmcdsStringToStubMethod("f/s", &stub) != SUCCESS)
        goto done;
	
	
	TCurve *zerocurve = BuildZeroCurve(maturities,rates,spotDate, today
											  , (char *)currency
											  , baddayconvention			
											  , holidays			
											  , moneyMarketDCC			
											  , swapFixedDCC
											  , swapFloatDCC
											  , swapFloatFreq
											  , swapFixFreq
											  , types
									   , NULL
									   , NULL
											  );
	
    if (zerocurve == NULL)
        goto done;
	
/*  print teh cashflows
 CDS_FeeLegFlows(  startDate
						,  endDate
						, couponRate
						, notional
						, "Q"
						, "f/s"
						, "ACT/360"
						, 'F'
						, "none"
					);
	
*/	
	TBoolean payAccOnDefault = TRUE;
	if (JpmcdsCdsoneUpfrontCharge(today,
                                  valueDate,
                                  benchmarkStart,
                                  stepinDate,
                                  startDate,
                                  endDate,
                                  couponRate / 10000.0,
                                  payAccOnDefault,
                                  &frequency,
                                  &stub,
                                  dcc,
                                  'F',
                                  "none",
                                  zerocurve,
                                  parSpread / 10000.0,
                                  recovery,
                                  isPriceClean,
                                  result) != SUCCESS) goto done;
	
    /* return 'no error' */
    status = 0;
	
done:
	/*
    if (status != 0)
	{
        printf("\n*** ERROR ***\n");
				
		printf("\n");
		printf("Error log contains:\n");
		printf("------------------:\n");
		
		char **lines = JpmcdsErrGetMsgRecord();
		if (lines == NULL)
			printf("(no log contents)\n");
		else
		{
			for(int i = 0; lines[i] != NULL; i++)
			{
				if (strcmp(lines[i],"") != 0)
					printf("%s\n", lines[i]);
			}//for
		}// if lines
	}//if status
	*/

    FREE(zerocurve);
    return status;
}


/*
 ***************************************************************************
 ** Main function.
 ***************************************************************************
 */
//int main(int argc, char** argv)
double markit_main( double dCouponRate, double dParSpread, double dRecovery, double dNotional
				   , TDate today
				   , TDate valueDate
				   , TDate startDate
				   , TDate endDate
				   , TDate benchmarkStart
				   , TDate stepinDate
				   , char *maturities[],double rates[], TDate spotDate, const char *currency
				   , char baddayconvention			
				   , char *holidays			
				   , char *moneyMarketDCC			
				   , char *swapFixedDCC
				   , char *swapFloatDCC
				   , char *swapFloatFreq
				   , char *swapFixFreq
				   , char *types
				   , TBoolean isPriceClean
					)
{
    int     status = 1;
    char    version[256];
    char  **lines = NULL;
    int     i;
   // TCurve *zerocurve = NULL;
	double result = 0.0;
	
    if (JpmcdsVersionString(version) != SUCCESS)
        goto done;
	
    /* print library version */
//  printf("starting...\n");
//  printf("%s\n", version);
    
    /* enable logging */
//  printf("enabling logging...\n");
    if (JpmcdsErrMsgEnableRecord(20, 128) != SUCCESS) /* ie. 20 lines, each of max length 128 */
        goto done;
	
    /* construct IR zero curve */
  //  printf("building zero curve...\n");

	TCurve *zerocurve = BuildExampleZeroCurve(maturities,rates,spotDate,(char *)currency
											  , baddayconvention			
											  , holidays			
											  , moneyMarketDCC			
											  , swapFixedDCC
											  , swapFloatDCC
											  , swapFloatFreq
											  , swapFixFreq
											  , types
											  );

    if (zerocurve == NULL)
        goto done;
	
    /* get discount factor */
 /*
	printf("\n");
	double dDF = JpmcdsZeroPrice(zerocurve, JpmcdsDate(2008,1,3));
    printf("Discount factor on 3rd Jan 08 = %5.10f\n", dDF);
	dDF = JpmcdsZeroPrice(zerocurve, JpmcdsDate(2009,1,3));
    printf("Discount factor on 3rd Jan 09 = %5.10f\n", dDF);
	dDF = JpmcdsZeroPrice(zerocurve, JpmcdsDate(2017,1,3));
    printf("Discount factor on 3rd Jan 17 = %5.10f\n", dDF);
*/
	
    /* get upfront charge */
/*
	int nParSpread = 1500;
	float fRecovery=0.4;
	float fNotional=1e7;

	
	printf("\n");
	
    printf("Upfront charge @ cpn = 0bps    = %5.5f\n", CalcUpfrontCharge(zerocurve, dCouponRate, dParSpread, dRecovery, dNotional
																		 , JpmcdsDate(2008, 2, 1)
																		 , JpmcdsDate(2008, 2, 1)
																		 , JpmcdsDate(2008, 2, 8)
																		 , JpmcdsDate(2008, 2, 12)
																		 , JpmcdsDate(2008, 2, 2)
																		 , JpmcdsDate(2008, 2, 9)
																		 ));

	printf("Upfront charge @ cpn = 100bps  = %5.5f\n", CalcUpfrontCharge(zerocurve, 100
																		 , nParSpread, fRecovery, fNotional, JpmcdsDate(2008, 2, 1), JpmcdsDate(2008, 2, 1), JpmcdsDate(2008, 2, 8)
																		 , JpmcdsDate(2008, 2, 12), JpmcdsDate(2008, 2, 2), JpmcdsDate(2008, 2, 9)
																		 ));
    printf("Upfront charge @ cpn = 500bps  = %5.5f\n", CalcUpfrontCharge(zerocurve, 500
																		 , nParSpread, fRecovery, fNotional, JpmcdsDate(2008, 2, 1), JpmcdsDate(2008, 2, 1), JpmcdsDate(2008, 2, 8)
																		 , JpmcdsDate(2008, 2, 12), JpmcdsDate(2008, 2, 2), JpmcdsDate(2008, 2, 9)
																		 ));
    printf("Upfront charge @ cpn = 1000bps = %5.5f\n", CalcUpfrontCharge(zerocurve, 1000
																		 , nParSpread, fRecovery, fNotional, JpmcdsDate(2008, 2, 1), JpmcdsDate(2008, 2, 1), JpmcdsDate(2008, 2, 8)
																		 , JpmcdsDate(2008, 2, 12), JpmcdsDate(2008, 2, 2), JpmcdsDate(2008, 2, 9)
																		 ));
*/

    result = CalcUpfrontCharge(zerocurve, dCouponRate, dParSpread, dRecovery, dNotional
				/*
				, JpmcdsDate(2009, 11, 1)
				, JpmcdsDate(2009, 11, 1)
				, JpmcdsDate(2009, 11, 8)
				, JpmcdsDate(2009, 11, 12)
				, JpmcdsDate(2009, 11, 2)
				, JpmcdsDate(2009, 11, 9)
				*/
							   
				, today
				, valueDate
				, startDate
				, endDate
				, benchmarkStart
				, stepinDate
				, isPriceClean			   
				);
	
	
    /* return 'no error' */
    status = 0;
	
done:
    if (status != 0)
	{
        printf("\n*** ERROR ***\n");
	
		/* print error log contents */
    
		printf("\n");
		printf("Error log contains:\n");
		printf("------------------:\n");
	
		lines = JpmcdsErrGetMsgRecord();
		if (lines == NULL)
			printf("(no log contents)\n");
		else
		{
			for(i = 0; lines[i] != NULL; i++)
			{
				if (strcmp(lines[i],"") != 0)
					printf("%s\n", lines[i]);
			}//for
		}// if lines
	}//if status
	
    FREE(zerocurve);
    return result;
}
