/* airportd shim for macOS 27 (loaded only through DYLD_INSERT_LIBRARIES):
 * 1. IO80211 log functions: variadic calls break across the a2x bridge (ARM64 passes them on the stack).
 * 2. apple80211_*toStr: plain functions on macOS 27, data symbols in the OCLP IO80211 shim.
 * 3. EAPOLControl*: configd runs as x86_64, EAPOLController.bundle exists only for arm64e.
 *    The Mach service is therefore never served and every call blocks forever.
 *    Answer here: "no 802.1X active". WPA Personal does not need the service. */
#include <errno.h>
#include <stddef.h>
extern void ASL_LOG(void), IO8Log(void), IO8Log2(void), apple80211_roam_profile_typetoStr(void),
    apple80211_authtype_uppertoStr(void), apple80211_apmodetoStr(void);
extern void EAPOLControlStart(void), EAPOLControlStartWithOptions(void), EAPOLControlStartWithClientItemID(void),
    EAPOLControlStartSystem(void), EAPOLControlStartSystemWithClientItemID(void), EAPOLControlStop(void),
    EAPOLControlUpdate(void), EAPOLControlRetry(void), EAPOLControlProvideUserInput(void), EAPOLControlSetLogLevel(void),
    EAPOLControlCopyStateAndStatus(void), EAPOLControlCopyLoginWindowConfiguration(void),
    EAPOLControlCopyLoginWindowClientItemID(void), EAPOLControlCopyAutoDetectInformation(void), EAPOLControlDidUserCancel(void);

static long no_log(void) { return 0; }
static const char *roam_profile_str(int type) { (void)type; return "Unknown"; }

static int eap_unavailable(void) { return ENOTSUP; }
static int eap_not_running(void) { return ENOENT; }
static int eap_no_cancel(void) { return 0; }
static int eap_state(const void *ifname, unsigned int *state, const void **status) {
    (void)ifname; if (state) *state = 0; /* kEAPOLControlStateIdle */ if (status) *status = NULL; return ENOENT;
}
static int eap_copy_if(const void *ifname, const void **out) { (void)ifname; if (out) *out = NULL; return ENOENT; }
static int eap_copy(const void **out) { if (out) *out = NULL; return ENOENT; }

__attribute__((used, section("__DATA,__interpose")))
static const struct { const void *replacement, *replacee; } interposers[] = {
    { no_log, ASL_LOG }, { no_log, IO8Log }, { no_log, IO8Log2 },
    { roam_profile_str, apple80211_roam_profile_typetoStr }, { roam_profile_str, apple80211_authtype_uppertoStr },
    { roam_profile_str, apple80211_apmodetoStr },
    { eap_unavailable, EAPOLControlStart }, { eap_unavailable, EAPOLControlStartWithOptions },
    { eap_unavailable, EAPOLControlStartWithClientItemID }, { eap_unavailable, EAPOLControlStartSystem },
    { eap_unavailable, EAPOLControlStartSystemWithClientItemID },
    { eap_not_running, EAPOLControlStop }, { eap_not_running, EAPOLControlUpdate }, { eap_not_running, EAPOLControlRetry },
    { eap_not_running, EAPOLControlProvideUserInput }, { eap_not_running, EAPOLControlSetLogLevel },
    { eap_state, EAPOLControlCopyStateAndStatus }, { eap_copy_if, EAPOLControlCopyLoginWindowConfiguration },
    { eap_copy_if, EAPOLControlCopyLoginWindowClientItemID }, { eap_copy, EAPOLControlCopyAutoDetectInformation },
    { eap_no_cancel, EAPOLControlDidUserCancel },
};
