#import "AngelNotchServiceBridge.h"

#import <ServiceManagement/ServiceManagement.h>
#include <stdio.h>
#include <string.h>

static char ANLaunchAtLoginErrorBuffer[1024] = "";

static void ANStoreError(NSError *error) {
    const char *message = error.localizedDescription.UTF8String;
    snprintf(
        ANLaunchAtLoginErrorBuffer,
        sizeof(ANLaunchAtLoginErrorBuffer),
        "%s",
        message ?: "Unable to update Launch at Login."
    );
}

bool ANLaunchAtLoginIsEnabled(void) {
    if (@available(macOS 13.0, *)) {
        return SMAppService.mainAppService.status == SMAppServiceStatusEnabled;
    }
    return false;
}

bool ANLaunchAtLoginRequiresApproval(void) {
    if (@available(macOS 13.0, *)) {
        return SMAppService.mainAppService.status
            == SMAppServiceStatusRequiresApproval;
    }
    return false;
}

bool ANSetLaunchAtLoginEnabled(bool enabled) {
    ANLaunchAtLoginErrorBuffer[0] = '\0';
    if (@available(macOS 13.0, *)) {
        NSError *error = nil;
        BOOL succeeded = enabled
            ? [SMAppService.mainAppService registerAndReturnError:&error]
            : [SMAppService.mainAppService unregisterAndReturnError:&error];
        if (!succeeded) {
            ANStoreError(error);
        }
        return succeeded;
    }

    snprintf(
        ANLaunchAtLoginErrorBuffer,
        sizeof(ANLaunchAtLoginErrorBuffer),
        "%s",
        "Launch at Login requires macOS 13 or newer."
    );
    return false;
}

const char *ANLaunchAtLoginLastError(void) {
    return ANLaunchAtLoginErrorBuffer[0] == '\0'
        ? NULL
        : ANLaunchAtLoginErrorBuffer;
}
