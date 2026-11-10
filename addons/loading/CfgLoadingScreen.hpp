#define LOADING_SCREEN_CLASS(className,authorName) \
    class className { \
        author = QUOTE(authorName); \
        path = QPATHTOF(ui\loading\##className##.paa); \
        class Noise { \
            text="\A3\Ui_f\data\GUI\Cfg\LoadingScreens\LoadingNoise_ca.paa"; \
        }; \
    }

// a holiday on a fixed date, and one on the nth weekday of its month; both
// run the usual HOLIDAY_RUN_UP_DAYS ahead of the day and end on it
#define HOLIDAY_ON(className,m,d) \
    class className { \
        logo = QPATHTOF(ui\holidays\##className##.paa); \
        month = m; \
        day = d; \
        daysBefore = HOLIDAY_RUN_UP_DAYS; \
        daysAfter = 0; \
    }
#define HOLIDAY_NTH(className,m,wd,n) \
    class className { \
        logo = QPATHTOF(ui\holidays\##className##.paa); \
        month = m; \
        weekday = wd; \
        nth = n; \
        daysBefore = HOLIDAY_RUN_UP_DAYS; \
        daysAfter = 0; \
    }

class GVAR(CfgLoadingScreen) {
    class Backgrounds {
        LOADING_SCREEN_CLASS(269676636,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(269676677,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(271859839,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(285905473,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(296841733,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(297308106,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(298480575,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(361616315,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(287796119,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(288887578,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(319048089,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(maxresdefault,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(269677107,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(272813407,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(275306051,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(283924597,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(371890417,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(400370807,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(254754921,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(273347491,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(275458856,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(286142395,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(298331323,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(356376886,1st Joint Multi-Functional Strike Battalion);
        LOADING_SCREEN_CLASS(S291207115895,1st Joint Multi-Functional Strike Battalion);
    };

    // THE HOLIDAY CRESTS (user, 2026-10-30: "set up these holiday logos, in
    // most cases run them 7 days before the holiday; Christmas takes priority
    // over New Year's; run New Year's the 26th to Jan 2"). One class per
    // crest, ui\holidays\<class>.paa from art/JMSB-holidays
    // (tools/gen_holiday_logos.py), shown from daysBefore days ahead of its
    // day to daysAfter days past it. The date is month + day; month + weekday
    // + nth (the month's nth such weekday, NTH_LAST its last); or easter = 1
    // (the computus). Where two windows overlap the holiday nearer today wins
    // (FUNC(holiday)): Christmas Day over a New Year run-up, St Patrick's
    // over an early Easter's.
    class Holidays {
        // Christmas has its day first: the 26th to Jan 2, not the usual 7
        class newYearsDay {
            logo = QPATHTOF(ui\holidays\newYearsDay.paa);
            month = 1;
            day = 1;
            daysBefore = 6;
            daysAfter = 1;
        };
        HOLIDAY_ON(valentinesDay,2,14);
        HOLIDAY_ON(stPatricksDay,3,17);
        class easter {
            logo = QPATHTOF(ui\holidays\easter.paa);
            easter = 1;
            daysBefore = HOLIDAY_RUN_UP_DAYS;
            daysAfter = 0;
        };
        HOLIDAY_NTH(memorialDay,5,WEEKDAY_MONDAY,NTH_LAST);
        HOLIDAY_ON(independenceDay,7,4);
        HOLIDAY_NTH(indigenousPeoplesDay,10,WEEKDAY_MONDAY,2);
        HOLIDAY_ON(halloween,10,31);
        HOLIDAY_ON(veteransDay,11,11);
        HOLIDAY_NTH(thanksgiving,11,WEEKDAY_THURSDAY,4);
        HOLIDAY_ON(christmas,12,25);
    };
};
