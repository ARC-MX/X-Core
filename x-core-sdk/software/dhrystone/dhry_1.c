/*
 ****************************************************************************
 *
 *                   "DHRYSTONE" Benchmark Program
 *                   -----------------------------
 *                                                                            
 *  Version:    C, Version 2.1
 *                                                                            
 *  File:       dhry_1.c (part 2 of 3)
 *
 *  Date:       May 25, 1988
 *
 *  Author:     Reinhold P. Weicker
 *
 ****************************************************************************
 */

#include "dhry.h"
#include "string.h"
//#include "dhrystone.h"

/* Global Variables: */
Rec_Pointer     Ptr_Glob,
                Next_Ptr_Glob;
int             Int_Glob;
Boolean         Bool_Glob;
char            Ch_1_Glob,
                Ch_2_Glob;
int             Arr_1_Glob [50];
int             Arr_2_Glob [50] [50];

extern char     *malloc ();
Enumeration     Func_1 ();
  /* forward declaration necessary since Enumeration may not simply be int */

#ifndef REG
        Boolean Reg = false;
#define REG
        /* REG becomes defined as empty */
        /* i.e. no register variables   */
#else
        Boolean Reg = true;
#endif

/* variables for time measurement: */

#ifdef TIMES
struct tms      time_info;
extern  int     times ();
                /* see library function "times" */
#define Too_Small_Time 120
                /* Measurements should last at least about 2 seconds */
#endif
#ifdef TIME
extern long     time();
                /* see library function "time"  */
#define Too_Small_Time 2
                /* Measurements should last at least 2 seconds */
#endif

long            Begin_Cycle,
                End_Cycle,
                User_Cycle;
long            Begin_Instret,
                End_Instret,
                User_Instret,
                Instret;
long            Begin_Time,
                End_Time,
                User_Time;
float           Microseconds,
                Dhrystones_Per_Second;
float           DMIPS_MHZ;

/* end of variables for time measurement */


