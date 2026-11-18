/* For WiFiAgent and ControlCenter: EAPOLController never answers on macOS 27,
 * because configd runs as x86_64 and the plugin exists only for arm64e. Answer: "no 802.1X active". */
#include <errno.h>
#include <stddef.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
extern void EAPOLControlStart(void), EAPOLControlStartWithOptions(void), EAPOLControlStartWithClientItemID(void),
    EAPOLControlStartSystem(void), EAPOLControlStartSystemWithClientItemID(void), EAPOLControlStop(void),
    EAPOLControlUpdate(void), EAPOLControlRetry(void), EAPOLControlProvideUserInput(void), EAPOLControlSetLogLevel(void),
    EAPOLControlCopyStateAndStatus(void), EAPOLControlCopyLoginWindowConfiguration(void),
    EAPOLControlCopyLoginWindowClientItemID(void), EAPOLControlCopyAutoDetectInformation(void), EAPOLControlDidUserCancel(void);
static int eap_unavailable(void) { return ENOTSUP; }
static int eap_not_running(void) { return ENOENT; }
static int eap_no_cancel(void) { return 0; }
static int eap_state(const void *i, unsigned int *s, const void **d) { (void)i; if (s) *s = 0; if (d) *d = NULL; return ENOENT; }
static int eap_copy_if(const void *i, const void **o) { (void)i; if (o) *o = NULL; return ENOENT; }
static int eap_copy(const void **o) { if (o) *o = NULL; return ENOENT; }
/* Marker so the service can tell that the shim is loaded. */
__attribute__((constructor)) static void mark(void) {
    char p[64]; snprintf(p, sizeof p, "/tmp/wifi27-eapolshim.%d", getpid());
    int f = open(p, O_CREAT | O_EXCL | O_WRONLY | O_NOFOLLOW, 0644); if (f >= 0) close(f);
}
__attribute__((used, section("__DATA,__interpose")))
static const struct { const void *replacement, *replacee; } interposers[] = {
    { eap_unavailable, EAPOLControlStart }, { eap_unavailable, EAPOLControlStartWithOptions },
    { eap_unavailable, EAPOLControlStartWithClientItemID }, { eap_unavailable, EAPOLControlStartSystem },
    { eap_unavailable, EAPOLControlStartSystemWithClientItemID }, { eap_not_running, EAPOLControlStop },
    { eap_not_running, EAPOLControlUpdate }, { eap_not_running, EAPOLControlRetry },
    { eap_not_running, EAPOLControlProvideUserInput }, { eap_not_running, EAPOLControlSetLogLevel },
    { eap_state, EAPOLControlCopyStateAndStatus }, { eap_copy_if, EAPOLControlCopyLoginWindowConfiguration },
    { eap_copy_if, EAPOLControlCopyLoginWindowClientItemID }, { eap_copy, EAPOLControlCopyAutoDetectInformation },
    { eap_no_cancel, EAPOLControlDidUserCancel },
};
