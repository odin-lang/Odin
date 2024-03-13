//+build darwin
package darwin

Bool :: b8

timespec :: struct {
        seconds:      int,
        microseconds: int,
}

RUsage :: struct {
        utime:         timespec,
        stime:         timespec,
        maxrss_word:   int,
        ixrss_word:    int,
        idrss_word:    int,
        isrss_word:    int,
        minflt_word:   int,
        majflt_word:   int,
        nswap_word:    int,
        inblock_word:  int,
        oublock_word:  int,
        msgsnd_word:   int,
        msgrcv_word:   int,
        nsignals_word: int,
        nvcsw_word:    int,
        nivcsw_word:   int,
}