int main ()
/*****/

  /* main program, corresponds to procedures        */
  /* Main and Proc_0 in the Ada version             */
{
        One_Fifty       Int_1_Loc;
  REG   One_Fifty       Int_2_Loc;
        One_Fifty       Int_3_Loc;
  REG   char            Ch_Index;
        Enumeration     Enum_Loc;
        Str_30          Str_1_Loc;
        Str_30          Str_2_Loc;
  REG   int             Run_Index;
  REG   int             Number_Of_Runs;

  /* Initializations */

  Next_Ptr_Glob = (Rec_Pointer) malloc (sizeof (Rec_Type));
  Ptr_Glob = (Rec_Pointer) malloc (sizeof (Rec_Type));

  Ptr_Glob->Ptr_Comp                    = Next_Ptr_Glob;
  Ptr_Glob->Discr                       = Ident_1;
  Ptr_Glob->variant.var_1.Enum_Comp     = Ident_3;
  Ptr_Glob->variant.var_1.Int_Comp      = 40;
  strcpy (Ptr_Glob->variant.var_1.Str_Comp, 
          "DHRYSTONE PROGRAM, SOME STRING");
  strcpy (Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");

  Arr_2_Glob [8][7] = 10;
        /* Was missing in published program. Without this statement,    */
        /* Arr_2_Glob [8][7] would have an undefined value.             */
        /* Warning: With 16-Bit processors and Number_Of_Runs > 32000,  */
        /* overflow may occur for this array element.                   */

  printf ("\r\n");
  printf ("Dhrystone Benchmark, Version 2.1 (Language: C)\r\n");
  printf ("\r\n");
  if (Reg)
  {
    printf ("Program compiled with 'register' attribute\r\n");
    printf ("\f\n");
  }
  else
  {
    printf ("Program compiled without 'register' attribute\r\n");
    printf ("\r\n");
  }
  printf ("Please give the number of runs through the benchmark: ");
  {
    int n;
    scanf ("%d", &n);
    Number_Of_Runs = 2000000;
  }
  printf ("\r\n");

  printf ("Execution starts, %d runs through Dhrystone\r\n", Number_Of_Runs);

  /***************/
  /* Start timer */
  /***************/
 
#ifdef TIMES
  times (&time_info);
  Begin_Time = (long) time_info.tms_utime;
#endif
#ifdef TIME
  Begin_Time = time ( );
#endif
  Begin_Instret =  csr_instret ( );
  Begin_Cycle =  csr_cycle ( );

  for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index)
  {

    Proc_5();
    Proc_4();
      /* Ch_1_Glob == 'A', Ch_2_Glob == 'B', Bool_Glob == true */
    Int_1_Loc = 2;
    Int_2_Loc = 3;
    strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
    Enum_Loc = Ident_2;
    Bool_Glob = ! Func_2 (Str_1_Loc, Str_2_Loc);
      /* Bool_Glob == 1 */
    while (Int_1_Loc < Int_2_Loc)  /* loop body executed once */
    {
      Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
        /* Int_3_Loc == 7 */
      Proc_7 (Int_1_Loc, Int_2_Loc, &Int_3_Loc);
        /* Int_3_Loc == 7 */
      Int_1_Loc += 1;
    } /* while */
      /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
    Proc_8 (Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
      /* Int_Glob == 5 */
    Proc_1 (Ptr_Glob);
    for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index)
                             /* loop body executed twice */
    {
      if (Enum_Loc == Func_1 (Ch_Index, 'C'))
          /* then, not executed */
        {
        Proc_6 (Ident_1, &Enum_Loc);
        strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
        Int_2_Loc = Run_Index;
        Int_Glob = Run_Index;
        }
    }
      /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
    Int_2_Loc = Int_2_Loc * Int_1_Loc;
    Int_1_Loc = Int_2_Loc / Int_3_Loc;
    Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
      /* Int_1_Loc == 1, Int_2_Loc == 13, Int_3_Loc == 7 */
    Proc_2 (&Int_1_Loc);
      /* Int_1_Loc == 5 */

  } /* loop "for Run_Index" */

  /**************/
  /* Stop timer */
  /**************/
  End_Cycle = csr_cycle ( );
  
#ifdef TIMES
  times (&time_info);
  End_Time = (long) time_info.tms_utime;
#endif
#ifdef TIME
  End_Time = time ( );
#endif
  End_Instret = csr_instret ( );

  printf ("Execution ends\r\n");
  printf ("\r\n");
  printf ("Final values of the variables used in the benchmark:\r\n");
  printf ("\r\n");
  printf ("Int_Glob:            %d\r\n", Int_Glob);
  printf ("        should be:   %d\r\n", 5);
  printf ("Bool_Glob:           %d\r\n", Bool_Glob);
  printf ("        should be:   %d\r\n", 1);
  printf ("Ch_1_Glob:           %c\r\n", Ch_1_Glob);
  printf ("        should be:   %c\r\n", 'A');
  printf ("Ch_2_Glob:           %c\r\n", Ch_2_Glob);
  printf ("        should be:   %c\r\n", 'B');
  printf ("Arr_1_Glob[8]:       %d\r\n", Arr_1_Glob[8]);
  printf ("        should be:   %d\r\n", 7);
  printf ("Arr_2_Glob[8][7]:    %d\r\n", Arr_2_Glob[8][7]);
  printf ("        should be:   Number_Of_Runs + 10\r\n");
  printf ("Ptr_Glob->\r\n");
  printf ("  Ptr_Comp:          %d\r\n", (int) Ptr_Glob->Ptr_Comp);
  printf ("        should be:   (implementation-dependent)\r\n");
  printf ("  Discr:             %d\r\n", Ptr_Glob->Discr);
  printf ("        should be:   %d\r\n", 0);
  printf ("  Enum_Comp:         %d\r\n", Ptr_Glob->variant.var_1.Enum_Comp);
  printf ("        should be:   %d\r\n", 2);
  printf ("  Int_Comp:          %d\r\n", Ptr_Glob->variant.var_1.Int_Comp);
  printf ("        should be:   %d\r\n", 17);
  printf ("  Str_Comp:          %s\r\n", Ptr_Glob->variant.var_1.Str_Comp);
  printf ("        should be:   DHRYSTONE PROGRAM, SOME STRING\r\n");
  printf ("Next_Ptr_Glob->\r\n");
  printf ("  Ptr_Comp:          %d\r\n", (int) Next_Ptr_Glob->Ptr_Comp);
  printf ("        should be:   (implementation-dependent), same as above\r\n");
  printf ("  Discr:             %d\r\n", Next_Ptr_Glob->Discr);
  printf ("        should be:   %d\r\n", 0);
  printf ("  Enum_Comp:         %d\r\n", Next_Ptr_Glob->variant.var_1.Enum_Comp);
  printf ("        should be:   %d\r\n", 1);
  printf ("  Int_Comp:          %d\r\n", Next_Ptr_Glob->variant.var_1.Int_Comp);
  printf ("        should be:   %d\r\n", 18);
  printf ("  Str_Comp:          %s\r\n",
                                Next_Ptr_Glob->variant.var_1.Str_Comp);
  printf ("        should be:   DHRYSTONE PROGRAM, SOME STRING\r\n");
  printf ("Int_1_Loc:           %d\r\n", Int_1_Loc);
  printf ("        should be:   %d\r\n", 5);
  printf ("Int_2_Loc:           %d\r\n", Int_2_Loc);
  printf ("        should be:   %d\r\n", 13);
  printf ("Int_3_Loc:           %d\r\n", Int_3_Loc);
  printf ("        should be:   %d\r\n", 7);
  printf ("Enum_Loc:            %d\r\n", Enum_Loc);
  printf ("        should be:   %d\r\n", 1);
  printf ("Str_1_Loc:           %s\r\n", Str_1_Loc);
  printf ("        should be:   DHRYSTONE PROGRAM, 1'ST STRING\r\n");
  printf ("Str_2_Loc:           %s\r\n", Str_2_Loc);
  printf ("        should be:   DHRYSTONE PROGRAM, 2'ND STRING\r\n");
  printf ("\r\n");

  User_Time = End_Time - Begin_Time;
  User_Instret = End_Instret - Begin_Instret;
  User_Cycle = End_Cycle - Begin_Cycle;

  if (User_Time < Too_Small_Time)
  {
    printf ("Measured time too small to obtain meaningful results\r\n");
    printf ("Please increase number of runs %d\r\n",User_Time);
    printf ("\r\n");
  }
  else
  {
#ifdef TIME
    Microseconds = (float) User_Time * Mic_secs_Per_Second 
                        / (float) Number_Of_Runs;
    Dhrystones_Per_Second = (float) Number_Of_Runs / (float) User_Time;
#else
    Microseconds = (float) User_Time * Mic_secs_Per_Second 
                        / ((float) HZ * ((float) Number_Of_Runs));
    Dhrystones_Per_Second = ((float) HZ * (float) Number_Of_Runs)
                        / (float) User_Time;
#endif
    Instret =  User_Instret / Number_Of_Runs;

    //printf ("Microseconds for one run through Dhrystone: ");
    //printf ("%6.1f \n", Microseconds);
    //printf ("Dhrystones per Second:                      ");
    //printf ("%6.1f \n", Dhrystones_Per_Second);
    //printf ("\n");
    //printf ("\n");

    //DMIPS_MHZ = (Dhrystones_Per_Second/8.388)/1757;
    DMIPS_MHZ = (1000000/((float)User_Cycle/(float)Number_Of_Runs))/1757;

    //printf ("Print Personal Added Addtional Info to Easy Visual Analysis\n");
    //printf ("\n");
    printf (" (*) User_Cycle for total run through Dhrystone with loops %d: \r\n", Number_Of_Runs);
    printf ("%ld \r\n", User_Cycle);
    //printf (" (*) User_Time  for total run through Dhrystone with loops %d: \n", Number_Of_Runs);
    //printf ("%lld \n", User_Time);
    //printf ("\n");
    //printf (" (*) Instret for one run through Dhrystone: ");
    //printf ("%lld \n", Instret);
    //printf ("\n");
    //printf (" (*) Please ignore the above printed Dhrystones_Per_Second since it is using the User_Time which\n");
    //printf ("       is a long type and derived from a division and generated quite lots of deviations. So here\n");
    //printf ("       we use the original User_Cycle to caculate.\n");
    //printf ("     Assume the core is running at 1MHZ, and each loop need cycles of User_Cycle/Number_Of_Runs \n");
    //printf ("       then the Dhrystones_Per_Second is 1000000/(User_Cycle/Number_Of_Runs)\n");
    printf ("       So the DMIPS/MHz can be caculated by: \r\n");
    printf ("       1000000/(User_Cycle/Number_Of_Runs)/1757 = %2.6f DMIPS/MHz\r\n",DMIPS_MHZ);
    printf ("\r\n");
  }
  
}


Proc_1 (Ptr_Val_Par)
/******************/

REG Rec_Pointer Ptr_Val_Par;
    /* executed once */
{
  REG Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;  
                                        /* == Ptr_Glob_Next */
  /* Local variable, initialized with Ptr_Val_Par->Ptr_Comp,    */
  /* corresponds to "rename" in Ada, "with" in Pascal           */
  
  structassign (*Ptr_Val_Par->Ptr_Comp, *Ptr_Glob); 
  Ptr_Val_Par->variant.var_1.Int_Comp = 5;
  Next_Record->variant.var_1.Int_Comp 
        = Ptr_Val_Par->variant.var_1.Int_Comp;
  Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
  Proc_3 (&Next_Record->Ptr_Comp);
    /* Ptr_Val_Par->Ptr_Comp->Ptr_Comp 
                        == Ptr_Glob->Ptr_Comp */
  if (Next_Record->Discr == Ident_1)
    /* then, executed */
  {
    Next_Record->variant.var_1.Int_Comp = 6;
    Proc_6 (Ptr_Val_Par->variant.var_1.Enum_Comp, 
           &Next_Record->variant.var_1.Enum_Comp);
    Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
    Proc_7 (Next_Record->variant.var_1.Int_Comp, 10, 
           &Next_Record->variant.var_1.Int_Comp);
  }
  else /* not executed */
    structassign (*Ptr_Val_Par, *Ptr_Val_Par->Ptr_Comp);
} /* Proc_1 */


Proc_2 (Int_Par_Ref)
/******************/
    /* executed once */
    /* *Int_Par_Ref == 1, becomes 4 */

One_Fifty   *Int_Par_Ref;
{
  One_Fifty  Int_Loc;  
  Enumeration   Enum_Loc;

  Int_Loc = *Int_Par_Ref + 10;
  do /* executed once */
    if (Ch_1_Glob == 'A')
      /* then, executed */
    {
      Int_Loc -= 1;
      *Int_Par_Ref = Int_Loc - Int_Glob;
      Enum_Loc = Ident_1;
    } /* if */
  while (Enum_Loc != Ident_1); /* true */
} /* Proc_2 */


Proc_3 (Ptr_Ref_Par)
/******************/
    /* executed once */
    /* Ptr_Ref_Par becomes Ptr_Glob */

Rec_Pointer *Ptr_Ref_Par;

{
  if (Ptr_Glob != Null)
    /* then, executed */
    *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
  Proc_7 (10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
} /* Proc_3 */


Proc_4 () /* without parameters */
/*******/
    /* executed once */
{
  Boolean Bool_Loc;

  Bool_Loc = Ch_1_Glob == 'A';
  Bool_Glob = Bool_Loc | Bool_Glob;
  Ch_2_Glob = 'B';
} /* Proc_4 */


Proc_5 () /* without parameters */
/*******/
    /* executed once */
{
  Ch_1_Glob = 'A';
  Bool_Glob = false;
} /* Proc_5 */


        /* Procedure for the assignment of structures,          */
        /* if the C compiler doesn't support this feature       */
#ifdef  NOSTRUCTASSIGN
memcpy (d, s, l)
register char   *d;
register char   *s;
register int    l;
{
        while (l--) *d++ = *s++;
}
#endif


